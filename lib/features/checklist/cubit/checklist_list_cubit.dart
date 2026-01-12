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
        
        emit(ChecklistListLoaded(checklists: checklists));
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        emit(ChecklistListError(message: 'Failed to load checklists: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ Error loading checklists: $e');
      emit(ChecklistListError(message: 'Error loading checklists: $e'));
    }
  }
}
