import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/checklist_model.dart';
import 'checklist_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChecklistCubit extends Cubit<ChecklistState> {
  final AuthManager _authManager;
  Timer? _draftSaveDebounce;

  ChecklistCubit(this._authManager) : super(const ChecklistInitial());

  String _draftKey(int checklistId) {
    final employeeId = _authManager.currentEmployeeId ?? 0;
    return 'checklist_draft_${employeeId}_$checklistId';
  }

  Future<void> _saveDraft(ChecklistLoaded state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'itemStates': state.itemStates
            .map((key, value) => MapEntry(key.toString(), value)),
        'itemNotes': state.itemNotes
            .map((key, value) => MapEntry(key.toString(), value)),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_draftKey(state.checklist.id), json.encode(payload));
    } catch (e) {
      print('⚠️ Failed to save checklist draft: $e');
    }
  }

  void _scheduleDraftSave(ChecklistLoaded state) {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveDraft(state);
    });
  }

  Future<({Map<int, bool> states, Map<int, String> notes})?> _loadDraft(
      int checklistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey(checklistId));
      if (raw == null) return null;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final states = <int, bool>{};
      final notes = <int, String>{};
      (decoded['itemStates'] as Map<String, dynamic>?)?.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null) states[id] = v == true;
      });
      (decoded['itemNotes'] as Map<String, dynamic>?)?.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null) notes[id] = (v ?? '').toString();
      });
      return (states: states, notes: notes);
    } catch (e) {
      print('⚠️ Failed to load checklist draft: $e');
      return null;
    }
  }

  Future<void> _clearDraft(int checklistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey(checklistId));
    } catch (e) {
      print('⚠️ Failed to clear checklist draft: $e');
    }
  }

  @override
  Future<void> close() {
    _draftSaveDebounce?.cancel();
    return super.close();
  }

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

        // Merge persisted draft (resume where the user left off)
        final draft = await _loadDraft(checklistId);
        if (draft != null) {
          for (final entry in draft.states.entries) {
            if (itemStates.containsKey(entry.key)) {
              itemStates[entry.key] = entry.value;
            }
          }
          for (final entry in draft.notes.entries) {
            if (itemNotes.containsKey(entry.key)) {
              itemNotes[entry.key] = entry.value;
            }
          }
          print('📝 Restored checklist draft for $checklistId');
        }

        final completedCount = itemStates.values.where((v) => v).length;
        final totalCount = itemStates.length;
        final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

        print('✅ Loaded checklist: ${checklist.name} with ${checklist.items.length} items');

        emit(ChecklistLoaded(
          checklist: checklist,
          itemStates: itemStates,
          itemNotes: itemNotes,
          progress: progress,
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

      final newState = currentState.copyWith(
        itemStates: updatedStates,
        progress: progress,
      );
      emit(newState);
      // Toggle is discrete; persist immediately (no debounce needed).
      _saveDraft(newState);
    }
  }

  void updateItemNote(int itemId, String note) {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final updatedNotes = Map<int, String>.from(currentState.itemNotes);
      updatedNotes[itemId] = note;

      final newState = currentState.copyWith(
        itemNotes: updatedNotes,
      );
      emit(newState);
      // Notes update on every keystroke; debounce writes.
      _scheduleDraftSave(newState);
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
        await _clearDraft(currentState.checklist.id);
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
