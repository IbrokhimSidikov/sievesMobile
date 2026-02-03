class TrainingEvent {
  final String id;
  final String title;
  final DateTime date;
  final String? time;
  final String description;
  final String category;
  final String? videoUrl;

  TrainingEvent({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    required this.description,
    required this.category,
    this.videoUrl,
  });

  factory TrainingEvent.fromJson(Map<String, dynamic> json) {
    return TrainingEvent(
      id: json['id'].toString(),
      title: json['title'] ?? json['name'] ?? 'Training',
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      time: json['time'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      videoUrl: json['video_url'] ?? json['videoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'time': time,
      'description': description,
      'category': category,
      'videoUrl': videoUrl,
    };
  }
}
