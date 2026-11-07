/// Application-wide constants for the Mossy app.
class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'Mossy';
  static const String appTagline = 'Look closer. Discover more.';
  static const String appDescription =
      'AI-Powered Nature Exploration & Discovery';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  static const Duration leafPulseDuration = Duration(milliseconds: 1400);

  // Layout Dimensions & Radius
  static const double defaultRadius = 20.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 14.0;
  static const double inputRadius = 16.0;
  static const double chipRadius = 12.0;
  static const double bottomSheetRadius = 28.0;
  static const double maxContentWidth = 600.0;

  // Asset Paths
  static const String iconsPath = 'assets/icons/';
  static const String illustrationsPath = 'assets/illustrations/';
  static const String mascotPath = 'assets/mascot/';
  static const String imagesPath = 'assets/images/';

  // Demo Mode Constants
  static const bool defaultDemoMode = true;
  static const String demoUserId = 'demo-mossy-user-001';
  static const String demoUserName = 'Mossy Explorer';
  static const String demoUserEmail = 'explorer@mossy.app';
  static const String demoUserAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

  // Pagination & Debouncing
  static const int defaultPageSize = 20;
  static const int searchDebounceMs = 400;

  // Storage Keys
  static const String keyAuthToken = 'mossy_auth_token';
  static const String keyRefreshToken = 'mossy_refresh_token';
  static const String keyUserId = 'mossy_user_id';
  static const String keyThemeMode = 'mossy_theme_mode';
  static const String keyDemoMode = 'mossy_demo_mode_enabled';
  static const String keyUserOnboarded = 'mossy_user_onboarded';
  static const String keyRecentSearches = 'mossy_recent_searches';
  static const String keySavedExplorations = 'mossy_saved_explorations';

  // Environmental / Defaults
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 14.0;
}
