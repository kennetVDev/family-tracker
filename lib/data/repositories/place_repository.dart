import 'package:supabase_flutter/supabase_flutter.dart';
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
    // Check if already inside
    final existingVisit = await _client
        .from('place_visits')
        .select()
        .eq('place_id', placeId)
        .eq('user_id', userId)
        .is_('left_at', null)
        .maybeSingle();

    if (existingVisit != null) {
      throw Exception('Already inside this place');
    }

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
        .select('''
          id,
          place_id,
          user_id,
          arrived_at,
          left_at,
          places:place_id(name)
        ''')
        .eq('place_id', placeId)
        .order('arrived_at', descending: true);

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
    // Get all places in circle
    final places = await getCirclePlaces(circleId);
    
    // Check which places contain the location
    final List<PlaceModel> insidePlaces = [];
    for (final place in places) {
      final distance = _calculateDistance(
        latitude, longitude,
        place.latitude, place.longitude,
      );
      if (distance <= place.radiusMeters) {
        insidePlaces.add(place);
      }
    }
    
    return insidePlaces;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 
      _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
      _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5707963267948966);
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x) : 0;
  double _atan2(double y, double x) => _approxAtan2(y, x);

  double _taylorSin(double x) {
    x = x % (2 * 3.14159265359);
    if (x > 3.14159265359) x -= 2 * 3.14159265359;
    if (x < -3.14159265359) x += 2 * 3.14159265359;
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approxAtan2(double y, double x) {
    if (x == 0) return y > 0 ? 1.5707963267948966 : -1.5707963267948966;
    double atan = _approxAtan(y / x);
    if (x < 0) return y >= 0 ? atan + 3.14159265359 : atan - 3.14159265359;
    return atan;
  }

  double _approxAtan(double x) {
    if (x > 1) return 1.5707963267948966 - _approxAtan(1 / x);
    if (x < -1) return -1.5707963267948966 - _approxAtan(1 / x);
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }
}
