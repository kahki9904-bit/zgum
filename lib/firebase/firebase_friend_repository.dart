// Firestore 연동 포인트: 컬렉션 'friend_requests', 'friends/{userId}/connections'
// 전환 시: friend_provider.dart 에서 MockFriendRepository → FirebaseFriendRepository 교체
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../features/friend/data/models/friend.dart';
import '../features/friend/data/models/friend_duration.dart';
import '../features/friend/data/models/friend_request.dart';
import '../features/friend/data/repositories/friend_repository.dart';

class FirebaseFriendRepository implements FriendRepository {
  FirebaseFriendRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _rand = Random();

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> _connectionsRef(String userId) =>
      _firestore.collection('friends').doc(userId).collection('connections');

  String _generateCode() => _rand.nextInt(100).toString().padLeft(2, '0');

  // ── A: 신청 브로드캐스트 ───────────────────────────────────────────────────

  @override
  Future<FriendRequest> broadcastRequest({
    required String myUserId,
    required LatLng myLocation,
    required FriendDuration duration,
  }) async {
    final now = DateTime.now();
    final request = FriendRequest(
      id: '${myUserId}_${now.millisecondsSinceEpoch}',
      requesterId: myUserId,
      requesterLocation: myLocation,
      createdAt: now,
      expiresAt: now.add(FriendRepository.requestTtl),
      duration: duration,
    );

    await _requestsRef.doc(request.id).set({
      ...request.toJson(),
      'expiresAtTs': Timestamp.fromDate(request.expiresAt),
    });

    return request;
  }

  // ── B: 근처 신청 감지 ──────────────────────────────────────────────────────

  @override
  Future<List<FriendRequest>> getNearbyRequests({
    required LatLng myLocation,
    required String myUserId,
  }) async {
    try {
      final snapshot = await _requestsRef
          .where('expiresAtTs', isGreaterThan: Timestamp.now())
          .get();

      final all = snapshot.docs
          .map((d) => FriendRequest.fromJson(d.data()))
          .where((r) => r.requesterId != myUserId && !r.isExpired)
          .toList();

      // 거리 필터: 100m 이내
      const calc = Distance();
      return all.where((r) {
        final dist = calc.as(
          LengthUnit.Meter,
          r.requesterLocation,
          myLocation,
        );
        return dist <= FriendRepository.proximityMeters;
      }).toList();
    } catch (e) {
      debugPrint('[FriendRepo] getNearbyRequests 오류: $e');
      return [];
    }
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
    try {
      final doc = await _requestsRef.doc(requestId).get();
      if (!doc.exists) return null;

      final request = FriendRequest.fromJson(doc.data()!);
      if (request.isExpired) return null;

      if (!skipProximityCheck) {
        const calc = Distance();
        final dist = calc.as(
          LengthUnit.Meter,
          request.requesterLocation,
          myLocation,
        );
        if (dist > FriendRepository.proximityMeters) return null;
      }

      final code = _generateCode();
      await _requestsRef.doc(requestId).update({
        'acceptorDuration': duration.name,
        'responseCode': code,
        'acceptorId': myUserId,
      });

      return code;
    } catch (e) {
      debugPrint('[FriendRepo] respondToRequest 오류: $e');
      return null;
    }
  }

  // ── A: B 코드 확인 → 이음 생성 ────────────────────────────────────────────

  @override
  Future<Friend?> confirmRequest({
    required String requestId,
    required String responseCode,
    required String myUserId,
    required LatLng myLocation,
  }) async {
    try {
      final doc = await _requestsRef.doc(requestId).get();
      if (!doc.exists) return null;

      final rawData = doc.data()!;
      final request = FriendRequest.fromJson(rawData);
      if (request.isExpired) return null;
      if (request.responseCode == null) return null;
      if (request.responseCode != responseCode) return null;

      final acceptorId = rawData['acceptorId'] as String?;
      if (acceptorId == null) return null;

      final now = DateTime.now();
      final aDur = request.duration.duration;
      final bDur = (request.acceptorDuration ?? request.duration).duration;
      final effectiveDur = aDur.compareTo(bDur) <= 0 ? aDur : bDur;

      final friendId =
          '${request.requesterId}_${acceptorId}_${now.millisecondsSinceEpoch}';

      final batch = _firestore.batch();

      // A의 connections: 상대방은 B
      final aFriendData = {
        ...Friend(
          id: friendId,
          friendUserId: acceptorId,
          createdAt: now,
          expiresAt: now.add(effectiveDur),
        ).toJson(),
        'expiresAtTs': Timestamp.fromDate(now.add(effectiveDur)),
      };
      batch.set(_connectionsRef(myUserId).doc(friendId), aFriendData);

      // B의 connections: 상대방은 A
      final bFriendData = {
        ...Friend(
          id: friendId,
          friendUserId: myUserId,
          createdAt: now,
          expiresAt: now.add(effectiveDur),
        ).toJson(),
        'expiresAtTs': Timestamp.fromDate(now.add(effectiveDur)),
      };
      batch.set(_connectionsRef(acceptorId).doc(friendId), bFriendData);

      // 사용된 신청 삭제
      batch.delete(_requestsRef.doc(requestId));
      await batch.commit();

      return Friend(
        id: friendId,
        friendUserId: acceptorId,
        createdAt: now,
        expiresAt: now.add(effectiveDur),
      );
    } catch (e) {
      debugPrint('[FriendRepo] confirmRequest 오류: $e');
      return null;
    }
  }

  // ── 활성 이음 목록 ─────────────────────────────────────────────────────────

  @override
  Future<List<Friend>> getActiveFriends(String userId) async {
    try {
      final snapshot = await _connectionsRef(userId)
          .where('expiresAtTs', isGreaterThan: Timestamp.now())
          .get();

      return snapshot.docs
          .map((d) => Friend.fromJson(d.data()))
          .where((f) => f.isActive)
          .toList();
    } catch (e) {
      debugPrint('[FriendRepo] getActiveFriends 오류: $e');
      return [];
    }
  }

  @override
  Future<void> recordNotification(String friendId) async {
    // friendId만으로는 userId를 알 수 없어 현재 사용자 기기에서만 업데이트
    // 실제 알림 기록은 FCM 연동 후 확장
    debugPrint('[FriendRepo] recordNotification: $friendId');
  }

  @override
  Future<void> renewFriend(String friendId, DateTime newExpiry) async {
    // 이음 갱신은 양쪽 모두 업데이트 필요 — FCM 연동 후 확장
    debugPrint('[FriendRepo] renewFriend: $friendId → $newExpiry');
  }

  @override
  Future<void> removeExpiredFriends(String userId) async {
    try {
      final snapshot = await _connectionsRef(userId)
          .where('expiresAtTs', isLessThanOrEqualTo: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) await batch.commit();
    } catch (e) {
      debugPrint('[FriendRepo] removeExpiredFriends 오류: $e');
    }
  }
}
