import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/circle_provider.dart';
import '../../providers/location_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadLocations();
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
  }

  @override
  Widget build(BuildContext context) {
    final circleAsync = ref.watch(circleNotifierProvider);
    final isTracking = ref.watch(locationTrackerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(circleAsync.valueOrNull?.name ?? 'Family Tracker'),
        actions: [
          IconButton(
            icon: Icon(isTracking ? Icons.location_on : Icons.location_off),
            onPressed: () {
              if (isTracking) {
                ref.read(locationTrackerProvider.notifier).stopTracking();
              } else {
                ref.read(locationTrackerProvider.notifier).startTracking();
              }
            },
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final position = snapshot.data;
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
            mapType: MapType.normal,
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select location on map')),
                );
              },
              child: const Text('Select Location'),
            ),
          ],
        ),
      ),
    );
  }
}
