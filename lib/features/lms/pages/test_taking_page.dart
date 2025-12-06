import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/question_type.dart';
import '../models/test.dart';
import '../models/question.dart';
import '../models/test_answer.dart';
import '../models/test_session.dart';

class TestTakingPage extends StatefulWidget {
  final Test test;

  const TestTakingPage({super.key, required this.test});

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage> {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  Map<String, TestAnswer> _answers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  int? _sessionId;
  bool _isStartingSession = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _remainingSeconds = widget.test.duration * 60;
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final authManager = AuthManager();
      final accessToken = await authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ No access token available');
        setState(() => _isStartingSession = false);
        _startTimer();
        return;
      }
      
      print('📡 Starting test session for course ID: ${widget.test.id}');
      
      final response = await http.post(
        Uri.parse('https://api.v3.sievesapp.com/course/session/start'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'course_id': int.parse(widget.test.id),
        }),
      );
      
      print('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final sessionData = json.decode(response.body);
        final session = TestSession.fromJson(sessionData);
        
        setState(() {
          _sessionId = session.id;
          _isStartingSession = false;
        });
        
        print('✅ Session started successfully');
        print('   Session ID: ${session.id}');
        
        _startTimer();
      } else {
        print('❌ Failed to start session: ${response.statusCode}');
        print('   Response: ${response.body}');
        
        setState(() => _isStartingSession = false);
        _startTimer();
      }
    } catch (e) {
      print('❌ Error starting session: $e');
      setState(() => _isStartingSession = false);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  void _selectAnswer(String questionId, String optionId, bool isMultiSelect) {
    setState(() {
      if (isMultiSelect) {
        final currentAnswer = _answers[questionId];
        if (currentAnswer != null) {
          final selectedIds = List<String>.from(currentAnswer.selectedOptionIds);
          if (selectedIds.contains(optionId)) {
            selectedIds.remove(optionId);
          } else {
            selectedIds.add(optionId);
          }
          _answers[questionId] = TestAnswer(
            questionId: questionId,
            selectedOptionIds: selectedIds,
          );
        } else {
          _answers[questionId] = TestAnswer(
            questionId: questionId,
            selectedOptionIds: [optionId],
          );
        }
      } else {
        _answers[questionId] = TestAnswer(
          questionId: questionId,
          selectedOptionIds: [optionId],
        );
      }
    });
  }

  void _goToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) return;

    final unansweredCount = widget.test.questions!.length - _answers.length;
    
    if (unansweredCount > 0) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Test?'),
          content: Text(
            'You have $unansweredCount unanswered question${unansweredCount > 1 ? 's' : ''}. Do you want to submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_sessionId != null) {
        await _submitToAPI();
      } else {
        await _submitLocally();
      }
    } catch (e) {
      print('❌ Error in submit flow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit test. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitToAPI() async {
    try {
      final authManager = AuthManager();
      final accessToken = await authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ No access token available');
        await _submitLocally();
        return;
      }
      
      print('📡 Submitting test answers to API...');
      print('   Session ID: $_sessionId');
      
      final answers = <TestSessionAnswer>[];
      for (var question in widget.test.questions!) {
        final answer = _answers[question.id];
        if (answer != null && answer.selectedOptionIds.isNotEmpty) {
          answers.add(TestSessionAnswer(
            testId: int.parse(question.id),
            selectedOptionId: int.parse(answer.selectedOptionIds.first),
          ));
        }
      }
      
      print('   Submitting ${answers.length} answers');
      
      final response = await http.post(
        Uri.parse('https://api.v3.sievesapp.com/course/session/submit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'session_id': _sessionId,
          'answers': answers.map((a) => a.toJson()).toList(),
        }),
      );
      
      print('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resultData = json.decode(response.body);
        print('✅ Test submitted successfully');
        print('   Result: $resultData');
        
        if (mounted) {
          context.pushReplacement('/testResult', extra: {
            'test': widget.test,
            'sessionId': _sessionId,
            'sessionData': resultData,
            'answers': _answers,
            'timeTaken': widget.test.duration * 60 - _remainingSeconds,
          });
        }
      } else {
        print('❌ Failed to submit test: ${response.statusCode}');
        print('   Response: ${response.body}');
        await _submitLocally();
      }
    } catch (e) {
      print('❌ Error submitting test: $e');
      await _submitLocally();
    }
  }

  Future<void> _submitLocally() async {
    int correctAnswers = 0;
    final questions = widget.test.questions!;

    for (var question in questions) {
      final answer = _answers[question.id];
      if (answer != null) {
        final correctOptionIds = question.options
            .where((opt) => opt.isCorrect)
            .map((opt) => opt.id)
            .toSet();
        final selectedIds = answer.selectedOptionIds.toSet();

        if (correctOptionIds.length == selectedIds.length &&
            correctOptionIds.containsAll(selectedIds)) {
          correctAnswers++;
        }
      }
    }

    final score = (correctAnswers / questions.length * 100).round();

    if (mounted) {
      context.pushReplacement('/testResult', extra: {
        'test': widget.test,
        'score': score,
        'answers': _answers,
        'timeTaken': widget.test.duration * 60 - _remainingSeconds,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.test.questions == null || widget.test.questions!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No questions available'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text('Your progress will be lost. Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cxCrimsonRed,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).colorScheme.surface,
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
                _buildHeader(),
                _buildProgressBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: widget.test.questions!.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(widget.test.questions![index]);
                    },
                  ),
                ),
                _buildNavigationBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isLowTime = _remainingSeconds < 300; // Less than 5 minutes

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: AppColors.cxRoyalBlue,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.test.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${widget.test.questions!.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isLowTime ? AppColors.cxCrimsonRed.withOpacity(0.1) : AppColors.cxRoyalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isLowTime ? AppColors.cxCrimsonRed : AppColors.cxRoyalBlue,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isLowTime ? AppColors.cxCrimsonRed : AppColors.cxRoyalBlue,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isLowTime ? AppColors.cxCrimsonRed : AppColors.cxRoyalBlue,
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

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    final answeredCount = _answers.length;
    final totalQuestions = widget.test.questions!.length;
    final progress = answeredCount / totalQuestions;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$answeredCount / $totalQuestions answered',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cxRoyalBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxRoyalBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final theme = Theme.of(context);
    final answer = _answers[question.id];
    final isMultiSelect = question.type == QuestionType.multiSelect;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Q${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (isMultiSelect)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.cxWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.cxWarning,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Multiple Select',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cxWarning,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              question.text,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            ...question.options.map((option) {
              final isSelected = answer?.selectedOptionIds.contains(option.id) ?? false;
              
              return GestureDetector(
                onTap: () => _selectAnswer(question.id, option.id, isMultiSelect),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.cxRoyalBlue.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.cxRoyalBlue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          shape: isMultiSelect ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: isMultiSelect ? BorderRadius.circular(6.r) : null,
                          color: isSelected
                              ? AppColors.cxRoyalBlue
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cxRoyalBlue
                                : AppColors.cxSilverTint,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16.sp,
                              )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final theme = Theme.of(context);
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == widget.test.questions!.length - 1;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Question grid button
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: IconButton(
                onPressed: () => _showQuestionGrid(),
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Previous button
            if (!isFirstQuestion)
              Expanded(
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _goToQuestion(_currentQuestionIndex - 1),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Center(
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!isFirstQuestion) SizedBox(width: 12.w),
            // Next/Submit button
            Expanded(
              flex: isFirstQuestion ? 1 : 1,
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLastQuestion
                        ? [AppColors.cxEmeraldGreen, AppColors.cxEmeraldGreen]
                        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isLastQuestion ? AppColors.cxEmeraldGreen : const Color(0xFF6366F1))
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting
                        ? null
                        : (isLastQuestion
                            ? _submitTest
                            : () => _goToQuestion(_currentQuestionIndex + 1)),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Center(
                      child: _isSubmitting && isLastQuestion
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Submitting...',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastQuestion ? 'Submit Test' : 'Next',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  isLastQuestion ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
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
      ),
    );
  }

  void _showQuestionGrid() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.cxSilverTint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Questions',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                  ),
                  itemCount: widget.test.questions!.length,
                  itemBuilder: (context, index) {
                    final question = widget.test.questions![index];
                    final isAnswered = _answers.containsKey(question.id);
                    final isCurrent = index == _currentQuestionIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _goToQuestion(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.cxRoyalBlue
                              : isAnswered
                                  ? AppColors.cxEmeraldGreen.withOpacity(0.1)
                                  : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.cxRoyalBlue
                                : isAnswered
                                    ? AppColors.cxEmeraldGreen
                                    : Colors.transparent,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                      ? AppColors.cxEmeraldGreen
                                      : AppColors.cxSilverTint,
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
      },
    );
  }
}
