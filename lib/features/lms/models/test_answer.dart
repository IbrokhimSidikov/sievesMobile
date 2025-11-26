class TestAnswer {
  final String questionId;
  final List<String> selectedOptionIds;
  final bool isCorrect;

  TestAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    this.isCorrect = false,
  });

  TestAnswer copyWith({
    String? questionId,
    List<String>? selectedOptionIds,
    bool? isCorrect,
  }) {
    return TestAnswer(
      questionId: questionId ?? this.questionId,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
