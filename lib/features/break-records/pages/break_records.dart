import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/model/break_order_model.dart';
import '../../../core/services/auth/auth_manager.dart';

import '../../../core/services/api/api_service.dart';

class BreakRecords extends StatefulWidget {
  const BreakRecords({super.key});

  @override
  State<BreakRecords> createState() => _BreakRecordsState();
}

class _BreakRecordsState extends State<BreakRecords> with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  bool _isLoading = true;
  String? _errorMessage;
  List<BreakOrder> _breakOrders = [];
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
    
    _fetchBreakOrders();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchBreakOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      print('🔍 Fetching break orders for employee ID: $employeeId');
      
      final orders = await _authManager.apiService.getBreakOrders(employeeId);
      
      setState(() {
        _breakOrders = orders;
        _isLoading = false;
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
    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 24.h),
              
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
            color: AppColors.cxBlack.withOpacity(0.05),
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
                  'Break Records',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your meal history',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxSilverTint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
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
    final isEvenRow = index % 2 == 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isEvenRow ? AppColors.cxWhite : AppColors.cxF5F7F9.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cxPlatinumGray.withOpacity(0.2),
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
              color: AppColors.cxGraphiteGray,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          _buildHeaderCell('Date', flex: 3),
          _buildHeaderCell('Amount', flex: 2),
          _buildHeaderCell('Details', flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.cxGraphiteGray,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRecordCard(BreakOrder record, int index) {
    final isEvenRow = index % 2 == 0;
    
    return InkWell(
      onTap: () => _showItemDetailsPopup(record),
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isEvenRow ? AppColors.cxWhite : AppColors.cxF5F7F9.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: AppColors.cxPlatinumGray.withOpacity(0.2),
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
                      color: AppColors.cxGraphiteGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatTime(record.createdAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.cxSilverTint,
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cxWhite,
                  AppColors.cxF5F7F9,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxBlack.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
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
                            color: AppColors.cxBlack.withOpacity(0.1),
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
                            'Break Record #${record.id}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cxDarkCharcoal,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_formatDate(record.createdAt)} at ${_formatTime(record.createdAt)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.cxSilverTint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cxRoyalBlue.withOpacity(0.15),
                                  AppColors.cxBlue.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.cxRoyalBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Total: ${_formatAmount(record.value)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxRoyalBlue,
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
                    'Order Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cxDarkCharcoal,
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Items list
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxF7F6F9.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.cxPlatinumGray.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: record.orderItems.isEmpty
                      ? Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.cxSilverTint,
                          ),
                        )
                      : Column(
                          children: record.orderItems.map<Widget>((item) {
                            final productName = item.product?.name ?? 'Unknown Product';
                            final quantity = item.quantity;
                            final price = _formatAmount(item.totalPrice);
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.cxEmeraldGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.cxEmeraldGreen,
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
                                            color: AppColors.cxEmeraldGreen,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          price,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.cxEmeraldGreen.withOpacity(0.8),
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
                          colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
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
                            'Close',
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
}
