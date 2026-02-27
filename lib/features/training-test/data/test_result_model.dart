class TestSessionResult {
  final int id;
  final int companyId;
  final int identityId;
  final int courseId;
  final String status;
  final int totalQuestions;
  final int correctMatches;
  final int totalMatches;
  final String scorePercentage;
  final int passingScore;
  final String startedAt;
  final String completedAt;
  final List<TestResultDetail> results;
  final ResultCourse course;

  TestSessionResult({
    required this.id,
    required this.companyId,
    required this.identityId,
    required this.courseId,
    required this.status,
    required this.totalQuestions,
    required this.correctMatches,
    required this.totalMatches,
    required this.scorePercentage,
    required this.passingScore,
    required this.startedAt,
    required this.completedAt,
    required this.results,
    required this.course,
  });

  factory TestSessionResult.fromJson(Map<String, dynamic> json) {
    return TestSessionResult(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      identityId: json['identity_id'] as int,
      courseId: json['course_id'] as int,
      status: json['status'] as String,
      totalQuestions: json['total_questions'] as int,
      correctMatches: json['correct_matches'] as int,
      totalMatches: json['total_matches'] as int,
      scorePercentage: json['score_percentage'] as String,
      passingScore: json['passing_score'] as int,
      startedAt: json['started_at'] as String,
      completedAt: json['completed_at'] as String,
      results: (json['results'] as List)
          .map((r) => TestResultDetail.fromJson(r))
          .toList(),
      course: ResultCourse.fromJson(json['course']),
    );
  }
}

class TestResultDetail {
  final int id;
  final int sessionId;
  final int testId;
  final int? pairId;
  final int? matchedPairId;
  final int? optionId;
  final bool isCorrect;
  final ResultTest test;
  final ResultPair? pair;
  final ResultPair? matchedPair;
  final ResultOption? option;

  TestResultDetail({
    required this.id,
    required this.sessionId,
    required this.testId,
    this.pairId,
    this.matchedPairId,
    this.optionId,
    required this.isCorrect,
    required this.test,
    this.pair,
    this.matchedPair,
    this.option,
  });

  factory TestResultDetail.fromJson(Map<String, dynamic> json) {
    return TestResultDetail(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      testId: json['test_id'] as int,
      pairId: json['pair_id'] as int?,
      matchedPairId: json['matched_pair_id'] as int?,
      optionId: json['option_id'] as int?,
      isCorrect: json['is_correct'] as bool,
      test: ResultTest.fromJson(json['test']),
      pair: json['pair'] != null ? ResultPair.fromJson(json['pair']) : null,
      matchedPair: json['matchedPair'] != null ? ResultPair.fromJson(json['matchedPair']) : null,
      option: json['option'] != null ? ResultOption.fromJson(json['option']) : null,
    );
  }
}

class ResultTest {
  final int id;
  final String testType;
  final String question;

  ResultTest({
    required this.id,
    required this.testType,
    required this.question,
  });

  factory ResultTest.fromJson(Map<String, dynamic> json) {
    return ResultTest(
      id: json['id'] as int,
      testType: json['test_type'] as String,
      question: json['question'] as String,
    );
  }
}

class ResultPair {
  final int id;
  final String leftItem;
  final String rightItem;

  ResultPair({
    required this.id,
    required this.leftItem,
    required this.rightItem,
  });

  factory ResultPair.fromJson(Map<String, dynamic> json) {
    return ResultPair(
      id: json['id'] as int,
      leftItem: json['left_item'] as String,
      rightItem: json['right_item'] as String,
    );
  }
}

class ResultOption {
  final int id;
  final String text;
  final bool isCorrect;

  ResultOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory ResultOption.fromJson(Map<String, dynamic> json) {
    return ResultOption(
      id: json['id'] as int,
      text: json['text'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }
}

class ResultCourse {
  final int id;
  final String name;
  final String description;

  ResultCourse({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ResultCourse.fromJson(Map<String, dynamic> json) {
    return ResultCourse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}
