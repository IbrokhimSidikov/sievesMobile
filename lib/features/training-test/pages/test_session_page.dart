import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/test_models.dart';
import 'test_result_page.dart';

class TestSessionPage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const TestSessionPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TestSessionPage> createState() => _TestSessionPageState();
}

class _TestSessionPageState extends State<TestSessionPage> {
  final _authManager = AuthManager();
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  CourseWithTests? _course;
  int? _sessionId;
  
  int _currentQuestionIndex = 0;
  Map<int, int?> _singleChoiceAnswers = {}; // testId -> optionId
  Map<int, Map<int, int?>> _matchingAnswers = {}; // testId -> {leftPairId -> matchedRightPairId}
  Map<int, List<TestPair>> _shuffledPairs = {}; // testId -> shuffled pairs for dropdown
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _loadCourseWithTests();
  }

  Future<void> _loadCourseWithTests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Fetch course details
      final course = await _authManager.apiService.fetchCourseWithTests(widget.courseId);
      
      // Start session
      final sessionId = await _authManager.apiService.startTrainingSession(widget.courseId);
      
      if (mounted) {
        setState(() {
          _course = course;
          _sessionId = sessionId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _nextQuestion() {
    if (_course != null && _currentQuestionIndex < _course!.tests.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitTest() async {
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session not started. Please try again.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare match answers
      List<Map<String, dynamic>> matchAnswers = [];
      for (var test in _course!.tests) {
        if (test.testType == 'matching') {
          final userMatches = _matchingAnswers[test.id] ?? {};
          for (var entry in userMatches.entries) {
            final leftPairId = entry.key;
            final matchedRightPairId = entry.value;
            
            if (matchedRightPairId != null) {
              matchAnswers.add({
                'test_id': test.id,
                'pair_id': leftPairId,
                'matched_pair_id': matchedRightPairId,
              });
            }
          }
        }
      }

      // Prepare option answers
      List<Map<String, dynamic>> optionAnswers = [];
      for (var test in _course!.tests) {
        if (test.testType == 'single_choice') {
          final selectedOptionId = _singleChoiceAnswers[test.id];
          if (selectedOptionId != null) {
            optionAnswers.add({
              'test_id': test.id,
              'option_id': selectedOptionId,
            });
          }
        }
      }

      // Submit to API
      final result = await _authManager.apiService.submitTrainingSession(
        sessionId: _sessionId!,
        matchAnswers: matchAnswers,
        optionAnswers: optionAnswers,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Navigate to result page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TestResultPage(sessionId: _sessionId!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit test: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.cxF5F7F9,
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: TextStyle(
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState(l10n)
              : _course == null || _course!.tests.isEmpty
                  ? _buildEmptyState(l10n)
                  : _buildTestContent(l10n, isDark, colorScheme),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF252532) : Colors.grey[100]!,
      child: Column(
        children: [
          // Progress bar shimmer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    Container(
                      width: 40.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          
          // Question content shimmer
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question badges
                  Row(
                    children: [
                      Container(
                        width: 120.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 100.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  
                  // Question text
                  Container(
                    width: double.infinity,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: 250.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Answer options shimmer
                  ...List.generate(4, (index) => Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Container(
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          // Navigation buttons shimmer
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.r, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadCourseWithTests,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64.r, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'No tests available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestContent(AppLocalizations l10n, bool isDark, ColorScheme colorScheme) {
    final currentTest = _course!.tests[_currentQuestionIndex];
    
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(isDark),
        
        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number and type
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF6366F1).withOpacity(0.3), const Color(0xFF8B5CF6).withOpacity(0.2)]
                              : [AppColors.cxRoyalBlue.withOpacity(0.2), AppColors.cxRoyalBlue.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Question ${_currentQuestionIndex + 1}/${_course!.tests.length}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A24)
                            : AppColors.cxPlatinumGray.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        currentTest.testType == 'single_choice' ? 'Multiple Choice' : 'Matching',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFD1D5DB) : AppColors.cxGraphiteGray,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                
                // Question text
                Text(
                  currentTest.question,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Question type specific widget
                if (currentTest.testType == 'single_choice')
                  _buildSingleChoiceQuestion(currentTest, isDark)
                else if (currentTest.testType == 'matching')
                  _buildMatchingQuestion(currentTest, isDark),
              ],
            ),
          ),
        ),
        
        // Navigation buttons
        _buildNavigationButtons(isDark),
      ],
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    final progress = (_currentQuestionIndex + 1) / _course!.tests.length;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: isDark ? const Color(0xFFD1D5DB) : AppColors.cxGraphiteGray,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                '${(_currentQuestionIndex + 1)}/${_course!.tests.length}',
                style: TextStyle(
                  color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? const Color(0xFF252532)
                  : AppColors.cxPlatinumGray.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
              ),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChoiceQuestion(Test test, bool isDark) {
    return Column(
      children: test.options.map((option) {
        final isSelected = _singleChoiceAnswers[test.id] == option.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _singleChoiceAnswers[test.id] = option.id;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF6366F1).withOpacity(0.2) : AppColors.cxRoyalBlue.withOpacity(0.1))
                  : (isDark ? const Color(0xFF1A1A24) : Colors.white),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue)
                    : (isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue)
                          : (isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16.r, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchingQuestion(Test test, bool isDark) {
    // Initialize matching answers for this test if not exists
    if (!_matchingAnswers.containsKey(test.id)) {
      _matchingAnswers[test.id] = {};
    }
    
    // Initialize and shuffle pairs only once per test
    if (!_shuffledPairs.containsKey(test.id)) {
      _shuffledPairs[test.id] = List.from(test.pairs)..shuffle();
    }
    
    final userMatches = _matchingAnswers[test.id]!;
    final shuffledPairs = _shuffledPairs[test.id]!;
    
    return Column(
      children: [
        Text(
          'Match the items on the left with the correct items on the right',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 16.h),
        ...test.pairs.map((leftPair) {
          final selectedMatchedPairId = userMatches[leftPair.id];
          
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left item
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.1)]
                          : [AppColors.cxRoyalBlue.withOpacity(0.1), AppColors.cxRoyalBlue.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 16.r,
                        color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          leftPair.leftItem,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Dropdown for right item
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: selectedMatchedPairId != null
                          ? (isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen)
                          : (isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3)),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedMatchedPairId,
                      hint: Text(
                        'Select match',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
                        ),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
                      ),
                      items: shuffledPairs.map((rightPair) {
                        return DropdownMenuItem<int>(
                          value: rightPair.id,
                          child: Text(
                            rightPair.rightItem,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (pairId) {
                        setState(() {
                          userMatches[leftPair.id] = pairId;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    final isLastQuestion = _currentQuestionIndex == _course!.tests.length - 1;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                  ),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (isLastQuestion ? _submitTest : _nextQuestion),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLastQuestion ? 'Submit Test' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
