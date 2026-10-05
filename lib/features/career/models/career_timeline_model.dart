/// Career roadmap of the logged-in employee, from
/// `GET /employee-lifecycle/me/timeline` (sieves-api-v3).
class CareerTimeline {
  /// null when the employee has no employment contract yet.
  final CareerProfile? profile;

  /// Oldest first.
  final List<CareerEvent> events;

  const CareerTimeline({this.profile, this.events = const []});

  int get promotionCount =>
      events.where((e) => e.change == CareerChange.promotion).length;

  factory CareerTimeline.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>?;
    return CareerTimeline(
      profile: employee == null ? null : CareerProfile.fromJson(employee),
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => CareerEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CareerProfile {
  final String name;
  final String? branchName;
  final String? jobPositionName;
  final String? salaryStructureName;

  /// `t_salary_structure.description` of the current step; shown as a hint.
  final String? salaryStructureDescription;

  /// Start of the first employment contract.
  final DateTime? hireDate;

  /// Set once employment ended.
  final DateTime? exitDate;
  final bool isActive;
  final int contractCount;
  final int trainingCount;

  const CareerProfile({
    required this.name,
    this.branchName,
    this.jobPositionName,
    this.salaryStructureName,
    this.salaryStructureDescription,
    this.hireDate,
    this.exitDate,
    this.isActive = true,
    this.contractCount = 0,
    this.trainingCount = 0,
  });

  factory CareerProfile.fromJson(Map<String, dynamic> json) {
    return CareerProfile(
      name: json['employeeName'] as String? ?? '',
      branchName: json['branchName'] as String?,
      jobPositionName: json['jobPositionName'] as String?,
      salaryStructureName: json['salaryStructureName'] as String?,
      salaryStructureDescription: _blankToNull(
        json['salaryStructureDescription'] as String?,
      ),
      hireDate: _parseDate(json['hireDate']),
      exitDate: _parseDate(json['exitDate']),
      isActive: json['isActive'] as bool? ?? true,
      contractCount: (json['contractCount'] as num?)?.toInt() ?? 0,
      trainingCount: (json['trainingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

enum CareerEventType { hire, contract, training, exit, unknown }

/// How a contract moved the salary step versus the previous contract.
enum CareerChange { promotion, demotion, renewal }

class CareerEvent {
  final DateTime? date;
  final CareerEventType type;
  final CareerChange? change;
  final String? salaryStructureName;
  final String? salaryStructureDescription;
  final String? trainingTheme;
  final String? refNumber;

  const CareerEvent({
    required this.type,
    this.date,
    this.change,
    this.salaryStructureName,
    this.salaryStructureDescription,
    this.trainingTheme,
    this.refNumber,
  });

  factory CareerEvent.fromJson(Map<String, dynamic> json) {
    return CareerEvent(
      date: _parseDate(json['date']),
      type: switch (json['type']) {
        'hire' => CareerEventType.hire,
        'contract' => CareerEventType.contract,
        'training' => CareerEventType.training,
        'exit' => CareerEventType.exit,
        _ => CareerEventType.unknown,
      },
      change: switch (json['change']) {
        'promotion' => CareerChange.promotion,
        'demotion' => CareerChange.demotion,
        'renewal' => CareerChange.renewal,
        _ => null,
      },
      salaryStructureName: json['salaryStructureName'] as String?,
      salaryStructureDescription: _blankToNull(
        json['salaryStructureDescription'] as String?,
      ),
      trainingTheme: json['trainingTheme'] as String?,
      refNumber: json['refNumber'] as String?,
    );
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// `YYYY-MM-DD` as a local calendar date.
DateTime? _parseDate(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}
