import '../models/task_comment_model.dart';
import '../models/task_model.dart';

abstract class TaskDetailState {
  const TaskDetailState();
}

class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

class TaskDetailLoaded extends TaskDetailState {
  final TaskModel task;
  final List<TaskCommentModel> comments;
  final bool isUpdatingStatus;
  final bool isSendingComment;
  final bool isUploadingImage;

  const TaskDetailLoaded({
    required this.task,
    required this.comments,
    this.isUpdatingStatus = false,
    this.isSendingComment = false,
    this.isUploadingImage = false,
  });

  TaskDetailLoaded copyWith({
    TaskModel? task,
    List<TaskCommentModel>? comments,
    bool? isUpdatingStatus,
    bool? isSendingComment,
    bool? isUploadingImage,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      comments: comments ?? this.comments,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isSendingComment: isSendingComment ?? this.isSendingComment,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }
}

class TaskDetailError extends TaskDetailState {
  final String message;
  const TaskDetailError(this.message);
}
