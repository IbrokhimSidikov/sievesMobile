import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/test_result_model.dart';

class TestResultPage extends StatefulWidget {
  final int sessionId;

  const TestResultPage({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage> with SingleTickerProviderStateMixin {
  final _authManager = AuthManager();
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  TestSessionResult? _result;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _loadResult();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadResult() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _authManager.apiService.fetchSessionResult(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _animationController.forward();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.cxF5F7F9,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading(isDark)
            : _hasError
                ? _buildError(isDark)
                : _buildResultContent(isDark),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading results...',
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.r,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Results',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadResult,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(bool isDark) {
    final result = _result!;
    final scoreValue = double.parse(result.scorePercentage);
    final isPassed = result.status == 'passed';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280.h,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildScoreHeader(isDark, scoreValue, isPassed),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(isDark, result),
                SizedBox(height: 24.h),
                _buildResultsList(isDark, result),
                SizedBox(height: 24.h),
                _buildActionButtons(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHeader(bool isDark, double score, bool isPassed) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPassed
                ? [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ]
                : [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 8.w,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Icon(
              isPassed ? Icons.check_circle : Icons.cancel,
              size: 48.r,
              color: Colors.white,
            ),
            SizedBox(height: 8.h),
            Text(
              isPassed ? 'Congratulations!' : 'Keep Trying!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isPassed ? 'You passed the test!' : 'You need ${_result!.passingScore}% to pass',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, TestSessionResult result) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.quiz,
            label: 'Total Questions',
            value: '${result.totalQuestions}',
            color: const Color(0xFF6366F1),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.check_circle,
            label: 'Correct',
            value: '${result.correctMatches}',
            color: const Color(0xFF10B981),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.cancel,
            label: 'Wrong',
            value: '${result.totalMatches - result.correctMatches}',
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isDark, TestSessionResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Results',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 16.h),
        ...result.results.asMap().entries.map((entry) {
          final index = entry.key;
          final detail = entry.value;
          return _buildResultItem(isDark, detail, index + 1);
        }).toList(),
      ],
    );
  }

  Widget _buildResultItem(bool isDark, TestResultDetail detail, int questionNumber) {
    final isCorrect = detail.isCorrect;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16.r,
                      color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isCorrect ? 'Correct' : 'Wrong',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : AppColors.cxRoyalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            detail.test.question,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 12.h),
          if (detail.test.testType == 'matching' && detail.pair != null)
            _buildMatchingAnswer(isDark, detail)
          else if (detail.test.testType == 'single_choice' && detail.option != null)
            _buildSingleChoiceAnswer(isDark, detail),
        ],
      ),
    );
  }

  Widget _buildMatchingAnswer(bool isDark, TestResultDetail detail) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252532)
            : AppColors.cxF5F7F9,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.1)]
                          : [AppColors.cxRoyalBlue.withOpacity(0.1), AppColors.cxRoyalBlue.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    detail.pair!.leftItem,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20.r,
                  color: detail.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: detail.isCorrect
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: detail.isCorrect
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    detail.matchedPair!.rightItem,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!detail.isCorrect) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16.r,
                    color: const Color(0xFF10B981),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Correct: ${detail.pair!.rightItem}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleChoiceAnswer(bool isDark, TestResultDetail detail) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: detail.isCorrect
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: detail.isCorrect
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            detail.isCorrect ? Icons.check_circle : Icons.cancel,
            size: 20.r,
            color: detail.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              detail.option!.text,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              backgroundColor: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Back to Courses',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
