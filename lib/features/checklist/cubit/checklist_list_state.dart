import 'package:equatable/equatable.dart';
import '../models/checklist_model.dart';

abstract class ChecklistListState extends Equatable {
  const ChecklistListState();

  @override
  List<Object?> get props => [];
}

class ChecklistListInitial extends ChecklistListState {
  const ChecklistListInitial();
}

class ChecklistListLoading extends ChecklistListState {
  const ChecklistListLoading();
}

class ChecklistListLoaded extends ChecklistListState {
  final List<Checklist> checklists;
  final Set<int> submittedChecklistIds;

  const ChecklistListLoaded({
    required this.checklists,
    this.submittedChecklistIds = const {},
  });

  @override
  List<Object?> get props => [checklists, submittedChecklistIds];
}

class ChecklistListError extends ChecklistListState {
  final String message;

  const ChecklistListError({required this.message});

  @override
  List<Object?> get props => [message];
}
