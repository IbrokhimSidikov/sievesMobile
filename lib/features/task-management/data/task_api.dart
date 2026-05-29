import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth/auth_manager.dart';
import '../models/task_comment_model.dart';
import '../models/task_model.dart';

class TaskApiException implements Exception {
  final String message;
  final int? statusCode;
  TaskApiException(this.message, {this.statusCode});
  @override
  String toString() => 'TaskApiException($statusCode): $message';
}

class TaskApi {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const String _v1BaseUrl = 'https://app.sievesapp.com/v1';
  final AuthManager _authManager;

  TaskApi(this._authManager);

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authManager.authService.getAccessToken();
    if (token == null) {
      throw TaskApiException('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<TaskModel>> fetchMyTasks({int? assigneeId}) async {
    final id = assigneeId ?? _authManager.currentEmployeeId;
    if (id == null) {
      throw TaskApiException('Employee ID not found');
    }
    final url = Uri.parse('$_baseUrl/task?assignee_id=$id');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load tasks',
        statusCode: res.statusCode,
      );
    }
    final List<dynamic> list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaskModel> fetchTask(int id) async {
    final url = Uri.parse('$_baseUrl/task/$id');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load task',
        statusCode: res.statusCode,
      );
    }
    return TaskModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<TaskModel> updateStatus(int id, TaskStatus status) async {
    final url =
        Uri.parse('$_baseUrl/task/$id/status?status=${status.apiValue}');
    final res = await http.patch(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to update status',
        statusCode: res.statusCode,
      );
    }
    return TaskModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<List<TaskCommentModel>> fetchComments(int taskId) async {
    final url = Uri.parse('$_baseUrl/task/$taskId/comments');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load comments',
        statusCode: res.statusCode,
      );
    }
    final List<dynamic> list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => TaskCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaskCommentModel> addComment(int taskId, String content) async {
    final url = Uri.parse('$_baseUrl/task/comment');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: json.encode({'task_id': taskId, 'content': content}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw TaskApiException(
        'Failed to add comment',
        statusCode: res.statusCode,
      );
    }
    return TaskCommentModel.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    );
  }

  Future<TaskModel> createTask({
    required int listId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.normal,
    List<int> assigneeIds = const [],
    DateTime? dueDate,
    DateTime? startDate,
  }) async {
    final url = Uri.parse('$_baseUrl/task');
    final body = <String, dynamic>{
      'list_id': listId,
      'title': title,
      'priority': priority.apiValue,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (assigneeIds.isNotEmpty) {
      body['assignee_ids'] = assigneeIds;
    }
    if (dueDate != null) {
      body['due_date'] = dueDate.toUtc().toIso8601String();
    }
    if (startDate != null) {
      body['start_date'] = startDate.toUtc().toIso8601String();
    }
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: json.encode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw TaskApiException(
        'Failed to create task',
        statusCode: res.statusCode,
      );
    }
    return TaskModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<List<TaskSpaceRef>> fetchSpaces({int? departmentId}) async {
    final qp = <String, String>{};
    if (departmentId != null) qp['department_id'] = '$departmentId';
    final url = Uri.parse('$_baseUrl/task/space')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load spaces',
        statusCode: res.statusCode,
      );
    }
    final List<dynamic> list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => TaskSpaceRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TaskListRef>> fetchLists({int? spaceId}) async {
    final qp = <String, String>{};
    if (spaceId != null) qp['space_id'] = '$spaceId';
    final url = Uri.parse('$_baseUrl/task/list')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load lists',
        statusCode: res.statusCode,
      );
    }
    final List<dynamic> list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => TaskListRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DepartmentBrief>> fetchDepartments({int? branchId}) async {
    final qp = <String, String>{'pagination': '0'};
    if (branchId != null) qp['branch_id'] = '$branchId';
    final url =
        Uri.parse('$_v1BaseUrl/department').replace(queryParameters: qp);
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load departments',
        statusCode: res.statusCode,
      );
    }
    final decoded = json.decode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List
            ? decoded['items'] as List<dynamic>
            : const <dynamic>[]);
    final all = list
        .map((e) => DepartmentBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    // Guard: server may ignore unknown query params, so also filter client-side.
    if (branchId == null) return all;
    return all.where((d) => d.branchId == branchId).toList();
  }

  Future<List<EmployeeBrief>> fetchEmployees({int? departmentId}) async {
    final qp = <String, String>{
      'pagination': '0',
      'expand': 'individual,individual.photo,department',
    };
    if (departmentId != null) qp['department_id'] = '$departmentId';
    final url =
        Uri.parse('$_v1BaseUrl/employee').replace(queryParameters: qp);
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw TaskApiException(
        'Failed to load employees',
        statusCode: res.statusCode,
      );
    }
    final decoded = json.decode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List
            ? decoded['items'] as List<dynamic>
            : const <dynamic>[]);
    return list
        .map((e) => EmployeeBrief.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
