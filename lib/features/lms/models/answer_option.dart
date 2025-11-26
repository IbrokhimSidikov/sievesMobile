class AnswerOption {
  final String id;
  final String text;
  final bool isCorrect;

  AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}
