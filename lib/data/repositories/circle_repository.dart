import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_model.dart';

class CircleRepository {
  final SupabaseClient _client;

  CircleRepository(this._client);

  Future<CircleModel> createCircle(String name, String ownerId) async {
    final inviteCode = _generateInviteCode();
    
    final response = await _client.from('circles').insert({
      'name': name,
      'owner_id': ownerId,
      'invite_code': inviteCode,
    }).select().single();

    // Add owner as member
    await _client.from('circle_members').insert({
      'circle_id': response['id'],
      'user_id': ownerId,
      'role': 'owner',
    });

    return CircleModel.fromMap(response);
  }

  Future<CircleModel?> getMyCircle() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('circle_members')
        .select('circle_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final circle = await _client
        .from('circles')
        .select()
        .eq('id', response['circle_id'])
        .maybeSingle();

    if (circle == null) return null;
    return CircleModel.fromMap(circle);
  }

  Future<CircleModel?> joinCircle(String inviteCode, String userId) async {
    // Find circle with invite code
    final circle = await _client
        .from('circles')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .maybeSingle();

    if (circle == null) {
      throw Exception('Invalid invite code');
    }

    // Check if already a member
    final existingMember = await _client
        .from('circle_members')
        .select()
        .eq('circle_id', circle['id'])
        .eq('user_id', userId)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('Already a member of this circle');
    }

    // Add member
    await _client.from('circle_members').insert({
      'circle_id': circle['id'],
      'user_id': userId,
      'role': 'member',
    });

    return CircleModel.fromMap(circle);
  }

  Future<void> leaveCircle(String circleId, String userId) async {
    await _client
        .from('circle_members')
        .delete()
        .eq('circle_id', circleId)
        .eq('user_id', userId);
  }

  Future<List<CircleMemberModel>> getCircleMembers(String circleId) async {
    final response = await _client
        .from('circle_members')
        .select('''
          circle_id,
          user_id,
          role,
          joined_at,
          profiles:user_id(full_name, avatar_url)
        ''')
        .eq('circle_id', circleId);

    return response.map((row) {
      return CircleMemberModel(
        circleId: row['circle_id'] as String,
        userId: row['user_id'] as String,
        role: row['role'] as String,
        joinedAt: DateTime.parse(row['joined_at'] as String),
        userName: row['profiles']?['full_name'] as String?,
        userAvatar: row['profiles']?['avatar_url'] as String?,
      );
    }).toList();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    return code;
  }
}
