import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/employee_model.dart';
import '../../model/identity_model.dart';
import '../auth/auth_service.dart';

class ApiService {
  final String baseUrl = 'https://api.sievesapp.com/api';
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
}