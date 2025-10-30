import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/employee_model.dart';
import '../../model/identity_model.dart';
import '../../model/work_entry_model.dart';
import '../../model/break_order_model.dart';
import '../../model/history_model.dart';
import '../auth/auth_service.dart';
import 'http_client.dart';

class ApiService {
  final String baseUrl = 'https://app.sievesapp.com/v1';
  // final String baseUrl = 'https://app.sievesapp.com/v1';
  final AuthService authService;
  late final AuthHttpClient _httpClient;
  
  // Callback for when token refresh fails (logout needed)
  Function()? onTokenRefreshFailed;

  ApiService(this.authService) {
    _httpClient = AuthHttpClient(
      authService,
      onRefreshFailed: () {
        print('⚠️ Token refresh failed completely - logout required');
        onTokenRefreshFailed?.call();
      },
    );
  }

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

      // test uri
      // final uri = Uri.parse('https://app.sievesapp.com/v1/identity/0?auth_id=auth0%7C65bcde009830a9e7bbce75d4&expand=employee.branch,employee.individual,employee.reward');

      final response = await _httpClient.get(uri, headers: headers);

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

      final response = await _httpClient.put(
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

      final response = await _httpClient.get(uri, headers: headers);

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
      final response = await _httpClient.get(uri, headers: headers);

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

  // Get work entries for a given date range with pagination support
  Future<Map<String, dynamic>?> getWorkEntries(
    int employeeId, 
    String startDate, 
    String endDate, {
    int? page,
    int? limit,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'employee_id': employeeId.toString(),
        'date_range': '$startDate,$endDate',
      };

      // Add pagination parameters if provided
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('$baseUrl/work-entry').replace(
        queryParameters: queryParams,
      );

      print('📋 Request URL: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('📊 JSON Type: ${jsonData.runtimeType}');
        print('📊 JSON Data: $jsonData');
        
        // Handle both array and object responses
        List<dynamic> entriesList;
        Map<String, dynamic>? metadata;
        
        if (jsonData is List) {
          entriesList = jsonData;
        } else if (jsonData is Map) {
          if (jsonData.containsKey('models')) {
            entriesList = jsonData['models'] as List;
            // Extract pagination metadata if available
            metadata = {
              'total': jsonData['total'],
              'page': jsonData['page'],
              'limit': jsonData['limit'],
              'hasMore': jsonData['hasMore'] ?? false,
            };
          } else if (jsonData.containsKey('data')) {
            entriesList = jsonData['data'] as List;
            metadata = jsonData['meta'];
          } else {
            print('❌ Unexpected response format: $jsonData');
            return null;
          }
        } else {
          print('❌ Unexpected response format: $jsonData');
          return null;
        }
        
        final entries = entriesList.map((json) => WorkEntry.fromJson(json)).toList();
        print('✅ Found ${entries.length} work entries');
        
        return {
          'entries': entries,
          'metadata': metadata,
          'total': entries.length,
        };
      } else {
        print('Error getting work entries: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getting work entries: $e');
      return null;
    }
  }

  // Get work entries for an employee within a date range
  Future<List<WorkEntry>> getWorkEntriesInRange(int employeeId, String dateRange) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/work-entry').replace(
        queryParameters: {
          'employee_id': employeeId.toString(),
          'date_range': dateRange,
        },
      );

