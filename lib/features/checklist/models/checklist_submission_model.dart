import 'package:equatable/equatable.dart';

class ChecklistSubmission extends Equatable {
  final int checklistId;
  final int employeeId;
  final List<ChecklistFieldResponse> responses;
  final DateTime submittedAt;
  final String? notes;

  const ChecklistSubmission({
    required this.checklistId,
    required this.employeeId,
    required this.responses,
    required this.submittedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'checklistId': checklistId,
      'employeeId': employeeId,
      'responses': responses.map((r) => r.toJson()).toList(),
      'submittedAt': submittedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory ChecklistSubmission.fromJson(Map<String, dynamic> json) {
    return ChecklistSubmission(
      checklistId: json['checklistId'],
      employeeId: json['employeeId'],
      responses: (json['responses'] as List)
          .map((r) => ChecklistFieldResponse.fromJson(r))
          .toList(),
      submittedAt: DateTime.parse(json['submittedAt']),
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props => [checklistId, employeeId, responses, submittedAt, notes];
}

class ChecklistFieldResponse extends Equatable {
  final int fieldId;
  final dynamic value;
  final DateTime? completedAt;

  const ChecklistFieldResponse({
    required this.fieldId,
    required this.value,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'value': value,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChecklistFieldResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistFieldResponse(
      fieldId: json['fieldId'],
      value: json['value'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [fieldId, value, completedAt];
}
