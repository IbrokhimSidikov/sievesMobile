import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/task_api.dart';
import '../models/task_model.dart';
import 'task_list_state.dart';

class TaskListCubit extends Cubit<TaskListState> {
  final TaskApi _api;

  TaskListCubit(AuthManager authManager)
      : _api = TaskApi(authManager),
        super(const TaskListInitial());

  Future<void> loadMyTasks() async {
    emit(const TaskListLoading());
    try {
      final tasks = await _api.fetchMyTasks();
      emit(TaskListLoaded(tasks: tasks, grouped: _groupByStatus(tasks)));
    } on TaskApiException catch (e) {
      emit(TaskListError(e.message));
    } catch (e) {
      emit(TaskListError('Error loading tasks: $e'));
    }
  }

  Future<void> quickUpdateStatus(int taskId, TaskStatus status) async {
    final current = state;
    if (current is! TaskListLoaded) return;
    try {
      final updated = await _api.updateStatus(taskId, status);
      final newList = current.tasks
          .map((t) => t.id == taskId ? t.copyWith(status: updated.status) : t)
          .toList();
      emit(TaskListLoaded(tasks: newList, grouped: _groupByStatus(newList)));
    } on TaskApiException catch (e) {
      emit(TaskListError(e.message));
    }
  }

  Map<TaskStatus, List<TaskModel>> _groupByStatus(List<TaskModel> tasks) {
    final map = <TaskStatus, List<TaskModel>>{
      for (final s in TaskStatus.values) s: <TaskModel>[],
    };
    for (final t in tasks) {
      map[t.status]!.add(t);
    }
    return map;
  }
}
