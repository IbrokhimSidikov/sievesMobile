import '../models/task_model.dart';

class CreateTaskState {
  final bool loadingForm;
  final String? formError;

  final List<DepartmentBrief> departments;
  final List<TaskSpaceRef> spaces;
  final List<TaskListRef> lists;
  final List<EmployeeBrief> employees;
  final bool loadingEmployees;
  final bool employeesLoaded;
  final String? employeesError;

  final int? selectedDepartmentId;
  final int? selectedSpaceId;
  final int? selectedListId;
  final Set<int> selectedAssigneeIds;

  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;

  final bool loadingSpaces;
  final bool loadingLists;

  final bool submitting;
  final String? submitError;
  final bool submitted;

  const CreateTaskState({
    this.loadingForm = false,
    this.formError,
    this.departments = const [],
    this.spaces = const [],
    this.lists = const [],
    this.employees = const [],
    this.loadingEmployees = false,
    this.employeesLoaded = false,
    this.employeesError,
    this.selectedDepartmentId,
    this.selectedSpaceId,
    this.selectedListId,
    this.selectedAssigneeIds = const {},
    this.title = '',
    this.description = '',
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.loadingSpaces = false,
    this.loadingLists = false,
    this.submitting = false,
    this.submitError,
    this.submitted = false,
  });

  bool get canSubmit =>
      title.trim().isNotEmpty &&
      selectedListId != null &&
      selectedAssigneeIds.isNotEmpty &&
      !submitting;

  CreateTaskState copyWith({
    bool? loadingForm,
    String? formError,
    bool clearFormError = false,
    List<DepartmentBrief>? departments,
    List<TaskSpaceRef>? spaces,
    List<TaskListRef>? lists,
    List<EmployeeBrief>? employees,
    bool? loadingEmployees,
    bool? employeesLoaded,
    String? employeesError,
    bool clearEmployeesError = false,
    int? selectedDepartmentId,
    bool clearDepartment = false,
    int? selectedSpaceId,
    bool clearSpace = false,
    int? selectedListId,
    bool clearList = false,
    Set<int>? selectedAssigneeIds,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? loadingSpaces,
    bool? loadingLists,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitted,
  }) {
    return CreateTaskState(
      loadingForm: loadingForm ?? this.loadingForm,
      formError: clearFormError ? null : (formError ?? this.formError),
      departments: departments ?? this.departments,
      spaces: spaces ?? this.spaces,
      lists: lists ?? this.lists,
      employees: employees ?? this.employees,
      loadingEmployees: loadingEmployees ?? this.loadingEmployees,
      employeesLoaded: employeesLoaded ?? this.employeesLoaded,
      employeesError: clearEmployeesError
          ? null
          : (employeesError ?? this.employeesError),
      selectedDepartmentId: clearDepartment
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      selectedSpaceId:
          clearSpace ? null : (selectedSpaceId ?? this.selectedSpaceId),
      selectedListId:
          clearList ? null : (selectedListId ?? this.selectedListId),
      selectedAssigneeIds: selectedAssigneeIds ?? this.selectedAssigneeIds,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      loadingSpaces: loadingSpaces ?? this.loadingSpaces,
      loadingLists: loadingLists ?? this.loadingLists,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitted: submitted ?? this.submitted,
    );
  }
}
