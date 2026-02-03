import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/checklist_model.dart';
import 'checklist_list_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChecklistListCubit extends Cubit<ChecklistListState> {
  final AuthManager _authManager;

  ChecklistListCubit(this._authManager) : super(const ChecklistListInitial());

  Future<void> loadChecklists() async {
    try {
      emit(const ChecklistListLoading());

      final branchId = _authManager.currentIdentity?.employee?.branchId;
      
      if (branchId == null) {
        emit(const ChecklistListError(message: 'Branch ID not found. Please login again.'));
        return;
      }

      print('🔄 Fetching checklists for branch ID: $branchId');

      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        emit(const ChecklistListError(message: 'Authentication failed. Please login again.'));
        return;
      }

      final url = Uri.parse('https://api.v3.sievesapp.com/checklist?branch_id=$branchId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final allChecklists = jsonList.map((json) => Checklist.fromJson(json)).toList();
        
        // Get current user role
        final userRole = _authManager.currentUserRole?.toLowerCase();
        
        // Filter checklists based on user role
        final checklists = allChecklists.where((checklist) {
          final checklistRole = checklist.role.toLowerCase();
          
          // If user has no role or no checklist access, show nothing
          if (userRole == null || !_authManager.hasChecklistAccess) {
            return false;
          }
          
          // Match checklist role with user role
          return checklistRole == userRole;
        }).toList();
        
        print('✅ Loaded ${allChecklists.length} total checklists, filtered to ${checklists.length} for role: $userRole');
        
        // Fetch today's submissions to hide already submitted checklists
        final submittedChecklistIds = await _fetchTodaySubmissions(accessToken);
        
        emit(ChecklistListLoaded(
          checklists: checklists,
          submittedChecklistIds: submittedChecklistIds,
        ));
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        emit(ChecklistListError(message: 'Failed to load checklists: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ Error loading checklists: $e');
      emit(ChecklistListError(message: 'Error loading checklists: $e'));
    }
  }

  Future<Set<int>> _fetchTodaySubmissions(String accessToken) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dateRange = '$todayStr,$todayStr';

      print('🔄 Fetching today\'s submissions: $dateRange');

      final url = Uri.parse('https://api.v3.sievesapp.com/checklist/submissions/my?date_range=$dateRange');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Filter submissions to only include those created today
        final submittedIds = jsonList.where((json) {
          if (json['created_at'] == null) return false;
          
          try {
            final createdAt = DateTime.parse(json['created_at']);
            final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
            final isToday = createdDate.isAtSameMomentAs(today);
            
            if (!isToday) {
              print('⚠️ Filtering out submission from ${createdAt.toString()} (not today)');
            }
            
            return isToday;
          } catch (e) {
            print('⚠️ Error parsing date for submission: $e');
            return false;
          }
        }).map((json) => json['checklist_id'] as int?)
            .whereType<int>()
            .toSet();
        
        print('✅ Found ${submittedIds.length} submitted checklists today: $submittedIds');
        return submittedIds;
      } else {
        print('⚠️ Failed to fetch today\'s submissions: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('⚠️ Error fetching today\'s submissions: $e');
      return {};
    }
  }
}
