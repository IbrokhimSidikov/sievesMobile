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
}
