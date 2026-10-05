import 'career_timeline_model.dart';

/// Work anniversaries shown on the roadmap, in months since hire.
const List<int> kCareerMilestoneMonths = [1, 3, 6, 12, 24, 36, 48, 60, 84, 120];

enum RoadmapKind {
  hire,
  promotion,
  renewal,
  stepChanged,
  milestone,
  exit,
  today,

  /// Anniversary still ahead, drawn as a locked stop after "today".
  upcoming,
}

/// How many future anniversaries the roadmap shows after "today".
const int kUpcomingMilestoneCount = 2;

/// One node on the career roadmap, ready to render.
class RoadmapItem {
  final RoadmapKind kind;
  final DateTime? date;

  /// Salary step name for hire / contract stops.
  final String? detail;

  /// Anniversary length in months (milestone and upcoming stops).
  final int? milestoneMonths;

  /// Days until an upcoming stop is reached.
  final int? daysLeft;

  /// Day of employment, 1 = hire day ([RoadmapKind.today] only).
  final int? dayNumber;

  /// Days spent on this salary step, set only on the stop where the step
  /// began (hire, or a contract that changed the step). Renewals on the same
  /// step don't restart the count.
  final int? daysInStep;

  /// Whether [daysInStep] is still counting (the employee's current step).
  final bool isCurrentStep;

  const RoadmapItem({
    required this.kind,
    this.date,
    this.detail,
    this.milestoneMonths,
    this.daysLeft,
    this.dayNumber,
    this.daysInStep,
    this.isCurrentStep = false,
  });

  RoadmapItem copyWith({int? daysInStep, bool? isCurrentStep}) => RoadmapItem(
    kind: kind,
    date: date,
    detail: detail,
    milestoneMonths: milestoneMonths,
    daysLeft: daysLeft,
    dayNumber: dayNumber,
    daysInStep: daysInStep ?? this.daysInStep,
    isCurrentStep: isCurrentStep ?? this.isCurrentStep,
  );

  bool get isUpcoming => kind == RoadmapKind.upcoming;
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

/// Roadmap stops, oldest first: hire, contract changes, exit and passed
/// anniversaries, then — while still employed — "today" followed by the next
/// [kUpcomingMilestoneCount] anniversaries. Trainings are left out.
List<RoadmapItem> buildRoadmap(CareerTimeline timeline) {
  final profile = timeline.profile;
  if (profile == null) return const [];

  final items = <RoadmapItem>[];
  for (final event in timeline.events) {
    final kind = switch (event.type) {
      CareerEventType.hire => RoadmapKind.hire,
      CareerEventType.exit => RoadmapKind.exit,
      CareerEventType.contract => switch (event.change) {
        CareerChange.promotion => RoadmapKind.promotion,
        CareerChange.demotion => RoadmapKind.stepChanged,
        _ => RoadmapKind.renewal,
      },
      CareerEventType.training || CareerEventType.unknown => null,
    };
    if (kind == null) continue;
    items.add(
      RoadmapItem(
        kind: kind,
        date: event.date,
        detail: event.salaryStructureName,
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
  final sorted = _withStepDurations(
    indexed.map((e) => e.value).toList(),
    tenureEnd(profile),
    stillEmployed: profile.isActive,
  );

  if (profile.isActive) {
    final today = _today();
    sorted.add(
      RoadmapItem(
        kind: RoadmapKind.today,
        date: today,
        dayNumber: hire == null ? null : today.difference(hire).inDays + 1,
      ),
    );
    if (hire != null) {
      sorted.addAll(
        kCareerMilestoneMonths
            .map((months) => (months, addMonths(hire, months)))
            .where((m) => m.$2.isAfter(today))
            .take(kUpcomingMilestoneCount)
            .map(
              (m) => RoadmapItem(
                kind: RoadmapKind.upcoming,
                date: m.$2,
                milestoneMonths: m.$1,
                daysLeft: m.$2.difference(today).inDays,
              ),
            ),
      );
    }
  }
  return sorted;
}

const _contractKinds = {
  RoadmapKind.hire,
  RoadmapKind.promotion,
  RoadmapKind.renewal,
  RoadmapKind.stepChanged,
};

/// Marks each stop where a salary step began with the days spent on it: up
/// to the next step change, or to [end] (exit / today) for the last step.
List<RoadmapItem> _withStepDurations(
  List<RoadmapItem> items,
  DateTime end, {
  required bool stillEmployed,
}) {
  // Indexes of the stops that start a new step.
  final starts = <int>[];
  String? step;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (!_contractKinds.contains(item.kind) || item.date == null) continue;
    if (starts.isEmpty || item.detail != step) {
      starts.add(i);
      step = item.detail;
    }
  }

  final out = [...items];
  for (var s = 0; s < starts.length; s++) {
    final from = items[starts[s]].date!;
    final isLast = s == starts.length - 1;
    final to = isLast ? end : items[starts[s + 1]].date!;
    out[starts[s]] = items[starts[s]].copyWith(
      daysInStep: to.difference(from).inDays.clamp(0, 1 << 30),
      isCurrentStep: isLast && stillEmployed,
    );
  }
  return out;
}

/// Days on the current salary step, or null when unknown / no longer employed.
int? currentStepDays(List<RoadmapItem> roadmap) {
  for (final item in roadmap.reversed) {
    if (item.isCurrentStep) return item.daysInStep;
  }
  return null;
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
