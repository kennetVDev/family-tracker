import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  Timer? locationTimer;
  String? circleId;
  String? userId;

  service.on('updateSettings').listen((event) {
    if (event != null) {
      circleId = event['circleId'];
      userId = event['userId'];
    }
  });

  service.on('start').listen((event) async {
    if (event == null) return;
    
    circleId = event['circleId'];
    userId = event['userId'];
    final intervalSeconds = event['intervalSeconds'] ?? 30;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      service.invoke('error', {'message': 'Location permission denied'});
      return;
    }

    locationTimer?.cancel();
    locationTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        if (circleId != null && userId != null) {
          await _saveLocation(
            userId: userId!,
            circleId: circleId!,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
          );
          
          service.invoke('locationUpdate', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        service.invoke('error', {'message': e.toString()});
      }
    });

    service.invoke('started');
  });

  service.on('stop').listen((event) {
    locationTimer?.cancel();
    locationTimer = null;
    service.invoke('stopped');
  });
}

Future<bool> _checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return false;
  }

  return true;
}

Future<void> _saveLocation({
  required String userId,
  required String circleId,
  required double latitude,
  required double longitude,
  required double accuracy,
}) async {
  try {
    final client = Supabase.instance.client;
    await client.from('locations').insert({
      'user_id': userId,
      'circle_id': circleId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    });
  } catch (e) {
    // Silent fail for background service
  }
}

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'family_tracker_location',
        initialNotificationTitle: 'Family Tracker',
        initialNotificationContent: 'Tracking your location',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  Future<bool> startService({
    required String circleId,
    required String userId,
    int intervalSeconds = 30,
  }) async {
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('start', {
        'circleId': circleId,
        'userId': userId,
        'intervalSeconds': intervalSeconds,
      });
      return true;
    }

    final result = await _service.startService();
    if (!result) return false;

    _service.invoke('start', {
      'circleId': circleId,
      'userId': userId,
      'intervalSeconds': intervalSeconds,
    });
    return true;
  }

  Future<void> stopService() async {
    _service.invoke('stop');
  }

  Stream<Map<String, dynamic>?> get onLocationUpdate {
    return _service.on('locationUpdate');
  }

  Stream<Map<String, dynamic>?> get onError {
    return _service.on('error');
  }

  Stream<Map<String, dynamic>?> get onStarted {
    return _service.on('started');
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}
