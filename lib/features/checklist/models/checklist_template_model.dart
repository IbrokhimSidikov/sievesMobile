import 'package:equatable/equatable.dart';
import 'checklist_section_model.dart';

class ChecklistTemplate extends Equatable {
  final int id;
  final String title;
  final String? description;
  final List<ChecklistSection> sections;
  final DateTime? dueDate;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChecklistTemplate({
    required this.id,
    required this.title,
    this.description,
    required this.sections,
    this.dueDate,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  ChecklistTemplate copyWith({
    int? id,
    String? title,
    String? description,
    List<ChecklistSection>? sections,
    DateTime? dueDate,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sections: sections ?? this.sections,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sections': sections.map((s) => s.toJson()).toList(),
      'dueDate': dueDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplate(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      sections: (json['sections'] as List?)
              ?.map((s) => ChecklistSection.fromJson(s))
              .toList() ??
          [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assignedTo: json['assignedTo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [id, title, description, sections, dueDate, assignedTo, createdAt, updatedAt];
}
