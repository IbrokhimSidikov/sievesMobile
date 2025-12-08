import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/model/history_model.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/cache/history_cache_service.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  final HistoryCacheService _cacheService = HistoryCacheService();
  List<HistoryRecord> historyRecords = [];
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Record type filter
  String selectedFilter = 'Все';
  final List<String> filterOptions = [
    'Все',
    'Информация',
    'Достижение',
    'Устное предупреждение',
    'Объяснительное письмо',
    'Испытательный срок',
    'Освобождение от должности'
  ];

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
    
    _fetchHistoryData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final employeeId = _authManager.currentEmployeeId;
      
      if (employeeId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Employee ID not found. Please log in again.';
        });
        return;
      }

      // Try to load from cache first
      final cachedData = await _cacheService.getCachedHistoryRecords(employeeId);
      if (cachedData != null) {
        final cachedRecords = cachedData.map((json) => HistoryRecord.fromJson(json)).toList();
        setState(() {
          historyRecords = cachedRecords;
          isLoading = false;
        });
        print('📦 Loaded ${cachedRecords.length} history records from cache');
        return;
      }

      // If no cache, fetch from API
      print('🌐 No cache found, fetching from API...');
      final records = await _authManager.apiService.getHistory(employeeId);

      if (records != null) {
        // Cache the records
        final recordsJson = records.map((record) => record.toJson()).toList();
        await _cacheService.cacheHistoryRecords(employeeId, recordsJson);
        
        setState(() {
          historyRecords = records;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load history records. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred: $e';
      });
    }
  }

  // Helper method to get color based on history type
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'информация':
      case 'information':
        return AppColors.cxBlue;
      case 'достижение':
      case 'achievement':
        return AppColors.cxEmeraldGreen;
      case 'устное предупреждение':
      case 'verbal warning':
        return AppColors.cxWarning;
      case 'объяснительное письмо':
      case 'explanatory letter':
        return AppColors.cxAmberGold;
      case 'испытательный срок':
      case 'probation':
        return AppColors.cxPurple;
      case 'освобождение от должности':
      case 'dismissal':
        return AppColors.cxWarning;
      default:
        return AppColors.cxGraphiteGray;
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
              // Back button
              _buildBackButton(),
              SizedBox(height: 16.h),
              // Header
              // _buildHeader(),
              // SizedBox(height: 20.h),
              
              // Filter Section
              _buildFilterSection(),
              SizedBox(height: 20.h),
              
              // History Timeline with loading/error states
              Expanded(
                child: isLoading
                    ? _buildSkeletonLoader()
                    : errorMessage != null
                        ? _buildErrorState()
                        : historyRecords.isEmpty
                            ? _buildEmptyState()
                            : _buildHistoryTimeline(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return _buildSkeletonLoader();
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
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 6, // Show 6 skeleton timeline items
        itemBuilder: (context, index) {
          return _buildSkeletonTimelineItem(index, 6);
        },
      ),
    );
  }

  Widget _buildErrorState() {
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
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64.sp,
                color: AppColors.cxWarning,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                errorMessage ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),
              InkWell(
                onTap: _fetchHistoryData,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cxWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64.sp,
              color: AppColors.cxSilverTint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No History Records',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your history will appear here',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxSilverTint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.cxBlue,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          'History Records',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.history_rounded,
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
                  'History Records',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Employee activity timeline',
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
              color: AppColors.cxBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.cxBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_getFilteredRecords().length} Records',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Filter by Type',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 38.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final isSelected = selectedFilter == option;
                return Container(
                  margin: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedFilter = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected 
                            ? null 
                            : isDark 
                                ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                                : AppColors.cxF5F7F9,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.transparent 
                              : isDark
                                  ? theme.colorScheme.outline.withOpacity(0.3)
                                  : AppColors.cxPlatinumGray.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.cxBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredRecords = _getFilteredRecords();
    
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
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          return _buildTimelineItem(filteredRecords[index], index, filteredRecords.length);
        },
      ),
    );
  }

  Widget _buildTimelineItem(HistoryRecord record, int index, int totalItems) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = index == totalItems - 1;
    final color = _getColorForType(record.displayType);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 60.h,
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
          ],
        ),
        
        SizedBox(width: 16.w),
        
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.05),
                  color.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        record.displayType,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cxWhite,
                        ),
                      ),
                    ),
                    Text(
                      record.formattedDateTime,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Description
                Text(
                  record.displayDescription,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Branch
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 14.sp,
                      color: color,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      record.branchName,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<HistoryRecord> _getFilteredRecords() {
    if (selectedFilter == 'Все') {
      return historyRecords;
    }
    return historyRecords.where((record) => record.displayType == selectedFilter).toList();
  }

  Widget _buildSkeletonTimelineItem(int index, int totalItems) {
    final isLast = index == totalItems - 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                        AppColors.cxSilverTint.withOpacity(_shimmerAnimation.value * 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 80.h,
                color: AppColors.cxPlatinumGray.withOpacity(0.2),
              ),
          ],
        ),
        
        SizedBox(width: 16.w),
        
        // Content skeleton
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.cxF5F7F9.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxPlatinumGray.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Date row skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerBox(width: 100.w, height: 16.h),
                    _buildShimmerBox(width: 80.w, height: 14.h),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // Description skeleton
                _buildShimmerBox(width: double.infinity, height: 12.h),
                SizedBox(height: 6.h),
                _buildShimmerBox(width: 200.w, height: 12.h),
                
                SizedBox(height: 12.h),
                
                // Branch skeleton
                _buildShimmerBox(width: 150.w, height: 12.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
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
            borderRadius: BorderRadius.circular(6.r),
          ),
        );
      },
    );
  }
}
