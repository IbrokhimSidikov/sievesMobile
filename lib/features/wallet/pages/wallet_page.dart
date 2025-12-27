import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

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
  bool _isUpdatingMonthly = false;
  bool _isUpdatingDuration = false;

  double? _totalPayment;
  double? _extraPayment;
  bool _showResults = false;

  @override
  void dispose() {
    _productPriceController.dispose();
    _monthlyPaymentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _monthlyPaymentController.addListener(_onMonthlyChanged);
    _durationController.addListener(_onDurationChanged);
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

  // Calculate installment
  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final productPrice = _parseFormattedNumber(_productPriceController.text);
      final monthlyPayment = _parseFormattedNumber(_monthlyPaymentController.text);
      final duration = int.tryParse(_durationController.text) ?? 0;

      // Calculate total payment = monthly payment × months
      final totalPayment = monthlyPayment * duration;
      
      // Calculate extra payment = total payment − product price
      final extraPayment = totalPayment - productPrice;

      setState(() {
        _totalPayment = totalPayment;
        _extraPayment = extraPayment;
        _showResults = true;
      });
    }
  }

  void _reset() {
    setState(() {
      _productPriceController.clear();
      _monthlyPaymentController.clear();
      _durationController.clear();
      _totalPayment = null;
      _extraPayment = null;
      _showResults = false;
    });
  }

  void _onMonthlyChanged() {
    if (_isUpdatingMonthly) return;

    final price = _parseFormattedNumber(_productPriceController.text);
    final monthly = _parseFormattedNumber(_monthlyPaymentController.text);

    if (price <= 0 || monthly <= 0) return;

    _isUpdatingDuration = true;

    final months = (price / monthly).ceil();
    _durationController.text = months.toString();

    _isUpdatingDuration = false;
  }

  void _onDurationChanged() {
    if (_isUpdatingDuration) return;

    final price = _parseFormattedNumber(_productPriceController.text);
    final months = int.tryParse(_durationController.text) ?? 0;

    if (price <= 0 || months <= 0) return;

    _isUpdatingMonthly = true;

    final monthly = price / months;
    _monthlyPaymentController.text =
        _formatCurrency(monthly.roundToDouble());

    _isUpdatingMonthly = false;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        size: 48.sp,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12.h),
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

                // Product Price Input
                _buildInputField(
                  controller: _productPriceController,
                  label: 'Buyum narxi (so\'mda)',
                  hint: '0',
                  icon: Icons.shopping_bag_outlined,
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

                // Monthly Payment Input
                _buildInputField(
                  controller: _monthlyPaymentController,
                  label: 'Oylik to\'lov (so\'mda)',
                  hint: '0',
                  icon: Icons.payments_outlined,
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
                SizedBox(height: 16.h),

                // Duration Input
                _buildInputField(
                  controller: _durationController,
                  label: 'Nasiya muddati (oy)',
                  hint: '0',
                  icon: Icons.calendar_month_outlined,
                  keyboardType: TextInputType.number,
                  isMonthInput: true,
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
                // if (_showResults) ...[
                //   SizedBox(height: 24.h),
                //   // _buildResultCard(
                //   //   title: 'Umumiy to\'lov',
                //   //   amount: _totalPayment!,
                //   //   icon: Icons.account_balance_wallet_outlined,
                //   //   gradient: isDark
                //   //       ? [
                //   //           const Color(0xFF6366F1),
                //   //           const Color(0xFF4F46E5),
                //   //         ]
                //   //       : [
                //   //           AppColors.cxRoyalBlue,
                //   //           AppColors.cxRoyalBlue.withOpacity(0.8),
                //   //         ],
                //   // ),
                //   SizedBox(height: 16.h),
                //   // _buildResultCard(
                //   //   title: 'Ortiqcha to\'lov (Sizning zararingiz)',
                //   //   amount: _extraPayment!,
                //   //   icon: Icons.trending_up,
                //   //   gradient: _extraPayment! > 0
                //   //       ? (isDark
                //   //           ? [
                //   //               const Color(0xFFEF4444),
                //   //               const Color(0xFFDC2626),
                //   //             ]
                //   //           : [
                //   //               AppColors.cxCrimsonRed,
                //   //               AppColors.cxCrimsonRed.withOpacity(0.8),
                //   //             ])
                //   //       : (isDark
                //   //           ? [
                //   //               const Color(0xFF34D399),
                //   //               const Color(0xFF10B981),
                //   //             ]
                //   //           : [
                //   //               AppColors.cxEmeraldGreen,
                //   //               AppColors.cxEmeraldGreen.withOpacity(0.8),
                //   //             ]),
                //   //   isExtra: true,
                //   // ),
                // ],
              ],
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
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          if (!isMonthInput) _CurrencyInputFormatter(),
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
          suffixText: isMonthInput ? 'oy' : 'so\'m',
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
            '${_formatCurrency(amount)} so\'m',
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
