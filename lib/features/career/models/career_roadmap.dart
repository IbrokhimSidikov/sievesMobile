import 'career_timeline_model.dart';

/// Work anniversaries shown on the roadmap, in months since hire.
const List<int> kCareerMilestoneMonths = [1, 3, 6, 12, 24, 36, 48, 60, 84, 120];

enum RoadmapKind {
  hire,
  promotion,
  renewal,
  stepChanged,
  training,
  milestone,
  exit,
  today,
}

/// One node on the career roadmap, ready to render.
class RoadmapItem {
  final RoadmapKind kind;
  final DateTime? date;

  /// Step / training theme, depending on [kind].
  final String? detail;

  /// Milestone length in months ([RoadmapKind.milestone] only).
  final int? milestoneMonths;

  /// Day of employment, 1 = hire day ([RoadmapKind.today] only).
  final int? dayNumber;

  const RoadmapItem({
    required this.kind,
    this.date,
    this.detail,
    this.milestoneMonths,
    this.dayNumber,
  });
}

class NextMilestone {
  final int months;
  final DateTime date;

  /// 0..1 between the previous milestone (or hire) and this one.
  final double progress;
  final int daysLeft;

  const NextMilestone({
    required this.months,
    required this.date,
    required this.progress,
    required this.daysLeft,
  });
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// [date] plus [months], clamping the day to the target month's length
/// (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime date, int months) {
  final firstOfTarget = DateTime(date.year, date.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    date.day > lastDay ? lastDay : date.day,
  );
}

/// Whole calendar months between [from] and [to].
int monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months--;
  return months < 0 ? 0 : months;
}

/// End of the tenure: exit date, or today while still employed.
DateTime tenureEnd(CareerProfile profile) =>
    profile.isActive ? _today() : (profile.exitDate ?? _today());

/// Roadmap nodes, oldest first: API events, passed anniversaries, and a
/// closing "today" node while the employee is still working.
List<RoadmapItem> buildRoadmap(CareerTimeline timeline) {
  final profile = timeline.profile;
  if (profile == null) return const [];

  final items = <RoadmapItem>[];
  for (final event in timeline.events) {
    final kind = switch (event.type) {
      CareerEventType.hire => RoadmapKind.hire,
      CareerEventType.training => RoadmapKind.training,
      CareerEventType.exit => RoadmapKind.exit,
      CareerEventType.contract => switch (event.change) {
        CareerChange.promotion => RoadmapKind.promotion,
        CareerChange.demotion => RoadmapKind.stepChanged,
        _ => RoadmapKind.renewal,
      },
      CareerEventType.unknown => null,
    };
    if (kind == null) continue;
    items.add(
      RoadmapItem(
        kind: kind,
        date: event.date,
        detail: event.type == CareerEventType.training
            ? event.trainingTheme
            : event.salaryStructureName,
      ),
    );
  }

  final hire = profile.hireDate;
  if (hire != null) {
    final end = tenureEnd(profile);
    for (final months in kCareerMilestoneMonths) {
      final date = addMonths(hire, months);
      if (date.isAfter(end)) break;
      items.add(
        RoadmapItem(
          kind: RoadmapKind.milestone,
          date: date,
          milestoneMonths: months,
        ),
      );
    }
  }

  // Stable sort keeps the API order for same-day events; undated go last.
  final indexed = items.asMap().entries.toList()
    ..sort((a, b) {
      final da = a.value.date, db = b.value.date;
      if (da == null && db == null) return a.key - b.key;
      if (da == null) return 1;
      if (db == null) return -1;
      final byDate = da.compareTo(db);
      return byDate != 0 ? byDate : a.key - b.key;
    });
  final sorted = indexed.map((e) => e.value).toList();

  if (profile.isActive) {
    final today = _today();
    sorted.add(
      RoadmapItem(
        kind: RoadmapKind.today,
        date: today,
        dayNumber: hire == null ? null : today.difference(hire).inDays + 1,
      ),
    );
  }
  return sorted;
}

/// The next anniversary still ahead, or null once the last one passed or the
/// employee left.
NextMilestone? nextMilestone(CareerProfile profile) {
  final hire = profile.hireDate;
  if (hire == null || !profile.isActive) return null;
  final today = _today();

  var previous = hire;
  for (final months in kCareerMilestoneMonths) {
    final date = addMonths(hire, months);
    if (date.isAfter(today)) {
      final span = date.difference(previous).inDays;
      final done = today.difference(previous).inDays;
      return NextMilestone(
        months: months,
        date: date,
        progress: span <= 0 ? 1 : (done / span).clamp(0.0, 1.0),
        daysLeft: date.difference(today).inDays,
      );
    }
    previous = date;
  }
  return null;
}
