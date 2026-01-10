import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/training_event.dart';

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
        'name': _nameController.text.trim(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully')),
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
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text('Failed to create event: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error creating event: $e');
      setDialogLoading(false);
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateEventDialog(
        formKey: _formKey,
        nameController: _nameController,
        dateController: _dateController,
        timeController: _timeController,
        onDateSelected: (date) {
          setState(() {
            _selectedEventDate = date;
            _dateController.text = DateFormat('yyyy-MM-dd').format(date);
          });
        },
        onTimeSelected: (time) {
          setState(() {
            _selectedEventTime = time;
            _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          });
        },
        onCancel: () {
          _nameController.clear();
          _dateController.clear();
          _timeController.clear();
          _selectedEventDate = null;
          _selectedEventTime = null;
        },
        onSubmit: _createEvent,
      ),
    );
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
          _errorMessage = 'Authentication required';
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
          _errorMessage = 'Failed to load training events';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading training events: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading training events';
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
          'Training Calendar',
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
          ? Center(child: CircularProgressIndicator())
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
                        child: Text('Retry'),
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
              'No training events in the next 30 days',
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
                  'Next 30 Days',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${upcomingEvents.length} training event${upcomingEvents.length != 1 ? 's' : ''}',
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(isCompact ? 14.sp : 16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.cxEmeraldGreen.withOpacity(0.2), AppColors.cxEmeraldGreen.withOpacity(0.1)]
              : [AppColors.cxEmeraldGreen.withOpacity(0.9), AppColors.cxEmeraldGreen.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: isDark ? Border.all(color: AppColors.cxEmeraldGreen.withOpacity(0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (event.time != null && !isCompact) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
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
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    event.time!.substring(0, 5),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
                Icons.school_outlined,
                color: Colors.white,
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
                    color: Colors.white,
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
                      color: Colors.white.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                ],
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13.sp, color: Colors.white.withOpacity(0.9)),
                    SizedBox(width: 5.w),
                    Text(
                      DateFormat('MMM dd, yyyy').format(event.date),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (event.time != null && isCompact) ...[
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.35),
                              Colors.white.withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 12.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              event.time!.substring(0, 5),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _CreateEventDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback onCancel;
  final Future<void> Function(BuildContext, Function(bool)) onSubmit;

  const _CreateEventDialog({
    required this.formKey,
    required this.nameController,
    required this.dateController,
    required this.timeController,
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
              'Create Training Event',
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
              TextFormField(
                controller: widget.nameController,
                enabled: !_isLoading,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: 'e.g., Customer Service Training',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.event, color: theme.colorScheme.onSurfaceVariant),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter event name';
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
                  labelText: 'Date',
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: 'Select date',
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
                    return 'Please select a date';
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
                  labelText: 'Time',
                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  hintText: 'Select time',
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
                    return 'Please select a time';
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
            'Cancel',
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
                  'Create',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
