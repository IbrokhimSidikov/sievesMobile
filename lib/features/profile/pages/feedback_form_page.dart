import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/api/api_service.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final AuthManager _authManager = AuthManager();
  late final ApiService _apiService;
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _submissionDetected = false;

  // ─── Google Form identifiers ──────────────────────────────────────────────
  static const String _formBaseUrl =
      'https://docs.google.com/forms/d/e/'
      '1FAIpQLSeQ-vcAimyrGVj_kyuesIav3PhyTlKGBllyBTxEzlEZsc4dqQ/viewform';
  static const String _fullNameEntryKey = 'entry.1974958285';

  // ─── Submission GET endpoint ─────────────────────────────────────────────
  static const String _submissionGetUrl =
      'https://app.sievesapp.com/v1/site/test';

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authManager.authService);
    _initWebView();
  }

  String _buildFormUrl() {
    final individual = _authManager.currentIdentity?.employee?.individual;
    final firstName = individual?.firstName ?? '';
    final lastName = individual?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final encoded = Uri.encodeComponent(fullName);
    return '$_formBaseUrl?usp=pp_url&$_fullNameEntryKey=$encoded';
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            _checkForSubmission(url);
          },
          onNavigationRequest: (request) {
            _checkForSubmission(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildFormUrl()));
  }

  /// Google Forms redirects to a URL containing "formResponse" after submission.
  void _checkForSubmission(String url) {
    if (!_submissionDetected && url.contains('formResponse')) {
      setState(() => _submissionDetected = true);
      _onFormSubmitted();
    }
  }

  Future<void> _onFormSubmitted() async {
    print('✅ [FeedbackForm] Submission detected');

    if (!mounted) return;

    // Show loading dialog immediately
    _showLoadingDialog();

    bool apiSuccess = false;

    // ── GET request to notify backend ───────────────────────────────────
    try {
      final employeeId = _authManager.currentEmployeeId;
      
      if (employeeId == null) {
        print('⚠️ [FeedbackForm] No employee ID, skipping notification');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSubmissionSuccessDialog();
        }
        return;
      }

      // Get current day session ID
      final daySession = await _apiService.getCurrentDaySession();
      if (daySession == null) {
        print('⚠️ [FeedbackForm] No day session found, skipping notification');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSubmissionSuccessDialog();
        }
        return;
      }

      final daySessionId = daySession['id'] as int?;
      if (daySessionId == null) {
        print('⚠️ [FeedbackForm] Day session has no ID, skipping notification');
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSubmissionSuccessDialog();
        }
        return;
      }

      // Build GET request URL with query parameters
      final uri = Uri.parse(_submissionGetUrl).replace(
        queryParameters: {
          'action': 'isFormClicked',
          'employee_id': employeeId.toString(),
          'day_session_id': daySessionId.toString(),
        },
      );

      print('📤 [FeedbackForm] Sending GET to $uri');

      final accessToken = await _authManager.authService.getAccessToken();
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📨 [FeedbackForm] Response status: ${response.statusCode}');
      print('📨 [FeedbackForm] Response body: ${response.body}');

      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        apiSuccess = true;
      } else {
        print('❌ [FeedbackForm] API returned error status: ${response.statusCode}');
        apiSuccess = false;
      }
    } catch (e) {
      print('⚠️ [FeedbackForm] GET request failed: $e');
      apiSuccess = false;
    }
    // ───────────────────────────────────────────────────────────────────

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (apiSuccess) {
        _showSubmissionSuccessDialog();
      } else {
        _showSubmissionErrorDialog();
      }
    }
  }

  void _showLoadingDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56.w,
                height: 56.h,
                child: CircularProgressIndicator(
                  color: AppColors.cx43C19F,
                  strokeWidth: 3.5,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                AppLocalizations.of(context).submitting,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmissionSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: AppColors.cx43C19F.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cx43C19F.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.cx43C19F,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                AppLocalizations.of(context).thankYou,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppLocalizations.of(context).feedbackSubmitted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : AppColors.cxBlack.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cx43C19F,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).done,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
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

  void _showSubmissionErrorDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                AppLocalizations.of(context).submissionError,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppLocalizations.of(context).submissionErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : AppColors.cxBlack.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark 
                              ? const Color(0xFFE8E8F0) 
                              : AppColors.cxBlack,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).close,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _onFormSubmitted();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context).tryAgain,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF12121A)
          : const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.sp,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Feedback',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: isDark ? const Color(0xFF12121A) : const Color(0xFFF5F5F8),
              child: _buildShimmerLoader(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F1F2E) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: 200.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: 150.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
