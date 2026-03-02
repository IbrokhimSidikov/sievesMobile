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

  bool _areAllQuestionsAnswered() {
    if (_course == null) return false;
    
    for (var test in _course!.tests) {
      if (test.testType == 'single_choice') {
        // Check if this single choice question has an answer
        if (!_singleChoiceAnswers.containsKey(test.id) || _singleChoiceAnswers[test.id] == null) {
          return false;
        }
      } else if (test.testType == 'matching') {
        // Check if all pairs in this matching question are matched
        final userMatches = _matchingAnswers[test.id] ?? {};
        for (var pair in test.pairs) {
          if (!userMatches.containsKey(pair.id) || userMatches[pair.id] == null) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  Future<void> _submitTest() async {
    // Validate that all questions are answered
    if (!_areAllQuestionsAnswered()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).answerAllQuestions),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }
    
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).sessionNotStarted)),
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
            content: Text('${AppLocalizations.of(context).failedToSubmitTest}: ${e.toString().replaceAll('Exception: ', '')}'),
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
              child: Text(l10n.retry),
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
              l10n.noTestsAvailable,
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
                        '${l10n.question} ${_currentQuestionIndex + 1}/${_course!.tests.length}',
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
                        currentTest.testType == 'single_choice' ? l10n.multipleChoice : l10n.matching,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.progress,
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
    final l10n = AppLocalizations.of(context);
    if (!_matchingAnswers.containsKey(test.id)) {
      _matchingAnswers[test.id] = {};
    }
    if (!_shuffledPairs.containsKey(test.id)) {
      _shuffledPairs[test.id] = List.from(test.pairs)..shuffle();
    }

    final userMatches = _matchingAnswers[test.id]!;
    final shuffledPairs = _shuffledPairs[test.id]!;
    final matchedRightIds = userMatches.values.where((id) => id != null).toSet();
    final answeredCount = userMatches.values.where((id) => id != null).length;
    final totalCount = test.pairs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF6366F1).withOpacity(0.18), const Color(0xFF8B5CF6).withOpacity(0.1)]
                  : [AppColors.cxRoyalBlue.withOpacity(0.09), AppColors.cxRoyalBlue.withOpacity(0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6366F1).withOpacity(0.3)
                  : AppColors.cxRoyalBlue.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(9.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.25)
                      : AppColors.cxRoyalBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 20.r,
                  color: isDark ? const Color(0xFF818CF8) : AppColors.cxRoyalBlue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchEachItem,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      l10n.tapCardToChoose,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: answeredCount == totalCount
                      ? (isDark
                          ? const Color(0xFF34D399).withOpacity(0.2)
                          : AppColors.cxEmeraldGreen.withOpacity(0.12))
                      : (isDark
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : AppColors.cxRoyalBlue.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: answeredCount == totalCount
                        ? (isDark
                            ? const Color(0xFF34D399).withOpacity(0.5)
                            : AppColors.cxEmeraldGreen.withOpacity(0.4))
                        : (isDark
                            ? const Color(0xFF6366F1).withOpacity(0.4)
                            : AppColors.cxRoyalBlue.withOpacity(0.3)),
                  ),
                ),
                child: Text(
                  '$answeredCount/$totalCount',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: answeredCount == totalCount
                        ? (isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen)
                        : (isDark ? const Color(0xFF818CF8) : AppColors.cxRoyalBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Pair cards
        ...List.generate(test.pairs.length, (index) {
          final leftPair = test.pairs[index];
          final selectedMatchedPairId = userMatches[leftPair.id];
          final isMatched = selectedMatchedPairId != null;
          TestPair? matchedPair;
          if (isMatched) {
            try {
              matchedPair = shuffledPairs.firstWhere((p) => p.id == selectedMatchedPairId);
            } catch (_) {
              matchedPair = null;
            }
          }

          return _buildMatchingPairCard(
            test: test,
            leftPair: leftPair,
            matchedPair: matchedPair,
            index: index,
            shuffledPairs: shuffledPairs,
            matchedRightIds: matchedRightIds,
            userMatches: userMatches,
            isDark: isDark,
            l10n: l10n,
          );
        }),
      ],
    );
  }

  Widget _buildMatchingPairCard({
    required Test test,
    required TestPair leftPair,
    required TestPair? matchedPair,
    required int index,
    required List<TestPair> shuffledPairs,
    required Set<int?> matchedRightIds,
    required Map<int, int?> userMatches,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final isMatched = matchedPair != null;
    final accentColor = isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue;
    final greenColor = isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMatched
              ? greenColor.withOpacity(0.4)
              : (isDark
                  ? const Color(0xFF374151)
                  : AppColors.cxPlatinumGray.withOpacity(0.3)),
          width: isMatched ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isMatched
                ? greenColor.withOpacity(0.08)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left item (the prompt)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [accentColor.withOpacity(0.22), accentColor.withOpacity(0.12)]
                    : [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    leftPair.leftItem,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider with connector arrow
          Row(
            children: [
              SizedBox(width: 16.w),
              Container(
                width: 28.r,
                height: 1,
                color: isDark
                    ? const Color(0xFF374151)
                    : AppColors.cxPlatinumGray.withOpacity(0.4),
              ),
              SizedBox(width: 6.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.r,
                color: isDark
                    ? const Color(0xFF4B5563)
                    : AppColors.cxSilverTint,
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF374151)
                      : AppColors.cxPlatinumGray.withOpacity(0.4),
                ),
              ),
            ],
          ),

          // Answer selector button
          GestureDetector(
            onTap: () => _showMatchingBottomSheet(
              test: test,
              leftPair: leftPair,
              shuffledPairs: shuffledPairs,
              matchedRightIds: matchedRightIds,
              userMatches: userMatches,
              isDark: isDark,
              l10n: l10n,
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: isMatched
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: greenColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14.r,
                                  color: greenColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  matchedPair!.rightItem,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE8E8F0)
                                        : AppColors.cxDarkCharcoal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 18.r,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : AppColors.cxSilverTint,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.tapToSelectMatch,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF6B7280)
                                      : AppColors.cxSilverTint,
                                  fontSize: 14.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? greenColor.withOpacity(0.12)
                          : (isDark
                              ? const Color(0xFF252532)
                              : AppColors.cxF5F7F9),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isMatched
                            ? greenColor.withOpacity(0.3)
                            : (isDark
                                ? const Color(0xFF374151)
                                : AppColors.cxPlatinumGray.withOpacity(0.3)),
                      ),
                    ),
                    child: Icon(
                      isMatched ? Icons.edit_rounded : Icons.expand_more_rounded,
                      size: 18.r,
                      color: isMatched
                          ? greenColor
                          : (isDark
                              ? const Color(0xFF9CA3AF)
                              : AppColors.cxGraphiteGray),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchingBottomSheet({
    required Test test,
    required TestPair leftPair,
    required List<TestPair> shuffledPairs,
    required Set<int?> matchedRightIds,
    required Map<int, int?> userMatches,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentSelection = userMatches[leftPair.id];
          final accentColor = isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue;
          final greenColor = isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF374151)
                        : AppColors.cxPlatinumGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // Sheet header with the left item
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 14.r,
                                  color: accentColor,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  l10n.chooseAMatch,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentSelection != null) ...[  
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  userMatches[leftPair.id] = null;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.close_rounded,
                                      size: 13.r,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      l10n.clearMatch,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // The left item prompt
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [accentColor.withOpacity(0.2), accentColor.withOpacity(0.1)]
                                : [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: accentColor.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          leftPair.leftItem,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16.r,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : AppColors.cxSilverTint,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            l10n.selectCorrectMatch,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : AppColors.cxSilverTint,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF374151)
                      : AppColors.cxPlatinumGray.withOpacity(0.3),
                ),

                // Scrollable options list
                Flexible(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    itemCount: shuffledPairs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final rightPair = shuffledPairs[i];
                      final isSelected = currentSelection == rightPair.id;
                      final isMatchedToOther =
                          matchedRightIds.contains(rightPair.id) && !isSelected;

                      return GestureDetector(
                        onTap: isMatchedToOther
                            ? null
                            : () {
                                setState(() {
                                  userMatches[leftPair.id] =
                                      isSelected ? null : rightPair.id;
                                });
                                Navigator.pop(ctx);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? greenColor.withOpacity(0.12)
                                : isMatchedToOther
                                    ? (isDark
                                        ? const Color(0xFF1F2937)
                                        : AppColors.cxPlatinumGray.withOpacity(0.2))
                                    : (isDark
                                        ? const Color(0xFF252532)
                                        : AppColors.cxF5F7F9),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected
                                  ? greenColor.withOpacity(0.5)
                                  : isMatchedToOther
                                      ? (isDark
                                          ? const Color(0xFF374151)
                                          : AppColors.cxPlatinumGray.withOpacity(0.3))
                                      : Colors.transparent,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: greenColor.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32.r,
                                height: 32.r,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? greenColor
                                      : isMatchedToOther
                                          ? (isDark
                                              ? const Color(0xFF374151)
                                              : AppColors.cxPlatinumGray.withOpacity(0.4))
                                          : accentColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 18.r,
                                          color: Colors.white,
                                        )
                                      : isMatchedToOther
                                          ? Icon(
                                              Icons.block_rounded,
                                              size: 16.r,
                                              color: isDark
                                                  ? const Color(0xFF6B7280)
                                                  : AppColors.cxSilverTint,
                                            )
                                          : Text(
                                              String.fromCharCode(65 + i),
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  rightPair.rightItem,
                                  style: TextStyle(
                                    color: isMatchedToOther
                                        ? (isDark
                                            ? const Color(0xFF6B7280)
                                            : AppColors.cxSilverTint)
                                        : isSelected
                                            ? (isDark
                                                ? const Color(0xFFE8E8F0)
                                                : AppColors.cxDarkCharcoal)
                                            : (isDark
                                                ? const Color(0xFFD1D5DB)
                                                : AppColors.cxDarkCharcoal),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14.sp,
                                    height: 1.5,
                                    decoration: isMatchedToOther
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: isDark
                                        ? const Color(0xFF6B7280)
                                        : AppColors.cxSilverTint,
                                  ),
                                ),
                              ),
                              if (isMatchedToOther)
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF374151)
                                          : AppColors.cxPlatinumGray.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      l10n.used,
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF6B7280)
                                            : AppColors.cxSilverTint,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 12.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    final l10n = AppLocalizations.of(context);
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
                  l10n.previous,
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
                      isLastQuestion ? l10n.submitTest : l10n.next,
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
