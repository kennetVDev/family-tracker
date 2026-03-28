class LocationModel {
  final String id;
  final String userId;
  final String circleId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  LocationModel({
    required this.id,
    required this.userId,
    required this.circleId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      circleId: map['circle_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'circle_id': circleId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  LocationModel copyWith({
    String? id,
    String? userId,
    String? circleId,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      circleId: circleId ?? this.circleId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
