import '../models/task_model.dart';

abstract class TaskListState {
  const TaskListState();
}

class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  final List<TaskModel> tasks;
  final Map<TaskStatus, List<TaskModel>> grouped;

  const TaskListLoaded({required this.tasks, required this.grouped});
}

class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);
}
