import 'dart:ui';
import 'package:flutter/material.dart';

/// Celebratory pop-up shown when a new employment contract becomes active for
/// the employee. Modelled on [AnnouncementDialog] but with a congratulatory
/// identity (trophy icon, "NEW CONTRACT" label) and an optional duration chip.
class ContractCongratsDialog extends StatefulWidget {
  final String title;
  final String body;

  /// Human-readable contract length, e.g. "1 year 6 months". Optional.
  final String? duration;

  const ContractCongratsDialog({
    super.key,
    required this.title,
    required this.body,
    this.duration,
  });

  /// Brand teal gradient (matches AppColors.cx43C19F).
  static const List<Color> gradient = [
    Color(0xFF43C19F),
    Color(0xFF2E9B7E),
  ];

  @override
  State<ContractCongratsDialog> createState() => _ContractCongratsDialogState();
}

class _ContractCongratsDialogState extends State<ContractCongratsDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1B1B2A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: ContractCongratsDialog.gradient[0]
                        .withOpacity(isDark ? 0.35 : 0.28),
                    blurRadius: 50,
                    spreadRadius: -4,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildContent(textColor, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // Gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ContractCongratsDialog.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Decorative translucent circles for depth
          Positioned(
            top: -34,
            right: -22,
            child: _circle(120, Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -46,
            left: -28,
            child: _circle(120, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            top: 26,
            left: 30,
            child: _circle(14, Colors.white.withOpacity(0.18)),
          ),
          // Centered glowing icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          // Dismiss (X) icon, top-right
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor, bool isDark) {
    final duration = widget.duration?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: ContractCongratsDialog.gradient[0].withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'NEW CONTRACT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ContractCongratsDialog.gradient[1],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.25,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: textColor.withOpacity(0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (duration != null && duration.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildDurationChip(duration, isDark),
          ],
          const SizedBox(height: 26),
          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildDurationChip(String duration, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ContractCongratsDialog.gradient[0]
            .withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ContractCongratsDialog.gradient[0].withOpacity(0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 18,
            color: ContractCongratsDialog.gradient[1],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Duration: $duration',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ContractCongratsDialog.gradient[1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ContractCongratsDialog.gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ContractCongratsDialog.gradient[0].withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
