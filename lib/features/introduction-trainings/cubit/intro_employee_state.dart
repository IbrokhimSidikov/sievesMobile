import '../../task-management/models/task_model.dart' show EmployeeBrief;

/// A single employee's overall intro-training completion, shown as a badge on
/// the employee list.
class EmployeeProgress {
  final int percent;
  final int completed;
  final int total;

  const EmployeeProgress({
    required this.percent,
    required this.completed,
    required this.total,
  });
}

abstract class IntroEmployeeState {
  const IntroEmployeeState();
}

class IntroEmployeeInitial extends IntroEmployeeState {
  const IntroEmployeeInitial();
}

class IntroEmployeeLoading extends IntroEmployeeState {
  const IntroEmployeeLoading();
}

class IntroEmployeeLoaded extends IntroEmployeeState {
  final List<EmployeeBrief> employees;

  /// Resolved completion per employee id. Absent = still loading.
  final Map<int, EmployeeProgress> progress;

  const IntroEmployeeLoaded(this.employees, {this.progress = const {}});

  IntroEmployeeLoaded copyWith({
    List<EmployeeBrief>? employees,
    Map<int, EmployeeProgress>? progress,
  }) {
    return IntroEmployeeLoaded(
      employees ?? this.employees,
      progress: progress ?? this.progress,
    );
  }
}

class IntroEmployeeError extends IntroEmployeeState {
  final String message;
  const IntroEmployeeError(this.message);
}
