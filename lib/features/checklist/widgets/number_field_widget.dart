import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NumberFieldWidget extends StatefulWidget {
  final String value;
  final Function(String) onChanged;
  final ThemeData theme;
  final bool isDark;
  final Map<String, dynamic>? metadata;

  const NumberFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.isDark,
    this.metadata,
  });

  @override
  State<NumberFieldWidget> createState() => _NumberFieldWidgetState();
}

class _NumberFieldWidgetState extends State<NumberFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        fontSize: 15.sp,
        color: widget.theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Enter number...',
        hintStyle: TextStyle(
          color: widget.theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        filled: true,
        fillColor: widget.isDark
            ? const Color(0xFF252532)
            : const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(14.w),
        suffixIcon: widget.value.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: widget.theme.colorScheme.onSurfaceVariant,
                  size: 20.sp,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}
