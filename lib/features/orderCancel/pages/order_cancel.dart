import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/cancel_order_model.dart';
import 'order_cancel_create.dart';

class OrderCancel extends StatefulWidget {
  const OrderCancel({super.key});

  @override
  State<OrderCancel> createState() => _OrderCancelState();
}

class _OrderCancelState extends State<OrderCancel> {
  final AuthManager _authManager = AuthManager();

  static const Color _accent = AppColors.cx3FBDA3;
  final NumberFormat _money = NumberFormat.decimalPattern();

  bool _isLoading = true;
  String? _error;
  int? _branchId;
  int? _daySessionId;
  List<CancelOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = _authManager.apiService;

      // Resolve the current day session (branch + session id).
      final session = await api.getCurrentDaySession();
      if (session == null) {
        setState(() {
          _isLoading = false;
          _error = 'Kunlik sessiya topilmadi';
        });
        return;
      }

      _branchId = (session['branch_id'] as num?)?.toInt() ??
          _authManager.currentIdentity?.employee?.branchId;
      _daySessionId = (session['id'] as num?)?.toInt();

      if (_branchId == null || _daySessionId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Filial yoki sessiya aniqlanmadi';
        });
        return;
      }

      final raw = await api.getCancelledOrders(
        branchId: _branchId!,
        daySessionId: _daySessionId!,
      );
      final orders = raw.map(CancelOrder.fromJson).toList();

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Xatolik yuz berdi';
      });
    }
  }

  Future<void> _openCreate() async {
    if (_branchId == null || _daySessionId == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderCancelCreate(
          branchId: _branchId!,
          daySessionId: _daySessionId!,
        ),
      ),
    );
    if (created == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Otmen chek',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: _accent,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _load,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return _buildSkeleton(theme);
    if (_error != null) return _buildError(theme);
    if (_orders.isEmpty) return _buildEmpty(theme);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      itemCount: _orders.length + 1,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(theme);
        return _OrderCard(
          order: _orders[index - 1],
          accent: _accent,
          money: _money,
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, top: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Umumiy: ${_orders.length}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        itemCount: 8,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => Container(
          height: 64.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: 160.h),
        Icon(
          Icons.receipt_long_outlined,
          size: 64.sp,
          color: theme.colorScheme.onSurface.withOpacity(0.25),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Text(
            'Bekor qilingan cheklar yo\'q',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Yangi bekor qilish uchun + tugmasini bosing',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: 160.h),
        Icon(Icons.error_outline, size: 56.sp, color: Colors.redAccent),
        SizedBox(height: 16.h),
        Center(
          child: Text(
            _error ?? 'Xatolik',
            style: TextStyle(
              fontSize: 15.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: TextButton(
            onPressed: _load,
            child: const Text('Qayta urinish'),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CancelOrder order;
  final Color accent;
  final NumberFormat money;

  const _OrderCard({
    required this.order,
    required this.accent,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.receipt_outlined, color: accent, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.receiptNumber}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (order.startTime != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    order.startTime!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '${money.format(order.value)} UZS',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
