import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  File? _chequePhoto;
  File? _witnessPhoto;

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
    }
  }

  Future<void> _captureWitnessPhoto() async {
    final file = await _pickCompressed(
      source: ImageSource.camera,
      camera: CameraDevice.front,
    );
    if (file != null && mounted) {
      setState(() => _witnessPhoto = file);
    }
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
      final objectId = order.receiptNumber;

      // Upload proof photos (cheque + witnesses selfie).
      final chequeModel = await api.uploadCancelPhoto(_chequePhoto!, objectId);
      final witnessModel =
          await api.uploadCancelPhoto(_witnessPhoto!, objectId);

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
      body: SafeArea(
        child: _loadingDetail
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _order == null
                ? _buildSearchView(theme)
                : _buildForm(theme),
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
              label: 'Sabab haqida batafsil',
              hint: 'Qanday sodir bo\'ldi',
            ),
            SizedBox(height: 16.h),
            _buildTextArea(
              theme,
              controller: _measuresCtrl,
              label: 'Qanday chora ko\'rildi',
              hint: 'Qanday choralar',
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
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
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
          minLines: 3,
          maxLines: 5,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
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
