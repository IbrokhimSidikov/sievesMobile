import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthManager _authManager = AuthManager();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // For testing UI - use static data
      await Future.delayed(Duration(seconds: 1)); // Simulate API delay
      
      final testData = {
        'id': 1748,
        'status': 'active',
        'individual': {
          'id': 2156,
          'firstName': 'Ibrokhim',
          'lastName': 'Sidikov',
          'email': '2281@sieves.uz',
          'phone': '+998 77 8783454',
          'photo': 'https://s.gravatar.com/avatar/da49ff38e3736fecdd6f56dd29b828dd?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fis.png'
        },
        'branch': {
          'id': 1,
          'name': 'Administration',
          'address': 'Uqchi Street 3A'
        },
        'jobPosition': {
          'id': 5,
          'name': 'Senior Mobile Developer'
        },
        'department': {
          'id': 3,
          'name': 'IT Department'
        },
        'identity': {
          'email': 'Ibrokhim.sidikov@gmail.com'
        },
        'activeContract': {
          'id': 1,
          'type': 'Full-time',
          'status': 'active'
        },
        'bonusInfo': {
          'amount': 5000,
          'type': 'Performance Bonus'
        },
        'workHours': {
          'totalHours': 168.5,
          'dayHours': 142.0,
          'nightHours': 26.5,
          'month': 'January 2024'
        }
      };
      
      if (mounted) {
        setState(() {
          _profileData = testData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cxSoftWhite,
              AppColors.cxPlatinumGray.withOpacity(0.3),
              AppColors.cxPureWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildProfileContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.cxRoyalBlue,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.cxBlack.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxBlack,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cxRoyalBlue,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.cxPureWhite,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_profileData == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildProfileCard(),
          SizedBox(height: 20.h),
          _buildWorkHoursCard(),
          SizedBox(height: 20.h),
          _buildJobInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.cxBlack,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.cxBlack,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final individual = _profileData?['individual'];
    final identity = _profileData?['identity'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxRoyalBlue,
            AppColors.cxEmeraldGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxRoyalBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Profile Photo
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: individual?['photo'] != null
                    ? Image.network(
                        individual['photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            SizedBox(height: 16.h),
            // Name
            Text(
              '${individual?['firstName'] ?? ''} ${individual?['lastName'] ?? ''}'.trim(),
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.cxPureWhite,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            // Email
            Text(
              identity?['email'] ?? individual?['email'] ?? 'No email',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.cxPureWhite.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.cxPureWhite.withOpacity(0.3),
            AppColors.cxPureWhite.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 50.sp,
        color: AppColors.cxPureWhite.withOpacity(0.8),
      ),
    );
  }

  Widget _buildWorkHoursCard() {
    final workHours = _profileData?['workHours'];
    final totalHours = workHours?['totalHours']?.toDouble() ?? 0.0;
    final dayHours = workHours?['dayHours']?.toDouble() ?? 0.0;
    final nightHours = workHours?['nightHours']?.toDouble() ?? 0.0;
    final month = workHours?['month'] ?? 'Current Month';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxEmeraldGreen,
            AppColors.cxEmeraldGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
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
                        'Work Hours',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cxPureWhite,
                        ),
                      ),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.cxPureWhite.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Total hours - prominent display
            Center(
              child: Column(
                children: [
                  Text(
                    '${totalHours.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cxPureWhite,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Total Hours',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cxPureWhite.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Day and Night hours breakdown
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.cxPureWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.cxPureWhite.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: AppColors.cxPureWhite,
                          size: 24.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${dayHours.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                        Text(
                          'Day Hours',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.cxPureWhite.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.cxPureWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.cxPureWhite.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.nightlight_round_outlined,
                          color: AppColors.cxPureWhite,
                          size: 24.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${nightHours.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cxPureWhite,
                          ),
                        ),
                        Text(
                          'Night Hours',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.cxPureWhite.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard() {
    final jobPosition = _profileData?['jobPosition'];
    final branch = _profileData?['branch'];
    
    return _buildInfoCard(
      title: 'Job Information',
      icon: Icons.work_outline,
      children: [
        _buildInfoRow('Position', jobPosition?['name'] ?? 'Not specified'),
        _buildInfoRow('Branch', branch?['name'] ?? 'Not specified'),
        _buildInfoRow('Department', _profileData?['department']?['name'] ?? 'Not specified'),
        _buildInfoRow('Employee ID', _profileData?['id']?.toString() ?? 'N/A'),
      ],
    );
  }


  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cxPureWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.cxRoyalBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cxBlack,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
