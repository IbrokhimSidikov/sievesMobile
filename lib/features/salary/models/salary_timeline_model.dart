// Models for the employee salary-progress timeline endpoint
// (GET /salary-progress/employee/{id}/timeline on the v3 API).
//
// The salary "ladder" is every salary structure in the company ranked by
// monthly rate. Each employment contract places the employee on one step of
// that ladder for a period of time; the timeline is that history over time.

/// A single rung on the company salary ladder.
class SalaryLadderStep {
  final int salaryStructureId;
  final String salaryStructureName;
  final double monthlyRate;
  final int step; // 1-based position on the ladder (1 = lowest paid)

  SalaryLadderStep({
    required this.salaryStructureId,
    required this.salaryStructureName,
    required this.monthlyRate,
    required this.step,
  });

  factory SalaryLadderStep.fromJson(Map<String, dynamic> json) {
    return SalaryLadderStep(
      salaryStructureId: (json['salaryStructureId'] as num?)?.toInt() ?? 0,
      salaryStructureName: json['salaryStructureName']?.toString() ?? '',
      monthlyRate: (json['monthlyRate'] as num?)?.toDouble() ?? 0,
      step: (json['step'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One contract period the employee spent on a given salary step.
class SalaryTimelineEntry {
  final int contractId;
  final String? refNumber;
  final String status;
  final int? salaryStructureId;
  final String? salaryStructureName;
  final double? monthlyRate;
  final int? step;
  final int totalSteps;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Day this salary step actually stopped applying (own end, else the next
  /// contract's start, else today while it is still running).
  final DateTime? periodEndDate;

  /// Calendar days spent on this step, null when the start date is unknown.
  final int? periodDays;

  /// True while the step is still running, so [periodDays] keeps growing.
  final bool isOngoing;

  SalaryTimelineEntry({
    required this.contractId,
    required this.refNumber,
    required this.status,
    required this.salaryStructureId,
    required this.salaryStructureName,
    required this.monthlyRate,
    required this.step,
    required this.totalSteps,
    required this.startDate,
    required this.endDate,
    required this.periodEndDate,
    required this.periodDays,
    required this.isOngoing,
  });

  factory SalaryTimelineEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return SalaryTimelineEntry(
      contractId: (json['contractId'] as num?)?.toInt() ?? 0,
      refNumber: json['refNumber']?.toString(),
      status: json['status']?.toString() ?? '',
      salaryStructureId: (json['salaryStructureId'] as num?)?.toInt(),
      salaryStructureName: json['salaryStructureName']?.toString(),
      monthlyRate: (json['monthlyRate'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toInt(),
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      periodEndDate: parseDate(json['periodEndDate']),
      periodDays: (json['periodDays'] as num?)?.toInt(),
      isOngoing: json['isOngoing'] == true,
    );
  }
}

/// Full salary journey of a single employee.
class SalaryTimeline {
  final int employeeId;
  final String employeeName;
  final String? branchName;
  final List<SalaryLadderStep> ladder;
  final List<SalaryTimelineEntry> timeline;

  /// Calendar days from the first contract start to the last period end.
  final int? totalDays;

  SalaryTimeline({
    required this.employeeId,
    required this.employeeName,
    required this.branchName,
    required this.ladder,
    required this.timeline,
    required this.totalDays,
  });

  factory SalaryTimeline.fromJson(Map<String, dynamic> json) {
    return SalaryTimeline(
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      employeeName: json['employeeName']?.toString() ?? '',
      branchName: json['branchName']?.toString(),
      ladder: (json['ladder'] as List? ?? [])
          .map((e) => SalaryLadderStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List? ?? [])
          .map((e) => SalaryTimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDays: (json['totalDays'] as num?)?.toInt(),
    );
  }

  int get totalSteps => ladder.length;

  /// The step the employee is on right now: the ongoing period if there is
  /// one, otherwise the most recent period that maps to a ladder step.
  SalaryTimelineEntry? get currentEntry {
    for (final e in timeline) {
      if (e.isOngoing) return e;
    }
    for (var i = timeline.length - 1; i >= 0; i--) {
      if (timeline[i].step != null) return timeline[i];
    }
    return timeline.isNotEmpty ? timeline.last : null;
  }
}
