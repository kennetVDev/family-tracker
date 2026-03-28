import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

class LocationRepository {
  final SupabaseClient _client;

  LocationRepository(this._client);

  Future<LocationModel> saveLocation({
    required String userId,
    required String circleId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final response = await _client.from('locations').insert({
      'user_id': userId,
      'circle_id': circleId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    }).select().single();

    return LocationModel.fromMap(response);
  }

  Future<List<LocationModel>> getCircleLocations(String circleId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('locations')
        .select()
        .eq('circle_id', circleId)
        .order('timestamp', descending: true)
        .limit(100);

    return response.map((row) => LocationModel.fromMap(row)).toList();
  }

  Future<List<LocationModel>> getMemberLocations(String circleId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Get latest location for each member
    final response = await _client
        .from('locations')
        .select('''
          id,
          user_id,
          circle_id,
          latitude,
          longitude,
          accuracy,
          timestamp
        ''')
        .eq('circle_id', circleId)
        .order('timestamp', descending: true);

    // Group by user and take only the latest
    final Map<String, LocationModel> latestLocations = {};
    for (final row in response) {
      final loc = LocationModel.fromMap(row);
      if (!latestLocations.containsKey(loc.userId)) {
        latestLocations[loc.userId] = loc;
      }
    }

    return latestLocations.values.toList();
  }

  Stream<List<LocationModel>> subscribeToLocations(String circleId) {
    return _client
        .channel('locations:$circleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'locations',
          filter: PostgresChangeFilter(
            eq: 'circle_id',
            value: circleId,
          ),
          (payload) {
            return LocationModel.fromMap(payload.newRecord);
          },
        )
        .stream();
  }

  Future<void> deleteOldLocations(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    await _client
        .from('locations')
        .delete()
        .lt('timestamp', cutoff.toIso8601String());
  }
}
