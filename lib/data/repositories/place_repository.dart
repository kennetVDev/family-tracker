import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';

class PlaceRepository {
  final SupabaseClient _client;

  PlaceRepository(this._client);

  Future<PlaceModel> createPlace({
    required String circleId,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String createdBy,
  }) async {
    final response = await _client.from('places').insert({
      'circle_id': circleId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'created_by': createdBy,
    }).select().single();

    return PlaceModel.fromMap(response);
  }

  Future<List<PlaceModel>> getCirclePlaces(String circleId) async {
    final response = await _client
        .from('places')
        .select()
        .eq('circle_id', circleId);

    return response.map((row) => PlaceModel.fromMap(row)).toList();
  }

  Future<void> updatePlace(PlaceModel place) async {
    await _client.from('places').update({
      'name': place.name,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'radius_meters': place.radiusMeters,
    }).eq('id', place.id);
  }

  Future<void> deletePlace(String placeId) async {
    await _client.from('places').delete().eq('id', placeId);
  }

  Future<PlaceVisitModel> recordArrival({
    required String placeId,
    required String userId,
  }) async {
    final response = await _client.from('place_visits').insert({
      'place_id': placeId,
      'user_id': userId,
    }).select().single();

    return PlaceVisitModel.fromMap(response);
  }

  Future<void> recordDeparture(String visitId) async {
    await _client.from('place_visits').update({
      'left_at': DateTime.now().toIso8601String(),
    }).eq('id', visitId);
  }

  Future<List<PlaceVisitModel>> getPlaceVisits(String placeId) async {
    final response = await _client
        .from('place_visits')
        .select()
        .eq('place_id', placeId)
        .limit(50);

    return response.map((row) => PlaceVisitModel(
      id: row['id'] as String,
      placeId: row['place_id'] as String,
      userId: row['user_id'] as String,
      arrivedAt: DateTime.parse(row['arrived_at'] as String),
      leftAt: row['left_at'] != null ? DateTime.parse(row['left_at'] as String) : null,
    )).toList();
  }

  Future<List<PlaceVisitModel>> getUserVisits(String userId, {int limit = 50}) async {
    final response = await _client
        .from('place_visits')
        .select('''
          id,
          place_id,
          user_id,
          arrived_at,
          left_at,
          places:place_id(name)
        ''')
        .eq('user_id', userId)
        .order('arrived_at', ascending: false)
        .limit(limit);

    return response.map((row) => PlaceVisitModel(
      id: row['id'] as String,
      placeId: row['place_id'] as String,
      userId: row['user_id'] as String,
      arrivedAt: DateTime.parse(row['arrived_at'] as String),
      leftAt: row['left_at'] != null ? DateTime.parse(row['left_at'] as String) : null,
      placeName: row['places']?['name'] as String?,
    )).toList();
  }

  Future<List<PlaceModel>> checkGeofences({
    required String circleId,
    required double latitude,
    required double longitude,
  }) async {
    final places = await getCirclePlaces(circleId);
    
    final List<PlaceModel> insidePlaces = [];
    for (final place in places) {
      final distance = Geolocator.distanceBetween(
        latitude, longitude,
        place.latitude, place.longitude,
      );
      if (distance <= place.radiusMeters) {
        insidePlaces.add(place);
      }
    }
    
    return insidePlaces;
  }
}
