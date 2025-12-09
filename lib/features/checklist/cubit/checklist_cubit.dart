import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/checklist_template_model.dart';
import '../models/checklist_section_model.dart';
import '../models/checklist_field_model.dart';
import '../models/checklist_submission_model.dart';
import 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  ChecklistCubit() : super(const ChecklistInitial());

  Future<void> loadChecklist(int checklistId) async {
    try {
      emit(const ChecklistLoading());

      await Future.delayed(const Duration(milliseconds: 500));

      final checklist = _getFakeChecklist(checklistId);
      final fieldValues = <int, dynamic>{};

      for (var section in checklist.sections) {
        for (var field in section.fields) {
          fieldValues[field.id] = field.value;
        }
      }

      emit(ChecklistLoaded(
        checklist: checklist,
        fieldValues: fieldValues,
        progress: _calculateProgress(checklist, fieldValues),
      ));
    } catch (e) {
      emit(ChecklistError(message: 'Failed to load checklist: $e'));
    }
  }

  void updateField(int fieldId, dynamic value) {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final updatedValues = Map<int, dynamic>.from(currentState.fieldValues);
      updatedValues[fieldId] = value;

      emit(currentState.copyWith(
        fieldValues: updatedValues,
        progress: _calculateProgress(currentState.checklist, updatedValues),
      ));
    }
  }

  Future<void> submitChecklist(int employeeId) async {
    final currentState = state;
    if (currentState is! ChecklistLoaded) return;

    final validationError = _validateRequiredFields(
      currentState.checklist,
      currentState.fieldValues,
    );

    if (validationError != null) {
      emit(ChecklistError(message: validationError));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
      return;
    }

    try {
      emit(const ChecklistSubmitting());

      await Future.delayed(const Duration(seconds: 1));

      final responses = currentState.fieldValues.entries
          .map((e) => ChecklistFieldResponse(
                fieldId: e.key,
                value: e.value,
                completedAt: DateTime.now(),
              ))
          .toList();

      final submission = ChecklistSubmission(
        checklistId: currentState.checklist.id,
        employeeId: employeeId,
        responses: responses,
        submittedAt: DateTime.now(),
      );

      print('📤 Submitting checklist: ${submission.toJson()}');

      emit(const ChecklistSubmitted());
    } catch (e) {
      emit(ChecklistError(message: 'Failed to submit checklist: $e'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  double _calculateProgress(
    ChecklistTemplate checklist,
    Map<int, dynamic> fieldValues,
  ) {
    int totalRequired = 0;
    int completedRequired = 0;

    for (var section in checklist.sections) {
      for (var field in section.fields) {
        if (field.isRequired) {
          totalRequired++;
          final value = fieldValues[field.id];
          if (_isFieldCompleted(field, value)) {
            completedRequired++;
          }
        }
      }
    }

    return totalRequired > 0 ? completedRequired / totalRequired : 0.0;
  }

  bool _isFieldCompleted(ChecklistField field, dynamic value) {
    if (value == null) return false;

    switch (field.type) {
      case ChecklistFieldType.checkbox:
        return value == true;
      case ChecklistFieldType.text:
      case ChecklistFieldType.number:
        return value.toString().trim().isNotEmpty;
      case ChecklistFieldType.date:
        return value is DateTime;
      case ChecklistFieldType.dropdown:
      case ChecklistFieldType.multiSelect:
        return value != null && value.toString().isNotEmpty;
      default:
        return value != null;
    }
  }

  String? _validateRequiredFields(
    ChecklistTemplate checklist,
    Map<int, dynamic> fieldValues,
  ) {
    for (var section in checklist.sections) {
      for (var field in section.fields) {
        if (field.isRequired) {
          final value = fieldValues[field.id];
          if (!_isFieldCompleted(field, value)) {
            return 'Please complete all required fields: "${field.label}"';
          }
        }
      }
    }
    return null;
  }

  ChecklistTemplate _getFakeChecklist(int checklistId) {
    return ChecklistTemplate(
      id: checklistId,
      title: 'Opening Shift Checklist',
      description: 'Complete all tasks before opening the store',
      dueDate: DateTime.now().add(const Duration(hours: 2)),
      assignedTo: 'Current Employee',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      sections: [
        ChecklistSection(
          id: 1,
          title: 'Store Preparation',
          description: 'Prepare the store for opening',
          order: 1,
          fields: [
            const ChecklistField(
              id: 1,
              type: ChecklistFieldType.checkbox,
              label: 'Unlock main entrance',
              description: 'Ensure all locks are properly opened',
              isRequired: true,
              order: 1,
              value: false,
            ),
            const ChecklistField(
              id: 2,
              type: ChecklistFieldType.checkbox,
              label: 'Turn on all lights',
              isRequired: true,
              order: 2,
              value: false,
            ),
            const ChecklistField(
              id: 3,
              type: ChecklistFieldType.checkbox,
              label: 'Check temperature settings',
              description: 'AC should be at 22°C',
              isRequired: true,
              order: 3,
              value: false,
            ),
            const ChecklistField(
              id: 4,
              type: ChecklistFieldType.text,
              label: 'Notes on store condition',
              description: 'Any issues or observations',
              isRequired: false,
              order: 4,
              value: '',
            ),
          ],
        ),
        ChecklistSection(
          id: 2,
          title: 'Equipment Check',
          description: 'Verify all equipment is working',
          order: 2,
          fields: [
            const ChecklistField(
              id: 5,
              type: ChecklistFieldType.checkbox,
              label: 'Test POS system',
              isRequired: true,
              order: 1,
              value: false,
            ),
            const ChecklistField(
              id: 6,
              type: ChecklistFieldType.checkbox,
              label: 'Check cash register',
              description: 'Verify starting cash amount',
              isRequired: true,
              order: 2,
              value: false,
            ),
            const ChecklistField(
              id: 7,
              type: ChecklistFieldType.number,
              label: 'Starting cash amount (UZS)',
              isRequired: true,
              order: 3,
              value: null,
              metadata: {'min': 0, 'max': 10000000},
            ),
            const ChecklistField(
              id: 8,
              type: ChecklistFieldType.checkbox,
              label: 'Test card payment terminal',
              isRequired: true,
              order: 4,
              value: false,
            ),
          ],
        ),
        ChecklistSection(
          id: 3,
          title: 'Safety & Cleanliness',
          description: 'Ensure safety standards are met',
          order: 3,
          fields: [
            const ChecklistField(
              id: 9,
              type: ChecklistFieldType.checkbox,
              label: 'Check fire extinguisher',
              description: 'Verify expiry date and accessibility',
              isRequired: true,
              order: 1,
              value: false,
            ),
            const ChecklistField(
              id: 10,
              type: ChecklistFieldType.checkbox,
              label: 'Verify emergency exits are clear',
              isRequired: true,
              order: 2,
              value: false,
            ),
            const ChecklistField(
              id: 11,
              type: ChecklistFieldType.checkbox,
              label: 'Clean customer areas',
              isRequired: true,
              order: 3,
              value: false,
            ),
            const ChecklistField(
              id: 12,
              type: ChecklistFieldType.date,
              label: 'Last deep cleaning date',
              isRequired: false,
              order: 4,
              value: null,
            ),
            const ChecklistField(
              id: 13,
              type: ChecklistFieldType.reminder,
              label: 'Schedule next safety inspection',
              description: 'Monthly safety inspection due',
              isRequired: false,
              order: 5,
              metadata: {'reminderDate': '2025-01-15T10:00:00Z'},
            ),
          ],
        ),
        ChecklistSection(
          id: 4,
          title: 'Final Checks',
          description: 'Complete before opening',
          order: 4,
          fields: [
            const ChecklistField(
              id: 14,
              type: ChecklistFieldType.checkbox,
              label: 'All staff members present',
              isRequired: true,
              order: 1,
              value: false,
            ),
            const ChecklistField(
              id: 15,
              type: ChecklistFieldType.checkbox,
              label: 'Opening announcement made',
              isRequired: true,
              order: 2,
              value: false,
            ),
            const ChecklistField(
              id: 16,
              type: ChecklistFieldType.text,
              label: 'Manager signature',
              description: 'Enter your full name',
              isRequired: true,
              order: 3,
              value: '',
            ),
          ],
        ),
      ],
    );
  }
}
