import '../models/intro_training.dart';

abstract class ChecklistState {
  const ChecklistState();
}

class ChecklistInitial extends ChecklistState {
  const ChecklistInitial();
}

class ChecklistLoading extends ChecklistState {
  const ChecklistLoading();
}

class ChecklistLoaded extends ChecklistState {
  final IntroEmployeeTrainings data;

  /// checklist item ids currently being toggled (awaiting the server).
  final Set<int> updating;

  const ChecklistLoaded(this.data, {this.updating = const {}});

  ChecklistLoaded copyWith({
    IntroEmployeeTrainings? data,
    Set<int>? updating,
  }) {
    return ChecklistLoaded(
      data ?? this.data,
      updating: updating ?? this.updating,
    );
  }
}

class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);
}
