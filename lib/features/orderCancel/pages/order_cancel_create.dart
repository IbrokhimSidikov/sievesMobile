import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/cancel_order_model.dart';

/// New cancellation flow: search & pick an order, capture the required proof
/// photos + witnesses + reason, then submit (cancel order + Telegram notice).
class OrderCancelCreate extends StatefulWidget {
  final int branchId;
  final int daySessionId;

  const OrderCancelCreate({
    super.key,
    required this.branchId,
    required this.daySessionId,
  });

  @override
  State<OrderCancelCreate> createState() => _OrderCancelCreateState();
}

class _OrderCancelCreateState extends State<OrderCancelCreate> {
  final AuthManager _authManager = AuthManager();
  final ImagePicker _picker = ImagePicker();
  final NumberFormat _money = NumberFormat.decimalPattern();

  static const Color _accent = AppColors.cx3FBDA3;

  static const List<String> _reasons = [
    'Ошибка Колл Центр',
    'Ошибка ресторана',
    'Клиент отменил',
  ];

  // ── Search / selection ──
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<CancelOrder> _results = [];

  CancelOrder? _order;
  bool _loadingDetail = false;

  /// IDs of orders already cancelled for this day session — excluded from
  /// search results so they can't be cancelled twice. Refreshed each time the
  /// page opens.
  final Set<int> _cancelledIds = {};

  // ── Witnesses ──
  List<Witness> _allWitnesses = [];
  final Set<Witness> _selectedWitnesses = {};

  // ── Form state ──
  bool _sign = false;
  bool _word = false;
  final Set<String> _selectedReasons = {};
  final TextEditingController _moreAboutReasonCtrl = TextEditingController();
  final TextEditingController _measuresCtrl = TextEditingController();
  final FocusNode _moreAboutReasonFocus = FocusNode();
  final FocusNode _measuresFocus = FocusNode();
  // Each photo is uploaded eagerly as soon as it's picked so that submit only
  // has to wait for whatever is still in flight (instead of both uploads).
  File? _chequePhoto;
  Map<String, dynamic>? _chequeModel;
  Future<Map<String, dynamic>?>? _chequeUpload;
  bool _chequeUploading = false;

