class Story {
  final String id;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final DateTime createdAt;
  final bool isViewed;

  Story({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.createdAt,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'].toString(),
      videoUrl: json['video_url'] ?? json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      duration: json['duration'] ?? 60,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isViewed: json['is_viewed'] ?? json['isViewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'is_viewed': isViewed,
    };
  }

  Story copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    DateTime? createdAt,
    bool? isViewed,
  }) {
    return Story(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

/// Represents a collection of stories.
/// Can be used for admin stories (shown to all users) or user-specific stories.
/// For admin stories: userId/userName/userPhoto represent the company/admin info.
class UserStories {
  final String userId;
  final String userName;
  final String? userPhoto;
  final List<Story> stories;
  final bool hasUnviewedStories;

  UserStories({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.stories,
    bool? hasUnviewedStories,
  }) : hasUnviewedStories = hasUnviewedStories ?? stories.any((s) => !s.isViewed);

  factory UserStories.fromJson(Map<String, dynamic> json) {
    return UserStories(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user_name'] ?? json['userName'] ?? 'User',
      userPhoto: json['user_photo'] ?? json['userPhoto'],
      stories: (json['stories'] as List<dynamic>?)
              ?.map((s) => Story.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_photo': userPhoto,
      'stories': stories.map((s) => s.toJson()).toList(),
      'has_unviewed_stories': hasUnviewedStories,
    };
  }
}
