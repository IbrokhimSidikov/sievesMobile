import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/career_roadmap.dart';
import 'career_format.dart';
import 'salary_step_sheet.dart';

/// Winding road from the hire day down to "today" and on to the next locked
/// anniversaries. Stops alternate left and right; the travelled stretch is
/// indigo, the road ahead is grey. The road draws itself on first show and
/// each stop pops in as the road reaches it.
class CareerRoadMap extends StatefulWidget {
  final List<RoadmapItem> items;

  const CareerRoadMap({super.key, required this.items});

  @override
  State<CareerRoadMap> createState() => _CareerRoadMapState();
}

class _CareerRoadMapState extends State<CareerRoadMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (500 + widget.items.length * 120).clamp(800, 2400),
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final t = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final geo = _RoadGeometry(
          width: constraints.maxWidth,
          items: items,
          rowHeight: 164.h,
          top: 24.h,
        );

        return SizedBox(
          height: geo.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOutCubic.transform(
                _controller.value,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoadPainter(
                        geo: geo,
                        progress: progress,
                        tokens: t,
                      ),
                    ),
                  ),
                  for (final sign in geo.yearSigns)
                    Positioned(
                      left: sign.center.dx - 32.w,
                      top: sign.center.dy - 12.h,
                      width: 64.w,
                      height: 24.h,
                      child: Opacity(
                        opacity: geo.appear(progress, sign.index),
                        child: _YearSign(year: sign.year),
                      ),
                    ),
                  for (var i = 0; i < items.length; i++)
                    ..._stop(context, geo, i, geo.appear(progress, i)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _stop(
    BuildContext context,
    _RoadGeometry geo,
    int i,
    double appear,
  ) {
    final item = widget.items[i];
    final style = RoadmapStyle.of(context, item);
    final point = geo.points[i];
    final onLeft = geo.isLeft(i);
    final nodeSize = _nodeSize(item, style);
    final cardInset = _maxNodeRadius + 12.w;
    final scale = Curves.easeOutBack.transform(appear);

    return [
      Positioned(
        top: point.dy - geo.rowHeight / 2,
        height: geo.rowHeight,
        left: onLeft ? point.dx + cardInset : 0,
        width: onLeft ? geo.width - point.dx - cardInset : point.dx - cardInset,
        child: Align(
          alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Opacity(
            opacity: appear,
            child: Transform.translate(
              offset: Offset((onLeft ? 16 : -16) * (1 - appear), 0),
              child: _StopCard(item: item, style: style),
            ),
          ),
        ),
      ),
      Positioned(
        left: point.dx - nodeSize / 2,
        top: point.dy - nodeSize / 2,
        width: nodeSize,
        height: nodeSize,
        child: Transform.scale(
          scale: scale,
          child: item.kind == RoadmapKind.today
              ? _TodayNode(size: nodeSize, color: style.color)
              : _StopNode(item: item, style: style, size: nodeSize),
        ),
      ),
    ];
  }
}

double get _maxNodeRadius => 28.w;

double _nodeSize(RoadmapItem item, RoadmapStyle style) {
  if (item.isUpcoming) return 40.w;
  return style.major ? 52.w : 44.w;
}

/// Positions of every stop and the road between them.
class _RoadGeometry {
  final double width;
  final double rowHeight;
  final double top;
  final List<RoadmapItem> items;

  late final List<Offset> points = [
    for (var i = 0; i < items.length; i++)
      Offset(
        isLeft(i) ? width * 0.18 : width * 0.82,
        top + i * rowHeight + rowHeight / 2,
      ),
  ];

  /// Last stop of the travelled stretch ("today", or the last past stop).
  late final int travelledEnd = math.max(
    0,
    items.lastIndexWhere((item) => !item.isUpcoming),
  );

  late final Path travelled = _path(0, travelledEnd);
  late final Path ahead = _path(travelledEnd, items.length - 1);

  /// Road length from the first stop to each stop.
  late final List<double> _distances = () {
    final out = <double>[0];
    for (var i = 1; i < points.length; i++) {
      out.add(out.last + _length(_path(i - 1, i)));
    }
    return out;
  }();

