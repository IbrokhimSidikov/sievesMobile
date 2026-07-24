import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/auth/auth_manager.dart';
import '../../task-management/models/task_model.dart' show EmployeeBrief;
import '../data/intro_api.dart';
import 'intro_employee_state.dart';

class IntroEmployeeCubit extends Cubit<IntroEmployeeState> {
  final IntroApi _api;

  // Guards against stale progress updates when the list is reloaded/refreshed.
  int _generation = 0;

  IntroEmployeeCubit(AuthManager authManager)
      : _api = IntroApi(authManager),
        super(const IntroEmployeeInitial());

  Future<void> loadEmployees() async {
    final gen = ++_generation;
    emit(const IntroEmployeeLoading());
    try {
      final employees = await _api.fetchBranchEmployees();
      if (isClosed || gen != _generation) return;
      emit(IntroEmployeeLoaded(employees));
      // Fire-and-forget: fill in each employee's completion progressively.
      _loadProgress(employees, gen);
    } on IntroApiException catch (e) {
      if (isClosed || gen != _generation) return;
      emit(IntroEmployeeError(e.message));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      emit(IntroEmployeeError('Error loading employees: $e'));
    }
  }

  /// Fetch each employee's intro-training summary in small concurrent batches,
  /// emitting after each batch so cards fill in as results arrive.
  Future<void> _loadProgress(List<EmployeeBrief> employees, int gen) async {
    const chunkSize = 6;
    final progress = <int, EmployeeProgress>{};

    for (var i = 0; i < employees.length; i += chunkSize) {
      if (isClosed || gen != _generation) return;
      final chunk = employees.skip(i).take(chunkSize);

      await Future.wait(
        chunk.map((e) async {
          try {
            final data = await _api.fetchEmployeeTrainings(e.id);
            progress[e.id] = EmployeeProgress(
              percent: data.summary.percent,
              completed: data.summary.completed,
              total: data.summary.total,
            );
          } catch (_) {
            // Leave this employee without a badge on failure.
          }
        }),
      );

      if (isClosed || gen != _generation) return;
      final current = state;
      if (current is IntroEmployeeLoaded) {
        emit(
          current.copyWith(
            progress: Map<int, EmployeeProgress>.from(progress),
          ),
        );
      }
    }
  }
}
