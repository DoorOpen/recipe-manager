/// Application-wide constants
class AppConstants {
  // Private constructor
  AppConstants._();

  // App info
  static const String appName = 'Recipe Manager';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // Database
  static const String databaseName = 'recipe_manager.db';
  static const int databaseVersion = 1;

  // Default values
  static const int defaultServings = 4;
  static const int recipeImportTimeout = 30; // seconds
}
