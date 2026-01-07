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

  @override
  void initState() {
    super.initState();
    _loadTrainingEvents();
  }

  Future<void> _loadTrainingEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _authManager.authService.getAccessToken();
      
      if (accessToken == null) {
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

      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = json.decode(response.body);
        
        // Convert API response to training events
        final events = <TrainingEvent>[];
        for (var course in coursesJson) {
          if (course['deleted'] != true) {
            events.add(TrainingEvent.fromJson(course));
          }
        }

        setState(() {
          _trainingEvents = events;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load training events';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading training events: $e');
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
              : SingleChildScrollView(
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
                      SizedBox(height: 24.h),
                      // _buildUpcomingEvents(theme, isDark),
                    ],
                  ),
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
    final upcomingEvents = _trainingEvents.where((event) {
      return event.date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
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
              'No upcoming training events',
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
            Icon(Icons.upcoming_outlined, size: 20.sp, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 8.w),
            Text(
              'Upcoming Training Events',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...upcomingEvents.take(5).map((event) => _buildEventCard(event, theme, isDark, isCompact: true)),
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
