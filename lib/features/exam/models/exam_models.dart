// Manual JSON models for the exam feature (snake_case JSON <-> camelCase Dart),
// matching the sieves-api-v3 `exam` module. Options never carry `is_correct`
// on the employee-facing endpoints, so the taker cannot see correct answers.

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

/// One row in the employee's assigned-exam list.
class ExamSummary {
  final int examId;
  final String title;
  final String? description;
  final int durationMinutes;
  final int passingScore;
  final String state; // 'available' | 'in_progress' | 'completed'
  final int? attemptId;
  final double? scorePercentage;
  final bool? passed;

  ExamSummary({
    required this.examId,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.passingScore,
    required this.state,
    this.attemptId,
    this.scorePercentage,
    this.passed,
  });

  bool get isCompleted => state == 'completed';
  bool get isInProgress => state == 'in_progress';
  bool get isAvailable => state == 'available';

  factory ExamSummary.fromJson(Map<String, dynamic> json) => ExamSummary(
        examId: _asInt(json['exam_id']) ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        durationMinutes: _asInt(json['duration_minutes']) ?? 0,
        passingScore: _asInt(json['passing_score']) ?? 0,
        state: json['state'] as String? ?? 'available',
        attemptId: _asInt(json['attempt_id']),
        scorePercentage:
            json['score_percentage'] != null ? _asDouble(json['score_percentage']) : null,
        passed: json['passed'] as bool?,
      );
}

class ExamOption {
  final int id;
  final int questionId;
  final int examId;
  final String text;
  final int sortOrder;

  ExamOption({
    required this.id,
    required this.questionId,
    required this.examId,
    required this.text,
    required this.sortOrder,
  });

  factory ExamOption.fromJson(Map<String, dynamic> json) => ExamOption(
        id: _asInt(json['id']) ?? 0,
        questionId: _asInt(json['question_id']) ?? 0,
        examId: _asInt(json['exam_id']) ?? 0,
        text: json['text'] as String? ?? '',
        sortOrder: _asInt(json['sort_order']) ?? 0,
      );
}

class ExamQuestion {
  final int id;
  final int examId;
  final String text;
  final String type; // 'single' | 'multiple'
  final int points;
  final int sortOrder;
  final List<ExamOption> options;

  ExamQuestion({
    required this.id,
    required this.examId,
    required this.text,
    required this.type,
    required this.points,
    required this.sortOrder,
    required this.options,
  });

  bool get isMultiple => type == 'multiple';

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: _asInt(json['id']) ?? 0,
        examId: _asInt(json['exam_id']) ?? 0,
        text: json['text'] as String? ?? '',
        type: json['type'] as String? ?? 'single',
        points: _asInt(json['points']) ?? 1,
        sortOrder: _asInt(json['sort_order']) ?? 0,
        options: ((json['options'] as List?) ?? [])
            .map((o) => ExamOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

/// Returned by POST /exam/:id/start — a live attempt with its question set.
class ExamAttempt {
  final int attemptId;
  final int examId;
  final String title;
  final String? description;
  final int durationMinutes;
  final int passingScore;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int totalQuestions;
  final List<ExamQuestion> questions;

  ExamAttempt({
    required this.attemptId,
    required this.examId,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.passingScore,
    this.startedAt,
    this.expiresAt,
    required this.totalQuestions,
    required this.questions,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) => ExamAttempt(
        attemptId: _asInt(json['attempt_id']) ?? 0,
        examId: _asInt(json['exam_id']) ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        durationMinutes: _asInt(json['duration_minutes']) ?? 0,
        passingScore: _asInt(json['passing_score']) ?? 0,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'].toString())
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        totalQuestions: _asInt(json['total_questions']) ?? 0,
        questions: ((json['questions'] as List?) ?? [])
            .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

/// Result summary — score + pass/fail only (no per-question reveal).
class ExamResult {
  final int attemptId;
  final int examId;
  final String status; // 'in_progress' | 'passed' | 'failed'
  final double scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final int passingScore;
  final int totalPoints;
  final int earnedPoints;
  final bool passed;
  final String? terminationReason;

  ExamResult({
    required this.attemptId,
    required this.examId,
    required this.status,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.passingScore,
    required this.totalPoints,
    required this.earnedPoints,
    required this.passed,
    this.terminationReason,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        attemptId: _asInt(json['attempt_id']) ?? 0,
        examId: _asInt(json['exam_id']) ?? 0,
        status: json['status'] as String? ?? 'failed',
        scorePercentage: _asDouble(json['score_percentage']),
        correctAnswers: _asInt(json['correct_answers']) ?? 0,
        totalQuestions: _asInt(json['total_questions']) ?? 0,
        passingScore: _asInt(json['passing_score']) ?? 0,
        totalPoints: _asInt(json['total_points']) ?? 0,
        earnedPoints: _asInt(json['earned_points']) ?? 0,
        passed: json['passed'] as bool? ?? false,
        terminationReason: json['termination_reason'] as String?,
      );
}