  double get totalLength => _distances.last;

  /// Year labels: above the first stop, then where the road crosses the
  /// middle between two stops of different years.
  late final List<({int year, Offset center, int index})> yearSigns = () {
    final signs = <({int year, Offset center, int index})>[];
    int? year;
    for (var i = 0; i < items.length; i++) {
      final y = items[i].date?.year;
      if (y == null || y == year) continue;
      final center = i == 0
          ? Offset(points[0].dx, math.max(12.0, points[0].dy - 52))
          : Offset(width / 2, (points[i - 1].dy + points[i].dy) / 2);
      signs.add((year: y, center: center, index: i));
      year = y;
    }
    return signs;
  }();

  _RoadGeometry({
    required this.width,
    required this.items,
    required this.rowHeight,
    required this.top,
  });

  double get height => top + items.length * rowHeight + 8;

  bool isLeft(int i) => i.isEven;

  /// 0..1 visibility of stop [i] for a road drawn up to [progress].
  double appear(double progress, int i) {
    if (totalLength <= 0) return progress;
    // Scaled so the last stop is fully shown when the road finishes.
    final at = _distances[i] / totalLength * 0.92;
    return ((progress - at + 0.04) / 0.08).clamp(0.0, 1.0);
  }

  Path _path(int from, int to) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[from].dx, points[from].dy);
    for (var i = from + 1; i <= to; i++) {
      final a = points[i - 1], b = points[i];
      final mid = (b.dy - a.dy) / 2;
      path.cubicTo(a.dx, a.dy + mid, b.dx, b.dy - mid, b.dx, b.dy);
    }
    return path;
  }

  static double _length(Path path) =>
      path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);
}

class _RoadPainter extends CustomPainter {
  final _RoadGeometry geo;
  final double progress;
  final AppTokens tokens;

  _RoadPainter({
    required this.geo,
    required this.progress,
    required this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = geo.totalLength * progress;
    final travelledLength = _RoadGeometry._length(geo.travelled);

    _road(
      canvas,
      geo.travelled,
      math.min(drawn, travelledLength),
      // A step stronger than primaryContainer so the road reads on the light
      // background too.
      bed: Color.alphaBlend(
        tokens.primary.withValues(alpha: 0.22),
        tokens.primaryContainer,
      ),
      lane: tokens.primary,
      glow: tokens.primary,
    );
    _road(
      canvas,
      geo.ahead,
      math.max(0, drawn - travelledLength),
      bed: tokens.surfaceTint,
      lane: tokens.outlineStrong,
    );
  }

  void _road(
    Canvas canvas,
    Path path,
    double length, {
    required Color bed,
    required Color lane,
    Color? glow,
  }) {
    if (length <= 0) return;
    for (final metric in path.computeMetrics()) {
      final visible = metric.extractPath(0, math.min(length, metric.length));

      Paint stroke(Color color, double width) => Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (glow != null) {
        canvas.drawPath(
          visible,
          stroke(glow.withValues(alpha: 0.12), 30)
            ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas.drawPath(visible, stroke(tokens.outline, 22));
      canvas.drawPath(visible, stroke(bed, 18));

      // Dashed lane marking down the middle of the road.
      final lanePaint = stroke(lane, 2.5);
      const dash = 10.0, gap = 9.0;
      final end = math.min(length, metric.length);
      for (var d = 0.0; d < end; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, end)),
          lanePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.progress != progress || old.geo != geo || old.tokens != tokens;
}

class _YearSign extends StatelessWidget {
  final int year;

  const _YearSign({required this.year});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.outlineStrong),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
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
    );
  }
}

class _StopNode extends StatelessWidget {
  final RoadmapItem item;
  final RoadmapStyle style;
  final double size;

