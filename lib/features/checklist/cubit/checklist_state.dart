import 'package:equatable/equatable.dart';
import '../models/checklist_model.dart';

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
  final Checklist checklist;
  final Map<int, bool> itemStates;
  final Map<int, String> itemNotes;
  final double progress;

  const ChecklistLoaded({
    required this.checklist,
    required this.itemStates,
    required this.itemNotes,
    required this.progress,
  });

  ChecklistLoaded copyWith({
    Checklist? checklist,
    Map<int, bool>? itemStates,
    Map<int, String>? itemNotes,
    double? progress,
  }) {
    return ChecklistLoaded(
      checklist: checklist ?? this.checklist,
      itemStates: itemStates ?? this.itemStates,
      itemNotes: itemNotes ?? this.itemNotes,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [checklist, itemStates, itemNotes, progress];
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
