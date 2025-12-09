import 'package:equatable/equatable.dart';
import 'checklist_field_model.dart';

class ChecklistSection extends Equatable {
  final int id;
  final String title;
  final String? description;
  final int order;
  final List<ChecklistField> fields;

  const ChecklistSection({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    required this.fields,
  });

  ChecklistSection copyWith({
    int? id,
    String? title,
    String? description,
    int? order,
    List<ChecklistField>? fields,
  }) {
    return ChecklistSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    return ChecklistSection(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      order: json['order'] ?? 0,
      fields: (json['fields'] as List?)
              ?.map((f) => ChecklistField.fromJson(f))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, title, description, order, fields];
}
