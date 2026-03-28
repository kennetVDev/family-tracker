class CircleModel {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final DateTime createdAt;

  CircleModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.createdAt,
  });

  factory CircleModel.fromMap(Map<String, dynamic> map) {
    return CircleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['owner_id'] as String,
      inviteCode: map['invite_code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CircleMemberModel {
  final String circleId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? userName;
  final String? userAvatar;

  CircleMemberModel({
    required this.circleId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userAvatar,
  });

  factory CircleMemberModel.fromMap(Map<String, dynamic> map) {
    return CircleMemberModel(
      circleId: map['circle_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      userName: map['user_name'] as String?,
      userAvatar: map['user_avatar'] as String?,
    );
  }
}
