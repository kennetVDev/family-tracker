import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/location_model.dart';
import '../../../data/models/place_model.dart';
import '../../../core/utils/map_styles.dart';
import '../../providers/circle_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

final placesMapProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final circleAsync = ref.watch(circleNotifierProvider);
  final circle = circleAsync.valueOrNull;
  if (circle == null) return [];
  return ref.read(placeRepositoryProvider).getCirclePlaces(circle.id);
});

final mapTypeProvider = StateProvider<MapType>((ref) => MapType.normal);

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Position? _currentPosition;
  bool _isDarkMode = false;
  bool _isBackgroundMode = false;
  List<LocationModel> _realtimeLocations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    final circle = ref.read(circleNotifierProvider).valueOrNull;
    if (circle != null) {
      ref.read(realtimeLocationServiceProvider).subscribeToCircleLocations(circle.id);
    }

    ref.listen<AsyncValue<List<LocationModel>>>(realtimeLocationsProvider, (previous, next) {
      next.whenData((locations) {
        _realtimeLocations = locations;
        _updateMarkersAndCircles();
      });
    });
  }

  Future<void> _loadData() async {
    _currentPosition = await ref.read(currentPositionProvider.future);
    await _updateMarkersAndCircles();
    _loadLocations();
  }

  Future<void> _updateMarkersAndCircles() async {
    final circleAsync = ref.watch(circleNotifierProvider);
    final circle = circleAsync.valueOrNull;
    if (circle == null) return;

    final locations = _realtimeLocations.isNotEmpty 
        ? _realtimeLocations 
        : await ref.read(locationRepositoryProvider).getMemberLocations(circle.id);
    final places = await ref.read(placeRepositoryProvider).getCirclePlaces(circle.id);
    final members = await ref.read(circleMembersProvider(circle.id).future);

    final markers = <Marker>{};
    final circles = <Circle>{};
    final currentUserId = ref.read(currentUserProvider)?.id;

    for (final loc in locations) {
      final member = members.where((m) => m.userId == loc.userId).firstOrNull;
      final isCurrentUser = loc.userId == currentUserId;
      
      markers.add(
        Marker(
          markerId: MarkerId(loc.userId),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            title: member?.userName ?? (isCurrentUser ? 'You' : 'Member'),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isCurrentUser ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    for (final place in places) {
      circles.add(
        Circle(
          circleId: CircleId(place.id),
          center: LatLng(place.latitude, place.longitude),
          radius: place.radiusMeters.toDouble(),
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );
      markers.add(
        Marker(
          markerId: MarkerId('place_${place.id}'),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(title: place.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _circles = circles;
      });
    }
  }

  Future<void> _loadLocations() async {
    final positions = await ref.read(currentPositionProvider.future);
    if (positions != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(positions.latitude, positions.longitude),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _loadLocations();
    _updateMarkersAndCircles();
    _applyMapStyle();
  }

  void _applyMapStyle() {
    if (_mapController == null) return;
    
    if (_isDarkMode) {
      _mapController!.setMapStyle(MapStyles.darkMode);
    } else {
      _mapController!.setMapStyle(MapStyles.lightMode);
    }
  }

  void _cycleMapType() {
    final currentType = ref.read(mapTypeProvider);
    MapType newType;
    
    switch (currentType) {
      case MapType.normal:
        newType = MapType.satellite;
        break;
      case MapType.satellite:
        newType = MapType.hybrid;
        break;
      case MapType.hybrid:
        newType = MapType.terrain;
        break;
      case MapType.terrain:
        newType = MapType.normal;
        break;
      default:
        newType = MapType.normal;
    }
    
    ref.read(mapTypeProvider.notifier).state = newType;
    
    if (newType == MapType.normal) {
      _isDarkMode = false;
      _applyMapStyle();
    } else if (newType == MapType.satellite) {
      _isDarkMode = false;
      _applyMapStyle();
    } else {
      _mapController?.setMapStyle(null);
    }
  }

  String _getMapTypeLabel(MapType type) {
    switch (type) {
      case MapType.normal:
        return 'Normal';
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.terrain:
        return 'Terrain';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleAsync = ref.watch(circleNotifierProvider);
    final isTracking = ref.watch(locationTrackerProvider);
    final settings = ref.watch(settingsProvider);
    final mapType = ref.watch(mapTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(circleAsync.valueOrNull?.name ?? 'Family Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _cycleMapType,
            tooltip: 'Change map style',
          ),
          if (settings.locationSharing)
            IconButton(
              icon: Icon(isTracking ? Icons.location_on : Icons.location_off),
              onPressed: () {
                if (isTracking) {
                  ref.read(locationTrackerProvider.notifier).stopTracking();
                } else {
                  ref.read(locationTrackerProvider.notifier).startTracking(backgroundMode: _isBackgroundMode);
                }
              },
            ),
          if (isTracking)
            IconButton(
              icon: Icon(_isBackgroundMode ? Icons.visibility : Icons.visibility_off),
              tooltip: _isBackgroundMode ? 'Background mode ON' : 'Background mode OFF',
              onPressed: () {
                setState(() {
                  _isBackgroundMode = !_isBackgroundMode;
                });
                if (_isBackgroundMode) {
                  ref.read(locationTrackerProvider.notifier).stopTracking();
                  ref.read(locationTrackerProvider.notifier).startTracking(backgroundMode: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Background tracking enabled')),
                  );
                } else {
                  ref.read(locationTrackerProvider.notifier).stopTracking();
                  ref.read(locationTrackerProvider.notifier).startTracking(backgroundMode: false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Background tracking disabled')),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateMarkersAndCircles,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: FutureBuilder(
        future: ref.read(currentPositionProvider.future),
        builder: (context, snapshot) {
          final position = _currentPosition ?? snapshot.data;
          
          if (snapshot.connectionState == ConnectionState.waiting && position == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (position == null) {
            return const Center(
              child: Text('Unable to get location. Please check permissions.'),
            );
          }

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            circles: _circles,
            mapType: mapType,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add place functionality
          _showAddPlaceDialog();
        },
        child: const Icon(Icons.add_location),
      ),
    );
  }

  void _showAddPlaceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Place',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Place Name',
                hintText: 'e.g., Home, School, Work',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final position = await ref.read(currentPositionProvider.future);
                if (position != null && context.mounted) {
                  final circle = ref.read(circleNotifierProvider).valueOrNull;
                  if (circle != null) {
                    final nameController = TextEditingController();
                    final radiusController = TextEditingController(text: '100');
                    
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add Place'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Place Name',
                                hintText: 'e.g., Home, School, Work',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: radiusController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Radius (meters)',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty) {
                                await ref.read(placeRepositoryProvider).createPlace(
                                  circleId: circle.id,
                                  name: nameController.text,
                                  latitude: position.latitude,
                                  longitude: position.longitude,
                                  radiusMeters: int.tryParse(radiusController.text) ?? 100,
                                  createdBy: ref.read(currentUserProvider)?.id ?? '',
                                );
                                Navigator.pop(ctx);
                                _updateMarkersAndCircles();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Place added!')),
                                );
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Select Location'),
            ),
          ],
        ),
      ),
    );
  }
}
