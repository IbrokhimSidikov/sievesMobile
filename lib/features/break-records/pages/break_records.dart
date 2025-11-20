import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sieves_mob/core/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/model/break_order_model.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/cache/break_records_cache_service.dart';

class BreakRecords extends StatefulWidget {
  const BreakRecords({super.key});

  @override
  State<BreakRecords> createState() => _BreakRecordsState();
}

class _BreakRecordsState extends State<BreakRecords> with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  final BreakRecordsCacheService _cacheService = BreakRecordsCacheService();
  bool _isLoading = true;
  String? _errorMessage;
  List<BreakOrder> _breakOrders = [];
  double? _breakBalance;
  bool _isLoadingBalance = true;
  bool _isOrdersFromCache = false;
  bool _isBalanceFromCache = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _fetchBreakBalance();
    _fetchBreakOrders();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  /// Force refresh all break records data (clear cache and reload)
  Future<void> _forceRefresh() async {
    final employeeId = _authManager.currentEmployeeId;
    
    if (employeeId != null) {
      await _cacheService.clearAllCachesForEmployee(employeeId);
    }
    
    // Reload all data
    await Future.wait([
      _fetchBreakBalance(forceRefresh: true),
      _fetchBreakOrders(forceRefresh: true),
    ]);
  }

  Future<void> _fetchBreakBalance({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingBalance = true;
      _isBalanceFromCache = false;
    });

    try {
      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        setState(() {
          _isLoadingBalance = false;
        });
        return;
      }

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedBalance = await _cacheService.getCachedBreakBalance(employeeId);
        if (cachedBalance != null) {
          print('✅ Loaded break balance from cache');
          setState(() {
            _breakBalance = cachedBalance;
            _isLoadingBalance = false;
            _isBalanceFromCache = true;
          });
          return;
        }
      }

      print('💰 Fetching break balance for employee ID: $employeeId');
      
      final balance = await _authManager.apiService.getBreakBalance(employeeId);
      
      // Cache the balance
      if (balance != null) {
        await _cacheService.cacheBreakBalance(employeeId, balance);
      }
      
      setState(() {
        _breakBalance = balance;
        _isLoadingBalance = false;
        _isBalanceFromCache = false;
      });

      if (balance != null) {
        print('✅ Successfully loaded break balance: $balance UZS');
      }
    } catch (e) {
      print('❌ Error fetching break balance: $e');
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _fetchBreakOrders({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOrdersFromCache = false;
    });

    try {
      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        setState(() {
          _errorMessage = 'Employee ID not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedOrders = await _cacheService.getCachedBreakOrders(employeeId);
        if (cachedOrders != null) {
          print('✅ Loaded break orders from cache');
          setState(() {
            _breakOrders = cachedOrders;
            _isLoading = false;
            _isOrdersFromCache = true;
          });
          return;
        }
      }

      print('🔍 Fetching break orders for employee ID: $employeeId');
      
      final orders = await _authManager.apiService.getBreakOrders(employeeId);
      
      // Cache the orders
      await _cacheService.cacheBreakOrders(employeeId, orders);
      
      setState(() {
        _breakOrders = orders;
        _isLoading = false;
        _isOrdersFromCache = false;
      });

      print('✅ Successfully loaded ${orders.length} break orders');
    } catch (e) {
      print('❌ Error fetching break orders: $e');
      setState(() {
        _errorMessage = 'Failed to load break records. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 20.h),
              
              // Break Balance Card
              _buildBreakBalanceCard(),
              SizedBox(height: 20.h),
              
              // Content based on state
              Expanded(
                child: _isLoading
                    ? _buildSkeletonLoader()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildBreakRecordsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakBalanceCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cxWarning,
            AppColors.cxFEDA84,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxWarning.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.cxWarning.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wallet Icon Container
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.cxWhite.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxBlack.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.cxWhite,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 20.w),
          
          // Balance Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.cxWhite.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.cxWhite.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).availableBreakBalance,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cxWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Amount
                _isLoadingBalance
                    ? _buildBalanceShimmer()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatBalanceAmount(_breakBalance ?? 0),
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cxWhite,
                              height: 1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              shadows: [
                                Shadow(
                                  color: AppColors.cxBlack.withOpacity(0.15),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Text(
                              'UZS',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxWhite.withOpacity(0.9),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          
          // Info Icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxWhite.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.cxWhite,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAnyCached = _isOrdersFromCache || _isBalanceFromCache;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        gradient: isDark ? null : LinearGradient(
          colors: [
            AppColors.cxWhite,
            AppColors.cxF5F7F9,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.coffee_rounded,
              color: AppColors.cxWhite,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).breakRecords,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context).breakRecordsSubtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Cache indicator
          if (isAnyCached)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Tooltip(
                message: 'Loaded from cache',
                child: Icon(
                  Icons.offline_bolt_rounded,
                  color: AppColors.cxWarning,
                  size: 20.sp,
                ),
              ),
            ),
          // Refresh button
          IconButton(
            onPressed: _forceRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.cxWarning,
              size: 24.sp,
            ),
            tooltip: 'Refresh',
            padding: EdgeInsets.all(8.w),
            constraints: BoxConstraints(),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.cxWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.cxWarning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_breakOrders.length} Records',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header (static)
          _buildTableHeader(),
          
          // Skeleton Rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: 8, // Show 8 skeleton rows
              itemBuilder: (context, index) {
                return _buildSkeletonRow(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEvenRow = index % 2 == 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isEvenRow 
            ? (isDark ? theme.colorScheme.surface : AppColors.cxWhite)
            : (isDark ? theme.colorScheme.surface.withOpacity(0.5) : AppColors.cxF5F7F9.withOpacity(0.5)),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // ID skeleton
          Expanded(
            flex: 1,
            child: Center(
              child: _buildShimmerBox(width: 24.w, height: 24.w, circular: true),
            ),
          ),
          
          // Date & Time skeleton
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShimmerBox(width: 80.w, height: 12.h),
                  SizedBox(height: 4.h),
                  _buildShimmerBox(width: 50.w, height: 10.h),
                ],
              ),
            ),
          ),
          
          // Amount skeleton
          Expanded(
            flex: 2,
            child: Center(
              child: _buildShimmerBox(width: 70.w, height: 24.h, borderRadius: 8.r),
            ),
          ),
          
          // Details indicator skeleton
          Expanded(
            flex: 1,
            child: Center(
              child: _buildShimmerBox(width: 32.w, height: 32.w, borderRadius: 8.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double? borderRadius,
    bool circular = false,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                AppColors.cxSilverTint.withOpacity(_shimmerAnimation.value * 0.5),
                AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: circular 
                ? BorderRadius.circular(width / 2) 
                : BorderRadius.circular(borderRadius ?? 6.r),
            shape: circular ? BoxShape.rectangle : BoxShape.rectangle,
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.cxWarning,
          ),
          SizedBox(height: 16.h),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _fetchBreakOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cxWarning,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakRecordsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(),
          
          // Records List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _breakOrders.length,
              itemBuilder: (context, index) {
                return _buildRecordCard(_breakOrders[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withOpacity(0.5) : null,
        gradient: isDark ? null : LinearGradient(
          colors: [
            AppColors.cxF5F7F9,
            AppColors.cxF7F6F9,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', flex: 1),
          _buildHeaderCell(AppLocalizations.of(context).date, flex: 3),
          _buildHeaderCell(AppLocalizations.of(context).amount, flex: 2),
          _buildHeaderCell(AppLocalizations.of(context).details, flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRecordCard(BreakOrder record, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEvenRow = index % 2 == 0;
    
    return InkWell(
      onTap: () => _showItemDetailsPopup(record),
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isEvenRow 
              ? (isDark ? theme.colorScheme.surface : AppColors.cxWhite)
              : (isDark ? theme.colorScheme.surface.withOpacity(0.5) : AppColors.cxF5F7F9.withOpacity(0.3)),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ID Number
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cxWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Date & Time
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(record.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatTime(record.createdAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Amount
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxRoyalBlue.withOpacity(0.12),
                      AppColors.cxBlue.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.cxRoyalBlue.withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _formatAmount(record.value),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxRoyalBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Details indicator
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.cxWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.cxWarning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: AppColors.cxWarning,
                  size: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showItemDetailsPopup(BreakOrder record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDarkMode ? const Color(0xFF1A1A24) : AppColors.cxWhite;
        final dialogBgSecondary = isDarkMode ? const Color(0xFF252532) : AppColors.cxF5F7F9;
        final primaryText = isDarkMode ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal;
        final secondaryText = isDarkMode ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint;
        final borderColor = isDarkMode ? const Color(0xFF374151) : AppColors.cxPlatinumGray;
        final itemBg = isDarkMode ? const Color(0xFF1F2937) : AppColors.cxF7F6F9;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.all(24.w),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dialogBg,
                  dialogBgSecondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: isDarkMode 
                  ? Border.all(color: const Color(0xFF374151), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxBlack.withOpacity(isDarkMode ? 0.4 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with photo and basic info
                Row(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cxBlack.withOpacity(isDarkMode ? 0.3 : 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: record.breakPhoto != null
                            ? Image.network(
                                record.breakPhoto!.fullUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      color: AppColors.cxWhite,
                                      size: 24.sp,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.cxWhite,
                                  size: 24.sp,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).breakRecord} #${record.id}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_formatDate(record.createdAt)} at ${_formatTime(record.createdAt)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDarkMode
                                    ? [
                                        const Color(0xFF6366F1).withOpacity(0.2),
                                        const Color(0xFF4F46E5).withOpacity(0.2),
                                      ]
                                    : [
                                        AppColors.cxRoyalBlue.withOpacity(0.15),
                                        AppColors.cxBlue.withOpacity(0.15),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : AppColors.cxRoyalBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${AppLocalizations.of(context).total}: ${_formatAmount(record.value)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? const Color(0xFF818CF8) : AppColors.cxRoyalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Items section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).orderDetails,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Items list
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: itemBg.withOpacity(isDarkMode ? 0.8 : 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: borderColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: record.orderItems.isEmpty
                      ? Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: secondaryText,
                          ),
                        )
                      : Column(
                          children: record.orderItems.map<Widget>((item) {
                            final productName = item.product?.name ?? 'Unknown Product';
                            final quantity = item.quantity;
                            final price = _formatAmount(item.totalPrice);
                            final greenColor = isDarkMode ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: greenColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: greenColor.withOpacity(isDarkMode ? 0.4 : 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: greenColor,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      color: AppColors.cxWhite,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$productName x $quantity',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? const Color(0xFF6EE7B7) : greenColor,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          price,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode 
                                                ? const Color(0xFF6EE7B7).withOpacity(0.7)
                                                : greenColor.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                              : [AppColors.cxWarning, AppColors.cxFEDA84],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isDarkMode ? const Color(0xFF6366F1) : AppColors.cxWarning)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: AppColors.cxWhite,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            AppLocalizations.of(context).close,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cxWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      // Convert from GMT 0 to GMT +5
      final localDate = date.add(const Duration(hours: 5));
      return '${localDate.day.toString().padLeft(2, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.year}';
    } catch (e) {
      return dateStr.split(' ')[0];
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      // Convert from GMT 0 to GMT +5
      final localDate = date.add(const Duration(hours: 5));
      return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.split(' ')[1] ?? '';
    }
  }

  String _formatAmount(int amount) {
    // Format amount with thousand separators (amount is already in the correct currency unit)
    final formatter = NumberFormat('#,###', 'en_US');
    return '${formatter.format(amount)} UZS';
  }

  String _formatBalanceAmount(double amount) {
    // Format balance amount with thousand separators
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount.round());
  }

  Widget _buildBalanceShimmer() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: 150.w,
          height: 32.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cxWhite.withOpacity(_shimmerAnimation.value * 0.3),
                AppColors.cxWhite.withOpacity(_shimmerAnimation.value * 0.5),
                AppColors.cxWhite.withOpacity(_shimmerAnimation.value * 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
        );
      },
    );
  }
}
