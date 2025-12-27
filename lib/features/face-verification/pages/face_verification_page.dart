import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sieves_mob/core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../break/widgets/face_capture_dialog.dart';
import '../services/work_entry_service.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/api/api_service.dart';

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
  File? _capturedPhoto;
  Map<String, dynamic>? _workEntryResponse;
  String? _currentEmployeeStatus;
  bool _isLoadingStatus = true;
  int? _selectedMood;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final WorkEntryService _workEntryService = WorkEntryService();
  final AuthManager _authManager = AuthManager();
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authManager.authService);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStatus();
      _openCameraDialog();
    });
  }
  
  Future<void> _loadCurrentStatus() async {
    final employeeId = _authManager.currentEmployeeId;
    if (employeeId != null) {
      final status = await _apiService.getCurrentEmployeeStatus(employeeId);
      if (mounted) {
        setState(() {
          _currentEmployeeStatus = status;
          _isLoadingStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openCameraDialog() async {
    final File? capturedImage = await showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FaceCaptureDialog(),
    );

    if (capturedImage != null) {
      _capturedPhoto = capturedImage;
      await _processWorkEntry(capturedImage);
    } else {
      setState(() {
        _statusMessage = AppLocalizations.of(context).cameraCancelled;
      });
    }
  }

  Future<void> _processWorkEntry(File capturedPhoto) async {
    // Check if this is a check-in action (employee is offline)
    final isOffline = _currentEmployeeStatus?.toLowerCase() != 'online';
    
    if (isOffline) {
      // Show mood selection dialog for check-in
      final mood = await _showMoodSelectionDialog();
      if (mood == null) {
        // User cancelled mood selection
        setState(() {
          _statusMessage = 'Check-in cancelled. Please select your mood.';
        });
        return;
      }
      _selectedMood = mood;
    }
    
    setState(() {
      _isVerifying = true;
      _isVerified = false;
      _verificationFailed = false;
      _statusMessage = 'Processing work entry...';
    });

    try {
      final result = await _workEntryService.performCompleteWorkEntry(
        capturedPhoto,
        mood: _selectedMood,
      );
      
      if (result != null && result['success'] == true) {
        // Identity has been refreshed in the service, get the updated data
        final identity = _authManager.currentIdentity;
        final employee = identity?.employee;
        
        // Reload current status from API to reflect the change
        await _loadCurrentStatus();
        
        setState(() {
          _isVerified = true;
          _isVerifying = false;
          _verificationFailed = false;
          _statusMessage = 'Work entry successful!';
          _employeeName = employee?.individual != null 
              ? '${employee!.individual!.firstName} ${employee.individual!.lastName}'
              : 'Employee';
          _employeePhoto = employee?.individual?.photoUrl;
          _workEntryResponse = result['data'];
        });
        
        print('🔄 Status updated - UI rebuilt with new status from API');
        
        // Show success dialog
        if (mounted) {
          _showSuccessDialog(result['data'], _currentEmployeeStatus);
        }
      } else {
        setState(() {
          _isVerified = false;
          _isVerifying = false;
          _verificationFailed = true;
          _statusMessage = result?['message'] ?? 'Work entry failed. Please try again.';
        });
        
        // Show beautiful error dialog based on error type
        if (mounted) {
          final errorType = result?['error_type'];
          if (errorType == 'face_verification_failed') {
            _showFaceVerificationErrorDialog(result?['message'] ?? 'Face verification failed');
          } else if (errorType == 'location_error') {
            _showLocationErrorDialog(result?['message'] ?? 'Location error');
          } else {
            _showGenericErrorDialog(result?['message'] ?? 'Work entry failed. Please try again.');
          }
        }
      }
    } catch (e) {
      print('❌ Error processing work entry: $e');
      setState(() {
        _isVerified = false;
        _isVerifying = false;
        _verificationFailed = true;
        _statusMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<int?> _showMoodSelectionDialog() async {
    int? selectedMood;
    
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cxPureWhite,
                      AppColors.cxEmeraldGreen.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_emotions,
                      size: 48.sp,
                      color: AppColors.cxEmeraldGreen,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      AppLocalizations.of(context).moodTitle,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cxBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context).moodSubTitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.cxBlack.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    Column(
                      children: [
                        _buildMoodOption(
                          context,
                          setDialogState,
                          selectedMood,
                          (value) => selectedMood = value,
                          20,
                          '😢',
                          AppLocalizations.of(context).bad,
                          Colors.red,
                        ),
                        SizedBox(height: 12.h),
                        _buildMoodOption(
                          context,
                          setDialogState,
                          selectedMood,
                          (value) => selectedMood = value,
                          40,
                          '😕',
                          AppLocalizations.of(context).mood40,
                          Colors.orange,
                        ),
                        SizedBox(height: 12.h),
                        _buildMoodOption(
                          context,
                          setDialogState,
                          selectedMood,
                          (value) => selectedMood = value,
                          60,
                          '😐',
                          AppLocalizations.of(context).mood60,
                          Colors.amber,
                        ),
                        SizedBox(height: 12.h),
                        _buildMoodOption(
                          context,
                          setDialogState,
                          selectedMood,
                          (value) => selectedMood = value,
                          80,
                          '😊',
                          AppLocalizations.of(context).mood80,
                          Colors.lightGreen,
                        ),
                        SizedBox(height: 12.h),
                        _buildMoodOption(
                          context,
                          setDialogState,
                          selectedMood,
                          (value) => selectedMood = value,
                          100,
                          '😄',
                          AppLocalizations.of(context).mood100,
                          Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedMood != null
                            ? () => Navigator.of(context).pop(selectedMood)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cxEmeraldGreen,
                          disabledBackgroundColor: AppColors.cxSilverTint,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context).continueText,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodOption(
    BuildContext context,
    StateSetter setDialogState,
    int? selectedMood,
    Function(int) onSelect,
    int value,
    String emoji,
    String label,
    Color color,
  ) {
    final isSelected = selectedMood == value;
    
    return InkWell(
      onTap: () {
        setDialogState(() {
          onSelect(value);
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.cxPureWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.cxSilverTint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: selectedMood,
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() {
                    onSelect(val);
                  });
                }
              },
              activeColor: color,
            ),
            SizedBox(width: 12.w),
            Text(
              emoji,
              style: TextStyle(fontSize: 32.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.cxBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic>? workEntryData, String? currentStatus) {
    final identity = _authManager.currentIdentity;
    final employee = identity?.employee;
    final employeeName = employee?.individual != null 
        ? '${employee!.individual!.firstName} ${employee.individual!.lastName}'
        : 'Employee';
    
    final entryType = workEntryData?['entry_type'] as String?;
    final timeLog = workEntryData?['time_log'] as String?;
    final isCheckOut = entryType?.toLowerCase() == 'stop';
    final newStatus = currentStatus?.toLowerCase() ?? 'unknown';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cxPureWhite,
                  isCheckOut 
                      ? AppColors.cxSilverTint.withOpacity(0.1)
                      : AppColors.cxEmeraldGreen.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isCheckOut 
                        ? AppColors.cxSilverTint.withOpacity(0.2)
                        : AppColors.cxEmeraldGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCheckOut ? Icons.logout : Icons.login,
                    size: 48.sp,
                    color: isCheckOut ? AppColors.cxSilverTint : AppColors.cxBlack,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).workEntrySuccess,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  employeeName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cxBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.cxSilverTint.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDialogInfoRow(
                        AppLocalizations.of(context).currentStatus,
                        newStatus.toUpperCase(),
                        Icons.circle,
                        newStatus == 'online' ? AppColors.cxEmeraldGreen : AppColors.cxSilverTint,
                      ),
                      if (timeLog != null) ...[
                        SizedBox(height: 12.h),
                        _buildDialogInfoRow(
                          AppLocalizations.of(context).time,
                          timeLog,
                          Icons.access_time,
                          AppColors.cxRoyalBlue,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          context.go('/home');
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cxRoyalBlue,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      AppLocalizations.of(context).returnHome,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cxPureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFaceVerificationErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cxPureWhite,
                  Colors.red.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.face_retouching_off,
                    size: 48.sp,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).workEntryFail,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxBlack.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppColors.cxSilverTint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cxBlack,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetVerification();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context).tryAgain,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cxPureWhite,
                  Colors.orange.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off,
                    size: 48.sp,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).locationError,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxBlack.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppColors.cxSilverTint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cxBlack,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetVerification();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context).tryAgain,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGenericErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cxPureWhite,
                  AppColors.cxSilverTint.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.cxSilverTint.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: AppColors.cxBlack,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).error,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxBlack.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppColors.cxSilverTint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cxBlack,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetVerification();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cxRoyalBlue,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context).tryAgain,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: color),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.cxBlack.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.cxBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resetVerification() {
    setState(() {
      _isVerifying = false;
      _isVerified = false;
      _verificationFailed = false;
      _statusMessage = AppLocalizations.of(context).subTitle2;
      _employeeName = null;
      _employeePhoto = null;
      _capturedPhoto = null;
      _workEntryResponse = null;
    });
    _openCameraDialog();
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
    // Use real-time status from API, fallback to cached status if still loading
    final status = (_currentEmployeeStatus ?? _authManager.currentEmployeeStatus)?.toLowerCase() ?? 'offline';
    final isOnline = status == 'online';
    
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
      child: Column(
        children: [
          Row(
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
                      AppLocalizations.of(context).faceVerification,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cxPureWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppLocalizations.of(context).workEntryDevice,
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
                  color: isOnline ? AppColors.cxEmeraldGreen : AppColors.cxSilverTint,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.cxEmeraldGreen : AppColors.cxSilverTint).withOpacity(0.3),
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
                      isOnline ? 'ONLINE' : 'OFFLINE',
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
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.cxPureWhite.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxPureWhite.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOnline ? Icons.logout : Icons.login,
                  color: AppColors.cxPureWhite,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  isOnline ? AppLocalizations.of(context).nextAction : AppLocalizations.of(context).nextAction2,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
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
                  if (_capturedPhoto != null)
                    Image.file(
                      _capturedPhoto!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
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
                    ? AppLocalizations.of(context).analysing
                    : _isVerified
                        ? AppLocalizations.of(context).faceDetected
                        : AppLocalizations.of(context).detectionFail,
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
                  AppLocalizations.of(context).employeeVerified,
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
                      '${AppLocalizations.of(context).verifiedAt} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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
              label: AppLocalizations.of(context).newVerification,
              icon: Icons.refresh,
              color: AppColors.cxRoyalBlue,
              onPressed: _resetVerification,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildButton(
              label: AppLocalizations.of(context).returnHome,
              icon:Icons.arrow_back_ios_new_rounded,
              color: AppColors.cxEmeraldGreen,
              onPressed:() => context.go('/home'),
            ),
          ),
        ],
      );
    }

    if (_verificationFailed) {
      return _buildButton(
        label: AppLocalizations.of(context).tryAgain,
        icon: Icons.refresh,
        color: AppColors.cxRoyalBlue,
        onPressed: _resetVerification,
      );
    }

    return _buildButton(
      label: _isVerifying ? AppLocalizations.of(context).processing : AppLocalizations.of(context).captureFace,
      icon: Icons.camera_alt,
      color: AppColors.cxRoyalBlue,
      onPressed: _isVerifying ? null : _openCameraDialog,
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
