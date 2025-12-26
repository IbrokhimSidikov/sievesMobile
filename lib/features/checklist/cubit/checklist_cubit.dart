import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/checklist_model.dart';
import 'checklist_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChecklistCubit extends Cubit<ChecklistState> {
  final AuthManager _authManager;

  ChecklistCubit(this._authManager) : super(const ChecklistInitial());

  Future<void> loadChecklist(int checklistId) async {
    try {
      emit(const ChecklistLoading());

      final branchId = _authManager.currentIdentity?.employee?.branchId;
      
      if (branchId == null) {
        emit(const ChecklistError(message: 'Branch ID not found. Please login again.'));
        return;
      }

      print('🔄 Fetching checklist with ID: $checklistId for branch: $branchId');

      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        emit(const ChecklistError(message: 'Authentication failed. Please login again.'));
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
        final checklists = jsonList.map((json) => Checklist.fromJson(json)).toList();
        
        final checklist = checklists.firstWhere(
          (c) => c.id == checklistId,
          orElse: () => throw Exception('Checklist not found'),
        );
        
        final itemStates = <int, bool>{};
        final itemNotes = <int, String>{};
        for (var item in checklist.items) {
          itemStates[item.id] = false;
          itemNotes[item.id] = '';
        }
        
        print('✅ Loaded checklist: ${checklist.name} with ${checklist.items.length} items');
        
        emit(ChecklistLoaded(
          checklist: checklist,
          itemStates: itemStates,
          itemNotes: itemNotes,
          progress: 0.0,
        ));
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        emit(ChecklistError(message: 'Failed to load checklist: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ Error loading checklist: $e');
      emit(ChecklistError(message: 'Error loading checklist: $e'));
    }
  }

  void toggleItem(int itemId) {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final updatedStates = Map<int, bool>.from(currentState.itemStates);
      updatedStates[itemId] = !(updatedStates[itemId] ?? false);

      final completedCount = updatedStates.values.where((v) => v).length;
      final totalCount = updatedStates.length;
      final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

      emit(currentState.copyWith(
        itemStates: updatedStates,
        progress: progress,
      ));
    }
  }

  void updateItemNote(int itemId, String note) {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final updatedNotes = Map<int, String>.from(currentState.itemNotes);
      updatedNotes[itemId] = note;

      emit(currentState.copyWith(
        itemNotes: updatedNotes,
      ));
    }
  }

  Future<void> submitChecklist() async {
    final currentState = state;
    if (currentState is! ChecklistLoaded) return;

    if (currentState.progress < 1.0) {
      emit(const ChecklistError(message: 'Please complete all checklist items'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
      return;
    }

    try {
      emit(const ChecklistSubmitting());

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        emit(const ChecklistError(message: 'Employee ID not found. Please login again.'));
        await Future.delayed(const Duration(seconds: 2));
        emit(currentState);
        return;
      }

      final accessToken = await _authManager.authService.getAccessToken();
      if (accessToken == null) {
        emit(const ChecklistError(message: 'Authentication failed. Please login again.'));
        await Future.delayed(const Duration(seconds: 2));
        emit(currentState);
        return;
      }

      // Build submission items
      final items = currentState.checklist.items.map((item) {
        final isChecked = currentState.itemStates[item.id] ?? false;
        final note = currentState.itemNotes[item.id]?.trim() ?? '';
        
        return {
          'checklist_item_id': item.id,
          'is_checked': isChecked,
          'note': note.isEmpty ? ' ' : note,
        };
      }).toList();

      final submissionData = {
        'checklist_id': currentState.checklist.id,
        'submitted_by': employeeId,
        'items': items,
      };

      print('📤 Submitting checklist: ${currentState.checklist.name}');
      print('📦 Submission data: ${json.encode(submissionData)}');

      final url = Uri.parse('https://api.v3.sievesapp.com/checklist/submissions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(submissionData),
      );

      print('📡 Submission Response Status: ${response.statusCode}');
      print('📡 Submission Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Checklist submitted successfully');
        emit(const ChecklistSubmitted());
      } else {
        print('❌ Submission failed: ${response.statusCode} - ${response.body}');
        emit(ChecklistError(message: 'Failed to submit checklist: ${response.statusCode}'));
        await Future.delayed(const Duration(seconds: 2));
        emit(currentState);
      }
    } catch (e) {
      print('❌ Error submitting checklist: $e');
      emit(ChecklistError(message: 'Failed to submit checklist: $e'));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

}
