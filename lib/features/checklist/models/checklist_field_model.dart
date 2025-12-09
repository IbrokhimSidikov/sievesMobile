import 'package:equatable/equatable.dart';

enum ChecklistFieldType {
  checkbox,
  text,
  number,
  date,
  reminder,
  photo,
  signature,
  dropdown,
  multiSelect,
}

class ChecklistField extends Equatable {
  final int id;
  final ChecklistFieldType type;
  final String label;
  final String? description;
  final bool isRequired;
  final int order;
  final dynamic value;
  final Map<String, dynamic>? metadata;

  const ChecklistField({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    required this.isRequired,
    required this.order,
    this.value,
    this.metadata,
  });

  ChecklistField copyWith({
    int? id,
    ChecklistFieldType? type,
    String? label,
    String? description,
    bool? isRequired,
    int? order,
    dynamic value,
    Map<String, dynamic>? metadata,
  }) {
    return ChecklistField(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      order: order ?? this.order,
      value: value ?? this.value,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'description': description,
      'isRequired': isRequired,
      'order': order,
      'value': value,
      'metadata': metadata,
    };
  }

  factory ChecklistField.fromJson(Map<String, dynamic> json) {
    return ChecklistField(
      id: json['id'],
      type: ChecklistFieldType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChecklistFieldType.text,
      ),
      label: json['label'],
      description: json['description'],
      isRequired: json['isRequired'] ?? false,
      order: json['order'] ?? 0,
      value: json['value'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [id, type, label, description, isRequired, order, value, metadata];
}
