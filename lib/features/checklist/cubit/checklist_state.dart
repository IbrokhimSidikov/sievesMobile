import 'package:equatable/equatable.dart';
import '../models/checklist_template_model.dart';

abstract class ChecklistState extends Equatable {
  const ChecklistState();

  @override
  List<Object?> get props => [];
}

class ChecklistInitial extends ChecklistState {
  const ChecklistInitial();
}

class ChecklistLoading extends ChecklistState {
  const ChecklistLoading();
}

class ChecklistLoaded extends ChecklistState {
  final ChecklistTemplate checklist;
  final Map<int, dynamic> fieldValues;
  final double progress;

  const ChecklistLoaded({
    required this.checklist,
    required this.fieldValues,
    required this.progress,
  });

  ChecklistLoaded copyWith({
    ChecklistTemplate? checklist,
    Map<int, dynamic>? fieldValues,
    double? progress,
  }) {
    return ChecklistLoaded(
      checklist: checklist ?? this.checklist,
      fieldValues: fieldValues ?? this.fieldValues,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [checklist, fieldValues, progress];
}

class ChecklistSubmitting extends ChecklistState {
  const ChecklistSubmitting();
}

class ChecklistSubmitted extends ChecklistState {
  final String message;

  const ChecklistSubmitted({this.message = 'Checklist submitted successfully!'});

  @override
  List<Object?> get props => [message];
}

class ChecklistError extends ChecklistState {
  final String message;

  const ChecklistError({required this.message});

  @override
  List<Object?> get props => [message];
}
