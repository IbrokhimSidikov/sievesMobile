import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_list_cubit.dart';
import '../cubit/checklist_list_state.dart';
import '../models/checklist_model.dart' as checklist_model;
import '../models/checklist_submission_model.dart';
import 'checklist_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChecklistListPage extends StatefulWidget {
  const ChecklistListPage({super.key});

  @override
  State<ChecklistListPage> createState() => _ChecklistListPageState();
}

class _ChecklistListPageState extends State<ChecklistListPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<ChecklistSubmission> _submissions = [];
  bool _isLoadingSubmissions = false;
  String? _submissionsError;
  bool _isSubmissionsExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<ChecklistListCubit>().loadChecklists();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      setState(() {
        _isLoadingSubmissions = true;
        _submissionsError = null;
      });

      final authManager = AuthManager();
      final employeeId = authManager.currentEmployeeId;

      if (employeeId == null) {
        setState(() {
          _isLoadingSubmissions = false;
          _submissionsError = 'Employee ID not found. Please login again.';
        });
        return;
      }

      print('🔄 Fetching submissions for employee ID: $employeeId');

      final accessToken = await authManager.authService.getAccessToken();
      if (accessToken == null) {
        setState(() {
          _isLoadingSubmissions = false;
          _submissionsError = 'Authentication failed. Please login again.';
        });
        return;
      }

      // Format dates as YYYY-MM-DD
      final startDateStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';
      final dateRange = '$startDateStr,$endDateStr';

      final url = Uri.parse('https://api.v3.sievesapp.com/checklist/submissions/my?date_range=$dateRange');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Submissions API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final submissions = jsonList.map((json) => ChecklistSubmission.fromJson(json)).toList();

        print('✅ Loaded ${submissions.length} submissions');

        setState(() {
          _submissions = submissions;
          _isLoadingSubmissions = false;
        });
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _isLoadingSubmissions = false;
          _submissionsError = 'Failed to load submissions: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('❌ Error loading submissions: $e');
      setState(() {
        _isLoadingSubmissions = false;
        _submissionsError = 'Error loading submissions: $e';
      });
    }
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checklists',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<ChecklistListCubit, ChecklistListState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            children: [
              // Submissions Section
              _buildSubmissionsCard(context, theme, isDark),
              SizedBox(height: 24.h),

              // Checklists Section
              if (state is ChecklistListLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF4ECDC4),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading checklists...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else if (state is ChecklistListError)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64.sp,
                          color: const Color(0xFFEF4444),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChecklistListCubit>().loadChecklists();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is ChecklistListLoaded)
                if (state.checklists.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 64.sp,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No checklists found',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'There are no checklists for your branch',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...state.checklists.map((checklist) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _buildChecklistCard(
                          context,
                          checklist,
                          theme,
                          isDark,
                        ),
                      )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubmissionsCard(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A24), const Color(0xFF252532)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible, tappable to toggle)
          GestureDetector(
            onTap: () {
              setState(() {
                _isSubmissionsExpanded = !_isSubmissionsExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44B3C2)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Submissions',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_submissions.length} submissions found',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isSubmissionsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 24.sp,
                ),
              ],
            ),
          ),

          // Content (only visible when expanded)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSubmissionsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Date Filters
                Row(
                  children: [
                    Expanded(
                      child: _buildDateFilter(
                        context,
                        'Start Date',
                        _startDate,
                        _selectStartDate,
                        theme,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildDateFilter(
                        context,
                        'End Date',
                        _endDate,
                        _selectEndDate,
                        theme,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Content
                if (_isLoadingSubmissions)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF4ECDC4),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading submissions...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_submissionsError != null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48.sp,
                            color: const Color(0xFFEF4444),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Error loading submissions',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _submissionsError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadSubmissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ECDC4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_submissions.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_rounded,
                            size: 48.sp,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No submissions found',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'No submissions in the selected date range',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _submissions.map((submission) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildSubmissionItem(submission, theme, isDark),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(ChecklistSubmission submission, ThemeData theme, bool isDark) {
    final completedItems = submission.submissionItems.where((item) => item.isChecked).length;
    final totalItems = submission.submissionItems.length;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF4ECDC4),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.checklist.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${submission.createdAt.day.toString().padLeft(2, '0')}/${submission.createdAt.month.toString().padLeft(2, '0')}/${submission.createdAt.year} at ${submission.createdAt.hour.toString().padLeft(2, '0')}:${submission.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      submission.checklist.role,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completedItems/$totalItems completed',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: completedItems == totalItems
                      ? const Color(0xFF4ECDC4).withOpacity(0.2)
                      : const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  completedItems == totalItems ? 'Complete' : 'Partial',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: completedItems == totalItems
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForChecklist(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('opening') || lowerName.contains('daily')) {
      return Icons.store_rounded;
    } else if (lowerName.contains('closing')) {
      return Icons.lock_clock_rounded;
    } else if (lowerName.contains('inventory')) {
      return Icons.inventory_2_rounded;
    } else if (lowerName.contains('safety') || lowerName.contains('security')) {
      return Icons.security_rounded;
    } else if (lowerName.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.checklist_rounded;
  }

  Color _getColorForChecklist(int index) {
    final colors = [
      const Color(0xFF4ECDC4),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];
    return colors[index % colors.length];
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _loadSubmissions();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _loadSubmissions();
    }
  }

  Widget _buildChecklistCard(
      BuildContext context,
      checklist_model.Checklist checklist,
      ThemeData theme,
      bool isDark,
      ) {
    final itemCount = checklist.items.length;
    final color = _getColorForChecklist(checklist.id);
    final icon = _getIconForChecklist(checklist.name);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ChecklistCubit(AuthManager()),
              child: ChecklistDetailPage(
                checklistId: checklist.id,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A24), const Color(0xFF252532)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checklist.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        checklist.description ?? 'No description',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (checklist.isActive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4ECDC4),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  checklist.branch.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.list_alt_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Role: ${checklist.role}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }}
