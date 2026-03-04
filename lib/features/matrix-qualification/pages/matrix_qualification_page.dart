import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';

class MatrixQualificationPage extends StatefulWidget {
  const MatrixQualificationPage({super.key});

  @override
  State<MatrixQualificationPage> createState() => _MatrixQualificationPageState();
}

class _MatrixQualificationPageState extends State<MatrixQualificationPage> with SingleTickerProviderStateMixin {
  String? _selectedEmployeeId;
  bool _isSubmitting = false;
  bool _isLoadingEmployees = true;
  bool _isLoadingFields = true;

  List<Map<String, dynamic>> _employees = [];
  List<SkillCategory> _skillCategories = [];

  final Map<String, int> _ratings = {};
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadEmployees(),
      _loadMatrixFields(),
    ]);
  }

  Future<void> _loadMatrixFields() async {
    try {
      setState(() {
        _isLoadingFields = true;
      });
      
      final authManager = AuthManager();
      final fields = await authManager.apiService.getMatrixQualificationFields();
      
      if (fields != null && fields.isNotEmpty) {
        final colors = [
          // AppColors.cxRoyalBlue,
          AppColors.cxEmeraldGreen,
          // AppColors.cxAmberGold,
          // AppColors.cxPurple,
          // AppColors.cxWarning,
        ];
        
        final icons = [
          Icons.star_rounded,
          Icons.workspace_premium_rounded,
          Icons.emoji_events_outlined,
          Icons.trending_up_rounded,
          Icons.verified_rounded,
        ];
        
        setState(() {
          _skillCategories = fields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            final title = field['title'] ?? 'Unknown';
            final uuid = field['uuid'] ?? field['id']?.toString() ?? '';
            
            return SkillCategory(
              title: title,
              description: field['description'] ?? '',
              icon: icons[index % icons.length],
              color: colors[index % colors.length],
              uuid: uuid,
            );
          }).toList();
          
          for (var category in _skillCategories) {
            _ratings[category.title] = 0;
          }
          
          _isLoadingFields = false;
        });
        print('✅ Loaded ${_skillCategories.length} matrix qualification fields');
      } else {
        throw Exception('No fields returned from API');
      }
    } catch (e) {
      print('❌ Error loading matrix fields: $e');
      setState(() {
        _isLoadingFields = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load qualification fields'),
            backgroundColor: AppColors.cxCrimsonRed,
          ),
        );
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoadingEmployees = true;
      });
      
      final authManager = AuthManager();
      final data = await authManager.apiService.getKitchenEmployees();
      
      if (data != null) {
        setState(() {
          _employees = data.map((employee) {
            final individual = employee['individual'] ?? {};
            final firstName = individual['first_name'] ?? '';
            final lastName = individual['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            final jobPosition = employee['jobPosition'] ?? {};
            
            return {
              'id': employee['id'].toString(),
              'name': fullName.isNotEmpty ? fullName : 'Unknown',
              'individual_id': employee['individual_id'],
              'job_position_id': jobPosition['id'],
              'job_position_name': jobPosition['name'] ?? 'Unknown',
            };
          }).toList();
          _isLoadingEmployees = false;
        });
        print('✅ Loaded ${_employees.length} kitchen employees');
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print('❌ Error loading employees: $e');
      setState(() {
        _isLoadingEmployees = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadEmployees),
            backgroundColor: AppColors.cxCrimsonRed,
          ),
        );
      }
    }
  }

  void _updateRating(String category, int rating) {
    setState(() {
      _ratings[category] = rating;
    });
  }

  double get _averageRating {
    if (_ratings.isEmpty) return 0;
    final total = _ratings.values.fold(0, (sum, rating) => sum + rating);
    return total / _ratings.length;
  }

  Map<int, int> get _ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var rating in _ratings.values) {
      if (rating > 0) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }
    }
    return distribution;
  }

  Future<void> _submitQualification() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }

    final unratedCategories = _ratings.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList();

    if (unratedCategories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all categories')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authManager = AuthManager();
      final employeeId = int.parse(_selectedEmployeeId!);
      
      final items = <Map<String, dynamic>>[];
      
      for (var entry in _ratings.entries) {
        final categoryTitle = entry.key;
        final rating = entry.value;
        
        final category = _skillCategories.firstWhere(
          (cat) => cat.title == categoryTitle,
        );
        
        final qualificationUuid = category.uuid ?? '';
        
        if (qualificationUuid.isEmpty) {
          print('⚠️ No UUID found for category: $categoryTitle');
          continue;
        }
        
        items.add({
          'qualification_uuid': qualificationUuid,
          'rating': rating,
          'comment': category.description,
        });
      }
      
      if (items.isEmpty) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid qualifications to submit'),
              backgroundColor: AppColors.cxWarning,
            ),
          );
        }
        return;
      }
      
      final success = await authManager.apiService.submitMatrixQualificationResults(
        employeeId: employeeId,
        items: items,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Qualification submitted successfully!'),
              backgroundColor: AppColors.cxEmeraldGreen,
            ),
          );
          
          setState(() {
            _selectedEmployeeId = null;
            for (var category in _skillCategories) {
              _ratings[category.title] = 0;
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit qualification. Please try again.'),
              backgroundColor: AppColors.cxCrimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error submitting qualification: $e');
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.cxCrimsonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surface,
                  ]
                : [
                    AppColors.cxWhite,
                    AppColors.cxF5F7F9,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations, isDark, theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmployeeDropdown(localizations, isDark, theme),
                      SizedBox(height: 24.h),
                      _buildPieChartCard(localizations, isDark, theme),
                      SizedBox(height: 24.h),
                      _isLoadingFields
                          ? _buildFieldsShimmer(isDark, theme)
                          : _buildRatingCards(isDark, theme),
                      SizedBox(height: 24.h),
                      _buildSubmitButton(localizations, isDark, theme),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStarInfoDialog(AppLocalizations localizations, bool isDark, ThemeData theme) {
    final starData = [
      (
        title: localizations.star1Title,
        desc: localizations.star1Desc,
        color: AppColors.cxCrimsonRed,
        icon: Icons.school_rounded,
      ),
      (
        title: localizations.star2Title,
        desc: localizations.star2Desc,
        color: AppColors.cxWarning,
        icon: Icons.person_rounded,
      ),
      (
        title: localizations.star3Title,
        desc: localizations.star3Desc,
        color: AppColors.cxAmberGold,
        icon: Icons.bolt_rounded,
      ),
      (
        title: localizations.star4Title,
        desc: localizations.star4Desc,
        color: AppColors.cxEmeraldGreen,
        icon: Icons.groups_rounded,
      ),
      (
        title: localizations.star5Title,
        desc: localizations.star5Desc,
        color: AppColors.cxRoyalBlue,
        icon: Icons.trending_up_rounded,
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : AppColors.cxPlatinumGray,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cxPurple.withOpacity(0.2),
                            AppColors.cxPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.cxPurple,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.starRatingTitle,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : AppColors.cxDarkCharcoal,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            localizations.starRatingSubtitle,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppColors.cxSilverTint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      ...starData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : item.color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: item.color.withOpacity(isDark ? 0.35 : 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        item.color.withOpacity(isDark ? 0.3 : 0.2),
                                        item.color.withOpacity(isDark ? 0.15 : 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(i + 1, (_) => Padding(
                                            padding: EdgeInsets.only(right: 2.w),
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: item.color,
                                              size: 13.sp,
                                            ),
                                          )),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? theme.colorScheme.onSurface
                                              : AppColors.cxDarkCharcoal,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        item.desc,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          height: 1.4,
                                          color: isDark
                                              ? theme.colorScheme.onSurfaceVariant
                                              : AppColors.cxGraphiteGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations localizations, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cxPurple.withOpacity(0.8),
                  AppColors.cxPurple.withOpacity(0.6),
                ]
              : [
                  AppColors.cxPurple,
                  AppColors.cxPurple.withOpacity(0.8),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxPurple.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.cxWhite,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxWhite.withOpacity(isDark ? 0.2 : 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.grid_on_outlined,
              color: AppColors.cxWhite,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.matrixQualification,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  localizations.matrixQualificationSubtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cxWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showStarInfoDialog(localizations, isDark, theme),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.cxWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
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
          ),
        ],
      ),
    );
  }

  void _showEmployeeSearchSheet(AppLocalizations localizations, bool isDark, ThemeData theme) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_employees);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void onSearch(String query) {
              setSheetState(() {
                filtered = _employees
                    .where((e) => (e['name'] as String)
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              });
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                          : AppColors.cxPlatinumGray,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cxPurple.withOpacity(0.2),
                                AppColors.cxPurple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            color: AppColors.cxPurple,
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.selectEmployee,
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? theme.colorScheme.onSurface
                                      : AppColors.cxDarkCharcoal,
                                ),
                              ),
                              Text(
                                '${_employees.length} ${localizations.employee.toLowerCase()}s',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.cxSilverTint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : AppColors.cxF5F7F9,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.sp,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppColors.cxGraphiteGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : AppColors.cxF5F7F9,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? theme.colorScheme.outline.withOpacity(0.3)
                              : AppColors.cxPlatinumGray,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: onSearch,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : AppColors.cxDarkCharcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: '${localizations.selectEmployee}...',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.cxSilverTint,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? theme.colorScheme.primary
                                : AppColors.cxPurple,
                            size: 20.sp,
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: searchController,
                            builder: (_, value, __) => value.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchController.clear();
                                      onSearch('');
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16.sp,
                                      color: isDark
                                          ? theme.colorScheme.onSurfaceVariant
                                          : AppColors.cxSilverTint,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48.sp,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.cxSilverTint,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  localizations.noEmployeesAvailable,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : AppColors.cxSilverTint,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 4.h),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? theme.colorScheme.outline.withOpacity(0.15)
                                  : AppColors.cxPlatinumGray.withOpacity(0.5),
                            ),
                            itemBuilder: (_, index) {
                              final employee = filtered[index];
                              final isSelected =
                                  employee['id'] == _selectedEmployeeId;
                              final name = employee['name'] as String;
                              final position =
                                  employee['job_position_name'] as String? ?? '';
                              final initials = name.isNotEmpty
                                  ? name
                                      .trim()
                                      .split(' ')
                                      .take(2)
                                      .map((w) => w.isNotEmpty ? w[0] : '')
                                      .join()
                                      .toUpperCase()
                                  : '?';

                              return InkWell(
                                onTap: () {
                                  setState(
                                      () => _selectedEmployeeId = employee['id']);
                                  Navigator.of(ctx).pop();
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isSelected
                                                ? [
                                                    AppColors.cxPurple,
                                                    AppColors.cxPurple
                                                        .withOpacity(0.7),
                                                  ]
                                                : [
                                                    AppColors.cxPurple
                                                        .withOpacity(
                                                            isDark ? 0.3 : 0.15),
                                                    AppColors.cxPurple
                                                        .withOpacity(
                                                            isDark ? 0.15 : 0.08),
                                                  ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? AppColors.cxWhite
                                                  : (isDark
                                                      ? theme.colorScheme.primary
                                                      : AppColors.cxPurple),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? (isDark
                                                        ? theme
                                                            .colorScheme.primary
                                                        : AppColors.cxPurple)
                                                    : (isDark
                                                        ? theme.colorScheme
                                                            .onSurface
                                                        : AppColors
                                                            .cxDarkCharcoal),
                                              ),
                                            ),
                                            if (position.isNotEmpty) ...[
                                              SizedBox(height: 2.h),
                                              Text(
                                                position,
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  color: isDark
                                                      ? theme.colorScheme
                                                          .onSurfaceVariant
                                                      : AppColors.cxSilverTint,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: EdgeInsets.all(4.r),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.cxPurple.withOpacity(
                                                    isDark ? 0.25 : 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 14.sp,
                                            color: isDark
                                                ? theme.colorScheme.primary
                                                : AppColors.cxPurple,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeeDropdown(AppLocalizations localizations, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.3)
              : AppColors.cxPlatinumGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: isDark ? theme.colorScheme.primary : AppColors.cxPurple,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                localizations.selectEmployee,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _isLoadingEmployees
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : AppColors.cxF5F7F9,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cxPurple.withOpacity(0.2),
                                  AppColors.cxPurple.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.6 + (_pulseAnimation.value * 0.4),
                                child: Container(
                                  width: 24.w,
                                  height: 24.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isDark
                                            ? theme.colorScheme.primary
                                            : AppColors.cxPurple)
                                        .withOpacity(1.0 - _pulseAnimation.value),
                                  ),
                                ),
                              );
                            },
                          ),
                          Icon(
                            Icons.people_outline_rounded,
                            color: isDark ? theme.colorScheme.primary : AppColors.cxPurple,
                            size: 16.sp,
                          ),
                        ],
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
                                borderRadius: BorderRadius.circular(4.r),
                                gradient: LinearGradient(
                                  colors: [
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.3),
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.1),
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.3),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              width: 120.w,
                              height: 10.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.r),
                                gradient: LinearGradient(
                                  colors: [
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.2),
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.05),
                                    (isDark
                                            ? theme.colorScheme.surfaceContainerHigh
                                            : AppColors.cxPlatinumGray)
                                        .withOpacity(0.2),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _employees.isEmpty
                      ? null
                      : () => _showEmployeeSearchSheet(localizations, isDark, theme),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : AppColors.cxF5F7F9,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _selectedEmployeeId != null
                            ? (isDark
                                ? AppColors.cxPurple.withOpacity(0.5)
                                : AppColors.cxPurple.withOpacity(0.4))
                            : (isDark
                                ? theme.colorScheme.outline.withOpacity(0.3)
                                : AppColors.cxPlatinumGray),
                        width: _selectedEmployeeId != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedEmployeeId != null
                              ? Icons.person_rounded
                              : Icons.search_rounded,
                          color: _selectedEmployeeId != null
                              ? (isDark ? theme.colorScheme.primary : AppColors.cxPurple)
                              : (isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppColors.cxSilverTint),
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _selectedEmployeeId != null
                                ? (_employees.firstWhere(
                                    (e) => e['id'] == _selectedEmployeeId,
                                    orElse: () => {'name': ''},
                                  )['name'] ?? '')
                                : (_employees.isEmpty
                                    ? localizations.noEmployeesAvailable
                                    : localizations.selectEmployee),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: _selectedEmployeeId != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedEmployeeId != null
                                  ? (isDark
                                      ? theme.colorScheme.onSurface
                                      : AppColors.cxDarkCharcoal)
                                  : (isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.cxSilverTint),
                            ),
                          ),
                        ),
                        if (_selectedEmployeeId != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedEmployeeId = null),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16.sp,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppColors.cxSilverTint,
                            ),
                          )
                        else
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? theme.colorScheme.primary : AppColors.cxPurple,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(AppLocalizations localizations, bool isDark, ThemeData theme) {
    final hasRatings = _ratings.values.any((rating) => rating > 0);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.3)
              : AppColors.cxPlatinumGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: isDark ? theme.colorScheme.primary : AppColors.cxPurple,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Rating Distribution',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxPurple.withOpacity(0.2),
                      AppColors.cxPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Avg: ${_averageRating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.cxPurple.withOpacity(0.9) : AppColors.cxPurple,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 200.h,
            child: hasRatings
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50.r,
                      sections: _buildPieChartSections(isDark),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48.sp,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : AppColors.cxSilverTint,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Start rating to see distribution',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.cxSilverTint,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (hasRatings) ...[
            SizedBox(height: 20.h),
            _buildLegend(isDark, theme),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(bool isDark) {
    final distribution = _ratingDistribution;
    final colors = [
      AppColors.cxCrimsonRed,
      AppColors.cxWarning,
      AppColors.cxAmberGold,
      AppColors.cxEmeraldGreen,
      AppColors.cxRoyalBlue,
    ];

    return distribution.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final rating = entry.key;
          final count = entry.value;
          final percentage = (count / _skillCategories.length) * 100;

          return PieChartSectionData(
            color: colors[rating - 1].withOpacity(isDark ? 0.8 : 1.0),
            value: count.toDouble(),
            title: '$count',
            radius: 50.r,
            titleStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.cxWhite,
            ),
          );
        })
        .toList();
  }

  Widget _buildLegend(bool isDark, ThemeData theme) {
    final colors = [
      AppColors.cxCrimsonRed,
      AppColors.cxWarning,
      AppColors.cxAmberGold,
      AppColors.cxEmeraldGreen,
      AppColors.cxRoyalBlue,
    ];
    final labels = ['1 Star', '2 Stars', '3 Stars', '4 Stars', '5 Stars'];

    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: List.generate(5, (index) {
        final count = _ratingDistribution[index + 1] ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: colors[index].withOpacity(isDark ? 0.8 : 1.0),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.cxGraphiteGray,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFieldsShimmer(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Categories',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 12.h),
        ...List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : AppColors.cxF5F7F9,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : AppColors.cxF5F7F9,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                width: 150.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : AppColors.cxF5F7F9,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (starIndex) {
                        return Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : AppColors.cxF5F7F9,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRatingCards(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Categories',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 12.h),
        ...List.generate(_skillCategories.length, (index) {
          final category = _skillCategories[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildRatingCard(category, isDark, theme),
          );
        }),
      ],
    );
  }

  Widget _buildRatingCard(SkillCategory category, bool isDark, ThemeData theme) {
    final currentRating = _ratings[category.title] ?? 0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: currentRating > 0
              ? category.color.withOpacity(isDark ? 0.5 : 0.3)
              : (isDark
                  ? theme.colorScheme.outline.withOpacity(0.3)
                  : AppColors.cxPlatinumGray.withOpacity(0.5)),
          width: currentRating > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withOpacity(isDark ? 0.3 : 0.2),
                      category.color.withOpacity(isDark ? 0.2 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.cxSilverTint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = currentRating >= rating;

              return GestureDetector(
                onTap: () => _updateRating(category.title, rating),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withOpacity(isDark ? 0.3 : 0.15)
                        : (isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : AppColors.cxF5F7F9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? category.color
                          : (isDark
                              ? theme.colorScheme.outline.withOpacity(0.3)
                              : AppColors.cxPlatinumGray),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected
                        ? category.color
                        : (isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.cxSilverTint),
                    size: 24.sp,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations localizations, bool isDark, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitQualification,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.cxPurple.withOpacity(0.8)
              : AppColors.cxPurple,
          foregroundColor: AppColors.cxWhite,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 8,
          shadowColor: AppColors.cxPurple.withOpacity(0.4),
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    localizations.submit,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SkillCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? uuid;

  SkillCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.uuid,
  });
}
