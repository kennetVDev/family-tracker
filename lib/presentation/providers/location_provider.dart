import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/location_model.dart';
import '../../data/models/place_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/background_location_service.dart';
import 'auth_provider.dart';
import 'circle_provider.dart';
import 'settings_provider.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LocationRepository(client);
});

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlaceRepository(client);
});

final realtimeLocationServiceProvider = Provider<RealtimeLocationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealtimeLocationService(client);
});

final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService();
});

final realtimeLocationsProvider = StreamProvider<List<LocationModel>>((ref) {
  final realtimeService = ref.watch(realtimeLocationServiceProvider);
  final circleAsync = ref.watch(circleNotifierProvider);
  final circle = circleAsync.valueOrNull;
  
  if (circle == null) {
    return Stream.value([]);
  }
  
  return realtimeService.locationStream;
});

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || 
          requested == LocationPermission.deniedForever) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    return null;
  }
});

final circleLocationsProvider = FutureProvider<List<LocationModel>>((ref) async {
  final circleAsync = ref.watch(circleNotifierProvider);
  final circle = circleAsync.valueOrNull;
  if (circle == null) return [];

  final repository = ref.watch(locationRepositoryProvider);
  return repository.getMemberLocations(circle.id);
});

final userVisitsProvider = FutureProvider<List<PlaceVisitModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(placeRepositoryProvider);
  return repository.getUserVisits(user.id);
});

class LocationTrackerNotifier extends StateNotifier<bool> {
  final LocationRepository _locationRepository;
  final PlaceRepository _placeRepository;
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _uploadTimer;
  Position? _lastPosition;
  String? _currentCircleId;
  String? _currentUserId;
  String? _currentPlaceId;
  String? _currentVisitId;
  final Set<String> _visitedPlaces = {};
  bool _isBackgroundMode = false;

  LocationTrackerNotifier(
    this._locationRepository,
    this._placeRepository,
    this._ref,
  ) : super(false);

  Future<void> startTracking({bool backgroundMode = false}) async {
    if (state) return;

    final settings = _ref.read(settingsProvider);
    if (!settings.locationSharing) {
      return;
    }

    final circle = _ref.read(circleNotifierProvider).valueOrNull;
    if (circle == null) return;

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    _currentCircleId = circle.id;
    _currentUserId = user.id;
    _isBackgroundMode = backgroundMode;

    // Check permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    if (backgroundMode) {
      await _startBackgroundTracking(circle.id, user.id, settings.trackingIntervalSeconds);
    } else {
      await _startForegroundTracking(settings.trackingIntervalSeconds);
    }

    state = true;
  }

  Future<void> _startForegroundTracking(int intervalSeconds) async {
    // Start listening to location updates
    _positionSubscription = Geolocator.getPositionStream().listen((position) {
      _lastPosition = position;
    });

    // Upload location based on settings
    _uploadTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _uploadCurrentLocation();
    });
  }

  Future<void> _startBackgroundTracking(String circleId, String userId, int intervalSeconds) async {
    final backgroundService = _ref.read(backgroundLocationServiceProvider);
    await backgroundService.initialize();
    await backgroundService.startService(
      circleId: circleId,
      userId: userId,
      intervalSeconds: intervalSeconds,
    );
  }

  Future<void> _uploadCurrentLocation() async {
    if (_lastPosition == null || _currentCircleId == null) return;

    final settings = _ref.read(settingsProvider);
    if (!settings.locationSharing) return;

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _locationRepository.saveLocation(
        userId: user.id,
        circleId: _currentCircleId!,
        latitude: _lastPosition!.latitude,
        longitude: _lastPosition!.longitude,
        accuracy: _lastPosition!.accuracy,
      );

      // Check geofences
      await _checkGeofences(_lastPosition!.latitude, _lastPosition!.longitude);

      _ref.invalidate(circleLocationsProvider);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _checkGeofences(double latitude, double longitude) async {
    if (_currentCircleId == null || _currentUserId == null) return;

    try {
      final insidePlaces = await _placeRepository.checkGeofences(
        circleId: _currentCircleId!,
        latitude: latitude,
        longitude: longitude,
      );

      final insidePlaceIds = insidePlaces.map((p) => p.id).toSet();

      // Check for arrivals
      for (final place in insidePlaces) {
        if (!_visitedPlaces.contains(place.id)) {
          _visitedPlaces.add(place.id);
          _currentPlaceId = place.id;
          final visit = await _placeRepository.recordArrival(
            placeId: place.id,
            userId: _currentUserId!,
          );
          _currentVisitId = visit.id;

          // Send notification
          if (_ref.read(settingsProvider).pushNotifications) {
            await NotificationService().showArrivalNotification(place.name);
          }
        }
      }

      // Check for departures
      final departedPlaces = _visitedPlaces.difference(insidePlaceIds);
      for (final placeId in departedPlaces) {
        if (_currentVisitId != null && _currentPlaceId == placeId) {
          await _placeRepository.recordDeparture(_currentVisitId!);
          
          final place = insidePlaces.firstWhere((p) => p.id == placeId, orElse: () => insidePlaces.first);
          if (_ref.read(settingsProvider).pushNotifications) {
            await NotificationService().showDepartureNotification(place.name, Duration(minutes: 5));
          }
          
          _currentVisitId = null;
          _currentPlaceId = null;
        }
        _visitedPlaces.remove(placeId);
      }
    } catch (e) {
      // Handle error
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _uploadTimer?.cancel();
    _uploadTimer = null;
    
    if (_isBackgroundMode) {
      _ref.read(backgroundLocationServiceProvider).stopService();
    }
    
    _visitedPlaces.clear();
    _currentVisitId = null;
    state = false;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final locationTrackerProvider = StateNotifierProvider<LocationTrackerNotifier, bool>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final placeRepo = ref.watch(placeRepositoryProvider);
  return LocationTrackerNotifier(locationRepo, placeRepo, ref);
});
