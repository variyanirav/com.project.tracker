/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ============ APP INFO ============
  static const String appName = 'TimeTracker';
  static const String appVersion = '0.1.0';
  static const String bundleId = 'com.project.tracker';

  // ============ UI CONSTANTS ============
  static const double roundRadius = 12.0; // ROUND_TWELVE
  static const double navRailWidth = 80.0;
  static const double sidebarWidth = 360.0;

  // ============ WINDOW CONSTRAINTS ============
  static const double minWindowWidth = 1200.0;
  static const double minWindowHeight = 800.0;

  // ============ SPACING (4px GRID) ============
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;

  // ============ ICON SIZES ============
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ============ FONT SIZES ============
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeHeading2 = 28.0;
  static const double fontSizeHeading1 = 32.0;

  // ============ DATABASE ============
  static const String databaseName = 'project_tracker.db';
  static const int databaseVersion = 1;

  // ============ TIME FORMAT ============
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // ============ ANIMATION DURATION ============
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ============ DEBOUNCE ============
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration throttleDelay = Duration(milliseconds: 1000);

  // ============ PROJECT STATUS ============
  static const String projectStatusActive = 'active';
  static const String projectStatusArchived = 'archived';

  static const List<String> projectStatuses = [
    projectStatusActive,
    projectStatusArchived,
  ];

  // ============ TASK STATUS ============
  static const String taskStatusPending = 'pending';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';
  static const String taskStatusPaused = 'paused';

  static const List<String> taskStatuses = [
    taskStatusPending,
    taskStatusInProgress,
    taskStatusCompleted,
    taskStatusPaused,
  ];

  // ============ VALIDATION ============
  static const int minProjectNameLength = 2;
  static const int maxProjectNameLength = 100;
  static const int minTaskNameLength = 2;
  static const int maxTaskNameLength = 255;
  static const int minDescriptionLength = 0;
  static const int maxDescriptionLength = 500;

  // ============ DISPLAY FORMATS ============
  static const int timerDisplayPrecision = 2; // decimal places for hours
}
