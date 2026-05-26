class TaskCommentAuthor {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? photoPath;
  final String? photoName;
  final String? photoFormat;

  const TaskCommentAuthor({
    required this.id,
    this.firstName,
    this.lastName,
    this.photoPath,
    this.photoName,
    this.photoFormat,
  });

  String? get photoUrl {
    if (photoPath == null || photoName == null || photoFormat == null) {
      return null;
    }
    return 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/$photoPath/$photoName.$photoFormat';
  }

  String get displayName {
    final f = firstName?.trim();
    final l = lastName?.trim();
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) {
      return 'Employee #$id';
    }
    return [f, l].where((s) => s != null && s.isNotEmpty).join(' ');
  }

  String get initials {
    final f = firstName?.trim();
    final l = lastName?.trim();
    final fi = (f != null && f.isNotEmpty) ? f[0].toUpperCase() : '';
    final li = (l != null && l.isNotEmpty) ? l[0].toUpperCase() : '';
    final result = '$fi$li';
    return result.isEmpty ? '#' : result;
  }

  factory TaskCommentAuthor.fromEmployeeJson(Map<String, dynamic> json) {
    final individual = json['individual'] is Map<String, dynamic>
        ? json['individual'] as Map<String, dynamic>
        : null;
    final photo = individual?['photo'] is Map<String, dynamic>
        ? individual!['photo'] as Map<String, dynamic>
        : null;

    return TaskCommentAuthor(
      id: (json['id'] ?? 0) as int,
      firstName: individual?['first_name'] as String?,
      lastName: individual?['last_name'] as String?,
      photoPath: photo?['path'] as String?,
      photoName: photo?['name'] as String?,
      photoFormat: photo?['format'] as String?,
    );
  }
}

class TaskCommentModel {
  final int id;
  final int taskId;
  final String content;
  final int? authorId;
  final TaskCommentAuthor? author;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.content,
    this.authorId,
    this.author,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    final authorJson = json['author'];
    return TaskCommentModel(
      id: json['id'] as int,
      taskId: (json['task_id'] ?? 0) as int,
      content: (json['content'] ?? '') as String,
      authorId: json['author_id'] as int?,
      author: authorJson is Map<String, dynamic>
          ? TaskCommentAuthor.fromEmployeeJson(authorJson)
          : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
