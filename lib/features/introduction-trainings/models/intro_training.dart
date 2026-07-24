// Models for the intro-trainings feature, matching v3
// `GET /intro-training/employee/:employeeId`.

class IntroSummary {
  final int total;
  final int completed;
  final int pending;
  final int percent;

  const IntroSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.percent,
  });

  factory IntroSummary.fromJson(Map<String, dynamic> json) {
    return IntroSummary(
      total: (json['total'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      percent: (json['percent'] ?? 0) as int,
    );
  }

  static const empty =
      IntroSummary(total: 0, completed: 0, pending: 0, percent: 0);
}

class IntroChecklistItem {
  final int id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? completedAt;
  final int? completedBy;
  final String? completedByName;

  /// Free-text note/comment captured when the item was marked complete.
  final String? note;

  const IntroChecklistItem({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    this.completedAt,
    this.completedBy,
    this.completedByName,
    this.note,
  });

  factory IntroChecklistItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['completedAt'];
    return IntroChecklistItem(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      completed: (json['completed'] ?? false) as bool,
      completedAt: rawDate is String && rawDate.isNotEmpty
          ? DateTime.tryParse(rawDate)?.toLocal()
          : null,
      completedBy: json['completedBy'] as int?,
      completedByName: json['completedByName'] as String?,
      note: (json['note'] ?? json['comment']) as String?,
    );
  }

  IntroChecklistItem copyWith({
    bool? completed,
    DateTime? completedAt,
    int? completedBy,
    String? completedByName,
    String? note,
    bool clearCompletion = false,
  }) {
    return IntroChecklistItem(
      id: id,
      title: title,
      description: description,
      completed: completed ?? this.completed,
      completedAt: clearCompletion ? null : (completedAt ?? this.completedAt),
      completedBy: clearCompletion ? null : (completedBy ?? this.completedBy),
      completedByName:
          clearCompletion ? null : (completedByName ?? this.completedByName),
      note: clearCompletion ? null : (note ?? this.note),
    );
  }
}

class IntroTraining {
  final int id;
  final String title;
  final String? description;
  final IntroSummary summary;
  final List<IntroChecklistItem> items;

  const IntroTraining({
    required this.id,
    required this.title,
    this.description,
    required this.summary,
    required this.items,
  });

  factory IntroTraining.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return IntroTraining(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      summary: json['summary'] is Map
          ? IntroSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : IntroSummary.empty,
      items: rawItems is List
          ? rawItems
              .map((e) => IntroChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const <IntroChecklistItem>[],
    );
  }

  IntroTraining copyWithItems(List<IntroChecklistItem> newItems) {
    final completed = newItems.where((i) => i.completed).length;
    return IntroTraining(
      id: id,
      title: title,
      description: description,
      summary: IntroSummary(
        total: newItems.length,
        completed: completed,
        pending: newItems.length - completed,
        percent: newItems.isEmpty
            ? 0
            : ((completed / newItems.length) * 100).round(),
      ),
      items: newItems,
    );
  }
}

class IntroEmployeeTrainings {
  final int employeeId;
  final IntroSummary summary;
  final List<IntroTraining> trainings;

  const IntroEmployeeTrainings({
    required this.employeeId,
    required this.summary,
    required this.trainings,
  });

  factory IntroEmployeeTrainings.fromJson(Map<String, dynamic> json) {
    final rawTrainings = json['trainings'];
    return IntroEmployeeTrainings(
      employeeId: (json['employeeId'] ?? 0) as int,
      summary: json['summary'] is Map
          ? IntroSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : IntroSummary.empty,
      trainings: rawTrainings is List
          ? rawTrainings
              .map((e) => IntroTraining.fromJson(e as Map<String, dynamic>))
              .toList()
          : const <IntroTraining>[],
    );
  }

  /// Recomputes the overall summary from the current trainings.
  IntroEmployeeTrainings recomputed() {
    var total = 0;
    var completed = 0;
    for (final t in trainings) {
      total += t.items.length;
      completed += t.items.where((i) => i.completed).length;
    }
    return IntroEmployeeTrainings(
      employeeId: employeeId,
      summary: IntroSummary(
        total: total,
        completed: completed,
        pending: total - completed,
        percent: total == 0 ? 0 : ((completed / total) * 100).round(),
      ),
      trainings: trainings,
    );
  }
}
