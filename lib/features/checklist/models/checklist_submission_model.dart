import 'package:equatable/equatable.dart';

class ChecklistSubmission extends Equatable {
  final int id;
  final int checklistId;
  final int submittedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Checklist checklist;
  final List<SubmissionItem> submissionItems;

  const ChecklistSubmission({
    required this.id,
    required this.checklistId,
    required this.submittedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.checklist,
    required this.submissionItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'submitted_by': submittedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'checklist': checklist.toJson(),
      'submission_items': submissionItems.map((item) => item.toJson()).toList(),
    };
  }

  factory ChecklistSubmission.fromJson(Map<String, dynamic> json) {
    return ChecklistSubmission(
      id: json['id'],
      checklistId: json['checklist_id'],
      submittedBy: json['submitted_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      checklist: Checklist.fromJson(json['checklist']),
      submissionItems: (json['submission_items'] as List)
          .map((item) => SubmissionItem.fromJson(item))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, checklistId, submittedBy, createdAt, updatedAt, checklist, submissionItems];
}

class Checklist extends Equatable {
  final int id;
  final int branchId;
  final String name;
  final String? description;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Checklist({
    required this.id,
    required this.branchId,
    required this.name,
    this.description,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      branchId: json['branch_id'],
      name: json['name'],
      description: json['description'],
      role: json['role'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, branchId, name, description, role, isActive, createdAt, updatedAt];
}

class SubmissionItem extends Equatable {
  final int id;
  final int submissionId;
  final int checklistItemId;
  final bool isChecked;
  final String note;
  final ChecklistItem checklistItem;

  const SubmissionItem({
    required this.id,
    required this.submissionId,
    required this.checklistItemId,
    required this.isChecked,
    required this.note,
    required this.checklistItem,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submission_id': submissionId,
      'checklist_item_id': checklistItemId,
      'is_checked': isChecked,
      'note': note,
      'checklist_item': checklistItem.toJson(),
    };
  }

  factory SubmissionItem.fromJson(Map<String, dynamic> json) {
    return SubmissionItem(
      id: json['id'],
      submissionId: json['submission_id'],
      checklistItemId: json['checklist_item_id'],
      isChecked: json['is_checked'],
      note: json['note'],
      checklistItem: ChecklistItem.fromJson(json['checklist_item']),
    );
  }

  @override
  List<Object?> get props => [id, submissionId, checklistItemId, isChecked, note, checklistItem];
}

class ChecklistItem extends Equatable {
  final int id;
  final int checklistId;
  final String name;
  final String? description;
  final bool isActive;

  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.name,
    this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      checklistId: json['checklist_id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
    );
  }

  @override
  List<Object?> get props => [id, checklistId, name, description, isActive];
}
