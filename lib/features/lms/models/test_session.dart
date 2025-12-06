class TestSession {
  final int id;
  final int identityId;
  final int courseId;
  final int totalQuestions;
  final int? correctAnswers;
  final double? scorePercentage;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestSession({
    required this.id,
    required this.identityId,
    required this.courseId,
    required this.totalQuestions,
    this.correctAnswers,
    this.scorePercentage,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: json['id'] as int,
      identityId: json['identity_id'] as int,
      courseId: json['course_id'] as int,
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int?,
      scorePercentage: json['score_percentage'] != null 
          ? _parseDouble(json['score_percentage'])
          : null,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identity_id': identityId,
      'course_id': courseId,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percentage': scorePercentage,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TestSessionAnswer {
  final int testId;
  final int selectedOptionId;

  TestSessionAnswer({
    required this.testId,
    required this.selectedOptionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'selected_option_id': selectedOptionId,
    };
  }
}
