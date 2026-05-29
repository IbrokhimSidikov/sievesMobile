import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/task_api.dart';
import '../models/task_model.dart';
import 'create_task_state.dart';

class CreateTaskCubit extends Cubit<CreateTaskState> {
  final TaskApi _api;

  CreateTaskCubit(AuthManager authManager)
      : _api = TaskApi(authManager),
        super(const CreateTaskState());

  Future<void> loadForm() async {
    emit(state.copyWith(loadingForm: true, clearFormError: true));
    try {
      final departments = await _api.fetchDepartments(branchId: 2);
      emit(state.copyWith(
        loadingForm: false,
        departments: departments,
      ));
    } on TaskApiException catch (e) {
      emit(state.copyWith(loadingForm: false, formError: e.message));
    } catch (e) {
      emit(state.copyWith(loadingForm: false, formError: 'Error: $e'));
    }
  }

  Future<void> loadEmployees({bool force = false}) async {
    if (state.loadingEmployees) return;
    if (state.employeesLoaded && !force) return;
    emit(state.copyWith(loadingEmployees: true, clearEmployeesError: true));
    try {
      final employees = await _api.fetchEmployees();
      emit(state.copyWith(
        loadingEmployees: false,
        employees: employees,
        employeesLoaded: true,
      ));
    } on TaskApiException catch (e) {
      emit(state.copyWith(
        loadingEmployees: false,
        employeesError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingEmployees: false,
        employeesError: 'Error: $e',
      ));
    }
  }

  void setTitle(String value) => emit(state.copyWith(title: value));
  void setDescription(String value) => emit(state.copyWith(description: value));
  void setPriority(TaskPriority p) => emit(state.copyWith(priority: p));
  void setDueDate(DateTime? d) {
    if (d == null) {
      emit(state.copyWith(clearDueDate: true));
    } else {
      emit(state.copyWith(dueDate: d));
    }
  }

  Future<void> selectDepartment(int departmentId) async {
    emit(state.copyWith(
      selectedDepartmentId: departmentId,
      clearSpace: true,
      clearList: true,
      spaces: const [],
      lists: const [],
      loadingSpaces: true,
    ));
    try {
      final spaces = await _api.fetchSpaces(departmentId: departmentId);
      emit(state.copyWith(spaces: spaces, loadingSpaces: false));
    } on TaskApiException catch (e) {
      emit(state.copyWith(loadingSpaces: false, formError: e.message));
    } catch (e) {
      emit(state.copyWith(loadingSpaces: false, formError: 'Error: $e'));
    }
  }

  Future<void> selectSpace(int spaceId) async {
    emit(state.copyWith(
      selectedSpaceId: spaceId,
      clearList: true,
      lists: const [],
      loadingLists: true,
    ));
    try {
      final lists = await _api.fetchLists(spaceId: spaceId);
      emit(state.copyWith(lists: lists, loadingLists: false));
    } on TaskApiException catch (e) {
      emit(state.copyWith(loadingLists: false, formError: e.message));
    } catch (e) {
      emit(state.copyWith(loadingLists: false, formError: 'Error: $e'));
    }
  }

  void selectList(int listId) =>
      emit(state.copyWith(selectedListId: listId));

  void toggleAssignee(int employeeId) {
    final next = Set<int>.from(state.selectedAssigneeIds);
    if (!next.add(employeeId)) next.remove(employeeId);
    emit(state.copyWith(selectedAssigneeIds: next));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      await _api.createTask(
        listId: state.selectedListId!,
        title: state.title.trim(),
        description: state.description.trim().isEmpty
            ? null
            : state.description.trim(),
        priority: state.priority,
        assigneeIds: state.selectedAssigneeIds.toList(),
        dueDate: state.dueDate,
      );
      emit(state.copyWith(submitting: false, submitted: true));
    } on TaskApiException catch (e) {
      emit(state.copyWith(submitting: false, submitError: e.message));
    } catch (e) {
      emit(state.copyWith(submitting: false, submitError: 'Error: $e'));
    }
  }
}
