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

  const ChecklistListLoaded({required this.checklists});

  @override
  List<Object?> get props => [checklists];
}

class ChecklistListError extends ChecklistListState {
  final String message;

  const ChecklistListError({required this.message});

  @override
  List<Object?> get props => [message];
}