      print('📅 Fetching work entries: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final entries = data.map((json) => WorkEntry.fromJson(json)).toList();
        print('✅ Fetched ${entries.length} work entries');
        return entries;
      } else {
        print('❌ Error getting work entries: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting work entries: $e');
      return [];
    }
  }

  // Get work entries by type (e.g., VACATION, ATTENDANCE)
  Future<Map<String, dynamic>?> getWorkEntriesByType({
    required int employeeId,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'employee_id': employeeId.toString(),
      };

      if (type != null) {
        queryParams['type'] = type;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (startDate != null && endDate != null) {
        queryParams['date_range'] = '$startDate,$endDate';
      }

      final uri = Uri.parse('$baseUrl/work-entry').replace(
        queryParameters: queryParams,
      );

      print('📋 Fetching work entries by type: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Handle both array and object responses
        List<dynamic> entriesList;
        int totalCount = 0;
        
        if (jsonData is List) {
          entriesList = jsonData;
          totalCount = entriesList.length;
        } else if (jsonData is Map) {
          if (jsonData.containsKey('models')) {
            entriesList = jsonData['models'] as List;
            totalCount = jsonData['_meta']?['totalCount'] ?? entriesList.length;
          } else if (jsonData.containsKey('data')) {
            entriesList = jsonData['data'] as List;
            totalCount = jsonData['meta']?['total'] ?? entriesList.length;
          } else {
            print('❌ Unexpected response format: $jsonData');
            return null;
          }
        } else {
          print('❌ Unexpected response format: $jsonData');
          return null;
        }
        
        final entries = entriesList.map((json) => WorkEntry.fromJson(json)).toList();
        print('✅ Fetched ${entries.length} work entries (type: $type, status: $status)');
        
        return {
          'entries': entries,
          'totalCount': totalCount,
        };
      } else {
        print('❌ Error getting work entries by type: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting work entries by type: $e');
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

  // Get break orders for an employee within a date range
  Future<List<BreakOrder>> getBreakOrders(int breakEmployeeId, {String? startDate, String? endDate}) async {
    try {
      final headers = await _getHeaders();
      
      // If dates not provided, use current month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final start = startDate ?? '${firstDayOfMonth.year}-${firstDayOfMonth.month.toString().padLeft(2, '0')}-${firstDayOfMonth.day.toString().padLeft(2, '0')}';
      final end = endDate ?? '${lastDayOfMonth.year}-${lastDayOfMonth.month.toString().padLeft(2, '0')}-${lastDayOfMonth.day.toString().padLeft(2, '0')}';
      
      final queryParams = {
        'orderType': 'break',
        'break_employee_id': breakEmployeeId.toString(),
        'expand': 'orderItems.product,breakPhoto',
        'dateRange': '$start,$end',
      };

      final uri = Uri.parse('$baseUrl/order').replace(
        queryParameters: queryParams,
      );

      print('🍔 Fetching break orders: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('📊 JSON Type: ${jsonData.runtimeType}');
        
        // Handle both array and object responses
        List<dynamic> ordersList;
        if (jsonData is List) {
          ordersList = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('models')) {
          ordersList = jsonData['models'] as List;
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          ordersList = jsonData['data'] as List;
        } else {
          print('❌ Unexpected response format: $jsonData');
          return [];
        }
        
        final orders = ordersList.map((json) => BreakOrder.fromJson(json)).toList();
        print('✅ Fetched ${orders.length} break orders');
        return orders;
      } else {
        print('❌ Error getting break orders: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting break orders: $e');
      return [];
    }
  }

  // Get break orders for the current month
  Future<List<BreakOrder>?> getBreakOrdersForCurrentMonth(int employeeId) async {
    try {
      final headers = await _getHeaders();
      final now = DateTime.now();
      final queryParams = {
        'employee_id': employeeId.toString(),
        'year': now.year.toString(),
        'month': now.month.toString().padLeft(2, '0'),
      };

      final uri = Uri.parse('$baseUrl/break-order').replace(
        queryParameters: queryParams,
      );

      print('📅 Fetching break orders: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final breakOrders = data.map((json) => BreakOrder.fromJson(json)).toList();
        print('✅ Fetched ${breakOrders.length} break orders');
        return breakOrders;
      } else {
        print('❌ Error getting break orders: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting break orders: $e');
      return null;
    }
  }

  // Get history records for an employee
  Future<List<HistoryRecord>?> getHistory(int employeeId) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'employee_id': employeeId.toString(),
        'expand': 'branch',
      };

      final uri = Uri.parse('$baseUrl/history').replace(
        queryParameters: queryParams,
      );

      print('📜 Fetching history records: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📋 Response type: ${responseData.runtimeType}');
        print('📋 Response data: $responseData');
        
        // Handle both direct list and wrapped object responses
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Try common property names for wrapped responses
          data = (responseData['models'] ?? 
                  responseData['data'] ?? 
                  responseData['results'] ?? 
                  responseData['records'] ?? 
                  responseData['items'] ?? 
                  []) as List<dynamic>;
        } else {
          print('❌ Unexpected response type: ${responseData.runtimeType}');
          return null;
        }
        
        final historyRecords = data.map((json) => HistoryRecord.fromJson(json)).toList();
        print('✅ Fetched ${historyRecords.length} history records');
        return historyRecords;
      } else {
        print('❌ Error getting history records: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting history records: $e');
      return null;
    }
  }

  // Get transactions for an individual
  Future<Map<String, dynamic>?> getTransactions({
    required String vendorType,
    required String source,
    required int vendorId,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'vendor_type': vendorType,
        'source': source,
        'vendor_id': vendorId.toString(),
      };

      final uri = Uri.parse('$baseUrl/transaction').replace(
        queryParameters: queryParams,
      );

      print('📊 Fetching transactions: $uri');
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Fetched transactions successfully');
        return data;
      } else {
        print('❌ Error getting transactions: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting transactions: $e');
      return null;
    }
  }
}