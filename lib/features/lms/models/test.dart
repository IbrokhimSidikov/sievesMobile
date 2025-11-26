import 'question.dart';

class Test {
  final String id;
  final String title;
  final String description;
  final String category;
  final int duration; // in minutes
  final int totalQuestions;
  final int passingScore;
  final String? imageUrl;
  final List<Question>? questions;
  final DateTime? createdAt;
  final bool isCompleted;
  final int? userScore;

  Test({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.totalQuestions,
    required this.passingScore,
    this.imageUrl,
    this.questions,
    this.createdAt,
    this.isCompleted = false,
    this.userScore,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      duration: json['duration'] as int,
      totalQuestions: json['totalQuestions'] as int,
      passingScore: json['passingScore'] as int,
      imageUrl: json['imageUrl'] as String?,
      questions: json['questions'] != null
          ? (json['questions'] as List<dynamic>)
              .map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      userScore: json['userScore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'passingScore': passingScore,
      'imageUrl': imageUrl,
      'questions': questions?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'userScore': userScore,
    };
  }

  Test copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? duration,
    int? totalQuestions,
    int? passingScore,
    String? imageUrl,
    List<Question>? questions,
    DateTime? createdAt,
    bool? isCompleted,
    int? userScore,
  }) {
    return Test(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      passingScore: passingScore ?? this.passingScore,
      imageUrl: imageUrl ?? this.imageUrl,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      userScore: userScore ?? this.userScore,
    );
  }
}
