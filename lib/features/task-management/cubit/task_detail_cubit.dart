import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/task_api.dart';
import '../models/task_model.dart';
import 'task_detail_state.dart';

class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskApi _api;

  TaskDetailCubit(AuthManager authManager)
      : _api = TaskApi(authManager),
        super(const TaskDetailInitial());

  Future<void> load(int taskId) async {
    emit(const TaskDetailLoading());
    try {
      final task = await _api.fetchTask(taskId);
      final comments = await _api.fetchComments(taskId);
      emit(TaskDetailLoaded(task: task, comments: comments));
    } on TaskApiException catch (e) {
      emit(TaskDetailError(e.message));
    } catch (e) {
      emit(TaskDetailError('Error loading task: $e'));
    }
  }

  Future<void> updateStatus(TaskStatus status) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(isUpdatingStatus: true));
    try {
      final updated = await _api.updateStatus(current.task.id, status);
      emit(
        current.copyWith(
          task: current.task.copyWith(status: updated.status),
          isUpdatingStatus: false,
        ),
      );
    } on TaskApiException catch (e) {
      emit(current.copyWith(isUpdatingStatus: false));
      emit(TaskDetailError(e.message));
    }
  }

  Future<void> addComment(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(isSendingComment: true));
    try {
      final comment = await _api.addComment(current.task.id, trimmed);
      emit(
        current.copyWith(
          comments: [...current.comments, comment],
          isSendingComment: false,
        ),
      );
    } on TaskApiException catch (e) {
      emit(current.copyWith(isSendingComment: false));
      emit(TaskDetailError(e.message));
    }
  }

  Future<void> uploadImages(List<File> files) async {
    if (files.isEmpty) return;
    final current = state;
    if (current is! TaskDetailLoaded) return;
    emit(current.copyWith(isUploadingImage: true));
    try {
      final updated = await _api.uploadTaskImages(current.task.id, files);
      emit(
        current.copyWith(
          task: current.task.copyWith(images: updated.images),
          isUploadingImage: false,
        ),
      );
    } on TaskApiException catch (e) {
      emit(current.copyWith(isUploadingImage: false));
      emit(TaskDetailError(e.message));
    }
  }

  Future<void> deleteImage(int imageId) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    final previous = current.task.images;
    // Optimistically remove, restore on failure.
    final remaining =
        previous.where((img) => img.id != imageId).toList();
    emit(current.copyWith(task: current.task.copyWith(images: remaining)));
    try {
      await _api.deleteTaskImage(imageId);
    } on TaskApiException catch (e) {
      emit(current.copyWith(task: current.task.copyWith(images: previous)));
      emit(TaskDetailError(e.message));
    }
  }
}
