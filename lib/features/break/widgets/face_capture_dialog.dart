import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';

class FaceCaptureDialog extends StatefulWidget {
  const FaceCaptureDialog({super.key});

  @override
  State<FaceCaptureDialog> createState() => _FaceCaptureDialogState();
}

class _FaceCaptureDialogState extends State<FaceCaptureDialog> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  File? _capturedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('📷 [FACE CAPTURE] Initializing camera...');
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      // Find front camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Use front camera if available, otherwise use first camera
      final selectedCamera = frontCamera ?? _cameras!.first;
      print('📷 [FACE CAPTURE] Using camera: ${selectedCamera.name} (${selectedCamera.lensDirection})');

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        print('✅ [FACE CAPTURE] Camera initialized successfully');
      }
    } catch (e) {
      print('❌ [FACE CAPTURE] Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      print('📸 [FACE CAPTURE] Taking picture...');
      final XFile photo = await _cameraController!.takePicture();
      
      // Save to a permanent location
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/face_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedFile = await File(photo.path).copy(filePath);
      
      print('✅ [FACE CAPTURE] Picture saved to: $filePath');
      print('   Size: ${await savedFile.length()} bytes');

      if (mounted) {
        setState(() {
          _capturedImage = savedFile;
          _isCapturing = false;
        });
      }
    } catch (e) {
      print('❌ [FACE CAPTURE] Error capturing image: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                          : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.face_rounded,
                    color: AppColors.cxWhite,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Face Verification',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Instruction text
            Text(
              _capturedImage != null 
                  ? 'Review your photo and confirm'
                  : 'Position your face in the frame',
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            
            // Camera preview or captured image
            Container(
              height: 350.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: _buildCameraContent(theme, isDark),
              ),
            ),
            SizedBox(height: 20.h),
            
            // Action buttons
            _buildActionButtons(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraContent(ThemeData theme, bool isDark) {
    // Show error state
    if (_errorMessage != null) {
      return Container(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64.sp,
                color: Colors.red,
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show captured image
    if (_capturedImage != null) {
      return Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
      );
    }

    // Show loading state
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
              ),
              SizedBox(height: 16.h),
              Text(
                'Initializing camera...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.cxWhite,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show camera preview with face guide overlay
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview with proper aspect ratio and mirror effect for front camera
        Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(1.0, 3.0), // Mirror horizontally for front camera
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        
        // Face guide overlay
        // CustomPaint(
        //   painter: FaceGuidePainter(
        //     color: isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3),
        //   ),
        // ),
        
        // Capture indicator when capturing
        if (_isCapturing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    // If image is captured, show Retake and Confirm buttons
    if (_capturedImage != null) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _retakePhoto,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Retake',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_capturedImage),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.cxWhite,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cxWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show capture button
    return GestureDetector(
      onTap: (_isCameraInitialized && !_isCapturing) ? _captureImage : null,
      child: Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [const Color(0xFF0071E3), const Color(0xFF5E5CE6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF0071E3))
                  .withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cxWhite,
              width: 3,
            ),
          ),
          child: _isCapturing
              ? Center(
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
                    ),
                  ),
                )
              : Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.cxWhite,
                  size: 28.sp,
                ),
        ),
      ),
    );
  }
}

// Custom painter for face guide overlay
class FaceGuidePainter extends CustomPainter {
  final Color color;

  FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw oval face guide
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 20;
    final ovalWidth = size.width * 0.6;
    final ovalHeight = size.height * 0.5;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw corner markers instead of full oval for cleaner look
    final cornerLength = 30.0;
    
    // Top left corner
    canvas.drawLine(
      Offset(centerX - ovalWidth / 2, centerY - ovalHeight / 2 + cornerLength),
      Offset(centerX - ovalWidth / 2, centerY - ovalHeight / 2),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ovalWidth,
        height: ovalHeight,
      ),
      -2.5,
      0.5,
      false,
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(centerX + ovalWidth / 2, centerY - ovalHeight / 2 + cornerLength),
      Offset(centerX + ovalWidth / 2, centerY - ovalHeight / 2),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ovalWidth,
        height: ovalHeight,
      ),
      -0.6,
      0.5,
      false,
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(centerX - ovalWidth / 2, centerY + ovalHeight / 2 - cornerLength),
      Offset(centerX - ovalWidth / 2, centerY + ovalHeight / 2),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ovalWidth,
        height: ovalHeight,
      ),
      2.5,
      0.5,
      false,
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(centerX + ovalWidth / 2, centerY + ovalHeight / 2 - cornerLength),
      Offset(centerX + ovalWidth / 2, centerY + ovalHeight / 2),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ovalWidth,
        height: ovalHeight,
      ),
      0.6,
      0.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
