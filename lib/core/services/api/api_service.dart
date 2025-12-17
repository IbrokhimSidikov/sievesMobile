import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../model/employee_model.dart';
import '../../model/identity_model.dart';
import '../../model/work_entry_model.dart';
import '../../model/break_order_model.dart';
import '../../model/history_model.dart';
import '../../model/inventory_model.dart';
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
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }



  // Get identity by Auth0 ID
  Future<Identity?> getIdentityByAuthId(String authId) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'auth_id': authId,
        'expand': ['employee.branch', 'employee.individual', 'employee.individual.photo', 'employee.reward'].join(','),
      };

      final uri = Uri.parse('$baseUrl/identity/0').replace(
        queryParameters: queryParams,
      );

      print('🌐 [API] Calling identity endpoint: $uri');
      print('🌐 [API] Expand parameter: ${queryParams['expand']}');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('🔍 [API] Identity response received');
        print('🔍 [API] Employee data: ${responseBody['employee']}');
        print('🔍 [API] Individual data: ${responseBody['employee']?['individual']}');
        print('🔍 [API] Photo data: ${responseBody['employee']?['individual']?['photo']}');
        
        final identity = Identity.fromJson(responseBody);
        print('🔍 [API] Parsed identity photo: ${identity.employee?.individual?.photo}');
        
        return identity;
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
        'expand': ['branch', 'individual.photo', 'jobPosition'].join(','),
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

  // Get employee data with custom expand parameters
  Future<Map<String, dynamic>?> getEmployeeWithExpand(int employeeId, List<String> expandFields) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'expand': expandFields.join(','),
      };

      final uri = Uri.parse('$baseUrl/employee/$employeeId').replace(
        queryParameters: queryParams,
      );

      print('🔍 Fetching employee data from: $uri');
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Employee data received');
        return data;
      } else {
        print('❌ Error getting employee data: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting employee data: $e');
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

  // Check if employee has already ordered today
  Future<bool> hasOrderedToday(int breakEmployeeId) async {
    try {
      final headers = await _getHeaders();
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final queryParams = {
        'orderType': 'break',
        'break_employee_id': breakEmployeeId.toString(),
        'dateRange': '$today,$today',
      };

      final uri = Uri.parse('$baseUrl/order').replace(
        queryParameters: queryParams,
      );

      print('🔍 Checking if employee $breakEmployeeId has ordered today: $uri');

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        List<dynamic> ordersList;
        if (jsonData is List) {
          ordersList = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('models')) {
          ordersList = jsonData['models'] as List;
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          ordersList = jsonData['data'] as List;
        } else {
          ordersList = [];
        }
        
        final hasOrdered = ordersList.isNotEmpty;
        print('📊 Has ordered today: $hasOrdered (found ${ordersList.length} orders)');
        return hasOrdered;
      }
      return false;
    } catch (e) {
      print('❌ Exception checking today\'s orders: $e');
      return false;
    }
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

  // Get break balance for an employee
  Future<double?> getBreakBalance(int employeeId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('https://api.sievesapp.com/v1/site/test').replace(
        queryParameters: {
          'action': 'breakBalanceGetter',
          'employee_id': employeeId.toString(),
        },
      );

      print('💰 Fetching break balance for employee $employeeId: $uri');
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['plugin_break_balance'] != null) {
          final balance = (data['plugin_break_balance'] as num).toDouble();
          print('✅ Fetched break balance: $balance UZS');
          return balance;
        } else {
          print('❌ Invalid break balance response: $data');
          return null;
        }
      } else {
        print('❌ Error getting break balance: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting break balance: $e');
      return null;
    }
  }

  // Get employee bonus for previous month
  Future<Map<String, dynamic>?> getEmployeeBonus(int employeeId) async {
    try {
      final headers = await _getHeaders();
      
      // Calculate previous month
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final year = previousMonth.year;
      final month = previousMonth.month;
      
      final queryParams = {
        'employee_id': employeeId.toString(),
        'year': year.toString(),
        'month': month.toString(),
      };

      final uri = Uri.parse('$baseUrl/employee-bonus/employee').replace(
        queryParameters: queryParams,
      );

      print('🎁 Fetching employee bonus for $year-$month: $uri');
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Fetched employee bonus successfully: $data');
        return data;
      } else {
        print('❌ Error getting employee bonus: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting employee bonus: $e');
      return null;
    }
  }

  // Get kitchen employees for productivity timer
  Future<List<dynamic>?> getKitchenEmployees() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('https://api.v3.sievesapp.com/efficiency-tracker/kitchen-employees');

      print('👨‍🍳 Fetching kitchen employees: $uri');
      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Fetched ${data.length} kitchen employees');
        return data;
      } else {
        print('❌ Error getting kitchen employees: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting kitchen employees: $e');
      return null;
    }
  }

  // Submit efficiency tracker data
  Future<bool> submitEfficiencyTracker({
    required int employeeId,
    required int jobPositionId,
    required String employeeName,
    required String jobPositionName,
    required String time,
    int? productId,
    String? comment,
    String? productName,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('https://api.v3.sievesapp.com/efficiency-tracker');

      final body = {
        'employee_id': employeeId,
        'job_position_id': jobPositionId,
        'employee_name': employeeName,
        'job_position_name': jobPositionName,
        'time': time,
        'product_id': productId,
        'comment': comment ?? '',
        'product_name': productName ?? '',
      };

      print('⏱️ Submitting efficiency tracker data: $body');
      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Efficiency tracker data submitted successfully');
        return true;
      } else {
        print('❌ Error submitting efficiency tracker: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception submitting efficiency tracker: $e');
      return false;
    }
  }

  // Get inventory menu items (recommended items for break orders)
  Future<List<InventoryItem>> getInventoryMenu() async {
    final startTime = DateTime.now();
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'is_active': '1',
        'is_pos': '1',
        'expand': 'inventoryPriceList,photo,changeableContains.default.photo,changeableContains.default.inventoryPriceList,changeableCategories.posCategory',
        'limit': '100',
      };

      final uri = Uri.parse('$baseUrl/inventory').replace(
        queryParameters: queryParams,
      );

      print('🍔 [API] Fetching inventory menu: $uri');
      final requestStart = DateTime.now();
      final response = await _httpClient.get(uri, headers: headers);
      final requestDuration = DateTime.now().difference(requestStart);
      final responseSizeKB = (response.body.length / 1024).toStringAsFixed(2);
      print('⏱️ [API] Inventory HTTP request took: ${requestDuration.inMilliseconds}ms (${responseSizeKB}KB)');

      if (response.statusCode == 200) {
        final parseStart = DateTime.now();
        final jsonData = jsonDecode(response.body);
        final parseDuration = DateTime.now().difference(parseStart);
        print('⏱️ [API] JSON decode took: ${parseDuration.inMilliseconds}ms');
        print('📊 JSON Type: ${jsonData.runtimeType}');
        
        List<dynamic> inventoryList;
        if (jsonData is List) {
          inventoryList = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('models')) {
          inventoryList = jsonData['models'] as List;
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          inventoryList = jsonData['data'] as List;
        } else {
          print('❌ Unexpected response format: $jsonData');
          return [];
        }
        
        final mappingStart = DateTime.now();
        final items = inventoryList.map((json) => InventoryItem.fromJson(json)).toList();
        final mappingDuration = DateTime.now().difference(mappingStart);
        
        final totalDuration = DateTime.now().difference(startTime);
        print('⏱️ [API] Object mapping took: ${mappingDuration.inMilliseconds}ms');
        print('✅ [API] Fetched ${items.length} inventory items in ${totalDuration.inMilliseconds}ms');
        return items;
      } else {
        print('❌ Error getting inventory: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting inventory: $e');
      return [];
    }
  }

  // Upload break photo
  Future<int?> uploadBreakPhoto(File photoFile) async {
    try {
      final token = await authService.getAccessToken();
      if (token == null) {
        print('❌ No access token available for photo upload');
        return null;
      }

      final uri = Uri.parse('$baseUrl/photo?belongs_to=employee_break');
      print('📸 [API] Uploading break photo to: $uri');
      print('📸 [API] Photo file path: ${photoFile.path}');
      print('📸 [API] Photo file exists: ${await photoFile.exists()}');
      
      final photoBytes = await photoFile.readAsBytes();
      print('📸 [API] Photo size: ${photoBytes.length} bytes');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the photo file with proper content type
      request.files.add(http.MultipartFile.fromBytes(
        'photos',
        photoBytes,
        filename: 'break_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      print('📸 [API] Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📸 [API] Photo upload response status: ${response.statusCode}');
      print('📸 [API] Photo upload response headers: ${response.headers}');
      print('📸 [API] Photo upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('📸 [API] Parsed response: $jsonData');
        print('📸 [API] Response type: ${jsonData.runtimeType}');
        
        // Response can be a single object or array
        if (jsonData is List && jsonData.isNotEmpty) {
          final photoId = jsonData[0]['id'] as int?;
          print('✅ [API] Photo uploaded successfully (from array), ID: $photoId');
          return photoId;
        } else if (jsonData is Map && jsonData.containsKey('id')) {
          final photoId = jsonData['id'] as int?;
          print('✅ [API] Photo uploaded successfully (from object), ID: $photoId');
          return photoId;
        }
        print('❌ [API] Unexpected photo upload response format: $jsonData');
        return null;
      } else {
        print('❌ [API] Error uploading photo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [API] Exception uploading photo: $e');
      print('❌ [API] Stack trace: $stackTrace');
      return null;
    }
  }

  // Create break order
  Future<Map<String, dynamic>?> createBreakOrder({
    required int branchId,
    required int breakEmployeeId,
    required int breakPhotoId,
    required int employeeId,
    required List<Map<String, dynamic>> orderItems,
    required int totalValue,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/order?isMobile=1');

      final body = {
        'delivery_employee_id': null,
        'isSynchronous': 'sync',
        'is_fast': 0,
        'queue_type': 'sync',
        'employee_id': employeeId,
        'order_type_id': 5,
        'customer_id': null,
        'start_time': 'now',
        'pager_number': 0,
        'orderItems': orderItems,
        'transactions': [
          {
            'account_id': 1,
            'payment_type_id': 2,
            'amount': totalValue,
            'type': 'deposit',
          }
        ],
        'value': totalValue,
        'break_employee_id': breakEmployeeId,
        'break_photo_id': breakPhotoId,
        'note': null,
        'customer_quantity': 1,
        'branch_id': 14,
        'paid': totalValue,
      };

      print('🛒 [API] Creating break order: $uri');
      print('🛒 [API] Order payload: ${jsonEncode(body)}');

      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('🛒 [API] Order response: ${response.statusCode}');
      print('🛒 [API] Order body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('✅ [API] Break order created successfully');
        return jsonData;
      } else {
        print('❌ [API] Error creating order: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [API] Exception creating order: $e');
      return null;
    }
  }

  // Get POS categories
  Future<List<PosActiveCategory>> getPosCategories() async {
    final startTime = DateTime.now();
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'expand': 'posActiveCategories.posCategory',
      };

      final uri = Uri.parse('$baseUrl/pos/94').replace(
        queryParameters: queryParams,
      );

      print('📂 [API] Fetching POS categories: $uri');
      final requestStart = DateTime.now();
      final response = await _httpClient.get(uri, headers: headers);
      final requestDuration = DateTime.now().difference(requestStart);
      final responseSizeKB = (response.body.length / 1024).toStringAsFixed(2);
      print('⏱️ [API] POS categories HTTP request took: ${requestDuration.inMilliseconds}ms (${responseSizeKB}KB)');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData is Map && jsonData.containsKey('posActiveCategories')) {
          final categoriesList = jsonData['posActiveCategories'] as List;
          final categories = categoriesList
              .map((json) => PosActiveCategory.fromJson(json))
              .toList();
          
          // Sort by index
          categories.sort((a, b) {
            final aIndex = int.tryParse(a.posCategory?.index ?? '0') ?? 0;
            final bIndex = int.tryParse(b.posCategory?.index ?? '0') ?? 0;
            return aIndex.compareTo(bIndex);
          });
          
          final totalDuration = DateTime.now().difference(startTime);
          print('✅ [API] Fetched ${categories.length} POS categories in ${totalDuration.inMilliseconds}ms');
          return categories;
        } else {
          print('❌ Unexpected response format: $jsonData');
          return [];
        }
      } else {
        print('❌ Error getting POS categories: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception getting POS categories: $e');
      return [];
    }
  }
}