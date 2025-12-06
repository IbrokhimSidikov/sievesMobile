import 'question.dart';

class Course {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final String name;
  final String description;
  final String pdfUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool deleted;
  final List<Question>? tests;

  Course({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.name,
    required this.description,
    required this.pdfUrl,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
    this.tests,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    List<Question>? tests;
    if (json['tests'] != null) {
      tests = (json['tests'] as List<dynamic>)
          .map((e) => Question.fromApiJson(e as Map<String, dynamic>))
          .toList();
    }
    
    return Course(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      createdBy: json['created_by'] as int,
      updatedBy: json['updated_by'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      pdfUrl: json['pdf_url'] as String,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deleted: json['deleted'] as bool,
      tests: tests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'name': name,
      'description': description,
      'pdf_url': pdfUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted': deleted,
      'tests': tests?.map((e) => e.toJson()).toList(),
    };
  }
}
