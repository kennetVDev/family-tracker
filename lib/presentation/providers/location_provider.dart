import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/place_repository.dart';
import 'auth_provider.dart';
import 'circle_provider.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LocationRepository(client);
});

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlaceRepository(client);
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

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
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

class LocationTrackerNotifier extends StateNotifier<bool> {
  final LocationRepository _locationRepository;
  final PlaceRepository _placeRepository;
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _uploadTimer;
  Position? _lastPosition;
  String? _currentCircleId;

  LocationTrackerNotifier(
    this._locationRepository,
    this._placeRepository,
    this._ref,
  ) : super(false);

  Future<void> startTracking() async {
    if (state) return;

    final circle = _ref.read(circleNotifierProvider).valueOrNull;
    if (circle == null) return;

    _currentCircleId = circle.id;
    
    // Check permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    // Start listening to location updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _lastPosition = position;
    });

    // Upload location every 30 seconds
    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _uploadCurrentLocation();
    });

    state = true;
  }

  Future<void> _uploadCurrentLocation() async {
    if (_lastPosition == null || _currentCircleId == null) return;

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
    if (_currentCircleId == null) return;

    try {
      final insidePlaces = await _placeRepository.checkGeofences(
        circleId: _currentCircleId!,
        latitude: latitude,
        longitude: longitude,
      );

      // Process geofence events
      for (final place in insidePlaces) {
        // TODO: Send notification
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
