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
    final response = await _client
        .from('locations')
        .select()
        .eq('circle_id', circleId)
        .limit(100);

    return response.map((row) => LocationModel.fromMap(row)).toList();
  }

  Future<List<LocationModel>> getMemberLocations(String circleId) async {
    final response = await _client
        .from('locations')
        .select()
        .eq('circle_id', circleId)
        .limit(500);

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

  Future<void> deleteOldLocations(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    await _client
        .from('locations')
        .delete()
        .lt('timestamp', cutoff.toIso8601String());
  }
}
