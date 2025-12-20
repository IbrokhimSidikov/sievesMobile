import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage>
    with SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _verificationFailed = false;
  String _statusMessage = 'Position your face in the frame';
  String? _employeeName;
  String? _employeePhoto;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    setState(() {
      _isVerifying = true;
      _isVerified = false;
      _verificationFailed = false;
      _statusMessage = 'Verifying face...';
    });

    // TODO: Implement actual face verification API call
    await Future.delayed(const Duration(seconds: 2));

    // Simulated response - replace with actual API call
    final bool success = DateTime.now().second % 2 == 0;

    if (success) {
      setState(() {
        _isVerified = true;
        _isVerifying = false;
        _verificationFailed = false;
        _statusMessage = 'Verification successful!';
        _employeeName = 'John Doe';
        _employeePhoto = null; // Set from API response
      });
    } else {
      setState(() {
        _isVerified = false;
        _isVerifying = false;
        _verificationFailed = true;
        _statusMessage = 'Verification failed. Please try again.';
      });
    }
  }

  void _resetVerification() {
    setState(() {
      _isVerifying = false;
      _isVerified = false;
      _verificationFailed = false;
      _statusMessage = 'Position your face in the frame';
      _employeeName = null;
      _employeePhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cxRoyalBlue.withOpacity(0.1),
              AppColors.cxPureWhite,
              AppColors.cxEmeraldGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      _buildCameraPreview(),
                      SizedBox(height: 32.h),
                      _buildStatusCard(),
                      SizedBox(height: 24.h),
                      if (_isVerified) _buildEmployeeInfo(),
                      if (_isVerified) SizedBox(height: 24.h),
                      _buildActionButton(),
                      SizedBox(height: 40.h),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxRoyalBlue,
            AppColors.cxRoyalBlue.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxRoyalBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.cxPureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.face_retouching_natural,
              color: AppColors.cxPureWhite,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Verification',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxPureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Work Entry Device',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxPureWhite.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.cxEmeraldGreen,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: AppColors.cxPureWhite,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxPureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isVerifying ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 320.w,
            height: 400.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isVerified
                    ? [
                        AppColors.cxEmeraldGreen.withOpacity(0.2),
                        AppColors.cxEmeraldGreen.withOpacity(0.1),
                      ]
                    : _verificationFailed
                        ? [
                            AppColors.cxCrimsonRed.withOpacity(0.2),
                            AppColors.cxCrimsonRed.withOpacity(0.1),
                          ]
                        : [
                            AppColors.cxRoyalBlue.withOpacity(0.1),
                            AppColors.cxPlatinumGray.withOpacity(0.3),
                          ],
              ),
              border: Border.all(
                color: _isVerified
                    ? AppColors.cxEmeraldGreen
                    : _verificationFailed
                        ? AppColors.cxCrimsonRed
                        : AppColors.cxRoyalBlue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isVerified
                          ? AppColors.cxEmeraldGreen
                          : _verificationFailed
                              ? AppColors.cxCrimsonRed
                              : AppColors.cxRoyalBlue)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: Stack(
                children: [
                  // Camera preview placeholder
                  Container(
                    color: AppColors.cxGraphiteGray.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.videocam,
                        size: 80.sp,
                        color: AppColors.cxSilverTint.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // Face detection overlay
                  _buildFaceOverlay(),
                  // Status indicator
                  if (_isVerifying || _isVerified || _verificationFailed)
                    _buildStatusOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: 240.w,
        height: 300.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(120.r),
          border: Border.all(
            color: AppColors.cxPureWhite.withOpacity(0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: CustomPaint(
          painter: _FaceGuidePainter(
            color: _isVerified
                ? AppColors.cxEmeraldGreen
                : _verificationFailed
                    ? AppColors.cxCrimsonRed
                    : AppColors.cxRoyalBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.cxDarkCharcoal.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.cxBlack.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isVerifying)
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.cxRoyalBlue,
                  ),
                ),
              ),
            if (_isVerified)
              Icon(
                Icons.check_circle,
                color: AppColors.cxEmeraldGreen,
                size: 24.sp,
              ),
            if (_verificationFailed)
              Icon(
                Icons.error,
                color: AppColors.cxCrimsonRed,
                size: 24.sp,
              ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                _isVerifying
                    ? 'Analyzing...'
                    : _isVerified
                        ? 'Face Detected'
                        : 'Detection Failed',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cxPureWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxPureWhite,
            AppColors.cxSoftWhite,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _isVerified
                ? Icons.check_circle_outline
                : _verificationFailed
                    ? Icons.error_outline
                    : Icons.face,
            size: 48.sp,
            color: _isVerified
                ? AppColors.cxEmeraldGreen
                : _verificationFailed
                    ? AppColors.cxCrimsonRed
                    : AppColors.cxRoyalBlue,
          ),
          SizedBox(height: 16.h),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.cxDarkCharcoal,
            ),
          ),
          if (_isVerifying) ...[
            SizedBox(height: 16.h),
            LinearProgressIndicator(
              backgroundColor: AppColors.cxPlatinumGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.cxRoyalBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxEmeraldGreen.withOpacity(0.1),
            AppColors.cxEmeraldGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.cxEmeraldGreen.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cxEmeraldGreen,
                  AppColors.cxEmeraldGreen.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _employeePhoto != null
                ? ClipOval(
                    child: Image.network(
                      _employeePhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: AppColors.cxPureWhite,
                          size: 32.sp,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: AppColors.cxPureWhite,
                    size: 32.sp,
                  ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Verified',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.cxEmeraldGreen,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _employeeName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14.sp,
                      color: AppColors.cxSilverTint,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Verified at ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.cxSilverTint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.cxEmeraldGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: AppColors.cxPureWhite,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isVerified) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              label: 'New Verification',
              icon: Icons.refresh,
              color: AppColors.cxRoyalBlue,
              onPressed: _resetVerification,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildButton(
              label: 'View Details',
              icon: Icons.info_outline,
              color: AppColors.cxEmeraldGreen,
              onPressed: () {
                // TODO: Navigate to employee details
              },
            ),
          ),
        ],
      );
    }

    if (_verificationFailed) {
      return _buildButton(
        label: 'Try Again',
        icon: Icons.refresh,
        color: AppColors.cxRoyalBlue,
        onPressed: _resetVerification,
      );
    }

    return _buildButton(
      label: _isVerifying ? 'Verifying...' : 'Start Verification',
      icon: Icons.face_retouching_natural,
      color: AppColors.cxRoyalBlue,
      onPressed: _isVerifying ? null : _startVerification,
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onPressed == null
              ? [
                  AppColors.cxSilverTint,
                  AppColors.cxSilverTint.withOpacity(0.7),
                ]
              : [
                  color,
                  color.withOpacity(0.8),
                ],
        ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.cxPureWhite,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxPureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final Color color;

  _FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;

    // Top-left corner
    canvas.drawLine(
      Offset(0, cornerLength),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
