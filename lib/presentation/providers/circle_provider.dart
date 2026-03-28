import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/circle_model.dart';
import '../../data/repositories/circle_repository.dart';
import 'auth_provider.dart';

final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CircleRepository(client);
});

final myCircleProvider = FutureProvider<CircleModel?>((ref) async {
  final repository = ref.watch(circleRepositoryProvider);
  return repository.getMyCircle();
});

final circleMembersProvider = FutureProvider.family<List<CircleMemberModel>, String>((ref, circleId) async {
  final repository = ref.watch(circleRepositoryProvider);
  return repository.getCircleMembers(circleId);
});

class CircleNotifier extends StateNotifier<AsyncValue<CircleModel?>> {
  final CircleRepository _repository;
  final Ref _ref;

  CircleNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadCircle();
  }

  Future<void> _loadCircle() async {
    try {
      final circle = await _repository.getMyCircle();
      state = AsyncValue.data(circle);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCircle(String name) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error(Exception('Not authenticated'), StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final circle = await _repository.createCircle(name, user.id);
      state = AsyncValue.data(circle);
      _ref.invalidate(myCircleProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinCircle(String inviteCode) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error(Exception('Not authenticated'), StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final circle = await _repository.joinCircle(inviteCode, user.id);
      state = AsyncValue.data(circle);
      _ref.invalidate(myCircleProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> leaveCircle() async {
    final circle = state.valueOrNull;
    final user = _ref.read(currentUserProvider);
    
    if (circle == null || user == null) return;

    try {
      await _repository.leaveCircle(circle.id, user.id);
      state = const AsyncValue.data(null);
      _ref.invalidate(myCircleProvider);
    } catch (e) {
      // Handle error
    }
  }

  void refresh() {
    _loadCircle();
  }
}

final circleNotifierProvider = StateNotifierProvider<CircleNotifier, AsyncValue<CircleModel?>>((ref) {
  final repository = ref.watch(circleRepositoryProvider);
  return CircleNotifier(repository, ref);
});
