class TrainingTheme {
  final int id;
  final String name;

  TrainingTheme({
    required this.id,
    required this.name,
  });

  factory TrainingTheme.fromJson(Map<String, dynamic> json) {
    return TrainingTheme(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
