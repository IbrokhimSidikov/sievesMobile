import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/employee_model.dart';
import '../../model/identity_model.dart';
import '../auth/auth_service.dart';

class ApiService {
  final String baseUrl = 'https://api.sievesapp.com/api';
  // final String baseUrl = 'https://app.sievesapp.com/v1';
  final Auth0Service authService;

  ApiService(this.authService);

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get identity by Auth0 ID
  Future<Identity?> getIdentityByAuthId(String authId) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'auth_id': authId,
        'expand': ['employee.branch', 'employee.individual', 'employee.reward'].join(','),
      };

      final uri = Uri.parse('$baseUrl/identity/0').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return Identity.fromJson(jsonDecode(response.body));
      } else {
        print('Error getting identity: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getting identity: $e');
      return null;
    }
  }

  // Update identity with token
  Future<Identity?> updateIdentityToken(int id, String token) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/identity/$id');

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        return Identity.fromJson(jsonDecode(response.body));
      } else {
        print('Error updating identity token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception updating identity token: $e');
      return null;
    }
  }

  // Get employee details
  Future<Employee?> getEmployeeDetails(int employeeId) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'expand': ['branch', 'individual', 'jobPosition'].join(','),
      };

      final uri = Uri.parse('$baseUrl/employee/$employeeId').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return Employee.fromJson(jsonDecode(response.body));
      } else {
        print('Error getting employee details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getting employee details: $e');
      return null;
    }
  }

  // Get detailed employee profile data for profile page
  Future<Map<String, dynamic>?> getEmployeeProfileData(int employeeId) async {
    try {
      final headers = await _getHeaders();
      final now = DateTime.now();
      final queryParams = {
        'employeeId': employeeId.toString(),
        'year': now.year.toString(),
        'month': now.month.toString().padLeft(2, '0'),
        'startBonus': _getWeekStart(now),
        'endBonus': _getWeekEnd(now),
        'expand': [
          'individual.photo',
          'branch',
          'jobPosition',
          'identity',
          'workEntries',
          'salaries',
          'activeContract',
          'reward',
          'bonusInfo'
        ].join(','),
      };

      // Use the app API base URL for this endpoint
      final uri = Uri.parse('https://app.sievesapp.com/v1/employee/$employeeId').replace(
        queryParameters: queryParams,
      );

      print('🔍 Fetching employee profile data from: $uri');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Employee profile data received');
        return data;
      } else {
        print('❌ Error getting employee profile data: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting employee profile data: $e');
      return null;
    }
  }

  // Helper method to get week start date (Sunday)
  String _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday % 7));
    return '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get week end date (Saturday)
  String _getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    final endOfWeek = date.add(Duration(days: 6 - (weekday % 7)));
    return '${endOfWeek.year}-${endOfWeek.month.toString().padLeft(2, '0')}-${endOfWeek.day.toString().padLeft(2, '0')}';
  }
}