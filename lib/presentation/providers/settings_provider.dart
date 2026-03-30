import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSettings {
  final bool locationSharing;
  final bool pushNotifications;
  final int trackingIntervalSeconds;

  const UserSettings({
    this.locationSharing = true,
    this.pushNotifications = true,
    this.trackingIntervalSeconds = 30,
  });

  UserSettings copyWith({
    bool? locationSharing,
    bool? pushNotifications,
    int? trackingIntervalSeconds,
  }) {
    return UserSettings(
      locationSharing: locationSharing ?? this.locationSharing,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      trackingIntervalSeconds: trackingIntervalSeconds ?? this.trackingIntervalSeconds,
    );
  }
}

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(const UserSettings());

  void toggleLocationSharing(bool value) {
    state = state.copyWith(locationSharing: value);
  }

  void togglePushNotifications(bool value) {
    state = state.copyWith(pushNotifications: value);
  }

  void setTrackingInterval(int seconds) {
    state = state.copyWith(trackingIntervalSeconds: seconds);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier();
});