  const _StopNode({
    required this.item,
    required this.style,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final upcoming = item.isUpcoming;
    final color = style.color;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: upcoming
            ? t.surface
            : Color.alphaBlend(color.withValues(alpha: 0.14), t.surface),
        border: Border.all(
          color: upcoming ? t.outlineStrong : color,
          width: style.major ? 3 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: upcoming ? t.shadow : color.withValues(alpha: 0.30),
            blurRadius: style.major ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        style.icon,
        size: size * 0.44,
        color: upcoming ? t.textSecondary : color,
      ),
    );
  }
}

/// "You are here" stop: filled indigo with a soft 1.5 s pulse.
class _TodayNode extends StatefulWidget {
  final double size;
  final Color color;

  const _TodayNode({required this.size, required this.color});

  @override
  State<_TodayNode> createState() => _TodayNodeState();
}

class _TodayNodeState extends State<_TodayNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final v = Curves.easeOut.transform(_pulse.value);
            final d = widget.size * (1 + v * 0.8);
            return OverflowBox(
              maxWidth: d,
              maxHeight: d,
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.30 * (1 - v)),
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(color: t.background, width: 4),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.near_me_rounded,
              size: widget.size * 0.42,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final RoadmapItem item;
  final RoadmapStyle style;

  const _StopCard({required this.item, required this.style});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isToday = item.kind == RoadmapKind.today;
    final upcoming = item.isUpcoming;
    final highlighted = isToday || item.kind == RoadmapKind.promotion;

    final detail = switch (item.kind) {
      RoadmapKind.today =>
        item.dayNumber == null
            ? null
            : l.careerDayOfJourney.replaceAll('{n}', '${item.dayNumber}'),
      RoadmapKind.upcoming =>
        item.daysLeft == null
            ? null
            : l.careerDaysLeft.replaceAll('{n}', '${item.daysLeft}'),
      RoadmapKind.milestone || RoadmapKind.exit => null,
      _ => item.detail == null ? null : '${l.careerStep}: ${item.detail}',
    };

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: upcoming
            ? t.surfaceTint
            : highlighted
            ? Color.alphaBlend(style.color.withValues(alpha: 0.08), t.surface)
            : t.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: highlighted ? style.color.withValues(alpha: 0.35) : t.outline,
        ),
        boxShadow: upcoming
            ? null
            : [
                BoxShadow(
                  color: t.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isToday)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l.careerYouAreHere.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            )
          else if (item.date != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  upcoming ? Icons.schedule_rounded : Icons.event_rounded,
                  size: 12.sp,
                  color: t.textSecondary,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    formatCareerDate(context, item.date!),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          SizedBox(height: 6.h),
          Text(
            style.title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: upcoming ? t.textSecondary : t.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (detail != null) ...[
            SizedBox(height: 2.h),
            _StepDetail(
              text: detail,
              color: isToday ? style.color : t.textSecondary,
              hintColor: style.color,
              // Only contract stops carry a step; the hint opens its description.
              onHint: item.detail != null && item.detailHint != null
                  ? () => showSalaryStepSheet(
                        context,
                        name: item.detail!,
                        description: item.detailHint!,
                      )
                  : null,
            ),
          ],
          if (item.daysInStep != null) ...[
            SizedBox(height: 8.h),
            _StepDaysPill(item: item, color: style.color),
          ],
        ],
      ),
    );
  }
}

/// Detail line under a stop title. When [onHint] is set the line ends with
/// an "i" icon and the whole line is tappable.
class _StepDetail extends StatelessWidget {
  final String text;
  final Color color;
  final Color hintColor;
  final VoidCallback? onHint;

  const _StepDetail({
    required this.text,
    required this.color,
    required this.hintColor,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (onHint == null) return label;

    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        onTap: onHint,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              SizedBox(width: 4.w),
              SalaryStepHintIcon(color: hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// "214 days at this step" under a stop where a salary step began; the
/// current step shows "... so far" with a filled pill.
class _StepDaysPill extends StatelessWidget {
  final RoadmapItem item;
  final Color color;

  const _StepDaysPill({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final current = item.isCurrentStep;
    final text = (current ? l.careerDaysInStepSoFar : l.careerDaysInStep)
        .replaceAll('{n}', '${item.daysInStep}');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: current ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            current ? Icons.timelapse_rounded : Icons.hourglass_bottom_rounded,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
