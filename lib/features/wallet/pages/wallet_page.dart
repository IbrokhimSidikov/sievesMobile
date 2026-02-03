import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import 'pdf_viewer_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _productPriceController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  final _durationController = TextEditingController();
  final _interestRateController = TextEditingController();
  bool _isUpdatingMonthly = false;
  bool _isUpdatingDuration = false;
  final _priceFocus = FocusNode();
  final _monthlyFocus = FocusNode();
  final _durationFocus = FocusNode();
  final _interestFocus = FocusNode();

  // Calculation mode: 'monthly' or 'duration'
  String _calculationMode = 'monthly';

  double? _totalPayment;
  double? _extraPayment;
  double? _totalInterest;
  double? _calculatedMonthlyPayment;
  double? _calculatedDuration;
  bool _showResults = false;

  @override
  void dispose() {
    _productPriceController.dispose();
    _monthlyPaymentController.dispose();
    _durationController.dispose();
    _interestRateController.dispose();
    _priceFocus.dispose();
    _monthlyFocus.dispose();
    _durationFocus.dispose();
    _interestFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Set default interest rate to 0%
    _interestRateController.text = '0';
  }

  // Format number with spaces as thousand separators
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'uz');
    return formatter.format(amount).replaceAll(',', ' ');
  }

  // Parse formatted input back to double
  double _parseFormattedNumber(String text) {
    if (text.isEmpty) return 0;

    final cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanText) ?? 0;
  }

  // Calculate total amount with simple interest
  double _calculateTotalWithInterest(double principal, double annualRate, int months) {
    // Simple interest: Total = Principal + (Principal × Rate × Time)
    // Time in years = months / 12
    final years = months / 12;
    final interest = principal * (annualRate / 100) * years;
    return principal + interest;
  }

  // Calculate monthly payment using simple interest
  double _calculateMonthlyPayment(double principal, double annualRate, int months) {
    final totalAmount = _calculateTotalWithInterest(principal, annualRate, months);
    return totalAmount / months;
  }

  // Calculate duration needed for given monthly payment
  int _calculateDuration(double principal, double annualRate, double monthlyPayment) {
    // We need to solve: monthlyPayment × months = principal + (principal × rate × months/12)
    // monthlyPayment × months = principal × (1 + rate × months/12)
    // This is a linear equation: months × (monthlyPayment - principal × rate/12) = principal
    // months = principal / (monthlyPayment - principal × rate/12)
    
    if (annualRate == 0) {
      return (principal / monthlyPayment).ceil();
    }
    
    final monthlyInterestAmount = principal * (annualRate / 100) / 12;
    final effectiveMonthlyPayment = monthlyPayment - monthlyInterestAmount;
    
    if (effectiveMonthlyPayment <= 0) {
      // Payment doesn't cover interest, return a large number
      return 999;
    }
    
    return (principal / effectiveMonthlyPayment).ceil();
  }

  // Calculate installment
  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final productPrice = _parseFormattedNumber(_productPriceController.text);
      final interestRate = double.tryParse(_interestRateController.text) ?? 0;

      if (_calculationMode == 'monthly') {
        // Calculate monthly payment based on duration
        final duration = int.tryParse(_durationController.text) ?? 0;
        
        final monthlyPayment = _calculateMonthlyPayment(productPrice, interestRate, duration);
        final totalPayment = monthlyPayment * duration;
        final totalInterest = totalPayment - productPrice;

        setState(() {
          _calculatedMonthlyPayment = monthlyPayment;
          _totalPayment = totalPayment;
          _totalInterest = totalInterest;
          _extraPayment = totalInterest;
          _calculatedDuration = null;
          _showResults = true;
        });
      } else {
        // Calculate duration based on monthly payment
        final monthlyPayment = _parseFormattedNumber(_monthlyPaymentController.text);
        
        // Validate that monthly payment is sufficient
        if (interestRate > 0) {
          final monthlyInterestAmount = productPrice * (interestRate / 100) / 12;
          if (monthlyPayment <= monthlyInterestAmount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Oylik to\'lov juda kam! Minimal: ${_formatCurrency(monthlyInterestAmount)}'),
                backgroundColor: AppColors.cxCrimsonRed,
              ),
            );
            return;
          }
        }
        
        final duration = _calculateDuration(productPrice, interestRate, monthlyPayment);
        final totalPayment = monthlyPayment * duration;
        final totalInterest = totalPayment - productPrice;

        setState(() {
          _calculatedDuration = duration.toDouble();
          _totalPayment = totalPayment;
          _totalInterest = totalInterest;
          _extraPayment = totalInterest;
          _calculatedMonthlyPayment = null;
          _showResults = true;
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _productPriceController.clear();
      _monthlyPaymentController.clear();
      _durationController.clear();
      _interestRateController.text = '0';
      _totalPayment = null;
      _extraPayment = null;
      _totalInterest = null;
      _calculatedMonthlyPayment = null;
      _calculatedDuration = null;
      _showResults = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9;
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal;
    final subtleTextColor = isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nasiya Kalkulyatori',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Financial Guide Button
                  _buildFinancialGuideButton(isDark, cardColor, textColor, subtleTextColor),
                  SizedBox(height: 16.h),

                  // Header Icon
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF6366F1),
                                const Color(0xFF4F46E5),
                              ]
                            : [
                                AppColors.cxRoyalBlue,
                                AppColors.cxRoyalBlue.withOpacity(0.8),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          size: 48.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Oylik to\'lovni hisoblang',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Calculation Mode Selector
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            'Hisoblash rejimi',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: subtleTextColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _calculationMode = 'monthly';
                                    _showResults = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    gradient: _calculationMode == 'monthly'
                                        ? LinearGradient(
                                            colors: isDark
                                                ? [
                                                    const Color(0xFF6366F1),
                                                    const Color(0xFF4F46E5),
                                                  ]
                                                : [
                                                    AppColors.cxRoyalBlue,
                                                    AppColors.cxRoyalBlue.withOpacity(0.8),
                                                  ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16.r),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        color: _calculationMode == 'monthly'
                                            ? Colors.white
                                            : subtleTextColor,
                                        size: 24.sp,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Oylik to\'lovni\nhisoblash',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _calculationMode == 'monthly'
                                              ? Colors.white
                                              : subtleTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60.h,
                              color: subtleTextColor.withOpacity(0.2),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _calculationMode = 'duration';
                                    _showResults = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    gradient: _calculationMode == 'duration'
                                        ? LinearGradient(
                                            colors: isDark
                                                ? [
                                                    const Color(0xFF6366F1),
                                                    const Color(0xFF4F46E5),
                                                  ]
                                                : [
                                                    AppColors.cxRoyalBlue,
                                                    AppColors.cxRoyalBlue.withOpacity(0.8),
                                                  ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(16.r),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: _calculationMode == 'duration'
                                            ? Colors.white
                                            : subtleTextColor,
                                        size: 24.sp,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Muddatni\nhisoblash',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _calculationMode == 'duration'
                                              ? Colors.white
                                              : subtleTextColor,
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
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Product Price Input
                  _buildInputField(
                    controller: _productPriceController,
                    label: 'Buyum narxi',
                    hint: '0',
                    icon: Icons.shopping_bag_outlined,
                    focusNode: _priceFocus,
                    nextFocus: _monthlyFocus,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Buyum narxini kiriting';
                      }
                      final price = _parseFormattedNumber(value);
                      if (price <= 0) {
                        return 'Narx 0 dan katta bo\'lishi kerak';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Interest Rate Input
                  _buildInputField(
                    controller: _interestRateController,
                    label: 'Yillik foiz stavkasi',
                    hint: '0',
                    icon: Icons.percent,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isPercentInput: true,
                    focusNode: _interestFocus,
                    nextFocus: _calculationMode == 'monthly' ? _durationFocus : _monthlyFocus,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Foiz stavkasini kiriting';
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0) {
                        return 'Foiz 0 dan katta yoki teng bo\'lishi kerak';
                      }
                      if (rate > 100) {
                        return 'Foiz 100 dan kichik bo\'lishi kerak';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Conditional inputs based on calculation mode
                  if (_calculationMode == 'monthly') ...[
                    // Duration Input
                    _buildInputField(
                      controller: _durationController,
                      label: 'Nasiya muddati (oy)',
                      hint: '0',
                      icon: Icons.calendar_month_outlined,
                      keyboardType: TextInputType.number,
                      isMonthInput: true,
                      focusNode: _durationFocus,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Muddatni kiriting';
                        }
                        final months = int.tryParse(value);
                        if (months == null || months <= 0) {
                          return 'Muddat 0 dan katta bo\'lishi kerak';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    // Monthly Payment Input
                    _buildInputField(
                      controller: _monthlyPaymentController,
                      label: 'Oylik to\'lov',
                      hint: '0',
                      icon: Icons.payments_outlined,
                      focusNode: _monthlyFocus,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Oylik to\'lovni kiriting';
                        }
                        final payment = _parseFormattedNumber(value);
                        if (payment <= 0) {
                          return 'To\'lov 0 dan katta bo\'lishi kerak';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 24.h),

                  // Calculate Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF34D399),
                                const Color(0xFF10B981),
                              ]
                            : [
                                AppColors.cx43C19F,
                                AppColors.cx4AC1A7,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF34D399) : AppColors.cx43C19F).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _calculate,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calculate,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Hisoblash',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Reset Button
                  if (_showResults)
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: Icon(Icons.refresh, color: subtleTextColor),
                      label: Text('Tozalash', style: TextStyle(color: subtleTextColor)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: subtleTextColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),

                  // Results Section
                  if (_showResults) ...[
                    SizedBox(height: 24.h),
                    
                    // Calculated Result Card
                    if (_calculationMode == 'monthly' && _calculatedMonthlyPayment != null)
                      _buildResultCard(
                        title: 'Oylik to\'lov',
                        amount: _calculatedMonthlyPayment!,
                        icon: Icons.payments_outlined,
                        gradient: isDark
                            ? [
                                const Color(0xFF8B5CF6),
                                const Color(0xFF7C3AED),
                              ]
                            : [
                                AppColors.cxRoyalBlue,
                                AppColors.cxRoyalBlue.withOpacity(0.8),
                              ],
                      ),
                    
                    if (_calculationMode == 'duration' && _calculatedDuration != null)
                      _buildResultCard(
                        title: 'Nasiya muddati',
                        amount: _calculatedDuration!,
                        icon: Icons.calendar_month_outlined,
                        gradient: isDark
                            ? [
                                const Color(0xFF8B5CF6),
                                const Color(0xFF7C3AED),
                              ]
                            : [
                                AppColors.cxRoyalBlue,
                                AppColors.cxRoyalBlue.withOpacity(0.8),
                              ],
                        isMonthDisplay: true,
                      ),
                    
                    SizedBox(height: 16.h),
                    
                    // Total Payment Card
                    _buildResultCard(
                      title: 'Umumiy to\'lov',
                      amount: _totalPayment!,
                      icon: Icons.account_balance_wallet_outlined,
                      gradient: isDark
                          ? [
                              const Color(0xFF6366F1),
                              const Color(0xFF4F46E5),
                            ]
                          : [
                              AppColors.cxRoyalBlue,
                              AppColors.cxRoyalBlue.withOpacity(0.8),
                            ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // Interest/Extra Payment Card
                    _buildResultCard(
                      title: 'Foiz to\'lovi',
                      amount: _totalInterest!,
                      icon: Icons.trending_up,
                      gradient: _totalInterest! > 0
                          ? (isDark
                              ? [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ]
                              : [
                                  AppColors.cxCrimsonRed,
                                  AppColors.cxCrimsonRed.withOpacity(0.8),
                                ])
                          : (isDark
                              ? [
                                  const Color(0xFF34D399),
                                  const Color(0xFF10B981),
                                ]
                              : [
                                  AppColors.cxEmeraldGreen,
                                  AppColors.cxEmeraldGreen.withOpacity(0.8),
                                ]),
                      isExtra: true,
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Summary Card
                    _buildSummaryCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.number,
    bool isMonthInput = false,
    bool isPercentInput = false,
    TextInputAction textInputAction = TextInputAction.next,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal;
    final subtleTextColor = isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint;
    final primaryColor = isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue;
    final errorColor = isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        inputFormatters: [
          if (isPercentInput)
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
          else if (!isMonthInput) ...[
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ] else
            FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: subtleTextColor.withOpacity(0.5),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24.sp,
            ),
          ),
          suffixText: isPercentInput ? '%' : (isMonthInput ? 'oy' : 'summa'),
          suffixStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: subtleTextColor,
          ),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            color: subtleTextColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: errorColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: errorColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradient,
    bool isExtra = false,
    bool isMonthDisplay = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            isMonthDisplay 
                ? '${amount.toInt()} oy'
                : '${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          if (isExtra && amount > 0) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${((amount / (_totalPayment! - amount)) * 100).toStringAsFixed(1)}% ortiqcha',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal;
    final subtleTextColor = isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint;
    
    final productPrice = _parseFormattedNumber(_productPriceController.text);
    final interestRate = double.tryParse(_interestRateController.text) ?? 0;
    final monthlyPayment = _calculatedMonthlyPayment ?? _parseFormattedNumber(_monthlyPaymentController.text);
    final duration = (_calculatedDuration ?? int.tryParse(_durationController.text) ?? 0).toInt();
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Xulosa',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow('Buyum narxi:', '${_formatCurrency(productPrice)}', textColor, subtleTextColor),
          _buildSummaryRow('Foiz stavkasi:', '${interestRate.toStringAsFixed(2)}%', textColor, subtleTextColor),
          _buildSummaryRow('Oylik to\'lov:', '${_formatCurrency(monthlyPayment)} ', textColor, subtleTextColor),
          _buildSummaryRow('Muddat:', '$duration oy', textColor, subtleTextColor),
          Divider(height: 24.h, color: subtleTextColor.withOpacity(0.3)),
          _buildSummaryRow(
            'Umumiy to\'lov:', 
            '${_formatCurrency(_totalPayment!)}',
            textColor, 
            subtleTextColor,
            isBold: true,
          ),
          _buildSummaryRow(
            'Foiz to\'lovi:', 
            '${_formatCurrency(_totalInterest!)}',
            _totalInterest! > 0 
                ? (isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed)
                : (isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen),
            subtleTextColor,
            isBold: true,
          ),
          if (_totalInterest! > 0 && productPrice > 0) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: (isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Siz buyum narxidan ${((_totalInterest! / productPrice) * 100).toStringAsFixed(1)}% ko\'proq to\'laysiz',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFEF4444) : AppColors.cxCrimsonRed,
                      ),
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

  Widget _buildSummaryRow(String label, String value, Color valueColor, Color labelColor, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15.sp : 14.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15.sp : 14.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialGuideButton(bool isDark, Color cardColor, Color textColor, Color subtleTextColor) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ]
              : [
                  AppColors.cxEmeraldGreen,
                  AppColors.cxEmeraldGreen.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF10B981) : AppColors.cxEmeraldGreen).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(
                  pdfPath: 'assets/presentations/financial_guide.pdf',
                  title: l10n.translate('financialGuide'),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 32.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('financialGuide'),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        l10n.translate('viewGuide'),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom formatter for currency input with space separators
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all spaces
    final number = newValue.text.replaceAll(' ', '');

    // Format with spaces
    final formatter = NumberFormat('#,###', 'uz');
    final formatted = formatter.format(int.parse(number)).replaceAll(',', ' ');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
