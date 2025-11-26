import 'answer_option.dart';
import 'question_type.dart';

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<AnswerOption> options;
  final String? explanation;
  final int points;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    this.explanation,
    this.points = 1,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: (json['options'] as List<dynamic>)
          .map((e) => AnswerOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'options': options.map((e) => e.toJson()).toList(),
      'explanation': explanation,
      'points': points,
    };
  }
}
