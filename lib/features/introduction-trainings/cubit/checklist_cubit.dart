import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/auth/auth_manager.dart';
import '../data/intro_api.dart';
import '../models/intro_training.dart';
import 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  final IntroApi _api;
  int? _employeeId;

  ChecklistCubit(AuthManager authManager)
      : _api = IntroApi(authManager),
        super(const ChecklistInitial());

  Future<void> load(int employeeId) async {
    _employeeId = employeeId;
    emit(const ChecklistLoading());
    try {
      final data = await _api.fetchEmployeeTrainings(employeeId);
      emit(ChecklistLoaded(data));
    } on IntroApiException catch (e) {
      emit(ChecklistError(e.message));
    } catch (e) {
      emit(ChecklistError('Error loading trainings: $e'));
    }
  }

  /// Optimistically toggle a checklist item, reverting if the server rejects it.
  Future<void> toggleItem({
    required int trainingId,
    required int checklistId,
    required bool completed,
  }) async {
    final current = state;
    if (current is! ChecklistLoaded || _employeeId == null) return;
    if (current.updating.contains(checklistId)) return;

    final optimistic =
        _apply(current.data, trainingId, checklistId, completed);
    emit(current.copyWith(
      data: optimistic,
      updating: {...current.updating, checklistId},
    ));

    try {
      await _api.setCompletion(
        employeeId: _employeeId!,
        checklistId: checklistId,
        completed: completed,
      );
      final done = state;
      if (done is ChecklistLoaded) {
        emit(done.copyWith(
          updating: {...done.updating}..remove(checklistId),
        ));
      }
    } catch (_) {
      // Revert on failure.
      final failed = state;
      if (failed is ChecklistLoaded) {
        final reverted =
            _apply(failed.data, trainingId, checklistId, !completed);
        emit(failed.copyWith(
          data: reverted,
          updating: {...failed.updating}..remove(checklistId),
        ));
      }
    }
  }

  IntroEmployeeTrainings _apply(
    IntroEmployeeTrainings data,
    int trainingId,
    int checklistId,
    bool completed,
  ) {
    final trainings = data.trainings.map((t) {
      if (t.id != trainingId) return t;
      final items = t.items.map((i) {
        if (i.id != checklistId) return i;
        return completed
            ? i.copyWith(completed: true, completedAt: DateTime.now())
            : i.copyWith(completed: false, clearCompletion: true);
      }).toList();
      return t.copyWithItems(items);
    }).toList();

    return IntroEmployeeTrainings(
      employeeId: data.employeeId,
      summary: data.summary,
      trainings: trainings,
    ).recomputed();
  }
}
