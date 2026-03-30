import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/location_model.dart';

class RealtimeLocationService {
  final SupabaseClient _client;
  StreamSubscription? _locationsSubscription;
  final _locationController = StreamController<List<LocationModel>>.broadcast();
  String? _currentCircleId;
  RealtimeChannel? _channel;

  RealtimeLocationService(this._client);

  Stream<List<LocationModel>> get locationStream => _locationController.stream;

  Future<void> subscribeToCircleLocations(String circleId) async {
    await unsubscribe();
    _currentCircleId = circleId;

    _channel = _client.channel('circle-locations:$circleId');
    
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'locations',
      callback: (payload) {
        _fetchLatestLocations(circleId);
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'locations',
      callback: (payload) {
        _fetchLatestLocations(circleId);
      },
    );

    _channel!.subscribe();

    await _fetchLatestLocations(circleId);
  }

  Future<void> _fetchLatestLocations(String circleId) async {
    try {
      final response = await _client
          .from('locations')
          .select()
          .eq('circle_id', circleId)
          .order('timestamp', ascending: false)
          .limit(500);

      final Map<String, LocationModel> latestLocations = {};
      for (final row in response) {
        final loc = LocationModel.fromMap(row);
        if (!latestLocations.containsKey(loc.userId)) {
          latestLocations[loc.userId] = loc;
        }
      }

      _locationController.add(latestLocations.values.toList());
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> unsubscribe() async {
    await _locationsSubscription?.cancel();
    _locationsSubscription = null;
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    _channel = null;
    _currentCircleId = null;
  }

  void dispose() {
    unsubscribe();
    _locationController.close();
  }
}
