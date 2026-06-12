import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/friend/data/models/friend.dart';
import '../features/friend/data/models/friend_duration.dart';
import '../features/friend/data/models/friend_request.dart';
import '../features/friend/data/repositories/friend_repository.dart';

class MockFriendRepository implements FriendRepository {
  static const _friendsKey = 'zgum_mock_friends';
  static const _requestsKey = 'zgum_mock_requests';

  final _rand = Random();

  // 1회용 2자리 랜덤 코드 (00~99)
  String _generateCode() => _rand.nextInt(100).toString().padLeft(2, '0');

  // ── A: 신청 ───────────────────────────────────────────────────────────────

  @override
  Future<FriendRequest> broadcastRequest({
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await _loadRequests(prefs);
    final now = DateTime.now();
    final request = FriendRequest(
      id: '${myUserId}_${now.millisecondsSinceEpoch}',
      requesterId: myUserId,
      requesterLocation: myLocation,
      createdAt: now,
      expiresAt: now.add(FriendRepository.requestTtl),
      duration: duration,
    );
    requests.add(request);
    await _saveRequests(prefs, requests);
    return request;
  }

  // ── B: 신청 감지 ──────────────────────────────────────────────────────────

  @override
  Future<List<FriendRequest>> getNearbyRequests({
    required LatLng myLocation,
    required String myUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await _loadRequests(prefs);
    return requests.where((r) => r.requesterId != myUserId).toList();
  }

  // ── B: 기간 선택 → 1회용 코드 생성 ───────────────────────────────────────

  @override
  Future<String?> respondToRequest({
    required String requestId,
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
    bool skipProximityCheck = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await _loadRequests(prefs);
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return null;

    if (!skipProximityCheck) {
      const calc = Distance();
      final dist = calc.as(
        LengthUnit.Meter,
        requests[idx].requesterLocation,
        myLocation,
      );
      if (dist > FriendRepository.proximityMeters) return null;
    }

    final code = _generateCode();
    requests[idx] = requests[idx].copyWith(
      acceptorDuration: duration,
      responseCode: code,
    );
    await _saveRequests(prefs, requests);
    return code;
  }

  // ── A: B 코드 확인 → 이음 생성 ────────────────────────────────────────────

  @override
  Future<Friend?> confirmRequest({
    required String requestId,
    required String responseCode,
    required String myUserId,
    required LatLng myLocation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await _loadRequests(prefs);
    final request = requests.where((r) => r.id == requestId).firstOrNull;

    if (request == null) return null;
    if (request.isExpired) return null;
    if (request.responseCode == null) return null;
    if (request.responseCode != responseCode) return null;

    final now = DateTime.now();
    // 유효기간 = min(A 기간, B 기간)
    final aDur = request.duration.duration;
    final bDur = (request.acceptorDuration ?? request.duration).duration;
    final effectiveDur = aDur.compareTo(bDur) <= 0 ? aDur : bDur;

    final friend = Friend(
      id: '${request.requesterId}_${myUserId}_${now.millisecondsSinceEpoch}',
      friendUserId: request.requesterId,
      createdAt: now,
      expiresAt: now.add(effectiveDur),
    );

    final friends = await _loadFriends(prefs);
    friends.add(friend);
    await _saveFriends(prefs, friends);

    // 사용된 코드 폐기 (요청 삭제)
    await _saveRequests(
      prefs,
      requests.where((r) => r.id != requestId).toList(),
    );

    return friend;
  }

  // ── 활성 이음 ──────────────────────────────────────────────────────────────

  @override
  Future<List<Friend>> getActiveFriends(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadFriends(prefs);
    return all.where((f) => f.isActive).toList();
  }

  @override
  Future<void> recordNotification(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await _loadFriends(prefs);
    final idx = friends.indexWhere((f) => f.id == friendId);
    if (idx < 0) return;
    friends[idx] = friends[idx].copyWith(lastNotifiedAt: DateTime.now());
    await _saveFriends(prefs, friends);
  }

  @override
  Future<void> renewFriend(String friendId, DateTime newExpiry) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await _loadFriends(prefs);
    final idx = friends.indexWhere((f) => f.id == friendId);
    if (idx < 0) return;
    friends[idx] = friends[idx].copyWith(expiresAt: newExpiry);
    await _saveFriends(prefs, friends);
  }

  @override
  Future<void> removeExpiredFriends(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadFriends(prefs);
    await _saveFriends(prefs, all.where((f) => f.isActive).toList());
  }

  // ── 내부 헬퍼 ─────────────────────────────────────────────────────────────

  Future<List<FriendRequest>> _loadRequests(SharedPreferences prefs) async {
    final raw = prefs.getString(_requestsKey);
    if (raw == null) return [];
    final all = FriendRequest.listFromJson(raw);
    return all.where((r) => !r.isExpired).toList();
  }

  Future<void> _saveRequests(
      SharedPreferences prefs, List<FriendRequest> requests) async {
    await prefs.setString(_requestsKey, FriendRequest.listToJson(requests));
  }

  Future<List<Friend>> _loadFriends(SharedPreferences prefs) async {
    final raw = prefs.getString(_friendsKey);
    if (raw == null) return [];
    return Friend.listFromJson(raw);
  }

  Future<void> _saveFriends(
      SharedPreferences prefs, List<Friend> friends) async {
    await prefs.setString(_friendsKey, Friend.listToJson(friends));
  }
}
