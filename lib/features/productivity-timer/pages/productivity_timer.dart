import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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
  
  // Fake data - will be replaced with API data
  final List<Map<String, String>> _employees = [
    {'id': '1', 'name': 'John Smith'},
    {'id': '2', 'name': 'Sarah Johnson'},
    {'id': '3', 'name': 'Michael Brown'},
    {'id': '4', 'name': 'Emily Davis'},
    {'id': '5', 'name': 'David Wilson'},
  ];
  
  final List<Map<String, String>> _products = [
    {'id': '1', 'name': 'Product A'},
    {'id': '2', 'name': 'Product B'},
    {'id': '3', 'name': 'Product C'},
    {'id': '4', 'name': 'Product D'},
    {'id': '5', 'name': 'Product E'},
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Validate required fields
    if (_selectedEmployeeId == null) {
      _showErrorDialog('Please select an employee');
      return;
    }
    if (_selectedProductId == null) {
      _showErrorDialog('Please select a product');
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
  
  void _showErrorDialog(String message) {
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
                'Required Field',
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
                'OK',
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
          'Stopwatch',
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
            // Form Fields (only show when not running)
            if (!_isRunning) ...[
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
                          'Employee',
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
                      value: _selectedEmployeeId,
                      decoration: InputDecoration(
                        hintText: 'Select employee',
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
                      onChanged: (value) {
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
                          'Product',
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
                        hintText: 'Select product',
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
                          'Note',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' (Optional)',
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
                        hintText: 'Add a note or comment...',
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
            ],
            
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
                        ? (_isPaused ? 'Paused' : 'Running')
                        : 'Ready to start',
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
                    label: 'Start',
                    color: const Color(0xFFFF6B6B),
                    onTap: _startTimer,
                    theme: theme,
                  ),
                ] else ...[
                  // Pause/Resume Button
                  _buildControlButton(
                    icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: _isPaused ? 'Resume' : 'Pause',
                    color: const Color(0xFFFF6B6B),
                    onTap: _isPaused ? _resumeTimer : _pauseTimer,
                    theme: theme,
                  ),
                  SizedBox(width: 16.w),
                  // Reset Button
                  _buildControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Reset',
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    onTap: _resetTimer,
                    theme: theme,
                  ),
                ],
              ],
            ),
            
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
                        'How to Use',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildTipItem('Press Start to begin tracking time', theme),
                  _buildTipItem('Use Pause to temporarily stop the timer', theme),
                  _buildTipItem('Press Reset to clear and start over', theme),
                  _buildTipItem('Track your productivity sessions easily', theme),
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
