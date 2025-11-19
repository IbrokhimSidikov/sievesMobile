import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/auth/auth_cubit.dart';
import '../../../core/services/auth/auth_state.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/cache/profile_cache_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/work_time_calculator.dart';
import '../../../core/model/work_entry_model.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthManager _authManager = AuthManager();
  final AuthService _authService = AuthService();
  late final ApiService _apiService = ApiService(_authService);
  final ProfileCacheService _cacheService = ProfileCacheService();
  Map<String, dynamic>? _profileData;
  List<WorkEntry> _workEntries = [];
  bool _isLoading = true;
  bool _isLoadingWorkEntries = true;
  bool _isLoadingPrePaid = true;
  bool _isLoadingVacation = true;
  bool _isLoadingBonus = true;
  double _prePaidAmount = 0.0;
  List<Map<String, dynamic>> _currentMonthTransactions = [];
  int _availableVacationDays = 0;
  int _totalVacationDays = 0;
  double _bonusAmount = 0.0;
  String _bonusMonth = '';
  String? _error;
  bool _isFromCache = false;
  bool _isPrePaidFromCache = false;
  bool _isVacationFromCache = false;

  @override
  void initState() {
    super.initState();
    print('🎬 [Profile] initState called');
    _loadProfileData();
    _loadCurrentMonthWorkEntries();
    _loadPrePaidAmount();
    _loadVacationDays();
    _loadBonusData();
  }

  @override
  void dispose() {
    print('🗑️  [Profile] dispose called');
    super.dispose();
  }

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isFromCache = false;
      });

      // Get current identity from AuthManager
      final identity = _authManager.currentIdentity;
      
      if (identity == null) {
        throw Exception('No user identity found. Please login again.');
      }

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        throw Exception('No employee ID found. Please login again.');
      }

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCachedProfileData(employeeId);
        if (cachedData != null) {
          print('✅ Loaded profile data from cache');
          if (mounted) {
            setState(() {
              _profileData = cachedData;
              _isLoading = false;
              _isFromCache = true;
            });
          }
          return;
        }
      }

      // Convert Identity model to Map for UI consumption
      final identityData = {
        'id': identity.id,
        'email': identity.email,
        'username': identity.username,
        'role': identity.role,
        'phone': identity.phone,
        'allowance': identity.allowance,
        'employee': identity.employee != null ? {
          'id': identity.employee!.id,
          'status': identity.employee!.status,
          'individual': identity.employee!.individual != null ? {
            'firstName': identity.employee!.individual!.firstName,
            'lastName': identity.employee!.individual!.lastName,
            'email': identity.employee!.individual!.email,
            'phone': identity.employee!.individual!.phone,
            'photo': identity.employee!.individual!.photo,
          } : null,
          'branch': identity.employee!.branch != null ? {
            'name': identity.employee!.branch!.name,
            'address': identity.employee!.branch!.address,
          } : null,
          'jobPosition': identity.employee!.jobPosition != null ? {
            'name': identity.employee!.jobPosition!.name,
          } : null,
          'department': identity.employee!.department != null ? {
            'name': identity.employee!.department!.name,
          } : null,
          'reward': identity.employee!.reward != null ? {
            'amount': identity.employee!.reward!.amount,
            'type': identity.employee!.reward!.type,
          } : null,
        } : null,
      };

      // Cache the profile data
      await _cacheService.cacheProfileData(employeeId, identityData);
      
      if (mounted) {
        setState(() {
          _profileData = identityData;
          _isLoading = false;
          _isFromCache = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Get current month's start and end dates in ISO format
  Map<String, String> _getCurrentMonthDateRange() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return {
      'startDate': firstDayOfMonth.toIso8601String().split('T')[0],
      'endDate': lastDayOfMonth.toIso8601String().split('T')[0],
    };
  }

  /// Fetch work entries for the current month from API
  Future<void> _loadCurrentMonthWorkEntries() async {
    try {
      setState(() {
        _isLoadingWorkEntries = true;
      });

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        print('❌ No employee ID found');
        setState(() {
          _isLoadingWorkEntries = false;
        });
        return;
      }

      final dateRange = _getCurrentMonthDateRange();
      print('📅 Fetching work entries from ${dateRange['startDate']} to ${dateRange['endDate']}');

      final workEntriesResponse = await _apiService.getWorkEntries(
        employeeId,
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      if (mounted) {
        setState(() {
          _workEntries = (workEntriesResponse?['entries'] as List<dynamic>?)
              ?.cast<WorkEntry>() ?? [];
          _isLoadingWorkEntries = false;
        });
        print('✅ Loaded ${_workEntries.length} work entries for current month');
      }
    } catch (e) {
      print('❌ Error loading work entries: $e');
      if (mounted) {
        setState(() {
          _workEntries = [];
          _isLoadingWorkEntries = false;
        });
      }
    }
  }

  /// Fetch and calculate pre-paid amount for current month from transactions
  Future<void> _loadPrePaidAmount({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingPrePaid = true;
        _isPrePaidFromCache = false;
      });

      // Get individual_id from employee
      final identity = _authManager.currentIdentity;
      final individualId = identity?.employee?.individualId;
      
      if (individualId == null) {
        print('❌ No individual ID found');
        setState(() {
          _isLoadingPrePaid = false;
          _prePaidAmount = 0.0;
          _currentMonthTransactions = [];
        });
        return;
      }

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCachedPrePaidData(individualId);
        if (cachedData != null) {
          print('✅ Loaded pre-paid data from cache');
          if (mounted) {
            setState(() {
              _prePaidAmount = (cachedData['amount'] as num?)?.toDouble() ?? 0.0;
              _currentMonthTransactions = (cachedData['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              _isLoadingPrePaid = false;
              _isPrePaidFromCache = true;
            });
          }
          return;
        }
      }

      print('📊 Fetching transactions for individual ID: $individualId');

      // Fetch transactions from API using the new method
      final response = await _apiService.getTransactions(
        vendorType: 'individual',
        source: 'regular',
        vendorId: individualId,
      );

      // Log the complete response
      print('🔍 Transaction API Response: $response');
      
      if (response != null) {
        print('📦 Response keys: ${response.keys.toList()}');
        if (response['models'] != null) {
          final transactions = response['models'] as List;
          print('📊 Total transactions received: ${transactions.length}');
          
          // Log first transaction for structure inspection
          if (transactions.isNotEmpty) {
            print('📝 First transaction sample: ${transactions.first}');
          }
        }
      }

      if (response != null && response['models'] != null) {
        final transactions = response['models'] as List;
        
        // Get current month and year
        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;
        
        print('📅 Filtering for current month: $currentMonth/$currentYear');
        
        // Filter transactions for current month and sum amounts
        double totalAmount = 0.0;
        int transactionCount = 0;
        List<Map<String, dynamic>> currentMonthTxns = [];
        
        for (var transaction in transactions) {
          try {
            final dateStr = transaction['date'] as String?;
            if (dateStr != null) {
              final transactionDate = DateTime.parse(dateStr);
              
              // Check if transaction is in current month
              if (transactionDate.month == currentMonth && 
                  transactionDate.year == currentYear) {
                final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                totalAmount += amount;
                transactionCount++;
                currentMonthTxns.add(transaction as Map<String, dynamic>);
                print('✅ Current month transaction: ${transaction['id']} - Amount: $amount - Date: $dateStr');
              }
            }
          } catch (e) {
            print('⚠️ Error parsing transaction date: $e');
          }
        }

        // Cache the pre-paid data
        await _cacheService.cachePrePaidData(individualId, totalAmount, currentMonthTxns);

        if (mounted) {
          setState(() {
            _prePaidAmount = totalAmount;
            _currentMonthTransactions = currentMonthTxns;
            _isLoadingPrePaid = false;
            _isPrePaidFromCache = false;
          });
          print('💰 Total pre-paid amount: $totalAmount UZS from $transactionCount transactions');
        }
      } else {
        print('⚠️ No models found in response');
        if (mounted) {
          setState(() {
            _prePaidAmount = 0.0;
            _currentMonthTransactions = [];
            _isLoadingPrePaid = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading pre-paid amount: $e');
      if (mounted) {
        setState(() {
          _prePaidAmount = 0.0;
          _currentMonthTransactions = [];
          _isLoadingPrePaid = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔴 [Profile] Logout button pressed');
    print('═══════════════════════════════════════════════════════');
    
    // Show confirmation dialog
    print('📋 [Profile] Showing confirmation dialog...');
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [
                      const Color(0xFF1F1F2E),
                      const Color(0xFF1A1A24),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  blurRadius: 60,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(28.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container with gradient background
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFEF4444).withOpacity(0.2),
                          const Color(0xFFDC2626).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: const Color(0xFFEF4444),
                      size: 40.sp,
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Title
                  Text(
                    'Logout Confirmation',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark 
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxBlack,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Description
                  Text(
                    'Are you sure you want to logout from your account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: isDark 
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxBlack.withOpacity(0.6),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: isDark
                              ? const Color(0xFF252532)
                              : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(false),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : AppColors.cxBlack.withOpacity(0.7),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      // Logout button
                      Expanded(
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFDC2626),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(true),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      print('✅ [Profile] User confirmed logout');
      
      // Perform logout via AuthCubit
      // NOTE: Don't show loading dialog here - the global BlocListener in main.dart
      // will handle navigation immediately, which would dispose this widget
      // before we can close the dialog
      print('🔄 [Profile] Calling AuthCubit.logout()...');
      await context.read<AuthCubit>().logout();
      print('✅ [Profile] AuthCubit.logout() completed');
      
      // The global BlocListener in main.dart will handle navigation to /onboard
      // when AuthUnauthenticated state is emitted
      
      print('═══════════════════════════════════════════════════════');
      print('✅ [Profile] Logout handler completed - waiting for global navigation');
      print('═══════════════════════════════════════════════════════');
      print('');
    } else {
      print('❌ [Profile] User cancelled logout');
      print('');
    }
  }

  /// Get formatted current month string
  String _getCurrentMonthString() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  /// Force refresh all profile data (clear cache and reload)
  Future<void> _forceRefresh() async {
    final employeeId = _authManager.currentEmployeeId;
    final individualId = _authManager.currentIdentity?.employee?.individualId;
    
    if (employeeId != null) {
      await _cacheService.clearAllCachesForUser(employeeId, individualId);
    }
    
    // Reload all data
    await Future.wait([
      _loadProfileData(forceRefresh: true),
      _loadCurrentMonthWorkEntries(),
      _loadPrePaidAmount(forceRefresh: true),
      _loadVacationDays(forceRefresh: true),
    ]);
  }

  /// Load vacation days based on work entries
  /// Formula: availableVacation = floor(totalWorkedMilliseconds / (3600000 * 234))
  /// Max 7 days, 234 hours = 1 vacation day
  Future<void> _loadVacationDays({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingVacation = true;
        _isVacationFromCache = false;
      });

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        print('❌ No employee ID found for vacation calculation');
        setState(() {
          _isLoadingVacation = false;
          _availableVacationDays = 0;
          _totalVacationDays = 0;
        });
        return;
      }

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCachedVacationData(employeeId);
        if (cachedData != null) {
          print('✅ Loaded vacation data from cache');
          if (mounted) {
            setState(() {
              _availableVacationDays = cachedData['availableDays'] as int? ?? 0;
              _totalVacationDays = cachedData['totalDays'] as int? ?? 0;
              _isLoadingVacation = false;
              _isVacationFromCache = true;
            });
          }
          return;
        }
      }

      print('🏖️ Calculating vacation days for employee $employeeId');

      // Step 1: Fetch vacation-type work entries
      final vacationResponse = await _apiService.getWorkEntriesByType(
        employeeId: employeeId,
        type: 'vacation',
      );

      final vacationEntries = (vacationResponse?['entries'] as List<WorkEntry>?) ?? [];
      final totalVacations = vacationResponse?['totalCount'] ?? 0;

      print('📊 Found $totalVacations vacation entries');

      String? startDate;
      String? endDate = DateTime.now().toIso8601String().split('T')[0];

      if (vacationEntries.isEmpty) {
        // No vacations exist - calculate from first work day
        print('📅 No vacations found, calculating from first work day');
        
        final allClosedEntriesResponse = await _apiService.getWorkEntriesByType(
          employeeId: employeeId,
          status: 'closed',
        );

        final closedEntries = (allClosedEntriesResponse?['entries'] as List<WorkEntry>?) ?? [];
        
        if (closedEntries.isEmpty) {
          print('⚠️ No closed work entries found');
          setState(() {
            _isLoadingVacation = false;
            _availableVacationDays = 0;
            _totalVacationDays = totalVacations;
          });
          return;
        }

        // Calculate total worked milliseconds
        int totalWorkedMilliseconds = 0;
        for (var entry in closedEntries) {
          if (entry.checkInTime != null && entry.checkOutTime != null) {
            final checkIn = DateTime.parse(entry.checkInTime!);
            final checkOut = DateTime.parse(entry.checkOutTime!);
            totalWorkedMilliseconds += checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          }
        }

        // Calculate available vacation days
        // Formula: floor(totalWorkedMilliseconds / (3600000 * 234))
        // 3600000 ms = 1 hour, 234 hours = 1 vacation day
        final calculatedDays = (totalWorkedMilliseconds / (3600000 * 234)).floor();
        final availableDays = calculatedDays > 7 ? 7 : calculatedDays;

        print('✅ Calculated vacation days: $availableDays (from ${closedEntries.length} closed entries)');

        // Cache the vacation data
        await _cacheService.cacheVacationData(employeeId, availableDays, totalVacations);

        setState(() {
          _availableVacationDays = availableDays;
          _totalVacationDays = totalVacations;
          _isLoadingVacation = false;
          _isVacationFromCache = false;
        });
      } else {
        // Vacations exist - calculate from most recent vacation date
        print('📅 Vacations found, calculating from most recent vacation');
        
        // Sort by check_in_time descending (most recent first)
        vacationEntries.sort((a, b) {
          final aTime = DateTime.parse(a.checkInTime ?? '');
          final bTime = DateTime.parse(b.checkInTime ?? '');
          return bTime.compareTo(aTime);
        });

        // Get the most recent vacation date
        final mostRecentVacation = vacationEntries.first;
        startDate = DateTime.parse(mostRecentVacation.checkInTime!).toIso8601String().split('T')[0];

        print('📅 Most recent vacation: $startDate');

        // Fetch attendance entries from most recent vacation to now
        final attendanceResponse = await _apiService.getWorkEntriesByType(
          employeeId: employeeId,
          type: 'attendance',
          status: 'closed',
          startDate: startDate,
          endDate: endDate,
        );

        final attendanceEntries = (attendanceResponse?['entries'] as List<WorkEntry>?) ?? [];

        print('📊 Found ${attendanceEntries.length} attendance entries since last vacation');

        // Calculate total worked milliseconds
        int totalWorkedMilliseconds = 0;
        for (var entry in attendanceEntries) {
          if (entry.checkInTime != null && entry.checkOutTime != null) {
            final checkIn = DateTime.parse(entry.checkInTime!);
            final checkOut = DateTime.parse(entry.checkOutTime!);
            totalWorkedMilliseconds += checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;
          }
        }

        print('⏱️ Total worked milliseconds: $totalWorkedMilliseconds');

        // Calculate available vacation days
        final calculatedDays = (totalWorkedMilliseconds / (3600000 * 234)).floor();
        final availableDays = calculatedDays > 7 ? 7 : calculatedDays;

        print('✅ Calculated vacation days: $availableDays (max 7)');

        // Cache the vacation data
        await _cacheService.cacheVacationData(employeeId, availableDays, totalVacations);

        setState(() {
          _availableVacationDays = availableDays;
          _totalVacationDays = totalVacations;
          _isLoadingVacation = false;
          _isVacationFromCache = false;
        });
      }
    } catch (e) {
      print('❌ Error calculating vacation days: $e');
      setState(() {
        _isLoadingVacation = false;
        _availableVacationDays = 0;
        _totalVacationDays = 0;
      });
    }
  }

  /// Load bonus data for previous month from API
  Future<void> _loadBonusData() async {
    try {
      setState(() {
        _isLoadingBonus = true;
      });

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        print('❌ No employee ID found for bonus');
        setState(() {
          _isLoadingBonus = false;
          _bonusAmount = 0.0;
        });
        return;
      }

      print('🎁 Fetching bonus data for employee $employeeId');

      // Fetch bonus from API (automatically fetches previous month)
      final response = await _apiService.getEmployeeBonus(employeeId);

      if (response != null) {
        // Calculate previous month for display
        final now = DateTime.now();
        final previousMonth = DateTime(now.year, now.month - 1, 1);
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthName = '${months[previousMonth.month - 1]} ${previousMonth.year}';

        // Extract bonus amount from response
        // Handle different response structures
        double bonusAmount = 0.0;
        
        if (response is Map<String, dynamic>) {
          // Helper function to safely parse amount (handles both String and num)
          double parseAmount(dynamic value) {
            if (value == null) return 0.0;
            if (value is num) return value.toDouble();
            if (value is String) {
              return double.tryParse(value) ?? 0.0;
            }
            return 0.0;
          }
          
          // Try different possible field names
          if (response.containsKey('amount')) {
            bonusAmount = parseAmount(response['amount']);
          } else if (response.containsKey('bonus_amount')) {
            bonusAmount = parseAmount(response['bonus_amount']);
          } else if (response.containsKey('total_bonus')) {
            bonusAmount = parseAmount(response['total_bonus']);
          } else if (response.containsKey('bonus')) {
            final bonus = response['bonus'];
            if (bonus is num) {
              bonusAmount = bonus.toDouble();
            } else if (bonus is String) {
              bonusAmount = double.tryParse(bonus) ?? 0.0;
            } else if (bonus is Map && bonus.containsKey('amount')) {
              bonusAmount = parseAmount(bonus['amount']);
            }
          }
          
          print('📊 Bonus response: $response');
          print('💰 Extracted bonus amount: $bonusAmount UZS');
        }

        if (mounted) {
          setState(() {
            _bonusAmount = bonusAmount;
            _bonusMonth = monthName;
            _isLoadingBonus = false;
          });
          print('✅ Loaded bonus: $bonusAmount UZS for $monthName');
        }
      } else {
        print('⚠️ No bonus data received');
        if (mounted) {
          setState(() {
            _bonusAmount = 0.0;
            _isLoadingBonus = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading bonus data: $e');
      if (mounted) {
        setState(() {
          _bonusAmount = 0.0;
          _isLoadingBonus = false;
        });
      }
    }
  }

  void _showTransactionDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDarkMode ? const Color(0xFF1A1A24) : AppColors.cxPureWhite;
        final itemBg = isDarkMode ? const Color(0xFF252532) : AppColors.cxF5F7F9;
        final primaryText = isDarkMode ? const Color(0xFFE8E8F0) : AppColors.cxBlack;
        final secondaryText = isDarkMode ? const Color(0xFF9CA3AF) : AppColors.cxBlack;
        final borderColor = isDarkMode ? const Color(0xFF374151) : AppColors.cxEmeraldGreen;
        final greenColor = isDarkMode ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 500.h),
            decoration: BoxDecoration(
              color: dialogBg,
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
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                          : [AppColors.cxEmeraldGreen, Color(0xFF4AC1A7)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.cxPureWhite,
                        size: 22.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Transactions (${_currentMonthTransactions.length})',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.cxPureWhite,
                          size: 22.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Transaction List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _currentMonthTransactions.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final transaction = _currentMonthTransactions[index];
                      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                      final description = transaction['description'] as String? ?? 'No description';
                      final dateStr = transaction['date'] as String?;
                      
                      String formattedDate = 'N/A';
                      if (dateStr != null) {
                        try {
                          final date = DateTime.parse(dateStr);
                          formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          print('Error parsing date: $e');
                        }
                      }
                      
                      return Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: borderColor.withOpacity(isDarkMode ? 0.3 : 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    greenColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                                    greenColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: greenColor,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: secondaryText.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(width: 8.w),
                            
                            // Amount
                            Text(
                              '${amount.toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]} ',
                              )}',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: greenColor,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // NOTE: Removed BlocListener here because main.dart has a global listener
    // that handles navigation when AuthUnauthenticated is emitted
    // Having two listeners caused navigation conflicts and the loading dialog to get stuck
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cxSoftWhite,
              AppColors.cxPlatinumGray.withOpacity(0.3),
              AppColors.cxPureWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildProfileContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cxRoyalBlue,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.cxPureWhite,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_profileData == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildProfileCard(),
          SizedBox(height: 20.h),
          _buildWorkHoursCard(),
          SizedBox(height: 20.h),
          _buildBonusCard(),
          SizedBox(height: 20.h),
          _buildPrePaidCard(),
          SizedBox(height: 20.h),
          _buildVacationDaysCard(),
          SizedBox(height: 20.h),
          _buildJobInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAnyCached = _isFromCache || _isPrePaidFromCache || _isVacationFromCache;
    
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cx43C19F.withOpacity(0.1),
                AppColors.cx4AC1A7.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.cx43C19F.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _forceRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.cx43C19F,
              size: 24.sp,
            ),
            tooltip: 'Refresh',
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.red.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _handleLogout,
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade600,
              size: 24.sp,
            ),
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final individual = _profileData?['employee']?['individual'];
    final identity = _profileData;
    final employee = _profileData?['employee'];
    final employeeIndividual = employee?['individual'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxRoyalBlue,
            AppColors.cxEmeraldGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxRoyalBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Profile Photo
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: individual?['photo'] != null
                    ? Image.network(
                        individual['photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            SizedBox(height: 16.h),
            // Name
            Text(
              '${employeeIndividual?['firstName'] ?? ''} ${employeeIndividual?['lastName'] ?? ''}'.trim().isNotEmpty 
                  ? '${employeeIndividual?['firstName'] ?? ''} ${employeeIndividual?['lastName'] ?? ''}'.trim()
                  : 'No name',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.cxPureWhite,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            // Email
            Text(
              identity?['email'] ?? 'No email',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.cxPureWhite.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.cxPureWhite.withOpacity(0.3),
            AppColors.cxPureWhite.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 50.sp,
        color: AppColors.cxPureWhite.withOpacity(0.8),
      ),
    );
  }

  Widget _buildWorkHoursCard() {
    // Use work entries fetched from API (already filtered to current month)
    final currentMonthEntries = _workEntries;
    
    // Calculate hours using WorkTimeCalculator
    final totalHoursFormatted = WorkTimeCalculator.calculateTotalHours(currentMonthEntries);
    final totalHours = WorkTimeCalculator.getTotalHoursAsDouble(currentMonthEntries);
    final dayHoursFormatted = WorkTimeCalculator.calculateDayHours(currentMonthEntries);
    final dayHours = WorkTimeCalculator.getDayHoursAsDouble(currentMonthEntries);
    final nightHoursFormatted = WorkTimeCalculator.calculateNightHours(currentMonthEntries);
    final nightHours = WorkTimeCalculator.getNightHoursAsDouble(currentMonthEntries);
    final isOvertime = WorkTimeCalculator.isOvertime(currentMonthEntries);
    
    // Display current month
    final month = _getCurrentMonthString();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxEmeraldGreen,
            AppColors.cxEmeraldGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: _isLoadingWorkEntries
            ? _buildWorkHoursShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: AppColors.cxPureWhite,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Hours',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxPureWhite,
                              ),
                            ),
                            Text(
                              month,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.cxPureWhite.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overtime badge
                      if (isOvertime)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'OVERTIME',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cxPureWhite,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Total hours - prominent display with formatted time
                  Center(
                    child: Column(
                      children: [
                        Text(
                          totalHoursFormatted,
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cxPureWhite,
                            height: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Total Hours (${totalHours.toStringAsFixed(1)}h)',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.cxPureWhite.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Day and Night hours breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                dayHoursFormatted,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${dayHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'Day Hours',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.nightlight_round_outlined,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                nightHoursFormatted,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${nightHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'Night Hours',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWorkHoursShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cxPureWhite.withOpacity(0.2),
      highlightColor: AppColors.cxPureWhite.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Total hours shimmer - prominent display
          Center(
            child: Column(
              children: [
                Container(
                  width: 180.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 140.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Day and Night hours shimmer breakdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.cxPureWhite.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 60.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 70.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.cxPureWhite.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 60.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 70.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusCard() {
    // Use real bonus data from API
    final bonusAmount = _bonusAmount;
    final bonusMonth = _bonusMonth.isNotEmpty ? _bonusMonth : 'Previous Month';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Color scheme for light and dark modes
    final cardBgStart = isDarkMode ? const Color(0xFF2D1B4E) : const Color(0xFFFFF5F7);
    final cardBgMid = isDarkMode ? const Color(0xFF3D2563) : const Color(0xFFFFE8EC);
    final cardBgEnd = isDarkMode ? const Color(0xFF4A2F7A) : const Color(0xFFFFD6DD);
    final borderColor = isDarkMode ? const Color(0xFF7C4DFF) : const Color(0xFFFF6B9D);
    final primaryText = isDarkMode ? const Color(0xFFF0F0F5) : AppColors.cxBlack;
    final secondaryText = isDarkMode ? const Color(0xFFB8B8C8) : AppColors.cxBlack;
    final purpleColor = isDarkMode ? const Color(0xFFB388FF) : const Color(0xFFAF52DE);
    final purpleColorLight = isDarkMode ? const Color(0xFF9C7AFF) : const Color(0xFFC77DFF);
    final accentGlow = isDarkMode ? const Color(0xFFB388FF) : const Color(0xFFFF6B9D);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgStart,
            cardBgMid,
            cardBgEnd,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: borderColor.withOpacity(isDarkMode ? 0.5 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          // Primary shadow
          BoxShadow(
            color: (isDarkMode ? AppColors.cxBlack : purpleColor).withOpacity(isDarkMode ? 0.6 : 0.15),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: isDarkMode ? -2 : 0,
          ),
          // Accent glow
          BoxShadow(
            color: accentGlow.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 32,
            offset: Offset(0, 0),
            spreadRadius: isDarkMode ? -8 : -4,
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: (isDarkMode ? AppColors.cxBlack : purpleColor).withOpacity(isDarkMode ? 0.4 : 0.08),
            blurRadius: 40,
            offset: Offset(0, 20),
            spreadRadius: isDarkMode ? -10 : -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    purpleColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    purpleColorLight.withOpacity(isDarkMode ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(24.w),
            child: _isLoadingBonus
                ? _buildBonusShimmer(isDarkMode, purpleColor, purpleColorLight)
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            purpleColor.withOpacity(isDarkMode ? 0.25 : 0.2),
                            purpleColorLight.withOpacity(isDarkMode ? 0.2 : 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: purpleColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: isDarkMode ? purpleColor : purpleColor,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonus',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            bonusMonth,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bonus badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            purpleColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                            purpleColorLight.withOpacity(isDarkMode ? 0.25 : 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: purpleColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: isDarkMode ? purpleColor : purpleColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                
                // Bonus amount - prominent display
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bonusAmount.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 52.sp,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                              height: 1.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                              shadows: [
                                Shadow(
                                  color: purpleColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              'UZS',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: secondaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              purpleColor.withOpacity(isDarkMode ? 0.2 : 0.15),
                              purpleColorLight.withOpacity(isDarkMode ? 0.15 : 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: purpleColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: purpleColor,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Current Bonus Amount',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Info message
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.white : Colors.black).withOpacity(isDarkMode ? 0.05 : 0.03),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(isDarkMode ? 0.1 : 0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: secondaryText,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          bonusAmount > 0
                              ? 'This bonus will be given after 10th of the month'
                              : 'No bonus available at the moment',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusShimmer(bool isDarkMode, Color purpleColor, Color purpleColorLight) {
    final shimmerBase = (isDarkMode ? Colors.white : purpleColor).withOpacity(isDarkMode ? 0.05 : 0.2);
    final shimmerHighlight = (isDarkMode ? Colors.white : purpleColor).withOpacity(isDarkMode ? 0.1 : 0.4);
    
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 140.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Amount shimmer - prominent display
          Center(
            child: Column(
              children: [
                Container(
                  width: 200.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: 160.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Info message shimmer
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: shimmerBase.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: shimmerBase,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 180.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: shimmerBase,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrePaidCard() {
    // Use actual data from API
    final double prePaidAmount = _prePaidAmount;
    final String month = _getCurrentMonthString();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Dark mode colors - more luxurious palette
    final cardBgStart = isDarkMode ? const Color(0xFF1E1E2E) : AppColors.cxPureWhite;
    final cardBgMid = isDarkMode ? const Color(0xFF252538) : AppColors.cxF7F6F9;
    final cardBgEnd = isDarkMode ? const Color(0xFF2A2A3E) : AppColors.cxF5F7F9;
    final borderColor = isDarkMode ? const Color(0xFF3D3D5C) : AppColors.cxEmeraldGreen;
    final primaryText = isDarkMode ? const Color(0xFFF0F0F5) : AppColors.cxBlack;
    final secondaryText = isDarkMode ? const Color(0xFFA8A8B8) : AppColors.cxBlack;
    final greenColor = isDarkMode ? const Color(0xFF3DDBA4) : AppColors.cxEmeraldGreen;
    final greenColorLight = isDarkMode ? const Color(0xFF2BC990) : Color(0xFF4AC1A7);
    final accentGlow = isDarkMode ? const Color(0xFF3DDBA4) : AppColors.cxEmeraldGreen;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgStart,
            cardBgMid,
            cardBgEnd,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: borderColor.withOpacity(isDarkMode ? 0.4 : 0.2),
          width: isDarkMode ? 1.5 : 1.5,
        ),
        boxShadow: [
          // Primary shadow
          BoxShadow(
            color: (isDarkMode ? AppColors.cxBlack : greenColor).withOpacity(isDarkMode ? 0.5 : 0.1),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: isDarkMode ? -2 : 0,
          ),
          // Accent glow for dark mode
          if (isDarkMode)
            BoxShadow(
              color: accentGlow.withOpacity(0.15),
              blurRadius: 32,
              offset: Offset(0, 0),
              spreadRadius: -8,
            ),
          // Secondary shadow for depth
          BoxShadow(
            color: (isDarkMode ? AppColors.cxBlack : greenColor).withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 40,
            offset: Offset(0, 20),
            spreadRadius: isDarkMode ? -10 : -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24.w),
            child: _isLoadingPrePaid
                ? _buildPrePaidShimmer()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  greenColor.withOpacity(isDarkMode ? 0.2 : 0.15),
                                  greenColorLight.withOpacity(isDarkMode ? 0.15 : 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: greenColor,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avans',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  month,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryText.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      
                      // Amount display - prominent and elegant
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              greenColor,
                              greenColorLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: greenColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 6.h),
                                  child: Text(
                                    'UZS',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cxPureWhite.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  prePaidAmount.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]} ',
                                  ),
                                  style: TextStyle(
                                    fontSize: 42.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cxPureWhite,
                                    height: 1.0,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.cxPureWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'Current Month Balance',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite.withOpacity(0.95),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Info note with icon
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: greenColor,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Pre-payment received for current month',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: secondaryText.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Details button in top-right corner
          if (!_isLoadingPrePaid && _currentMonthTransactions.isNotEmpty)
            Positioned(
              top: 16.h,
              right: 16.w,
              child: InkWell(
                onTap: _showTransactionDetails,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        greenColor.withOpacity(isDarkMode ? 0.2 : 0.15),
                        greenColorLight.withOpacity(isDarkMode ? 0.15 : 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: greenColor.withOpacity(isDarkMode ? 0.4 : 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: greenColor,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrePaidShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cxF5F7F9,
      highlightColor: AppColors.cxPureWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.cxF5F7F9,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxF5F7F9,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 80.w,
                      height: 13.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxF5F7F9,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Amount box shimmer
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.cxF5F7F9,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Container(
                  width: 180.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: 140.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Info row shimmer
          Row(
            children: [
              Container(
                width: 18.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: AppColors.cxF5F7F9,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxF5F7F9,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVacationDaysCard() {
    // Dynamic data from API calculation
    final int availableVacationDays = _availableVacationDays; // Days available to use
    final int usedVacationDays = _totalVacationDays; // Days already used (total vacation entries)
    final int maxVacationDays = 7; // Maximum vacation days that can be earned
    
    // Calculate percentage for progress bar (based on max 7 days)
    final double usagePercentage = availableVacationDays > 0 
        ? (availableVacationDays / maxVacationDays) * 100 
        : 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxRoyalBlue,
            AppColors.cxRoyalBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxRoyalBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: _isLoadingVacation
            ? _buildVacationShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.beach_access_rounded,
                          color: AppColors.cxPureWhite,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vacation Days',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxPureWhite,
                              ),
                            ),
                            Text(
                              'Earned Leave Balance',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.cxPureWhite.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Available days - prominent display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$availableVacationDays',
                          style: TextStyle(
                            fontSize: 56.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cxPureWhite,
                            height: 1,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Days Available',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.cxPureWhite.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Progress bar
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.cxPureWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: usagePercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cxPureWhite,
                              AppColors.cxPureWhite.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cxPureWhite.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Usage breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$usedVacationDays',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Days Used',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$maxVacationDays',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Max Days',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVacationShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cxPureWhite.withOpacity(0.2),
      highlightColor: AppColors.cxPureWhite.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 100.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Available days shimmer
          Center(
            child: Column(
              children: [
                Container(
                  width: 100.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 120.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Progress bar shimmer
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: AppColors.cxPureWhite.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Breakdown shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 40.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 60.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 40.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 60.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoCard() {
    final jobPosition = _profileData?['employee']?['jobPosition'];
    final branch = _profileData?['employee']?['branch'];
    
    return _buildInfoCard(
      title: 'Job Information',
      icon: Icons.work_outline,
      children: [
        _buildInfoRow('Branch', branch?['name'] ?? 'Not specified'),
        _buildInfoRow('Department', _profileData?['employee']?['department']?['name'] ?? 'Not specified'),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Dark mode colors
    final cardBgStart = isDarkMode ? const Color(0xFF1E1E2E) : AppColors.cxPureWhite;
    final cardBgEnd = isDarkMode ? const Color(0xFF252538) : AppColors.cxPureWhite;
    final borderColor = isDarkMode ? const Color(0xFF3D3D5C) : Colors.transparent;
    final primaryText = isDarkMode ? const Color(0xFFF0F0F5) : AppColors.cxBlack;
    final blueColor = isDarkMode ? const Color(0xFF818CF8) : AppColors.cxRoyalBlue;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardBgStart, cardBgEnd],
              )
            : null,
        color: isDarkMode ? null : AppColors.cxPureWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: isDarkMode
            ? Border.all(color: borderColor.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(isDarkMode ? 0.4 : 0.1),
            blurRadius: isDarkMode ? 20 : 15,
            offset: Offset(0, isDarkMode ? 8 : 5),
            spreadRadius: isDarkMode ? -2 : 0,
          ),
          if (isDarkMode)
            BoxShadow(
              color: blueColor.withOpacity(0.1),
              blurRadius: 24,
              offset: Offset(0, 0),
              spreadRadius: -6,
            ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        blueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                        blueColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: blueColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDarkMode ? const Color(0xFFF0F0F5) : AppColors.cxBlack;
    final secondaryText = isDarkMode ? const Color(0xFFA8A8B8) : AppColors.cxBlack;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: secondaryText.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
