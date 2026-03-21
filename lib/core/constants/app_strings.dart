/// Application-wide strings and constants
/// Centralized string management for easy localization and consistency
class AppStrings {
  // Screen titles
  static const screenTitles = _ScreenTitles();

  // Labels
  static const labels = _Labels();

  // Messages and notifications
  static const messages = _Messages();

  // Validation messages
  static const validation = _ValidationMessages();

  // Button labels
  static const buttons = _ButtonLabels();

  // Hints and placeholders
  static const hints = _Hints();

  // Error messages
  static const errors = _ErrorMessages();
}

/// Screen title strings
class _ScreenTitles {
  const _ScreenTitles();

  String get projectDetails => 'Project Details';
  String get projectTasks => 'Project Tasks';
  String get createNewTask => 'Create New Task';
  String get todaysTasks => "Today's Tasks";
}

/// Label strings
class _Labels {
  const _Labels();

  // Stats labels
  String get totalHours => 'Total Hours';
  String get todayHours => "Today's Hours";
  String get thisWeek => 'This Week';

  // Timer labels
  String get noActiveTimer => 'No Active Timer';
  String get currentlyTracking => 'Currently Tracking';
  String get inProgress => 'In Progress';

  // Task form labels
  String get taskTitle => 'Task Title';
  String get description => 'Description (Optional)';
  String get taskTitleHint => 'Enter task title...';
  String get descriptionHint => 'Add task details...';

  // Status and metadata
  String get taskStatus => 'Status';
  String get created => 'Created';
  String get duration => 'Duration';

  // Sidebar
  String get noTasksCreatedToday => 'No tasks created today';
}

/// Message strings
class _Messages {
  const _Messages();

  // Timer messages
  String get startTimerInstructions =>
      'Start a timer on any task below to begin tracking';
  String get noTasksYet => 'No tasks yet';
  String get createFirstTaskInstructions => 'Create your first task above';

  // Success messages
  String taskCreatedSuccess(String taskName) => 'Task "$taskName" created!';
  String taskUpdatedSuccess(String taskName) => 'Task "$taskName" updated!';
  String timerStartedSuccess(String taskName) =>
      'Timer started for "$taskName"';
  String timerStoppedSuccess(String taskName) =>
      'Timer stopped for "$taskName"';
  String get taskDeletedSuccess => 'Task deleted!';

  // Warning messages
  String get stopCurrentTimerWarning =>
      'Please stop the current timer before starting a new one';

  // Error messages for snackbars
  String get taskTitleRequired => 'Please enter a task title';
  String taskCreationError(String error) => 'Error creating task: $error';
  String taskUpdateError(String error) => 'Error updating task: $error';
  String taskDeletionError(String error) => 'Error deleting task: $error';
  String timerOperationError(String error) => error;
}

/// Validation messages
class _ValidationMessages {
  const _ValidationMessages();

  String get taskTitleEmpty => 'Task title cannot be empty';
  String get taskTitleTooLong => 'Task title must be less than 250 characters';
  String descriptionTooLong(int maxLength) =>
      'Description must be less than $maxLength characters';
}

/// Button labels
class _ButtonLabels {
  const _ButtonLabels();

  String get createTask => 'Create Task';
  String get startTimer => 'Start';
  String get pauseTimer => 'Pause';
  String get stopTimer => 'Stop';
  String get start => 'Start';
  String get stop => 'Stop';
  String get view => 'View';
  String get edit => 'Edit';
  String get delete => 'Delete';
  String get previous => 'Previous';
  String get next => 'Next';
}

/// Hint and placeholder strings
class _Hints {
  const _Hints();

  String get viewTaskDetails => 'View task details';
  String get editTask => 'Edit task';
  String get deleteTask => 'Delete task';
  String get startStopTimer => 'Start/Stop timer';
}

/// Error message strings
class _ErrorMessages {
  const _ErrorMessages();

  String get loadingTasks => 'Error loading tasks';
  String get loadingData => 'Error loading data';
  String unknownError(String? error) => 'Error: ${error ?? 'Unknown error'}';
}
