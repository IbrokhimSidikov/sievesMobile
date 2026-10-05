import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sieves_mob/core/l10n/app_localizations.dart';
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
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/language_switcher.dart';
import '../../../core/model/day_session_announcement_model.dart';
import '../../home/shared/day_amount_chip.dart';
import '../widgets/onboarding_checklist.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with WidgetsBindingObserver {
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
  // Full transaction list kept in memory so switching months re-filters
  // locally instead of re-fetching from the API every time.
  List<Map<String, dynamic>>? _allPrePaidTransactions;
  // The month currently shown in the Pre-Paid card (defaults to current month)
  DateTime _selectedPrePaidMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  int _availableVacationDays = 0;
  int _totalVacationDays = 0;
  // Distinct vacation days (date only, UTC), most recent first.
  List<DateTime> _vacationDates = [];
  bool _isVacationHistoryExpanded = false;
  double _bonusAmount = 0.0;
  String _bonusMonth = '';
  String? _error;
  String? _role;
  String? _jobPositionName;

  // ── Landing-tab extras (moved here from the old Home page) ──────────
  int _unreadNotificationCount = 0;
  Timer? _unreadRefreshTimer;
  String? _currentEmployeeStatus;
  DaySessionAnnouncement? _dayAnnouncement;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadCurrentMonthWorkEntries();
    _loadPrePaidAmount();
    _loadVacationDays();
    _loadBonusData();

    WidgetsBinding.instance.addObserver(this);
    _loadCurrentStatus();
    _loadDayAnnouncement();
    _loadUnreadCount();
    // Keep the bell badge fresh while this tab is alive.
    _unreadRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _unreadRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
      _loadCurrentStatus();
      _loadDayAnnouncement();
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await _apiService.getUnreadNotificationCount();
    if (mounted) setState(() => _unreadNotificationCount = count);
  }

  Future<void> _loadCurrentStatus() async {
    final employeeId = _authManager.currentEmployeeId;
    if (employeeId == null) return;
    final status = await _apiService.getCurrentEmployeeStatus(employeeId);
    if (mounted) setState(() => _currentEmployeeStatus = status);
  }

  Future<void> _loadDayAnnouncement() async {
    final announcement = await _apiService.getCurrentDaySessionAnnouncement();
    // Keep the last value on a failed refresh instead of hiding the chip.
    if (mounted && announcement != null) {
      setState(() => _dayAnnouncement = announcement);
    }
  }

  Future<void> _loadProfileData({
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    try {
      setState(() {
        if (showLoading) _isLoading = true;
        _error = null;
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
          if (mounted) {
            setState(() {
              _profileData = cachedData;
              _role = cachedData['role'] as String?;
              _jobPositionName = cachedData['jobPositionName'] as String?;
              _isLoading = false;
            });
          }
          return;
        }
      }

      final employeeData = await _apiService.getEmployeeWithExpand(employeeId, [
        'identity',
        'jobPosition',
        'individual.photo',
      ]);

      String? role;
      String? jobPositionName;

      if (employeeData != null) {
        role = employeeData['identity']?['role'] as String?;
        jobPositionName = employeeData['jobPosition']?['name'] as String?;
        print('✅ Role: $role, Job Position: $jobPositionName');
        print(
          '🖼️ Employee photo data from API: ${employeeData['individual']?['photo']}',
        );
      }

      final Map<String, dynamic> identityData = {
        'id': identity.id,
        'email': identity.email,
        'username': identity.username,
        'role': identity.role,
        'phone': identity.phone,
        'allowance': identity.allowance,
        'employee': identity.employee != null
            ? {
                'id': identity.employee!.id,
                'status': identity.employee!.status,
                'individual': identity.employee!.individual != null
                    ? {
                        'firstName': identity.employee!.individual!.firstName,
                        'lastName': identity.employee!.individual!.lastName,
                        'email': identity.employee!.individual!.email,
                        'phone': identity.employee!.individual!.phone,
                        // Use photo from employeeData API response if available
                        'photo':
                            employeeData?['individual']?['photo'] ??
                            (identity.employee!.individual!.photo != null
                                ? {
                                    'id': identity
                                        .employee!
                                        .individual!
                                        .photo!
                                        .id,
                                    'path': identity
                                        .employee!
                                        .individual!
                                        .photo!
                                        .path,
                                    'name': identity
                                        .employee!
                                        .individual!
                                        .photo!
                                        .name,
                                    'format': identity
                                        .employee!
                                        .individual!
                                        .photo!
                                        .format,
                                    'thumbnail': identity
                                        .employee!
                                        .individual!
                                        .photo!
                                        .thumbnail,
                                  }
                                : null),
                      }
                    : null,
                'branch': identity.employee!.branch != null
                    ? {
                        'name': identity.employee!.branch!.name,
                        'address': identity.employee!.branch!.address,
                      }
                    : null,
                'jobPosition': identity.employee!.jobPosition != null
                    ? {'name': identity.employee!.jobPosition!.name}
                    : null,
                'department': identity.employee!.department != null
                    ? {'name': identity.employee!.department!.name}
                    : null,
                'reward': identity.employee!.reward != null
                    ? {
                        'amount': identity.employee!.reward!.amount,
                        'type': identity.employee!.reward!.type,
                      }
                    : null,
              }
            : null,
        'role': role,
        'jobPositionName': jobPositionName,
      };

      // Debug: Log the converted identity data
      print(
        '📦 [Profile] Converted identity data photo: ${identityData['employee']?['individual']?['photo']}',
      );

      // Cache the profile data
      await _cacheService.cacheProfileData(employeeId, identityData);

      if (mounted) {
        setState(() {
          _profileData = identityData;
          _role = role;
          _jobPositionName = jobPositionName;
          _isLoading = false;
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
      print(
        '📅 Fetching work entries from ${dateRange['startDate']} to ${dateRange['endDate']}',
      );

      final workEntriesResponse = await _apiService.getWorkEntries(
        employeeId,
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      if (mounted) {
        setState(() {
          _workEntries =
              (workEntriesResponse?['entries'] as List<dynamic>?)
                  ?.cast<WorkEntry>() ??
              [];
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

      // Cache only applies to the current month (default view).
      final bool isCurrentMonth = _isCurrentMonth(_selectedPrePaidMonth);

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh && isCurrentMonth) {
        final cachedData = await _cacheService.getCachedPrePaidData(
          individualId,
        );
        if (cachedData != null) {
          print('✅ Loaded pre-paid data from cache');
          if (mounted) {
            setState(() {
              _prePaidAmount =
                  (cachedData['amount'] as num?)?.toDouble() ?? 0.0;
              _currentMonthTransactions =
                  (cachedData['transactions'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];
              _isLoadingPrePaid = false;
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
        final transactions = (response['models'] as List)
            .cast<Map<String, dynamic>>();

        // Keep the full list in memory so switching months re-filters
        // locally without another network call.
        _allPrePaidTransactions = transactions;

        // Filter to the selected month and update the UI.
        final result = _filterPrePaidForSelectedMonth();

        // Cache the pre-paid data (only for the current month default view)
        if (isCurrentMonth) {
          await _cacheService.cachePrePaidData(
            individualId,
            result.amount,
            result.transactions,
          );
        }

        if (mounted) {
          setState(() {
            _prePaidAmount = result.amount;
            _currentMonthTransactions = result.transactions;
            _isLoadingPrePaid = false;
          });
          print(
            '💰 Total pre-paid amount: ${result.amount} UZS from ${result.transactions.length} transactions',
          );
        }
      } else {
        print('⚠️ No models found in response');
        if (mounted) {
          setState(() {
            _allPrePaidTransactions = [];
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

  /// Filter the in-memory transaction list down to [_selectedPrePaidMonth]
  /// and return the total amount + matching transactions.
  ({double amount, List<Map<String, dynamic>> transactions})
  _filterPrePaidForSelectedMonth() {
    final month = _selectedPrePaidMonth.month;
    final year = _selectedPrePaidMonth.year;

    double totalAmount = 0.0;
    final List<Map<String, dynamic>> monthTxns = [];

    for (var transaction in _allPrePaidTransactions ?? []) {
      try {
        final dateStr = transaction['date'] as String?;
        if (dateStr != null) {
          final transactionDate = DateTime.parse(dateStr);
          if (transactionDate.month == month && transactionDate.year == year) {
            totalAmount += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
            monthTxns.add(transaction);
          }
        }
      } catch (e) {
        print('⚠️ Error parsing transaction date: $e');
      }
    }

    return (amount: totalAmount, transactions: monthTxns);
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
                    ? [const Color(0xFF1F1F2E), const Color(0xFF1A1A24)]
                    : [Colors.white, Colors.grey.shade50],
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
                    AppLocalizations.of(context).logoutTitle,
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
                    AppLocalizations.of(context).logoutDesc,
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
                                  AppLocalizations.of(context).cancelButton,
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
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
                                      AppLocalizations.of(context).logoutButton,
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

      // The global BlocListener in main.dart will handle navigation to /login
      // when AuthUnauthenticated state is emitted

      print('═══════════════════════════════════════════════════════');
      print(
        '✅ [Profile] Logout handler completed - waiting for global navigation',
      );
      print('═══════════════════════════════════════════════════════');
      print('');
    } else {
      print('❌ [Profile] User cancelled logout');
      print('');
    }
  }

  /// Get formatted current month string
  String _getCurrentMonthString() {
    return _getMonthLabel(DateTime.now());
  }

  /// Format any [date] as a "Month Year" label
  String _getMonthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Whether [date] falls within the current calendar month
  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Shift the Pre-Paid card's selected month by [delta] months and reload.
  /// Going past the current month is not allowed.
  void _changePrePaidMonth(int delta) {
    final candidate = DateTime(
      _selectedPrePaidMonth.year,
      _selectedPrePaidMonth.month + delta,
      1,
    );

    // Don't allow navigating into the future
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    if (candidate.isAfter(currentMonth)) return;

    setState(() {
      _selectedPrePaidMonth = candidate;
    });

    // If the full transaction list is already in memory, just re-filter
    // locally (no network call, no shimmer). Otherwise fetch it once.
    if (_allPrePaidTransactions != null) {
      final result = _filterPrePaidForSelectedMonth();
      setState(() {
        _prePaidAmount = result.amount;
        _currentMonthTransactions = result.transactions;
      });
    } else {
      _loadPrePaidAmount();
    }
  }

  /// Force refresh all profile data (clear cache and reload)
  Future<void> _forceRefresh() async {
    final employeeId = _authManager.currentEmployeeId;
    final individualId = _authManager.currentIdentity?.employee?.individualId;

    if (employeeId != null) {
      await _cacheService.clearAllCachesForUser(employeeId, individualId);
    }

    // Reload all data. Keep the current content on screen (pull-to-refresh
    // shows its own spinner) instead of flipping to the page shimmer.
    await Future.wait([
      _loadProfileData(forceRefresh: true, showLoading: false),
      _loadCurrentMonthWorkEntries(),
      _loadPrePaidAmount(forceRefresh: true),
      _loadVacationDays(forceRefresh: true),
      _loadBonusData(forceRefresh: true),
    ]);
  }

  /// Load vacation days based on work entries
  /// Formula: availableVacation = floor(totalWorkedMilliseconds / (3600000 * 234))
  /// Max 7 days, 234 hours = 1 vacation day
  Future<void> _loadVacationDays({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingVacation = true;
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
        final cachedData = await _cacheService.getCachedVacationData(
          employeeId,
        );
        if (cachedData != null && cachedData.containsKey('vacationDates')) {
          print('✅ Loaded vacation data from cache');
          if (mounted) {
            setState(() {
              _availableVacationDays = cachedData['availableDays'] as int? ?? 0;
              _totalVacationDays = cachedData['totalDays'] as int? ?? 0;
              _vacationDates = _toVacationDays(
                (cachedData['vacationDates'] as List?)?.cast<String>() ?? [],
              );
              _isLoadingVacation = false;
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

      final vacationEntries =
          (vacationResponse?['entries'] as List<WorkEntry>?) ?? [];
      final totalVacations = vacationResponse?['totalCount'] ?? 0;
      final vacationDates = _toVacationDays(
        vacationEntries.map((e) => e.checkInTime),
      );
      final cachedVacationDates = vacationDates
          .map((d) => d.toIso8601String().split('T')[0])
          .toList();

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

        final closedEntries =
            (allClosedEntriesResponse?['entries'] as List<WorkEntry>?) ?? [];

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
            totalWorkedMilliseconds +=
                checkOut.millisecondsSinceEpoch -
                checkIn.millisecondsSinceEpoch;
          }
        }

        // Calculate available vacation days
        // Formula: floor(totalWorkedMilliseconds / (3600000 * 234))
        // 3600000 ms = 1 hour, 234 hours = 1 vacation day
        final calculatedDays = (totalWorkedMilliseconds / (3600000 * 234))
            .floor();
        final availableDays = calculatedDays > 7 ? 7 : calculatedDays;

        print(
          '✅ Calculated vacation days: $availableDays (from ${closedEntries.length} closed entries)',
        );

        // Cache the vacation data
        await _cacheService.cacheVacationData(
          employeeId,
          availableDays,
          totalVacations,
          vacationDates: cachedVacationDates,
        );

        setState(() {
          _availableVacationDays = availableDays;
          _totalVacationDays = totalVacations;
          _vacationDates = vacationDates;
          _isLoadingVacation = false;
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
        startDate = DateTime.parse(
          mostRecentVacation.checkInTime!,
        ).toIso8601String().split('T')[0];

        print('📅 Most recent vacation: $startDate');

        // Fetch attendance entries from most recent vacation to now
        final attendanceResponse = await _apiService.getWorkEntriesByType(
          employeeId: employeeId,
          type: 'attendance',
          status: 'closed',
          startDate: startDate,
          endDate: endDate,
        );

        final attendanceEntries =
            (attendanceResponse?['entries'] as List<WorkEntry>?) ?? [];

        print(
          '📊 Found ${attendanceEntries.length} attendance entries since last vacation',
        );

        // Calculate total worked milliseconds
        int totalWorkedMilliseconds = 0;
        for (var entry in attendanceEntries) {
          if (entry.checkInTime != null && entry.checkOutTime != null) {
            final checkIn = DateTime.parse(entry.checkInTime!);
            final checkOut = DateTime.parse(entry.checkOutTime!);
            totalWorkedMilliseconds +=
                checkOut.millisecondsSinceEpoch -
                checkIn.millisecondsSinceEpoch;
          }
        }

        print('⏱️ Total worked milliseconds: $totalWorkedMilliseconds');

        // Calculate available vacation days
        final calculatedDays = (totalWorkedMilliseconds / (3600000 * 234))
            .floor();
        final availableDays = calculatedDays > 7 ? 7 : calculatedDays;

        print('✅ Calculated vacation days: $availableDays (max 7)');

        // Cache the vacation data
        await _cacheService.cacheVacationData(
          employeeId,
          availableDays,
          totalVacations,
          vacationDates: cachedVacationDates,
        );

        setState(() {
          _availableVacationDays = availableDays;
          _totalVacationDays = totalVacations;
          _vacationDates = vacationDates;
          _isLoadingVacation = false;
        });
      }
    } catch (e) {
      print('❌ Error calculating vacation days: $e');
      setState(() {
        _isLoadingVacation = false;
        _availableVacationDays = 0;
        _totalVacationDays = 0;
        _vacationDates = [];
      });
    }
  }

  /// Normalises raw check-in timestamps to distinct calendar days (UTC, so
  /// day arithmetic is exact), sorted most recent first.
  List<DateTime> _toVacationDays(Iterable<String?> raw) {
    final days = <DateTime>{};
    for (final value in raw) {
      final parsed = value == null ? null : DateTime.tryParse(value)?.toLocal();
      if (parsed != null) {
        days.add(DateTime.utc(parsed.year, parsed.month, parsed.day));
      }
    }
    return days.toList()..sort((a, b) => b.compareTo(a));
  }

  /// The API returns one vacation entry per day; merge consecutive days into
  /// periods, most recent first.
  List<_VacationPeriod> _groupVacationPeriods(List<DateTime> days) {
    final periods = <_VacationPeriod>[];
    for (final day in days) {
      if (periods.isNotEmpty &&
          periods.last.start.difference(day).inDays == 1) {
        final last = periods.removeLast();
        periods.add(_VacationPeriod(day, last.end, last.days + 1));
      } else {
        periods.add(_VacationPeriod(day, day, 1));
      }
    }
    return periods;
  }

  /// Load bonus data for previous month from API
  Future<void> _loadBonusData({bool forceRefresh = false}) async {
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

      // Try to load from cache first (if not forcing refresh)
      if (!forceRefresh) {
        final cachedData = await _cacheService.getCachedBonusData(employeeId);
        if (cachedData != null) {
          print('✅ Loaded bonus data from cache');
          if (mounted) {
            setState(() {
              _bonusAmount = (cachedData['amount'] as num?)?.toDouble() ?? 0.0;
              _bonusMonth = cachedData['month'] as String? ?? '';
              _isLoadingBonus = false;
            });
          }
          return;
        }
      }

      print('🎁 Fetching bonus data for employee $employeeId');

      // Fetch bonus from API (automatically fetches previous month)
      final response = await _apiService.getEmployeeBonus(employeeId);

      if (response != null) {
        // Calculate previous month for display
        final now = DateTime.now();
        final previousMonth = DateTime(now.year, now.month - 1, 1);
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final monthName =
            '${months[previousMonth.month - 1]} ${previousMonth.year}';

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

        // Cache the bonus data
        await _cacheService.cacheBonusData(employeeId, bonusAmount, monthName);

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
        final dialogBg = isDarkMode
            ? const Color(0xFF1A1A24)
            : AppColors.cxPureWhite;
        final itemBg = isDarkMode
            ? const Color(0xFF252532)
            : AppColors.cxF5F7F9;
        final primaryText = isDarkMode
            ? const Color(0xFFE8E8F0)
            : AppColors.cxBlack;
        final secondaryText = isDarkMode
            ? const Color(0xFF9CA3AF)
            : AppColors.cxBlack;
        final borderColor = isDarkMode
            ? const Color(0xFF374151)
            : AppColors.cxEmeraldGreen;
        final greenColor = isDarkMode
            ? const Color(0xFF34D399)
            : AppColors.cxEmeraldGreen;

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
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
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
                          '${AppLocalizations.of(context).transactions} (${_currentMonthTransactions.length})',
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
                      final amount =
                          (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                      final description =
                          transaction['description'] as String? ??
                          'No description';
                      final dateStr = transaction['date'] as String?;
                      final branchData = transaction['branch_id'] as num?;
                      final branchName = branchData?.toString();

                      String formattedDate = 'N/A';
                      if (dateStr != null) {
                        try {
                          final date = DateTime.parse(dateStr);
                          formattedDate =
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
                            color: borderColor.withOpacity(
                              isDarkMode ? 0.3 : 0.1,
                            ),
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
                                    greenColor.withOpacity(
                                      isDarkMode ? 0.2 : 0.1,
                                    ),
                                    greenColor.withOpacity(
                                      isDarkMode ? 0.15 : 0.1,
                                    ),
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
                                  if (branchName != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 12.sp,
                                          color: secondaryText.withOpacity(0.6),
                                        ),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            branchName,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: secondaryText.withOpacity(
                                                0.6,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                  ],
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
                              '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
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
          gradient: isDark
              ? null
              : LinearGradient(
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
          bottom: false,
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
        ),
      ),
    );
  }

  /// Loading silhouette for the header row and the profile card: 44 px end
  /// slots with a centered title bar, then avatar + status, name + email,
  /// divider and the 2×2 details grid.
  Widget _buildHeaderAndProfileShimmer() {
    final tokens = context.tokens;

    Widget box(double w, double h, {double radius = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: tokens.surfaceTint,
            borderRadius: BorderRadius.circular(radius.r),
          ),
        );

    Widget cell() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(56.w, 12.h, radius: 4),
            SizedBox(height: 6.h),
            box(double.infinity, 16.h),
          ],
        );

    return Shimmer.fromColors(
      baseColor: tokens.surfaceTint,
      highlightColor: tokens.surfaceElevated,
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: [44 slot]  ── title ──  [44 bell]
          SizedBox(
            height: 44.w,
            child: Row(
              children: [
                box(44.w, 44.w, radius: 12),
                Expanded(child: Center(child: box(96.w, 22.h))),
                box(44.w, 44.w, radius: 12),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Profile card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: tokens.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            color: tokens.surfaceTint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        box(48.w, 10.h, radius: 4),
                      ],
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(150.w, 18.h),
                          SizedBox(height: 8.h),
                          box(120.w, 12.h, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Divider(height: 1, thickness: 1, color: tokens.outline),
                ),
                Row(
                  children: [
                    Expanded(child: cell()),
                    SizedBox(width: 12.w),
                    Expanded(child: cell()),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: cell()),
                    SizedBox(width: 12.w),
                    Expanded(child: box(double.infinity, 40.h, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shimmerBase = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.grey.shade200;
    final shimmerHighlight = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade50;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        20.w + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + profile card shimmer (same silhouette as the real widgets)
          _buildHeaderAndProfileShimmer(),
          SizedBox(height: 20.h),

          // Work hours card shimmer (same silhouette as the real card)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: context.tokens.outline),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              child: _buildWorkHoursShimmer(),
            ),
          ),
          SizedBox(height: 20.h),

          // Info cards shimmer - 2 columns
          Row(
            children: [
              Expanded(
                child: _buildShimmerCard(
                  shimmerBase: shimmerBase,
                  shimmerHighlight: shimmerHighlight,
                  height: 160.h,
                  gradient: [
                    AppColors.cxWarning.withOpacity(0.3),
                    AppColors.cxWarning.withOpacity(0.25),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildShimmerCard(
                  shimmerBase: shimmerBase,
                  shimmerHighlight: shimmerHighlight,
                  height: 160.h,
                  gradient: [
                    AppColors.cxRoyalBlue.withOpacity(0.3),
                    AppColors.cxRoyalBlue.withOpacity(0.25),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildShimmerCard(
                  shimmerBase: shimmerBase,
                  shimmerHighlight: shimmerHighlight,
                  height: 160.h,
                  gradient: [
                    AppColors.cxEmeraldGreen.withOpacity(0.3),
                    AppColors.cxEmeraldGreen.withOpacity(0.25),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildShimmerCard(
                  shimmerBase: shimmerBase,
                  shimmerHighlight: shimmerHighlight,
                  height: 160.h,
                  gradient: [
                    Colors.purple.withOpacity(0.3),
                    Colors.purple.withOpacity(0.25),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({
    required Color shimmerBase,
    required Color shimmerHighlight,
    required double height,
    required List<Color> gradient,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            Spacer(),
            Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Container(
                width: 80.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Container(
                width: 60.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            SizedBox(height: 16.h),
            // Logout button - always visible even on error
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          AppLocalizations.of(context).logoutButton,
                          style: TextStyle(
                            color: AppColors.cxPureWhite,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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

    final tokens = context.tokens;
    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: tokens.primary,
      backgroundColor: tokens.surfaceElevated,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20.w,
          12.h,
          20.w,
          20.w + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16.h),
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
            _buildFeedbackButton(),
            SizedBox(height: 24.h),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.feedbackForm),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : AppColors.cxPureWhite,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.cx43C19F.withOpacity(isDark ? 0.3 : 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cx43C19F.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cx43C19F.withOpacity(0.2),
                    AppColors.cx4AC1A7.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.cx43C19F.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.feedback_outlined,
                color: AppColors.cx43C19F,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).feedback,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxBlack,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    AppLocalizations.of(context).feedbackSubtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : AppColors.cxBlack.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark
                  ? const Color(0xFF6B7280)
                  : AppColors.cxBlack.withOpacity(0.3),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tokens = context.tokens;
    // Managers and directors only (enforced by the API via `canView`).
    final showDayRate = _dayAnnouncement?.canView == true;

    // Title is centered on the full width; the day-rate chip and the bell
    // sit on top at the edges so an uneven chip width never shifts the title.
    return SizedBox(
      height: 44.w,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Text(
                AppLocalizations.of(context).profile,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showDayRate)
                DayAmountChip(announcement: _dayAnnouncement!)
              else
                SizedBox(width: 44.w),
              // Notifications (with unread badge)
              _buildNotificationButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Full-width destructive button at the end of the page. Confirmation is
  /// handled inside [_handleLogout].
  Widget _buildLogoutButton() {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).logoutButton,
      child: Material(
        color: tokens.error,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: 52.h,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 20.sp, color: tokens.textOnAccent),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context).logoutButton,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: tokens.textOnAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final individual = _profileData?['employee']?['individual'];
    final identity = _profileData;
    final employee = _profileData?['employee'];
    final employeeIndividual = employee?['individual'];

    print('🖼️ [Profile] Individual data: $individual');
    print('🖼️ [Profile] Photo data: ${individual?['photo']}');

    String? photoUrl;
    final photoData = individual?['photo'];
    if (photoData != null && photoData is Map) {
      final path = photoData['path'] as String?;
      final name = photoData['name'] as String?;
      final format = photoData['format'] as String?;
      if (path != null && name != null && format != null) {
        photoUrl =
            'https://sieveserp.ams3.cdn.digitaloceanspaces.com/$path/$name.$format';
      }
    }

    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final accent = tokens.primary;

    final fullName =
        '${employeeIndividual?['firstName'] ?? ''} ${employeeIndividual?['lastName'] ?? ''}'
            .trim();
    final branchName = employee?['branch']?['name'] as String?;

    // Key/value cells shown in a two-column grid under the header.
    final cells = <_ProfileCell>[
      if (branchName != null && branchName.isNotEmpty)
        _ProfileCell(l.branch, Text(branchName, style: _cellValueStyle)),
      if (_jobPositionName != null)
        _ProfileCell(l.jobPosition, Text(_jobPositionName!, style: _cellValueStyle)),
      if (_role != null) _ProfileCell(l.role, Text(_role!, style: _cellValueStyle)),
      // Career shortcut fills the last grid slot (no label of its own).
      _ProfileCell('', _buildCareerButton()),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: tokens.outline),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + status, name + email, onboarding ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(photoUrl, accent),
                    SizedBox(height: 6.h),
                    _buildStatusLabel(),
                  ],
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'No name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        identity?['email'] ?? 'No email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Onboarding check-list (new employees only)
                SizedBox(width: 8.w),
                const OnboardingChecklistIcon(),
              ],
            ),

            // ── Details grid ────────────────────────────────────────
            if (cells.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Divider(height: 1, thickness: 1, color: tokens.outline),
              ),
              for (var i = 0; i < cells.length; i += 2) ...[
                if (i > 0) SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProfileCell(cells[i])),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: i + 1 < cells.length
                          ? _buildProfileCell(cells[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Flat, full-width grid-cell button that opens the Career page.
  /// Violet 12 % fill with a 20 % border, no shadow (design.md §7.6 chip
  /// style); 40 px tall so it lines up with a label + value cell beside it.
  Widget _buildCareerButton() {
    final l = AppLocalizations.of(context);
    final accent = AppAccents.violet.resolve(context);
    return Semantics(
      button: true,
      label: l.careerTitle,
      child: Material(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () => context.push(AppRoutes.careerpage),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Icon(Icons.stairs_rounded, size: 18.sp, color: accent),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    l.careerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18.sp, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _cellValueStyle => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: context.tokens.textPrimary,
        height: 1.3,
      );

  /// Caption label over a value; the value is a widget so it can be a chip.
  Widget _buildProfileCell(_ProfileCell cell) {
    if (cell.label.isEmpty) return cell.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: context.tokens.textSecondary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        DefaultTextStyle.merge(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          child: cell.value,
        ),
      ],
    );
  }

  /// 44×44 header tile with the unread-notification count badge.
  Widget _buildNotificationButton() {
    final tokens = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.20)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await context.push(AppRoutes.notificationNew);
              _loadUnreadCount();
            },
            icon: Icon(
              Icons.notifications_rounded,
              color: tokens.primary,
              size: 24.sp,
            ),
            tooltip: AppLocalizations.of(context).notifications,
          ),
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: -4.w,
            top: -4.h,
            child: Container(
              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: tokens.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.background, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _unreadNotificationCount > 99
                      ? '99+'
                      : '$_unreadNotificationCount',
                  style: TextStyle(
                    color: tokens.textOnAccent,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Compact ONLINE / OFFLINE label under the avatar: 6 px dot + overline
  /// text in the semantic color. Falls back to the cached status until the
  /// live one arrives.
  Widget _buildStatusLabel() {
    final tokens = context.tokens;
    final status =
        (_currentEmployeeStatus ?? _authManager.currentEmployeeStatus)
            ?.toLowerCase() ??
        'offline';
    final isOnline = status == 'online';
    final color = isOnline ? tokens.success : tokens.textTertiary;

    return SizedBox(
      width: 64.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Profile photo with a thin accent ring.
  Widget _buildAvatar(String? photoUrl, Color accent) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(0.25), width: 2),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 64.w,
          height: 64.w,
          child: photoUrl != null
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(accent),
                )
              : _buildDefaultAvatar(accent),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(Color accent) {
    return Container(
      color: accent.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: 36.sp,
        color: accent.withOpacity(0.6),
      ),
    );
  }

  Widget _buildWorkHoursCard() {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final accent = AppAccents.teal.resolve(context);
    final entries = _workEntries;

    final totalFormatted = WorkTimeCalculator.calculateTotalHours(entries);
    final totalHours = WorkTimeCalculator.getTotalHoursAsDouble(entries);
    final dayFormatted = WorkTimeCalculator.calculateDayHours(entries);
    final nightFormatted = WorkTimeCalculator.calculateNightHours(entries);
    final isOvertime = WorkTimeCalculator.isOvertime(entries);

    // Days worked = distinct dates with a closed entry.
    final uniqueDays = <String>{};
    for (final entry in entries) {
      if (!entry.isOpen && entry.checkInTime != null) {
        try {
          final dt = DateTime.parse(entry.checkInTime!);
          uniqueDays.add('${dt.year}-${dt.month}-${dt.day}');
        } catch (_) {}
      }
    }
    final daysWorked = uniqueDays.length;
    final month = _getCurrentMonthString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: _isLoadingWorkEntries
            ? _buildWorkHoursShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: accent,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workHours,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              month,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (isOvertime) ...[
                        _buildWorkHoursChip(
                          label: 'OVERTIME',
                          color: tokens.warning,
                          icon: Icons.bolt_rounded,
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Tooltip(
                        message: l.daysWorkedTooltip(daysWorked, month),
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 3),
                        child: _buildWorkHoursChip(
                          label: '$daysWorked ${l.daysWorkedLabel}',
                          color: accent,
                          icon: Icons.event_available_rounded,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(height: 1, thickness: 1, color: tokens.outline),
                  ),

                  // ── Total hours (hero) ──────────────────────────────
                  Center(
                    child: Text(
                      l.totalHours,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          totalFormatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 0,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${totalHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // ── Day / night breakdown ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildHoursMini(
                          icon: Icons.wb_sunny_rounded,
                          label: l.dayHours,
                          value: dayFormatted,
                          color: tokens.warning,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildHoursMini(
                          icon: Icons.nightlight_round,
                          label: l.nightHours,
                          value: nightFormatted,
                          color: tokens.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  /// Small tinted chip used in the Work Hours header (days worked, overtime).
  Widget _buildWorkHoursChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Quiet secondary stat (day / night hours): tinted tile, icon, label, value.
  Widget _buildHoursMini({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: tokens.surfaceTint,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    height: 1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHoursShimmer() {
    final tokens = context.tokens;

    Widget box(double w, double h, {double radius = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: tokens.surfaceTint,
            borderRadius: BorderRadius.circular(radius.r),
          ),
        );

    return Shimmer.fromColors(
      baseColor: tokens.surfaceTint,
      highlightColor: tokens.surfaceElevated,
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              box(40.w, 40.w, radius: 12),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(110.w, 16.h),
                    SizedBox(height: 6.h),
                    box(70.w, 12.h, radius: 4),
                  ],
                ),
              ),
              box(64.w, 28.h),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Divider(height: 1, thickness: 1, color: tokens.outline),
          ),
          box(64.w, 12.h, radius: 4),
          SizedBox(height: 6.h),
          box(150.w, 36.h),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: box(double.infinity, 48.h, radius: 12)),
              SizedBox(width: 8.w),
              Expanded(child: box(double.infinity, 48.h, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusCard() {
    final bonusAmount = _bonusAmount;
    final bonusMonth = _bonusMonth.isNotEmpty ? _bonusMonth : 'Previous Month';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    const accent = AppColors.cxPurple;
    final cardBg = isDarkMode
        ? colorScheme.surface
        : const Color(0xFFF9F5FF);
    final borderColor = isDarkMode
        ? accent.withOpacity(0.18)
        : accent.withOpacity(0.14);
    final primaryText = colorScheme.onSurface;
    final secondaryText = isDarkMode
        ? colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: _isLoadingBonus
            ? _buildBonusShimmer(isDarkMode, accent)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: accent,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).bonus,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                            Text(
                              bonusMonth,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Active pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: accent, size: 7.sp),
                            SizedBox(width: 5.w),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: borderColor,
                    ),
                  ),

                  // ── Amount row ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bonusAmount
                            .toStringAsFixed(0)
                            .replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]} ',
                            ),
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Text(
                          'UZS',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: accent,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            AppLocalizations.of(context).currentBonusAmount,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Info strip ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: secondaryText,
                        size: 15.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          bonusAmount > 0
                              ? AppLocalizations.of(context).bonusDesc
                              : AppLocalizations.of(context).noBonus,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: secondaryText,
                            height: 1.4,
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

  Widget _buildBonusShimmer(bool isDarkMode, Color accent) {
    final base = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : accent.withOpacity(0.08);
    final highlight = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : accent.withOpacity(0.18);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(height: 1, color: base),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 60.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(width: 30.w),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.h,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrePaidCard() {
    final double prePaidAmount = _prePaidAmount;
    final String month = _getMonthLabel(_selectedPrePaidMonth);
    final bool isCurrentMonth = _isCurrentMonth(_selectedPrePaidMonth);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    const accent = AppColors.cxEmeraldGreen;
    final cardBg = isDarkMode
        ? colorScheme.surface
        : const Color(0xFFF2FBF7);
    final borderColor = isDarkMode
        ? accent.withOpacity(0.18)
        : accent.withOpacity(0.14);
    final primaryText = colorScheme.onSurface;
    final secondaryText = isDarkMode
        ? colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: _isLoadingPrePaid
            ? _buildPrePaidShimmer(isDarkMode, accent)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: accent,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).prePaid,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMonthArrow(
                                  icon: Icons.chevron_left_rounded,
                                  accent: accent,
                                  secondaryText: secondaryText,
                                  enabled: true,
                                  onTap: () => _changePrePaidMonth(-1),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  month,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryText,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                _buildMonthArrow(
                                  icon: Icons.chevron_right_rounded,
                                  accent: accent,
                                  secondaryText: secondaryText,
                                  enabled: !isCurrentMonth,
                                  onTap: () => _changePrePaidMonth(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Transactions count pill / receipt button
                      if (_currentMonthTransactions.isNotEmpty)
                        GestureDetector(
                          onTap: _showTransactionDetails,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: accent,
                                  size: 13.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  '${_currentMonthTransactions.length}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(height: 1, thickness: 1, color: borderColor),
                  ),

                  // ── Amount row ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        prePaidAmount
                            .toStringAsFixed(0)
                            .replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]} ',
                            ),
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Text(
                          'UZS',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: accent,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isCurrentMonth
                                ? AppLocalizations.of(
                                    context,
                                  ).currentMonthBalance
                                : month,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Info strip ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: secondaryText,
                        size: 15.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).prePaidDesc,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: secondaryText,
                            height: 1.4,
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

  /// Small chevron button used to step the Pre-Paid card between months.
  Widget _buildMonthArrow({
    required IconData icon,
    required Color accent,
    required Color secondaryText,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: enabled ? accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: enabled ? accent : secondaryText.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildPrePaidShimmer(bool isDarkMode, Color accent) {
    final base = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : accent.withOpacity(0.08);
    final highlight = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : accent.withOpacity(0.18);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(height: 1, color: base),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 60.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(width: 30.w),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.h,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4.r),
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
    final int availableVacationDays = _availableVacationDays;
    final int usedVacationDays = _totalVacationDays;
    const int maxVacationDays = 7;
    final double usagePercentage = availableVacationDays > 0
        ? (availableVacationDays / maxVacationDays).clamp(0.0, 1.0)
        : 0.0;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    const accent = AppColors.cxBlue;
    final cardBg = isDarkMode
        ? colorScheme.surface
        : const Color(0xFFF2F6FF);
    final borderColor = isDarkMode
        ? accent.withOpacity(0.18)
        : accent.withOpacity(0.14);
    final primaryText = colorScheme.onSurface;
    final secondaryText = isDarkMode
        ? colorScheme.onSurfaceVariant
        : const Color(0xFF6B7280);
    final trackColor = isDarkMode
        ? accent.withOpacity(0.15)
        : accent.withOpacity(0.12);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: _isLoadingVacation
            ? _buildVacationShimmer(isDarkMode, accent)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.beach_access_rounded,
                          color: accent,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).vacationDays,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context).earnedLeaveBalance,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Available pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: accent, size: 7.sp),
                            SizedBox(width: 5.w),
                            Text(
                              '$availableVacationDays / $maxVacationDays',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(height: 1, thickness: 1, color: borderColor),
                  ),

                  // ── Stats row ───────────────────────────────────────────
                  Row(
                    children: [
                      // Available (large)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$availableVacationDays',
                              style: TextStyle(
                                fontSize: 40.sp,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                                height: 1.0,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              AppLocalizations.of(context).daysAvailable,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider line
                      Container(
                        width: 1,
                        height: 48.h,
                        color: borderColor,
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      // Used + Max
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$usedVacationDays',
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: primaryText,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    AppLocalizations.of(context).daysUsed,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: secondaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36.h,
                              color: borderColor,
                              margin: EdgeInsets.symmetric(horizontal: 10.w),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$maxVacationDays',
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: primaryText,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    AppLocalizations.of(context).maxDays,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: secondaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Progress bar ────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: usagePercentage,
                      backgroundColor: trackColor,
                      color: accent,
                      minHeight: 6.h,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // ── Info strip ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: secondaryText,
                        size: 15.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          availableVacationDays > 0
                              ? AppLocalizations.of(context).earnedLeaveBalance
                              : AppLocalizations.of(context).earnedLeaveBalance,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(height: 1, thickness: 1, color: borderColor),
                  ),

                  // ── History ─────────────────────────────────────────────
                  _buildVacationHistorySection(accent),
                ],
              ),
      ),
    );
  }

  static const int _vacationHistoryPreviewCount = 3;

  Widget _buildVacationHistorySection(Color accent) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final periods = _groupVacationPeriods(_vacationDates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _isVacationHistoryExpanded,
          child: InkWell(
            onTap: () => setState(
              () => _isVacationHistoryExpanded = !_isVacationHistoryExpanded,
            ),
            borderRadius: BorderRadius.circular(8.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.vacationHistory,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  if (periods.isNotEmpty) ...[
                    Text(
                      l.dayCount(_vacationDates.length),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: t.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                  ],
                  AnimatedRotation(
                    turns: _isVacationHistoryExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: t.textSecondary,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_isVacationHistoryExpanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: periods.isEmpty
                      ? Row(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              color: t.textSecondary,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                l.noVacationHistory,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            for (final period in periods.take(
                              _vacationHistoryPreviewCount,
                            ))
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: _buildVacationPeriodRow(period, accent),
                              ),
                            if (periods.length > _vacationHistoryPreviewCount)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _showVacationHistorySheet(periods, accent),
                                  style: TextButton.styleFrom(
                                    foregroundColor: accent,
                                    minimumSize: Size(44.w, 44.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                  ),
                                  child: Text(
                                    l.seeAll,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildVacationPeriodRow(_VacationPeriod period, Color accent) {
    final t = context.tokens;

    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.event_available_rounded,
            color: accent,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            _formatVacationPeriod(period),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            AppLocalizations.of(context).dayCount(period.days),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  String _formatVacationPeriod(_VacationPeriod period) {
    final locale = Localizations.localeOf(context).languageCode;
    final full = DateFormat('d MMM yyyy', locale);
    if (period.days == 1) return full.format(period.start);
    final startFormat = period.start.year == period.end.year
        ? DateFormat('d MMM', locale)
        : full;
    return '${startFormat.format(period.start)} – ${full.format(period.end)}';
  }

  void _showVacationHistorySheet(List<_VacationPeriod> periods, Color accent) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: t.outlineStrong,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.vacationHistory,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      l.dayCount(_vacationDates.length),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: t.outline),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                  itemCount: periods.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, i) =>
                      _buildVacationPeriodRow(periods[i], accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVacationShimmer(bool isDarkMode, Color accent) {
    final base = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : accent.withOpacity(0.08);
    final highlight = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : accent.withOpacity(0.18);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(height: 1, color: base),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 60.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(width: 30.w),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.h,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One label/value pair in the profile card grid.
class _ProfileCell {
  const _ProfileCell(this.label, this.value);

  final String label;
  final Widget value;
}

class _VacationPeriod {
  const _VacationPeriod(this.start, this.end, this.days);

  final DateTime start;
  final DateTime end;
  final int days;
}
