/// Global application constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'SomaSmart';
  static const String appTagline = 'Smart Learning for O-Level & A-Level';
  
  // Storage Keys
  static const String keyThemeMode = 'somasmart_theme_mode';
  static const String keyLocale = 'somasmart_locale';
  static const String keyLastSelectedLevel = 'somasmart_selected_level';
  
  // Academic levels in Tanzania (NECTA)
  static const List<String> oLevelForms = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];
  static const List<String> aLevelForms = ['Form 5', 'Form 6'];
}
