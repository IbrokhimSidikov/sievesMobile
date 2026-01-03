import 'question.dart';
import 'course.dart';

class Test {
  final String id;
  final String title;
  final String description;
  final String category;
  final int duration;
  final int totalQuestions;
  final int passingScore;
  final String? imageUrl;
  final String? courseUrl;
  final String? videoUrl;
  final List<Question>? questions;
  final DateTime? createdAt;
  final bool isCompleted;
  final bool courseCompleted;
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
    this.courseUrl,
    this.videoUrl,
    this.questions,
    this.createdAt,
    this.isCompleted = false,
    this.courseCompleted = false,
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
      courseUrl: json['courseUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      questions: json['questions'] != null
          ? (json['questions'] as List<dynamic>)
              .map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      courseCompleted: json['courseCompleted'] as bool? ?? false,
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
      'courseUrl': courseUrl,
      'videoUrl': videoUrl,
      'questions': questions?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'courseCompleted': courseCompleted,
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
    String? courseUrl,
    String? videoUrl,
    List<Question>? questions,
    DateTime? createdAt,
    bool? isCompleted,
    bool? courseCompleted,
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
      courseUrl: courseUrl ?? this.courseUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      courseCompleted: courseCompleted ?? this.courseCompleted,
      userScore: userScore ?? this.userScore,
    );
  }

  factory Test.fromCourse(Course course) {
    final questionCount = course.tests?.length ?? 10;
    
    return Test(
      id: course.id.toString(),
      title: course.name,
      description: course.description,
      category: course.category ?? 'Training',
      duration: 15,
      totalQuestions: questionCount,
      passingScore: 70,
      imageUrl: null,
      courseUrl: course.pdfUrl,
      videoUrl: course.videoUrl,
      questions: course.tests,
      createdAt: course.createdAt,
      isCompleted: false,
      courseCompleted: false,
    );
  }
}
