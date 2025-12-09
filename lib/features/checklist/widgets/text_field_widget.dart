import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextFieldWidget extends StatefulWidget {
  final String value;
  final Function(String) onChanged;
  final ThemeData theme;
  final bool isDark;

  const TextFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.isDark,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
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
      maxLines: 3,
      style: TextStyle(
        fontSize: 15.sp,
        color: widget.theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Enter text...',
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
      ),
      onChanged: widget.onChanged,
    );
  }
}
