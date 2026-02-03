class TrainingEvent {
  final String id;
  final String title;
  final DateTime date;
  final String? time;
  final String description;
  final String category;
  final String? videoUrl;
  final int? trainingThemeId;

  TrainingEvent({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    required this.description,
    required this.category,
    this.videoUrl,
    this.trainingThemeId,
  });

  factory TrainingEvent.fromJson(Map<String, dynamic> json) {
    // Extract video URL from nested trainingTheme if available
    String? videoUrl;
    if (json['trainingTheme'] != null && json['trainingTheme']['video_url'] != null) {
      videoUrl = json['trainingTheme']['video_url'];
    } else {
      videoUrl = json['video_url'] ?? json['videoUrl'];
    }

    // Extract description from trainingTheme name if available
    String description = '';
    if (json['trainingTheme'] != null && json['trainingTheme']['name'] != null) {
      description = json['trainingTheme']['name'];
    } else {
      description = json['description'] ?? '';
    }

    return TrainingEvent(
      id: json['id'].toString(),
      title: json['name'] ?? json['title'] ?? 'Training',
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      time: json['time'],
      description: description,
      category: json['category'] ?? 'General',
      videoUrl: videoUrl,
      trainingThemeId: json['training_theme_id'],
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
