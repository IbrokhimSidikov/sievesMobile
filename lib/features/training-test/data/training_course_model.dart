class TrainingCourse {
  final int id;
  final int companyId;
  final int themeId;
  final int createdBy;
  final int updatedBy;
  final String name;
  final String description;
  final String? pdfUrl;
  final String? videoUrl;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;
  final CourseTheme? theme;

  TrainingCourse({
    required this.id,
    required this.companyId,
    required this.themeId,
    required this.createdBy,
    required this.updatedBy,
    required this.name,
    required this.description,
    this.pdfUrl,
    this.videoUrl,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
    this.theme,
  });

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      themeId: json['theme_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pdfUrl: json['pdf_url'],
      videoUrl: json['video_url'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
      theme: json['theme'] != null ? CourseTheme.fromJson(json['theme']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'theme_id': themeId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'name': name,
      'description': description,
      'pdf_url': pdfUrl,
      'video_url': videoUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'deleted': deleted,
      'theme': theme?.toJson(),
    };
  }
}

class CourseTheme {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final String name;
  final String? videoUrl;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool deleted;

  CourseTheme({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.name,
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
  });

  factory CourseTheme.fromJson(Map<String, dynamic> json) {
    return CourseTheme(
      id: json['id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'] ?? 0,
      name: json['name'] ?? '',
      videoUrl: json['video_url'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      deleted: json['deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'name': name,
      'video_url': videoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'deleted': deleted,
    };
  }
}
