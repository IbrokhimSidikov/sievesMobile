import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/api/api_service.dart';

class WorkEntryService {
  static const String _baseUrl = 'https://app.sievesapp.com/v1';
  final AuthManager _authManager = AuthManager();
  late final ApiService _apiService;

  WorkEntryService() {
    _apiService = ApiService(_authManager.authService);
  }

  Future<int?> getCurrentDaySessionId() async {
    try {
      print('📅 [WORK ENTRY] Fetching current day session...');
      
      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        print('❌ [WORK ENTRY] No access token available');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/day-session/0?specialType=current');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📥 [WORK ENTRY] Day session response status: ${response.statusCode}');
      print('📥 [WORK ENTRY] Day session response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daySessionId = data['id'] as int?;
        print('✅ [WORK ENTRY] Day session ID: $daySessionId');
        return daySessionId;
      } else {
        print('❌ [WORK ENTRY] Failed to get day session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [WORK ENTRY] Exception getting day session: $e');
      return null;
    }
  }

  Future<int?> uploadPhoto(File photoFile) async {
    try {
      print('📤 [WORK ENTRY] Uploading photo...');
      
      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        print('❌ [WORK ENTRY] No access token available');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/photo?belongs_to=work_entry');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          photoFile.path,
        ),
      );

      print('📤 [WORK ENTRY] Sending photo upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [WORK ENTRY] Photo upload response status: ${response.statusCode}');
      print('📥 [WORK ENTRY] Photo upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final photoId = data[0]['id'] as int?;
          print('✅ [WORK ENTRY] Photo uploaded successfully, ID: $photoId');
          return photoId;
        } else if (data is Map && data.containsKey('id')) {
          final photoId = data['id'] as int?;
          print('✅ [WORK ENTRY] Photo uploaded successfully, ID: $photoId');
          return photoId;
        }
      }
      
      print('❌ [WORK ENTRY] Failed to upload photo: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ [WORK ENTRY] Exception uploading photo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createWorkEntry({
    required int branchId,
    required int photoId,
    required int daySessionId,
    required int employeeDepartmentId,
    required int employeeId,
    required String entryType,
    required String timeLog,
    required bool isOnline,
    int? mood,
  }) async {
    try {
      print('📝 [WORK ENTRY] Creating work entry...');
      print('📊 [WORK ENTRY] Employee status: ${isOnline ? "ONLINE" : "OFFLINE"}');
      print('📊 [WORK ENTRY] Entry type: $entryType');
      if (mood != null) {
        print('😊 [WORK ENTRY] Mood: $mood');
      }
      
      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        print('❌ [WORK ENTRY] No access token available');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/work-entry?branch_id=$branchId');
      
      // Build payload based on employee status
      final Map<String, dynamic> body;
      
      if (isOnline) {
        // Employee is ONLINE -> Check OUT (stop)
        body = {
          'branch_id': branchId,
          'check_out_photo_id': photoId,
          'day_session_id': daySessionId,
          'employee_department_id': employeeDepartmentId,
          'employee_id': employeeId,
          'entry_type': 'stop',
          'is_manual': 0,
          'photo': '',
          'time_log': timeLog,
          'type': 'attendance',
        };
        print('🔴 [WORK ENTRY] Creating CHECK OUT entry (employee is online)');
      } else {
        // Employee is OFFLINE -> Check IN (start)
        body = {
          'branch_id': branchId,
          'check_in_photo_id': photoId,
          'day_session_id': daySessionId,
          'employee_department_id': employeeDepartmentId,
          'employee_id': employeeId,
          'entry_type': 'start',
          'is_manual': 0,
          'note': mood?.toString() ?? '100',
          'photo': '',
          'time_log': timeLog,
          'type': 'attendance',
        };
        print('🟢 [WORK ENTRY] Creating CHECK IN entry (employee is offline)');
        print('📝 [WORK ENTRY] Note (mood): ${mood?.toString() ?? "100"}');
      }

      print('📤 [WORK ENTRY] Request body: ${json.encode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('📥 [WORK ENTRY] Work entry response status: ${response.statusCode}');
      print('📥 [WORK ENTRY] Work entry response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ [WORK ENTRY] Work entry created successfully');
        return data;
      } else {
        print('❌ [WORK ENTRY] Failed to create work entry: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [WORK ENTRY] Exception creating work entry: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> performCompleteWorkEntry(File capturedPhoto, {int? mood}) async {
    try {
      print('');
      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STARTING COMPLETE WORK ENTRY FLOW                           │');
      print('└─────────────────────────────────────────────────────────────┘');
      print('');

      final identity = _authManager.currentIdentity;
      if (identity?.employee == null) {
        print('❌ [WORK ENTRY] No employee data available');
        return {'success': false, 'message': 'No employee data available'};
      }

      final employee = identity!.employee!;
      final employeeId = employee.id;
      final branchId = employee.branchId ?? 6;
      final departmentId = employee.departmentId ?? 52;

      print('👤 Employee ID: $employeeId');
      print('🏢 Branch ID: $branchId');
      print('📋 Department ID: $departmentId');
      print('');

      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 1: Getting current day session                        │');
      print('└─────────────────────────────────────────────────────────────┘');
      final daySessionId = await getCurrentDaySessionId();
      if (daySessionId == null) {
        print('❌ [WORK ENTRY] Failed to get day session ID');
        return {'success': false, 'message': 'Failed to get day session'};
      }
      print('✅ Day Session ID: $daySessionId');
      print('');

      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 2: Uploading captured photo                           │');
      print('└─────────────────────────────────────────────────────────────┘');
      final photoId = await uploadPhoto(capturedPhoto);
      if (photoId == null) {
        print('❌ [WORK ENTRY] Failed to upload photo');
        return {'success': false, 'message': 'Failed to upload photo'};
      }
      print('✅ Photo ID: $photoId');
      print('');

      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 3: Fetching current employee status from API          │');
      print('└─────────────────────────────────────────────────────────────┘');
      final currentStatus = await _apiService.getCurrentEmployeeStatus(employeeId!);
      if (currentStatus == null) {
        print('❌ [WORK ENTRY] Failed to get current employee status');
        return {'success': false, 'message': 'Failed to get employee status'};
      }
      final isOnline = currentStatus.toLowerCase() == 'online';
      print('📊 Employee Status (from API): $currentStatus');
      print('📊 Is Online: $isOnline');
      print('📊 Action: ${isOnline ? "CHECK OUT (stop)" : "CHECK IN (start)"}');
      print('');

      print('┌─────────────────────────────────────────────────────────────┐');
      print('│ STEP 4: Creating work entry                                │');
      print('└─────────────────────────────────────────────────────────────┘');
      final now = DateTime.now();
      final timeLog = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      
      final result = await createWorkEntry(
        branchId: branchId,
        photoId: photoId,
        daySessionId: daySessionId,
        employeeDepartmentId: departmentId,
        employeeId: employeeId!,
        entryType: isOnline ? 'stop' : 'start',
        timeLog: timeLog,
        isOnline: isOnline,
        mood: mood,
      );

      if (result != null) {
        print('✅ [WORK ENTRY] Complete flow successful!');
        print('');
        print('┌─────────────────────────────────────────────────────────────┐');
        print('│ WORK ENTRY RESPONSE                                         │');
        print('└─────────────────────────────────────────────────────────────┘');
        print(json.encode(result));
        print('');
        
        print('┌─────────────────────────────────────────────────────────────┐');
        print('│ STEP 5: Refreshing employee identity to update status      │');
        print('└─────────────────────────────────────────────────────────────┘');
        await _authManager.refreshIdentity();
        print('✅ Employee identity refreshed - status updated');
        print('📊 New status: ${_authManager.currentEmployeeStatus}');
        print('');
        
        return {'success': true, 'data': result};
      } else {
        print('❌ [WORK ENTRY] Failed to create work entry');
        return {'success': false, 'message': 'Failed to create work entry'};
      }
    } catch (e) {
      print('❌ [WORK ENTRY] Exception in complete flow: $e');
      return {'success': false, 'message': 'Exception: $e'};
    }
  }
}
