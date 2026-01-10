import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final int id;
  final int checklistId;
  final String name;
  final String? description;
  final bool isActive;
  final int createdBy;
  final int updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool deleted;

  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      checklistId: json['checklist_id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      deleted: json['deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted': deleted,
    };
  }

  @override
  List<Object?> get props => [
        id,
        checklistId,
        name,
        description,
        isActive,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        deletedAt,
        deleted,
      ];
}

class ChecklistBranch extends Equatable {
  final int id;
  final int companyId;
  final int createdBy;
  final int updatedBy;
  final String name;
  final String code;
  final String timezone;
  final String startWork;
  final String endWork;
  final bool isHq;
  final String workDays;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool deleted;

  const ChecklistBranch({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.updatedBy,
    required this.name,
    required this.code,
    required this.timezone,
    required this.startWork,
    required this.endWork,
    required this.isHq,
    required this.workDays,
    this.lat,
    this.lng,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
  });

  factory ChecklistBranch.fromJson(Map<String, dynamic> json) {
    return ChecklistBranch(
      id: json['id'],
      companyId: json['company_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      name: json['name'],
      code: json['code'],
      timezone: json['timezone'],
      startWork: json['start_work'],
      endWork: json['end_work'],
      isHq: json['is_hq'],
      workDays: json['work_days'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      deleted: json['deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'name': name,
      'code': code,
      'timezone': timezone,
      'start_work': startWork,
      'end_work': endWork,
      'is_hq': isHq,
      'work_days': workDays,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted': deleted,
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        createdBy,
        updatedBy,
        name,
        code,
        timezone,
        startWork,
        endWork,
        isHq,
        workDays,
        lat,
        lng,
        createdAt,
        updatedAt,
        deletedAt,
        deleted,
      ];
}

class Checklist extends Equatable {
  final int id;
  final int branchId;
  final String name;
  final String? description;
  final String role;
  final String? shift;
  final bool isActive;
  final int createdBy;
  final int updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool deleted;
  final List<ChecklistItem> items;
  final ChecklistBranch branch;

  const Checklist({
    required this.id,
    required this.branchId,
    required this.name,
    this.description,
    required this.role,
    this.shift,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deleted,
    required this.items,
    required this.branch,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      branchId: json['branch_id'],
      name: json['name'],
      description: json['description'],
      role: json['role'],
      shift: json['shift'],
      isActive: json['is_active'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      deleted: json['deleted'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      branch: ChecklistBranch.fromJson(json['branch']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'role': role,
      'shift': shift,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted': deleted,
      'items': items.map((item) => item.toJson()).toList(),
      'branch': branch.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        name,
        description,
        role,
        shift,
        isActive,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        deletedAt,
        deleted,
        items,
        branch,
      ];
}
