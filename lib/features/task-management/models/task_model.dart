enum TaskStatus { todo, inProgress, review, done, cancelled }

enum TaskPriority { low, normal, high, urgent }

extension TaskStatusX on TaskStatus {
  String get apiValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.review:
        return 'review';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'In Review';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TaskStatus fromApi(String? value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'review':
        return TaskStatus.review;
      case 'done':
        return TaskStatus.done;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

extension TaskPriorityX on TaskPriority {
  String get apiValue {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.normal:
        return 'normal';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  String get displayLabel {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  static TaskPriority fromApi(String? value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'normal':
      default:
        return TaskPriority.normal;
    }
  }
}

class TaskSpaceRef {
  final int id;
  final String name;
  final String? color;
  final int? departmentId;

  const TaskSpaceRef({
    required this.id,
    required this.name,
    this.color,
    this.departmentId,
  });

  factory TaskSpaceRef.fromJson(Map<String, dynamic> json) {
    return TaskSpaceRef(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      color: json['color'] as String?,
      departmentId: json['department_id'] as int?,
    );
  }
}

class DepartmentBrief {
  final int id;
  final String name;
  final int? branchId;

  const DepartmentBrief({
    required this.id,
    required this.name,
    this.branchId,
  });

  factory DepartmentBrief.fromJson(Map<String, dynamic> json) {
    return DepartmentBrief(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      branchId: json['branch_id'] as int?,
    );
  }
}

class EmployeeBrief {
  final int id;
  final String fullName;
  final int? departmentId;
  final String? departmentName;
  final String? photoUrl;

  const EmployeeBrief({
    required this.id,
    required this.fullName,
    this.departmentId,
    this.departmentName,
    this.photoUrl,
  });

  factory EmployeeBrief.fromJson(Map<String, dynamic> json) {
    final individual = json['individual'];
    final firstName = individual is Map
        ? (individual['first_name'] ?? '') as String
        : '';
    final lastName = individual is Map
        ? (individual['last_name'] ?? '') as String
        : '';
    final fullName = ('$firstName $lastName').trim();

    String? photoUrl;
    if (individual is Map && individual['photo'] is Map) {
      final photo = individual['photo'] as Map;
      final path = photo['path'];
      final name = photo['name'];
      final format = photo['format'];
      if (path != null && name != null && format != null) {
        photoUrl =
            'https://sieveserp.ams3.cdn.digitaloceanspaces.com/$path/$name.$format';
      }
    }

    final dept = json['department'];

    return EmployeeBrief(
      id: json['id'] as int,
      fullName: fullName.isEmpty ? 'Employee #${json['id']}' : fullName,
      departmentId: json['department_id'] as int?,
      departmentName: dept is Map ? dept['name'] as String? : null,
      photoUrl: photoUrl,
    );
  }
}

class TaskListRef {
  final int id;
  final String name;
  final String? color;
  final TaskSpaceRef? space;

  const TaskListRef({
    required this.id,
    required this.name,
    this.color,
    this.space,
  });

  factory TaskListRef.fromJson(Map<String, dynamic> json) {
    return TaskListRef(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      color: json['color'] as String?,
      space: json['space'] is Map<String, dynamic>
          ? TaskSpaceRef.fromJson(json['space'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TaskModel {
  final int id;
  final int listId;
  final int? parentTaskId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int? assigneeId;
  final DateTime? dueDate;
  final DateTime? startDate;
  final int? estimatedHours;
  final TaskListRef? list;
  final int subtaskCount;
  final int commentCount;

  const TaskModel({
    required this.id,
    required this.listId,
    this.parentTaskId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.dueDate,
    this.startDate,
    this.estimatedHours,
    this.list,
    this.subtaskCount = 0,
    this.commentCount = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return TaskModel(
      id: json['id'] as int,
      listId: (json['list_id'] ?? 0) as int,
      parentTaskId: json['parent_task_id'] as int?,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      status: TaskStatusX.fromApi(json['status'] as String?),
      priority: TaskPriorityX.fromApi(json['priority'] as String?),
      assigneeId: json['assignee_id'] as int?,
      dueDate: parseDate(json['due_date']),
      startDate: parseDate(json['start_date']),
      estimatedHours: json['estimated_hours'] as int?,
      list: json['list'] is Map<String, dynamic>
          ? TaskListRef.fromJson(json['list'] as Map<String, dynamic>)
          : null,
      subtaskCount: json['subtasks'] is List
          ? (json['subtasks'] as List).length
          : 0,
      commentCount: json['comments'] is List
          ? (json['comments'] as List).length
          : 0,
    );
  }

  TaskModel copyWith({TaskStatus? status}) => TaskModel(
        id: id,
        listId: listId,
        parentTaskId: parentTaskId,
        title: title,
        description: description,
        status: status ?? this.status,
        priority: priority,
        assigneeId: assigneeId,
        dueDate: dueDate,
        startDate: startDate,
        estimatedHours: estimatedHours,
        list: list,
        subtaskCount: subtaskCount,
        commentCount: commentCount,
      );
}
