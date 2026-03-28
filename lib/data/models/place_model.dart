class PlaceModel {
  final String id;
  final String circleId;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String createdBy;
  final DateTime createdAt;

  PlaceModel({
    required this.id,
    required this.circleId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdBy,
    required this.createdAt,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] as String,
      circleId: map['circle_id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: map['radius_meters'] as int? ?? 100,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circle_id': circleId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'created_by': createdBy,
    };
  }

  PlaceModel copyWith({
    String? id,
    String? circleId,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PlaceVisitModel {
  final String id;
  final String placeId;
  final String userId;
  final DateTime arrivedAt;
  final DateTime? leftAt;
  final String? placeName;

  PlaceVisitModel({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.arrivedAt,
    this.leftAt,
    this.placeName,
  });

  factory PlaceVisitModel.fromMap(Map<String, dynamic> map) {
    return PlaceVisitModel(
      id: map['id'] as String,
      placeId: map['place_id'] as String,
      userId: map['user_id'] as String,
      arrivedAt: DateTime.parse(map['arrived_at'] as String),
      leftAt: map['left_at'] != null ? DateTime.parse(map['left_at'] as String) : null,
      placeName: map['place_name'] as String?,
    );
  }
}
