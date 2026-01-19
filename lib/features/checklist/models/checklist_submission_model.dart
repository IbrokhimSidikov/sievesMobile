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
      id: json['id'] ?? 0,
      checklistId: json['checklist_id'] ?? 0,
      submittedBy: json['submitted_by'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      checklist: json['checklist'] != null ? Checklist.fromJson(json['checklist']) : const Checklist(
        id: 0,
        branchId: 0,
        name: 'Unknown',
        role: 'Unknown',
        isActive: false,
        createdAt: null,
        updatedAt: null,
      ),
      submissionItems: (json['submission_items'] as List?)
          ?.map((item) => item != null ? SubmissionItem.fromJson(item) : null)
          .whereType<SubmissionItem>()
          .toList() ?? [],
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      role: json['role'] ?? 'Unknown',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
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
      id: json['id'] ?? 0,
      submissionId: json['submission_id'] ?? 0,
      checklistItemId: json['checklist_item_id'] ?? 0,
      isChecked: json['is_checked'] ?? false,
      note: json['note'] ?? '',
      checklistItem: json['checklist_item'] != null ? ChecklistItem.fromJson(json['checklist_item']) : const ChecklistItem(
        id: 0,
        checklistId: 0,
        name: 'Unknown',
        isActive: false,
      ),
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
      id: json['id'] ?? 0,
      checklistId: json['checklist_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      isActive: json['is_active'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, checklistId, name, description, isActive];
}
