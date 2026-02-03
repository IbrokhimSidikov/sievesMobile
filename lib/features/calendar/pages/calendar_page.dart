import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/training_event.dart';
import '../models/training_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final AuthManager _authManager = AuthManager();
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<TrainingEvent> _trainingEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime? _selectedEventDate;
  TimeOfDay? _selectedEventTime;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _expandedEventId;
  List<TrainingTheme> _trainingThemes = [];
  TrainingTheme? _selectedTheme;
  bool _isLoadingThemes = false;
  Function(void Function())? _dialogSetState;

  @override
  void initState() {
    super.initState();
    _loadTrainingEvents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _canCreateEvent() {
    final departmentId = _authManager.currentIdentity?.employee?.departmentId;
    if (departmentId == null) return false;
    return departmentId == 16 || departmentId == 17;
  }

  Future<void> _createEvent(BuildContext dialogContext, Function(bool) setDialogLoading) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEventDate == null || _selectedEventTime == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    if (_selectedTheme == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Please select a training theme')),
      );
      return;
    }

    setDialogLoading(true);

    try {
      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        setDialogLoading(false);
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
        }
        return;
      }

      final requestBody = {
        'name': _selectedTheme!.name,
        'training_theme_id': _selectedTheme!.id,
        'date': DateFormat('yyyy-MM-dd').format(_selectedEventDate!),
        'time': '${_selectedEventTime!.hour.toString().padLeft(2, '0')}:${_selectedEventTime!.minute.toString().padLeft(2, '0')}:00',
      };

      final response = await http.post(
        Uri.parse('https://api.v3.sievesapp.com/training-calendar'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      setDialogLoading(false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.translate('success'),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.translate('eventCreatedSuccess'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.cxEmeraldGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.all(16.w),
              duration: const Duration(seconds: 3),
              elevation: 6,
            ),
          );
        }
        _nameController.clear();
        _dateController.clear();
        _timeController.clear();
        _selectedEventDate = null;
        _selectedEventTime = null;
        
        if (mounted) {
          _loadTrainingEvents();
        }
      } else {
        if (dialogContext.mounted) {
          final l10n = AppLocalizations.of(dialogContext);
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '${l10n.translate('failedToCreateEvent')}: ${response.statusCode}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.cxCrimsonRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating event: $e');
      setDialogLoading(false);
      if (dialogContext.mounted) {
        final l10n = AppLocalizations.of(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '${l10n.translate('failedToCreateEvent')}: $e',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.cxCrimsonRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    }
  }

  Future<void> _loadTrainingThemes() async {
    // Skip if already loaded
    if (_trainingThemes.isNotEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingThemes = true;
    });

    try {
      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingThemes = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.v3.sievesapp.com/training-theme'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _trainingThemes = data.map((json) => TrainingTheme.fromJson(json)).toList();
          _isLoadingThemes = false;
        });
        // Update dialog if it's open
        _dialogSetState?.call(() {});
      } else {
        setState(() {
          _isLoadingThemes = false;
        });
        // Update dialog if it's open
        _dialogSetState?.call(() {});
      }
    } catch (e) {
      print('Error loading training themes: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingThemes = false;
      });
      // Update dialog if it's open
      _dialogSetState?.call(() {});
    }
  }

  void _showCreateEventDialog() {
    // Load themes only if not already cached
    if (_trainingThemes.isEmpty) {
      _loadTrainingThemes();
    }
    _selectedTheme = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Store the setState callback so we can call it when themes load
          _dialogSetState = setDialogState;
          
          return _CreateEventDialog(
            formKey: _formKey,
            nameController: _nameController,
            dateController: _dateController,
            timeController: _timeController,
            trainingThemes: _trainingThemes,
            selectedTheme: _selectedTheme,
            isLoadingThemes: _isLoadingThemes,
            onThemeSelected: (theme) {
              setState(() {
                _selectedTheme = theme;
              });
              setDialogState(() {});
            },
            onDateSelected: (date) {
              setState(() {
                _selectedEventDate = date;
                _dateController.text = DateFormat('yyyy-MM-dd').format(date);
              });
              setDialogState(() {});
            },
            onTimeSelected: (time) {
              setState(() {
                _selectedEventTime = time;
                _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              });
              setDialogState(() {});
            },
            onCancel: () {
              _nameController.clear();
              _dateController.clear();
              _timeController.clear();
              _selectedEventDate = null;
              _selectedEventTime = null;
              _selectedTheme = null;
            },
            onSubmit: _createEvent,
          );
        },
      ),
    ).then((_) {
      // Clear the callback when dialog closes
      _dialogSetState = null;
    });
  }

  Future<void> _loadTrainingEvents() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('authenticationRequired');
          _isLoading = false;
        });
        return;
      }

      // Fetch courses/trainings from the LMS API
      final response = await http.get(
        Uri.parse('https://api.v3.sievesapp.com/training-calendar'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = json.decode(response.body);
        
        // Convert API response to training events
        final events = <TrainingEvent>[];
        for (var course in coursesJson) {
          if (course['deleted'] != true) {
            events.add(TrainingEvent.fromJson(course));
          }
        }

        if (!mounted) return;
        setState(() {
          _trainingEvents = events;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('failedToLoadEvents');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading training events: $e');
      if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('errorLoadingEvents');
          _isLoading = false;
        });
    }
  }

  List<TrainingEvent> _getEventsForDay(DateTime day) {
    return _trainingEvents.where((event) {
      return event.date.year == day.year &&
          event.date.month == day.month &&
          event.date.day == day.day;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('trainingCalendar'),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_canCreateEvent())
            GestureDetector(
              onTap: _showCreateEventDialog,
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20.sp),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoader(theme, isDark)
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(_errorMessage!, style: TextStyle(fontSize: 16.sp)),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadTrainingEvents,
                        child: Text(l10n.translate('retry')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          // Page 1: Calendar View
                          SingleChildScrollView(
                            padding: EdgeInsets.all(20.sp),
                            child: Column(
                              children: [
                                _buildMonthSelector(theme, isDark),
                                SizedBox(height: 24.h),
                                _buildCalendar(theme, isDark),
                                if (_selectedDay != null) ...[
                                  SizedBox(height: 24.h),
                                  _buildSelectedDayEvents(theme, isDark),
                                ],
                              ],
                            ),
                          ),
                          // Page 2: Upcoming Events List
                          SingleChildScrollView(
                            padding: EdgeInsets.all(20.sp),
                            child: _buildUpcomingEvents(theme, isDark),
                          ),
                        ],
                      ),
                    ),
                    // Page Indicator
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          2,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: _currentPage == index ? 24.w : 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              gradient: _currentPage == index
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    )
                                  : null,
                              color: _currentPage == index
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF6366F1).withOpacity(0.25), const Color(0xFF8B5CF6).withOpacity(0.15)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: isDark ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.white, size: 28.sp),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.white, size: 28.sp),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme, bool isDark) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 12.h),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.75,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.h,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox();
              }

              final day = dayOffset + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final events = _getEventsForDay(date);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return _buildDayCell(date, day, events, isToday, theme, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int day, List<TrainingEvent> events, bool isToday, ThemeData theme, bool isDark) {
    final hasEvents = events.isNotEmpty;
    final isSelected = _selectedDay != null &&
        _selectedDay!.year == date.year &&
        _selectedDay!.month == date.month &&
        _selectedDay!.day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDay = null;
          } else {
            _selectedDay = date;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF6366F1).withOpacity(0.3) : const Color(0xFF6366F1).withOpacity(0.15))
              : isToday
                  ? (isDark ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF6366F1).withOpacity(0.08))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: isSelected
              ? Border.all(color: const Color(0xFF6366F1), width: 2.5)
              : isToday
                  ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected || isToday
                    ? const Color(0xFF6366F1)
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (hasEvents) ...[
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  events.length > 3 ? 3 : events.length,
                  (index) => Container(
                    width: 5.w,
                    height: 5.h,
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : AppColors.cxEmeraldGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayEvents(ThemeData theme, bool isDark) {
    if (_selectedDay == null) return const SizedBox();

    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.sp),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy, size: 24.sp, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 12.w),
            Text(
              'Traininglar topilmadi ${DateFormat('MMM dd').format(_selectedDay!)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                DateFormat('EEEE, MMMM dd').format(_selectedDay!),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, size: 20.sp),
              onPressed: () {
                setState(() {
                  _selectedDay = null;
                });
              },
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...events.map((event) => _buildEventCard(event, theme, isDark, isCompact: false)),
      ],
    );
  }

  Widget _buildUpcomingEvents(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    final upcomingEvents = _trainingEvents.where((event) {
      return event.date.isAfter(now.subtract(const Duration(days: 1))) &&
          event.date.isBefore(thirtyDaysFromNow.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Container(
        padding: EdgeInsets.all(32.sp),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48.sp, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: 12.h),
            Text(
              l10n.translate('noEventsNext30Days'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.calendar_month, size: 20.sp, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('nextDays'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${upcomingEvents.length} ${upcomingEvents.length == 1 ? l10n.translate('trainingEvent') : l10n.translate('trainingEvents')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...upcomingEvents.map((event) => _buildEventCard(event, theme, isDark, isCompact: true)),
      ],
    );
  }

  Widget _buildEventCard(TrainingEvent event, ThemeData theme, bool isDark, {bool isCompact = true}) {
    final isExpanded = _expandedEventId == event.id;
    final hasVideo = event.videoUrl != null && event.videoUrl!.isNotEmpty;
    final hasDescription = event.description.isNotEmpty;
    final canExpand = hasVideo || hasDescription;

    return GestureDetector(
      onTap: canExpand ? () {
        setState(() {
          _expandedEventId = isExpanded ? null : event.id;
        });
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.cxEmeraldGreen.withOpacity(0.2), AppColors.cxEmeraldGreen.withOpacity(0.1)]
                : [AppColors.cxEmeraldGreen.withOpacity(0.9), AppColors.cxEmeraldGreen.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: isExpanded 
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
              : isDark ? Border.all(color: AppColors.cxEmeraldGreen.withOpacity(0.3), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cxEmeraldGreen.withOpacity(isDark ? 0.15 : 0.25),
              blurRadius: isExpanded ? 20 : 12,
              offset: Offset(0, isExpanded ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isCompact ? 14.sp : 16.sp),
              child: Row(
                children: [
                  if (event.time != null && !isCompact) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.2),
                                ]
                              : [
                                  AppColors.cxDarkCharcoal.withOpacity(0.15),
                                  AppColors.cxDarkCharcoal.withOpacity(0.1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.4) : AppColors.cxDarkCharcoal.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                            size: 20.sp,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            event.time!.substring(0, 5),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                              letterSpacing: 0.5,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ] else if (event.time == null || isCompact) ...[
                    Container(
                      width: isCompact ? 44.w : 52.w,
                      height: isCompact ? 44.h : 52.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        hasVideo ? Icons.play_circle_outline : Icons.school_outlined,
                        color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                        size: isCompact ? 22.sp : 26.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: isCompact ? 15.sp : 18.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                            letterSpacing: 0.3,
                          ),
                          maxLines: isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        if (!isCompact && event.description.isNotEmpty) ...[
                          Text(
                            event.description,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white.withOpacity(0.85) : AppColors.cxDarkCharcoal.withOpacity(0.75),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                        ],
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 13.sp, color: isDark ? Colors.white.withOpacity(0.9) : AppColors.cxDarkCharcoal.withOpacity(0.8)),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(event.date),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (event.time != null && isCompact) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            Colors.white.withOpacity(0.35),
                                            Colors.white.withOpacity(0.25),
                                          ]
                                        : [
                                            AppColors.cxDarkCharcoal.withOpacity(0.15),
                                            AppColors.cxDarkCharcoal.withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withOpacity(0.4) : AppColors.cxDarkCharcoal.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 12.sp, color: isDark ? Colors.white : AppColors.cxDarkCharcoal),
                                    SizedBox(width: 3.w),
                                    Text(
                                      event.time!.substring(0, 5),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (event.category.isNotEmpty) ...[
                              SizedBox(width: 12.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.2) : AppColors.cxDarkCharcoal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  event.category,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canExpand) ...[
                    SizedBox(width: 8.w),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isExpanded && canExpand) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    if (hasDescription) ...[
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white.withOpacity(0.9) : AppColors.cxDarkCharcoal.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                    if (hasVideo) _TrainingVideoPlayer(videoUrl: event.videoUrl!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(ThemeData theme, bool isDark) {
    final shimmerBase = isDark 
        ? Colors.white.withOpacity(0.05) 
        : const Color(0xFF6366F1).withOpacity(0.1);
    final shimmerHighlight = isDark 
        ? Colors.white.withOpacity(0.1) 
        : const Color(0xFF6366F1).withOpacity(0.2);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.sp),
      child: Column(
        children: [
          // Month selector shimmer
          Shimmer.fromColors(
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
            child: Container(
              height: 56.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Calendar shimmer
          Container(
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                // Weekday headers shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    7,
                    (index) => Expanded(
                      child: Center(
                        child: Shimmer.fromColors(
                          baseColor: shimmerBase,
                          highlightColor: shimmerHighlight,
                          child: Container(
                            width: 30.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Calendar grid shimmer
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 4.w,
                    mainAxisSpacing: 4.h,
                  ),
                  itemCount: 35,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: shimmerBase,
                      highlightColor: shimmerHighlight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          // Event cards shimmer
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _TrainingVideoPlayer({required this.videoUrl});

  @override
  State<_TrainingVideoPlayer> createState() => _TrainingVideoPlayerState();
}

class _TrainingVideoPlayerState extends State<_TrainingVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 32.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppLocalizations.of(context).translate('unableToLoadVideo'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                )
              : !_isInitialized
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: EdgeInsets.all(12.sp),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white.withOpacity(0.3),
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 4.h),
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
}

class _CreateEventDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final List<TrainingTheme> trainingThemes;
  final TrainingTheme? selectedTheme;
  final bool isLoadingThemes;
  final Function(TrainingTheme?) onThemeSelected;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback onCancel;
  final Future<void> Function(BuildContext, Function(bool)) onSubmit;

  const _CreateEventDialog({
    required this.formKey,
    required this.nameController,
    required this.dateController,
    required this.timeController,
    required this.trainingThemes,
    required this.selectedTheme,
    required this.isLoadingThemes,
    required this.onThemeSelected,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  bool _isLoading = false;

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: isDark
            ? BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))
            : BorderSide.none,
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add_circle_outline, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              l10n.translate('createEvent'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Training Theme Dropdown
              DropdownButtonFormField<TrainingTheme>(
                value: widget.selectedTheme,
                decoration: InputDecoration(
                  labelText: l10n.translate('eventName'),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: widget.isLoadingThemes ? 'Loading...' : l10n.translate('eventNameHint'),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.school_outlined, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                dropdownColor: isDark ? theme.cardColor : Colors.white,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.sp),
                isExpanded: true,
                items: widget.trainingThemes.map((themeItem) {
                  return DropdownMenuItem<TrainingTheme>(
                    value: themeItem,
                    child: Text(
                      themeItem.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.cxDarkCharcoal,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isLoading || widget.isLoadingThemes ? null : (TrainingTheme? newValue) {
                  widget.onThemeSelected(newValue);
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.translate('eventNameHint');
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: widget.dateController,
                enabled: !_isLoading,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: l10n.translate('eventDate'),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: l10n.translate('selectDate'),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                readOnly: true,
                onTap: _isLoading ? null : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    widget.onDateSelected(date);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('selectDate');
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: widget.timeController,
                enabled: !_isLoading,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: l10n.translate('eventTime'),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: l10n.translate('selectTime'),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.access_time, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                readOnly: true,
                onTap: _isLoading ? null : () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    widget.onTimeSelected(time);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('selectTime');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          child: Text(
            l10n.translate('cancel'),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => widget.onSubmit(context, _setLoading),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            elevation: 2,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  l10n.translate('create'),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
