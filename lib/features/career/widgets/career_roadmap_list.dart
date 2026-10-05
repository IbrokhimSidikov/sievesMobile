import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/career_roadmap.dart';
import 'career_format.dart';

/// Width of the rail column on the left of every roadmap row.
double get _railWidth => 32.w;

/// Distance from the top of a card to the center of its icon tile; the rail
/// dot is drawn at this height so it lines up with the icon.
double get _dotCenter => 16.h + 20.w;

/// Vertical roadmap (design.md §7.11): a 2 px rail with a colored dot per
/// event and one card per event, separated by year labels.
class CareerRoadmapSliver extends StatelessWidget {
  final List<RoadmapItem> items;

  const CareerRoadmapSliver({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Interleave a year label whenever the year changes.
    final rows = <Object>[];
    int? year;
    for (final item in items) {
      final y = item.date?.year;
      if (y != null && y != year) {
        rows.add(y);
        year = y;
      }
      rows.add(item);
    }

    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final isFirst = index == 0;
        final isLast = index == rows.length - 1;
        return _Reveal(
          child: row is int
              ? _YearRow(year: row, isFirst: isFirst)
              : _EventRow(
                  item: row as RoadmapItem,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
        );
      },
    );
  }
}

class _YearRow extends StatelessWidget {
  final int year;
  final bool isFirst;

  const _YearRow({required this.year, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Center(
              child: Container(
                width: 2,
                color: isFirst ? Colors.transparent : t.outline,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Padding(
            padding: EdgeInsets.only(bottom: 12.h, top: isFirst ? 0 : 4.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: t.surfaceTint,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: t.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final RoadmapItem item;
  final bool isFirst;
  final bool isLast;

  const _EventRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = RoadmapStyle.of(context, item);
    final dotSize = style.major ? 16.0 : 12.0;
    final isToday = item.kind == RoadmapKind.today;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: _dotCenter - dotSize / 2,
                  color: isFirst ? Colors.transparent : t.outline,
                ),
                isToday
                    ? _PulseDot(color: style.color, size: dotSize)
                    : _Dot(
                        color: style.color,
                        size: dotSize,
                        ring: style.major,
                      ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : t.outline,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _EventCard(item: item, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final RoadmapItem item;
  final RoadmapStyle style;

  const _EventCard({required this.item, required this.style});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final highlighted =
        item.kind == RoadmapKind.today || item.kind == RoadmapKind.promotion;

    final detail = switch (item.kind) {
      RoadmapKind.today =>
        item.dayNumber == null
            ? null
            : l.careerDayOfJourney.replaceAll('{n}', '${item.dayNumber}'),
      RoadmapKind.training => item.detail,
      RoadmapKind.milestone || RoadmapKind.exit => null,
      _ => item.detail == null ? null : '${l.careerStep}: ${item.detail}',
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: highlighted ? style.color.withValues(alpha: 0.08) : t.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: highlighted ? style.color.withValues(alpha: 0.30) : t.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: style.color.withValues(alpha: 0.20)),
            ),
            child: Icon(style.icon, size: 20.sp, color: style.color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        style.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.date != null &&
                        item.kind != RoadmapKind.today) ...[
                      SizedBox(width: 8.w),
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          formatCareerDate(context, item.date!),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: t.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (detail != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  final bool ring;

  const _Dot({required this.color, required this.size, required this.ring});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: context.tokens.background, width: 3)
            : null,
        boxShadow: ring
            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8)]
            : null,
      ),
    );
  }
}

/// "Today" dot with a soft 1.5 s pulse; static when animations are disabled.
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseDot({required this.color, required this.size});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = Curves.easeInOut.transform(_controller.value);
              return Container(
                width: widget.size * (1 + v * 1.2),
                height: widget.size * (1 + v * 1.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.35 * (1 - v)),
                ),
              );
            },
          ),
          _Dot(color: widget.color, size: widget.size, ring: true),
        ],
      ),
    );
  }
}

/// Fades and slides a row in the first time it is built (i.e. as it scrolls
/// into view).
class _Reveal extends StatelessWidget {
  final Widget child;

  const _Reveal({required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
    );
  }
}
