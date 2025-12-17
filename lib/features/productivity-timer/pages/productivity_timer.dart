import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/l10n/app_localizations.dart';

class ProductivityTimer extends StatefulWidget {
  const ProductivityTimer({super.key});

  @override
  State<ProductivityTimer> createState() => _ProductivityTimerState();
}

class _ProductivityTimerState extends State<ProductivityTimer> {
  Timer? _timer;
  int _milliseconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  
  // Form fields
  String? _selectedEmployeeId;
  String? _selectedProductId;
  final TextEditingController _noteController = TextEditingController();
  
  // Data from API
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = true;
  bool _isSubmitting = false;
  
  // Fake data for products - will be replaced with API data later
  final List<Map<String, String>> _products = [
    {'id': '1', 'name': 'Spinner'},
    {'id': '2', 'name': 'Burger'},
    {'id': '3', 'name': 'Pizza'},
    {'id': '4', 'name': 'Chicken'},
    {'id': '5', 'name': 'Coffee'},
    {'id': '6', 'name': 'IceCream'},
    {'id': '7', 'name': 'Waffle'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
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
        _showErrorDialog(l10n.errorLoadEmployees);
      }
    }
  }

  void _startTimer() {
    final l10n = AppLocalizations.of(context);
    // Validate required fields
    if (_selectedEmployeeId == null) {
      _showErrorDialog(l10n.validationEmployeeRequired);
      return;
    }
    if (_selectedProductId == null) {
      _showErrorDialog(l10n.validationProductRequired);
      return;
    }
    
    if (!_isRunning) {
      setState(() {
        _milliseconds = 0;
        _isRunning = true;
        _isPaused = false;
      });
      
      _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        setState(() {
          _milliseconds += 10;
        });
      });
    }
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _milliseconds += 10;
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _milliseconds = 0;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }
  
  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF6B6B),
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF4CAF50),
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  l10n.successSubmit,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedEmployeeId == null) {
      _showErrorDialog(l10n.validationEmployeeRequired);
      return;
    }
    if (_selectedProductId == null) {
      _showErrorDialog(l10n.validationProductRequired);
      return;
    }
    if (_milliseconds == 0) {
      _showErrorDialog(l10n.validationProductRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authManager = AuthManager();
      final selectedEmployee = _employees.firstWhere(
        (emp) => emp['id'] == _selectedEmployeeId,
      );
      final selectedProduct = _products.firstWhere(
        (prod) => prod['id'] == _selectedProductId,
      );

      // Format time as HH:MM:SS
      final totalSeconds = _milliseconds ~/ 1000;
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final secs = totalSeconds % 60;
      final timeFormatted = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      final success = await authManager.apiService.submitEfficiencyTracker(
        employeeId: int.parse(selectedEmployee['id']),
        jobPositionId: selectedEmployee['job_position_id'] ?? 0,
        employeeName: selectedEmployee['name'],
        jobPositionName: selectedEmployee['job_position_name'] ?? 'Unknown',
        time: timeFormatted,
        productId: int.tryParse(selectedProduct['id']!),
        comment: _noteController.text.trim(),
        productName: selectedProduct['name'],
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        _showSuccessDialog(l10n.successSubmit);
        // Reset form
        setState(() {
          _selectedEmployeeId = null;
          _selectedProductId = null;
          _noteController.clear();
          _milliseconds = 0;
          _isRunning = false;
          _isPaused = false;
        });
      } else {
        _showErrorDialog(l10n.errorSubmit);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog(l10n.errorSubmit);
    }
  }


  String _formatTime(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    final ms = (milliseconds % 1000) ~/ 10; // Show centiseconds (2 digits)
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.stopwatch,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
            // Form Fields (always visible)
            // Employee Dropdown
            Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDark
                      ? const Color(0xFF1A1A24)
                      : const Color(0xFFFFFFFF),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E5EA),
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
                          color: const Color(0xFFFF6B6B),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.employee,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _isLoadingEmployees
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: isDark
                                  ? const Color(0xFF252532)
                                  : const Color(0xFFF5F5F7),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  l10n.loadingEmployees,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedEmployeeId,
                            decoration: InputDecoration(
                              hintText: _employees.isEmpty 
                                  ? l10n.noEmployeesAvailable
                                  : l10n.selectEmployee,
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF252532)
                                  : const Color(0xFFF5F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                            ),
                            dropdownColor: isDark
                                ? const Color(0xFF1A1A24)
                                : const Color(0xFFFFFFFF),
                            items: _employees.map((employee) {
                              return DropdownMenuItem<String>(
                                value: employee['id'],
                                child: Text(
                                  employee['name']!,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _employees.isEmpty ? null : (value) {
                              setState(() {
                                _selectedEmployeeId = value;
                              });
                            },
                          ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Product Dropdown
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDark
                      ? const Color(0xFF1A1A24)
                      : const Color(0xFFFFFFFF),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: const Color(0xFFFF6B6B),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.product,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: InputDecoration(
                        hintText: l10n.selectProduct,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF252532)
                            : const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1A1A24)
                          : const Color(0xFFFFFFFF),
                      items: _products.map((product) {
                        return DropdownMenuItem<String>(
                          value: product['id'],
                          child: Text(
                            product['name']!,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Note Field
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDark
                      ? const Color(0xFF1A1A24)
                      : const Color(0xFFFFFFFF),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          color: const Color(0xFFFF6B6B),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.note,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' ${l10n.optional}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        // Dismiss keyboard when done is pressed
                        FocusScope.of(context).unfocus();
                      },
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.addNote,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF252532)
                            : const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
            
            // Timer Display Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1A24), const Color(0xFF252532)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Timer Circle
                  Container(
                    width: 240.w,
                    height: 240.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isRunning
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                            : isDark
                                ? [const Color(0xFF374151), const Color(0xFF4B5563)]
                                : [const Color(0xFFE5E5EA), const Color(0xFFD1D5DB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isRunning
                              ? const Color(0xFFFF6B6B).withOpacity(0.4)
                              : Colors.transparent,
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(_milliseconds),
                        style: TextStyle(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: _isRunning ? Colors.white : theme.colorScheme.onSurface,
                          letterSpacing: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Status Text
                  Text(
                    _isRunning
                        ? (_isPaused ? l10n.paused : l10n.running)
                        : l10n.readyToStart,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning) ...[
                  // Start Button
                  _buildControlButton(
                    icon: Icons.play_arrow_rounded,
                    label: l10n.start,
                    color: const Color(0xFFFF6B6B),
                    onTap: _startTimer,
                    theme: theme,
                  ),
                ] else ...[
                  // Pause/Resume Button
                  _buildControlButton(
                    icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: _isPaused ? l10n.resume : l10n.pause,
                    color: const Color(0xFFFF6B6B),
                    onTap: _isPaused ? _resumeTimer : _pauseTimer,
                    theme: theme,
                  ),
                  SizedBox(width: 16.w),
                  // Stop Button
                  _buildControlButton(
                    icon: Icons.stop_rounded,
                    label: l10n.stop,
                    color: const Color(0xFF4CAF50),
                    onTap: _stopTimer,
                    theme: theme,
                  ),
                ],
              ],
            ),
            
            // Submit and Reset Buttons (only show when timer has been stopped and has time)
            if (!_isRunning && _milliseconds > 0) ...[
              SizedBox(height: 24.h),
              Row(
                children: [
                  // Reset Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: isDark 
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E5EA),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: isDark 
                                  ? Colors.white
                                  : const Color(0xFF374151),
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              l10n.reset,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Submit Button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isSubmitting ? null : _submitData,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors: _isSubmitting
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [const Color(0xFF4CAF50), const Color(0xFF45A049)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: !_isSubmitting
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSubmitting) ...[
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12.w),
                            ] else ...[
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                            ],
                            Text(
                              _isSubmitting ? l10n.submitting : l10n.submit,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 32.h),
            
            // Tips Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: isDark
                    ? const Color(0xFF1A1A24)
                    : const Color(0xFFFFFFFF),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: const Color(0xFFFF6B6B),
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        l10n.tipsTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildTipItem(l10n.tip1, theme),
                  _buildTipItem(l10n.tip2, theme),
                  _buildTipItem(l10n.tip3, theme),
                  _buildTipItem(l10n.tip4, theme),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: isEnabled
                ? [color, color.withOpacity(0.8)]
                : [Colors.grey.shade400, Colors.grey.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            margin: EdgeInsets.only(top: 8.h, right: 12.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B6B),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