  File? _witnessPhoto;
  Map<String, dynamic>? _witnessModel;
  Future<Map<String, dynamic>?>? _witnessUpload;
  bool _witnessUploading = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadWitnesses();
    _loadCancelledIds();
  }

  Future<void> _loadCancelledIds() async {
    final raw = await _authManager.apiService.getCancelledOrders(
      branchId: widget.branchId,
      daySessionId: widget.daySessionId,
    );
    if (!mounted) return;
    setState(() {
      _cancelledIds
        ..clear()
        ..addAll(raw.map(CancelOrder.fromJson).map((o) => o.id));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _moreAboutReasonCtrl.dispose();
    _measuresCtrl.dispose();
    _moreAboutReasonFocus.dispose();
    _measuresFocus.dispose();
    super.dispose();
  }

  Future<void> _loadWitnesses() async {
    final employees =
        await _authManager.apiService.getBranchEmployees(widget.branchId);
    final witnesses = <Witness>[];
    for (final e in employees) {
      final individual = e['individual'];
      if (individual is Map) {
        final id = (individual['id'] as num?)?.toInt() ??
            (e['individual_id'] as num?)?.toInt();
        final name = individual['full_name']?.toString();
        if (id != null && name != null && name.trim().isNotEmpty) {
          witnesses.add(Witness(id: id, fullName: name));
        }
      }
    }
    if (mounted) setState(() => _allWitnesses = witnesses);
  }

  // ─────────────────────────── Search ───────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final raw = await _authManager.apiService.searchOrders(
      query: query,
      branchId: widget.branchId,
      daySessionId: widget.daySessionId,
    );
    if (!mounted) return;
    setState(() {
      _results = raw
          .map(CancelOrder.fromJson)
          .where((o) => !_cancelledIds.contains(o.id))
          .toList();
      _searching = false;
    });
  }

  Future<void> _selectOrder(CancelOrder order) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingDetail = true;
      _results = [];
      _searchCtrl.clear();
    });

    final detail = await _authManager.apiService.getOrderDetail(order.id);
    if (!mounted) return;
    setState(() {
      _order = detail != null ? CancelOrder.fromJson(detail) : order;
      _loadingDetail = false;
    });
  }

  void _changeOrder() {
    setState(() {
      _order = null;
      _results = [];
      _searchCtrl.clear();
    });
  }

  // ─────────────────────────── Photos ───────────────────────────

  Future<void> _pickChequePhoto() async {
    final source = await _chooseSource();
    if (source == null) return;
    final file = await _pickCompressed(source: source);
    if (file != null && mounted) {
      setState(() => _chequePhoto = file);
      _uploadCheque(file);
    }
  }

  Future<void> _captureWitnessPhoto() async {
    final file = await _pickCompressed(
      source: ImageSource.camera,
      camera: CameraDevice.front,
    );
    if (file != null && mounted) {
      setState(() => _witnessPhoto = file);
      _uploadWitness(file);
    }
  }

  String get _objectId => _order?.receiptNumber ?? '0';

  /// Start uploading the cheque photo in the background. A newer pick
  /// supersedes an in-flight upload (tracked by identity of the Future).
  void _uploadCheque(File file) {
    final future = _authManager.apiService.uploadCancelPhoto(file, _objectId);
    setState(() {
      _chequeUpload = future;
      _chequeModel = null;
      _chequeUploading = true;
    });
    future.then((model) {
      if (!mounted || _chequeUpload != future) return;
      setState(() {
        _chequeModel = model;
        _chequeUploading = false;
      });
      if (model == null) {
        _showSnack('Chek rasmini yuklashda xatolik', isError: true);
      }
    });
  }

  void _uploadWitness(File file) {
    final future = _authManager.apiService.uploadCancelPhoto(file, _objectId);
    setState(() {
      _witnessUpload = future;
      _witnessModel = null;
      _witnessUploading = true;
    });
    future.then((model) {
      if (!mounted || _witnessUpload != future) return;
      setState(() {
        _witnessModel = model;
        _witnessUploading = false;
      });
      if (model == null) {
        _showSnack('Guvohlar rasmini yuklashda xatolik', isError: true);
      }
    });
  }

  /// Picks an image with the resolution/quality capped so the upload stays
  /// well under the server's request-size limit (avoids HTTP 413). Rejects
  /// anything still unexpectedly large after compression.
  Future<File?> _pickCompressed({
    required ImageSource source,
    CameraDevice camera = CameraDevice.rear,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 55,
      maxWidth: 1280,
      maxHeight: 1280,
      preferredCameraDevice: camera,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final sizeMB = (await file.length()) / (1024 * 1024);
    if (sizeMB > 4) {
      if (mounted) {
        _showSnack(
          'Rasm hajmi juda katta (${sizeMB.toStringAsFixed(1)} MB). '
          'Kichikroq rasm tanlang.',
          isError: true,
        );
      }
      return null;
    }
    return file;
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galereya'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Submit ───────────────────────────

  String? _validate() {
    if (_sign == false) return 'Imzo qo\'yilmadi (Подпись)';
    if (_word == false) return '"Отмен" so\'zi yozilmadi';
    if (_selectedWitnesses.isEmpty) return 'Guvohlarni belgilang';
    if (_selectedReasons.isEmpty) return 'Bekor sababini tanlang';
    if (_moreAboutReasonCtrl.text.trim().length <= 4) {
      return 'Sabab haqida batafsil yozing (5+ harf)';
    }
    if (_measuresCtrl.text.trim().length <= 4) {
      return 'Qanday chora ko\'rildi (5+ harf)';
    }
    if (_chequePhoto == null) return 'Chek rasmi yetishmayapti';
    if (_witnessPhoto == null) return 'Guvohlar rasmi yetishmayapti';
    return null;
  }

  Future<void> _submit() async {
    final order = _order;
    if (order == null) return;

    final error = _validate();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = _authManager.apiService;

      // Photos were uploaded eagerly on pick; reuse their results, only
      // awaiting whatever upload is still in flight.
      final chequeModel = _chequeModel ?? await _chequeUpload;
      final witnessModel = _witnessModel ?? await _witnessUpload;

      if (chequeModel == null || witnessModel == null) {
        _fail('Rasm yuklashda xatolik');
        return;
      }

      // Cancel the order (PUT ?cancel=1 with the expanded order body).
      final ok = await api.cancelOrder(order.id, order.raw);
      if (!ok) {
        _fail('Buyurtmani bekor qilishda xatolik');
        return;
      }

      // Notify Telegram with the composed message + witnesses selfie proof.
      await api.sendCancelTelegramPost(
        message: _buildMessage(order),
        photo: witnessModel,
      );

      _cancelledIds.add(order.id);

      if (!mounted) return;
      _showSnack('Chek bekor qilindi', isError: false);
      Navigator.of(context).pop(true);
    } catch (e) {
      _fail('Xatolik yuz berdi');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _submitting = false);
    _showSnack(message, isError: true);
  }

  String _buildMessage(CancelOrder order) {
    final buffer = StringBuffer();
    buffer.writeln('🏤 Филиал: ${order.branchName ?? '-'}');
    buffer.writeln();
    buffer.writeln('🧾 Чек номер: ${order.receiptNumber}');
    buffer.writeln();
    buffer.writeln('👀 В курсе:');
    for (final w in _selectedWitnesses) {
      buffer.writeln(w.fullName);
    }
    buffer.writeln();
    final reason = _selectedReasons.join(' ');
    buffer.writeln('⚠️ Причина: $reason ${_moreAboutReasonCtrl.text.trim()}');
    buffer.writeln();
    buffer.write('📝 Действия: ${_measuresCtrl.text.trim()}');
    return buffer.toString();
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          _order == null ? 'Chek tanlash' : 'Chekni bekor qilish',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      // Tapping anywhere outside a focused field dismisses the keyboard.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: _loadingDetail
              ? _buildFormSkeleton(theme)
              : _order == null
                  ? _buildSearchView(theme)
                  : _buildForm(theme),
        ),
      ),
    );
  }

  // ── Shimmer skeleton shown while the selected order's detail loads ──

  Widget _buildFormSkeleton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    Widget block({double? width, required double height, double radius = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          block(height: 150.h, radius: 16), // order summary card
          SizedBox(height: 20.h),
          block(width: 180.w, height: 16.h, radius: 6), // section title
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: block(height: 150.h, radius: 14)),
              SizedBox(width: 12.w),
              Expanded(child: block(height: 150.h, radius: 14)),
            ],
          ),
          SizedBox(height: 16.h),
          block(width: 220.w, height: 14.h, radius: 6),
          SizedBox(height: 12.h),
          block(width: 200.w, height: 14.h, radius: 6),
          SizedBox(height: 24.h),
          block(width: 160.w, height: 16.h, radius: 6),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(
              4,
              (_) => block(width: 90.w, height: 34.h, radius: 20),
            ),
          ),
          SizedBox(height: 24.h),
          block(width: 140.w, height: 16.h, radius: 6),
          SizedBox(height: 12.h),
          block(height: 90.h, radius: 12),
          SizedBox(height: 16.h),
          block(height: 90.h, radius: 12),
        ],
      ),
    );
  }

  // ── Search view ──

  Widget _buildSearchView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              final q = v.trim();
              if (q.isNotEmpty) _runSearch(q);
            },
            style: TextStyle(
              fontSize: 15.sp,
              color: theme.colorScheme.onSurface,
            ),
            cursorColor: _accent,
            decoration: InputDecoration(
              hintText: 'Chek raqamini qidiring...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              suffixIcon: _searching
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text(
                    _searchCtrl.text.isEmpty
                        ? 'Bekor qilinadigan chekni qidiring'
                        : (_searching ? '' : 'Natija topilmadi'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final o = _results[index];
                    return _buildResultTile(theme, o);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildResultTile(ThemeData theme, CancelOrder o) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => _selectOrder(o),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_outlined, color: _accent, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '#${o.receiptNumber}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${_money.format(o.value)} UZS',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form view ──

  Widget _buildForm(ThemeData theme) {
    final order = _order!;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildOrderSummary(theme, order),
            SizedBox(height: 20.h),
            _sectionTitle(theme, 'Chek rasmi va guvohlar'),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPhotoBox(
                    theme,
                    label: 'Chek rasmi',
                    file: _chequePhoto,
                    onTap: _pickChequePhoto,
                    icon: Icons.receipt_long_outlined,
                    uploading: _chequeUploading,
                    uploaded: _chequeModel != null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildPhotoBox(
                    theme,
                    label: 'Guvohlar (selfi)',
                    file: _witnessPhoto,
                    onTap: _captureWitnessPhoto,
                    icon: Icons.camera_front_outlined,
                    uploading: _witnessUploading,
                    uploaded: _witnessModel != null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildCheckTile(
              theme,
              value: _sign,
              label: 'Podpis qo\'yilgan? (Подпись)',
              onChanged: (v) => setState(() => _sign = v),
            ),
            _buildCheckTile(
              theme,
              value: _word,
              label: '"Отмен" so\'zi yozilgan?',
              onChanged: (v) => setState(() => _word = v),
            ),
            SizedBox(height: 20.h),
            _sectionTitle(theme, 'Kto v kurse (В курсе)'),
            SizedBox(height: 10.h),
            _buildWitnessSelector(theme),
            SizedBox(height: 20.h),
            _sectionTitle(theme, 'Bekor sababi (Причина)'),
            SizedBox(height: 10.h),
            _buildReasonChips(theme),
            SizedBox(height: 16.h),
            _buildTextArea(
              theme,
              controller: _moreAboutReasonCtrl,
              focusNode: _moreAboutReasonFocus,
              label: 'Sabab haqida batafsil',
              hint: 'Qanday sodir bo\'ldi',
              textInputAction: TextInputAction.next,
              onSubmitted: () => _measuresFocus.requestFocus(),
            ),
            SizedBox(height: 16.h),
            _buildTextArea(
              theme,
              controller: _measuresCtrl,
              focusNode: _measuresFocus,
              label: 'Qanday chora ko\'rildi',
              hint: 'Qanday choralar',
              textInputAction: TextInputAction.done,
              onSubmitted: () => FocusScope.of(context).unfocus(),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildSubmitBar(theme),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme, CancelOrder order) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.receiptNumber}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _changeOrder,
                icon: Icon(Icons.swap_horiz, size: 18.sp, color: _accent),
                label: Text(
                  'O\'zgartirish',
                  style: TextStyle(color: _accent, fontSize: 13.sp),
                ),
              ),
            ],
          ),
          if (order.employeeName != null)
            _summaryRow(theme, 'Kassir', order.employeeName!),
          if (order.orderTypeName != null)
            _summaryRow(theme, 'Turi', order.orderTypeName!),
          if (order.startTime != null)
            _summaryRow(theme, 'Vaqt', order.startTime!),
          if (order.orderItems.isNotEmpty) ...[
            Divider(height: 24.h),
            ...order.orderItems.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      _money.format(item.lineTotal),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Divider(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jami',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '${_money.format(order.value)} UZS',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPhotoBox(
    ThemeData theme, {
    required String label,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    bool uploading = false,
    bool uploaded = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: file != null
                ? _accent
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08)),
            width: file != null ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file, fit: BoxFit.cover),
                  // Dim + spinner while the upload is in flight.
                  if (uploading)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Status badge: check when uploaded, edit otherwise.
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: uploaded ? _accent : Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        uploaded
                            ? Icons.check
                            : (uploading ? Icons.cloud_upload : Icons.edit),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30.sp, color: _accent),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckTile(
    ThemeData theme, {
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            SizedBox(
              width: 26.w,
              height: 26.w,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWitnessSelector(ThemeData theme) {
    if (_allWitnesses.isEmpty) {
      return Text(
        'Xodimlar yuklanmoqda...',
        style: TextStyle(
          fontSize: 13.sp,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _allWitnesses.map((w) {
        final selected = _selectedWitnesses.contains(w);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedWitnesses.remove(w);
            } else {
              _selectedWitnesses.add(w);
            }
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: selected ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected
                    ? _accent
                    : theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 15, color: Colors.white),
                  SizedBox(width: 5.w),
                ],
                Text(
                  w.fullName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReasonChips(ThemeData theme) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _reasons.map((r) {
        final selected = _selectedReasons.contains(r);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedReasons.remove(r);
            } else {
              _selectedReasons.add(r);
            }
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: selected
                  ? _accent.withOpacity(0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selected
                    ? _accent
                    : theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Text(
              r,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? _accent
                    : theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextArea(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required String hint,
    FocusNode? focusNode,
    TextInputAction textInputAction = TextInputAction.newline,
    VoidCallback? onSubmitted,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          focusNode: focusNode,
          minLines: 3,
          maxLines: 5,
          textInputAction: textInputAction,
          onSubmitted: (_) => onSubmitted?.call(),
          cursorColor: _accent,
          style: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            contentPadding: EdgeInsets.all(14.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: _submitting ? null : _confirmSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Chekni bekor qilish',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: const Text('Chekni bekor qilishni tasdiqlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
    if (confirmed == true) _submit();
  }
}
