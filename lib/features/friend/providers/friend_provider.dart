import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/friend.dart';
import '../data/repositories/friend_repository.dart';
import '../../../dev/mock_friend_repository.dart';

// 나중에 FirebaseFriendRepository로 교체만 하면 됨
final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => MockFriendRepository(),
);

// ── 친구탐험 ON/OFF ──────────────────────────────────────────────────────

class FriendExplorationNotifier extends StateNotifier<bool> {
  static const _key = 'zgum_friend_exploration';

  FriendExplorationNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(_key, state);
  }
}

final friendExplorationProvider =
    StateNotifierProvider<FriendExplorationNotifier, bool>(
  (ref) => FriendExplorationNotifier(),
);

// ── 활성 친구 목록 ───────────────────────────────────────────────────────

final activeFriendsProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  // TODO: 실서버 연동 시 실제 userId로 교체
  return repo.getActiveFriends('mock_user');
});

// ── 친구 수 (목록 대신 숫자만 노출) ─────────────────────────────────────

final friendCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(activeFriendsProvider).whenData((friends) => friends.length);
});
