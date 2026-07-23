import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/services/auth/auth_manager.dart';
import '../../task-management/models/task_model.dart' show EmployeeBrief;
import '../models/intro_training.dart';

class IntroApiException implements Exception {
  final String message;
  final int? statusCode;
  IntroApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Data source for the introduction-trainings feature.
///
/// Employees are read from the v1 endpoint (the only one that filters by
/// branch); the onboarding checklist is read from v3 `trained-employee`.
class IntroApi {
  static const String _v3BaseUrl = 'https://api.v3.sievesapp.com';
  static const String _v1BaseUrl = 'https://app.sievesapp.com/v1';

  final AuthManager _authManager;
  IntroApi(this._authManager);

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authManager.authService.getAccessToken();
    if (token == null) throw IntroApiException('Not authenticated');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Employees belonging to the current user's branch, sorted by name.
  Future<List<EmployeeBrief>> fetchBranchEmployees({int? branchId}) async {
    final id = branchId ?? _authManager.currentIdentity?.employee?.branchId;
    if (id == null) throw IntroApiException('Branch not found for user');

    final url = Uri.parse('$_v1BaseUrl/employee').replace(queryParameters: {
      'branch_id': '$id',
      'pagination': '0',
      'expand': 'individual,individual.photo,department',
    });

    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw IntroApiException(
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

    final employees = list
        .map((e) => EmployeeBrief.fromJson(e as Map<String, dynamic>))
        .where((e) => e.branchId == id)
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          ));
    return employees;
  }

  /// Intro trainings + checklist completion status for an employee.
  Future<IntroEmployeeTrainings> fetchEmployeeTrainings(int employeeId) async {
    final url = Uri.parse('$_v3BaseUrl/intro-training/employee/$employeeId');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      throw IntroApiException(
        'Failed to load trainings',
        statusCode: res.statusCode,
      );
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    return IntroEmployeeTrainings.fromJson(decoded);
  }

  /// Mark or unmark a checklist item for an employee (trainer/manager only).
  Future<void> setCompletion({
    required int employeeId,
    required int checklistId,
    required bool completed,
  }) async {
    final url = Uri.parse('$_v3BaseUrl/intro-training/completion');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: json.encode({
        'employee_id': employeeId,
        'checklist_id': checklistId,
        'completed': completed,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw IntroApiException(
        'Failed to update checklist item',
        statusCode: res.statusCode,
      );
    }
  }
}
