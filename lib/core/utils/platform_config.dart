import 'dart:io';

class PlatformConfig {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => false;
  
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Desktop';
  }

  static String get appVersion => '1.0.0';
}

class GeofenceConfig {
  static int get defaultRadiusMeters => 100;
  static int get minRadiusMeters => 50;
  static int get maxRadiusMeters => 500;
  
  static int get checkIntervalSeconds {
    return Platform.isAndroid ? 30 : 60;
  }
}

class NotificationConfig {
  static String get channelId {
    return Platform.isAndroid ? 'family_tracker_channel' : 'family_tracker_ios';
  }

  static String get channelName {
    return 'Family Tracker';
  }
}

class MapConfig {
  static bool get enableMyLocationButton => true;
  static bool get enableCompass => true;
  static double get defaultZoom => 16.0;
  static double get minZoom => 3.0;
  static double get maxZoom => 20.0;
}

class StorageKeys {
  static const String userId = 'user_id';
  static const String circleId = 'circle_id';
  static const String authToken = 'auth_token';
  static const String settings = 'user_settings';
  static const String firstLaunch = 'first_launch';
}