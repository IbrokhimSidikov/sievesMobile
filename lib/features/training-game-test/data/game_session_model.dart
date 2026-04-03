class GameSession {
  final int id;
  final int identityId;
  final int courseId;
  final String status;
  final int totalQuestions;
  final int correctMatches;
  final String scorePercentage;
  final int passingScore;
  final String? completedAt;
  final GameSessionCourse? course;
  final GameSessionIdentity? identity;
  final GameSessionEmployee? employee;

  GameSession({
    required this.id,
    required this.identityId,
    required this.courseId,
    required this.status,
    required this.totalQuestions,
    required this.correctMatches,
    required this.scorePercentage,
    required this.passingScore,
    this.completedAt,
    this.course,
    this.identity,
    this.employee,
  });

  double get score => double.tryParse(scorePercentage) ?? 0.0;

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] ?? 0,
      identityId: json['identity_id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      status: json['status'] ?? '',
      totalQuestions: json['total_questions'] ?? 0,
      correctMatches: json['correct_matches'] ?? 0,
      scorePercentage: json['score_percentage']?.toString() ?? '0.00',
      passingScore: json['passing_score'] ?? 70,
      completedAt: json['completed_at'],
      course: json['course'] != null
          ? GameSessionCourse.fromJson(json['course'])
          : null,
      identity: json['identity'] != null
          ? GameSessionIdentity.fromJson(json['identity'])
          : null,
      employee: json['employee'] != null
          ? GameSessionEmployee.fromJson(json['employee'])
          : null,
    );
  }
}

class GameSessionCourse {
  final int id;
  final String name;

  GameSessionCourse({required this.id, required this.name});

  factory GameSessionCourse.fromJson(Map<String, dynamic> json) {
    return GameSessionCourse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class GameSessionIdentity {
  final int id;
  final String username;
  final String? email;

  GameSessionIdentity({
    required this.id,
    required this.username,
    this.email,
  });

  factory GameSessionIdentity.fromJson(Map<String, dynamic> json) {
    return GameSessionIdentity(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
    );
  }
}

class GameSessionEmployee {
  final int id;
  final int? branchId;
  final GameSessionIndividual? individual;

  GameSessionEmployee({required this.id, this.branchId, this.individual});

  factory GameSessionEmployee.fromJson(Map<String, dynamic> json) {
    return GameSessionEmployee(
      id: json['id'] ?? 0,
      branchId: json['branch_id'],
      individual: json['individual'] != null
          ? GameSessionIndividual.fromJson(json['individual'])
          : null,
    );
  }
}

class GameSessionIndividual {
  final String? firstName;
  final String? lastName;
  final String? middleName;

  GameSessionIndividual({this.firstName, this.lastName, this.middleName});

  String get fullName {
    final parts = [
      firstName?.trim(),
      lastName?.trim(),
    ].where((p) => p != null && p.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : '';
  }

  factory GameSessionIndividual.fromJson(Map<String, dynamic> json) {
    return GameSessionIndividual(
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
    );
  }
}
