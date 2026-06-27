// ═══════════════════════════════════════════════════════════════════════════════
// [이스터에그] 관리자 지정 서비스
//
// 작동 방식:
//   총괄 단말기에서 이음 완료 → 상대방 Firebase UID를 관리자로 Firebase 저장
//   관리자는 복수 지정 가능.
//
// 해제 방식 (두 가지 모두 작동):
//   1. 자동 해제 — 이음 기간 만료 시 자동 해제 (FriendDuration 기준)
//   2. 수동 해제 — 총괄 단말기 전용 관리자 목록 UI에서 즉시 해제
//              → 연결 예정: 총괄 전용 화면 (미구현, 출시 후 작업)
//
// 연결 지점:
//   지정: lib/presentation/widgets/dialogs/ieum_request_dialog.dart
//         → _confirm() 내 confirmRequest 완료 후 호출
//   해제: 총괄 전용 관리자 목록 화면 (미구현)
//         → revoke(uid) 호출
//
// 현재 상태: 비활성화 (_enabled = false)
//   SuperAdminService._enabled = true 와 함께 활성화합니다.
//
// [다른 Claude 세션에 알림]
//   이 파일은 이스터에그 전용입니다. 임의로 수정하거나 삭제하지 마세요.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/friend/data/models/friend_duration.dart';

class AdminDesignationService {
  AdminDesignationService._();

  // [비활성화 스위치] SuperAdminService._enabled 와 함께 true 로 변경
  static const bool _enabled = false;

  static const String _collection = 'admin';
  static const String _doc = 'managers';
  static const String _field = 'managers';

  // ── 지정 ────────────────────────────────────────────────────────────────────

  // 이음 완료 후 총괄이 관리자 지정
  // friendUserId : Friend.friendUserId (이음 상대방 Firebase UID)
  // duration     : 이음 기간 — 만료 시 자동 해제 기준
  static Future<void> designate(String friendUserId, FriendDuration duration) async {
    if (!_enabled) return;
    final list = await _getList();
    list.removeWhere((m) => m['uid'] == friendUserId);
    list.add({
      'uid': friendUserId,
      'expiresAt': DateTime.now().add(duration.duration).toIso8601String(),
    });
    await _save(list);
  }

  // ── 해제 ────────────────────────────────────────────────────────────────────

  // 방법 1 — 자동 해제: 이음 기간 만료 확인 후 제거
  // 앱 실행 시 또는 총괄 화면 진입 시 호출
  static Future<void> removeExpired() async {
    if (!_enabled) return;
    final list = await _getList();
    final now = DateTime.now();
    final active = list.where((m) {
      final exp = DateTime.tryParse(m['expiresAt'] as String? ?? '');
      return exp != null && exp.isAfter(now);
    }).toList();
    await _save(active);
  }

  // 방법 2 — 수동 해제: 총괄 전용 관리자 목록 화면에서 호출
  static Future<void> revoke(String friendUserId) async {
    if (!_enabled) return;
    final list = await _getList();
    list.removeWhere((m) => m['uid'] == friendUserId);
    await _save(list);
  }

  // ── 조회 ────────────────────────────────────────────────────────────────────

  // 특정 UID가 유효한 관리자인지 확인
  static Future<bool> isAdmin(String uid) async {
    if (!_enabled) return false;
    await removeExpired();
    final list = await _getList();
    return list.any((m) => m['uid'] == uid);
  }

  // 총괄 화면용 — 현재 관리자 전체 목록 반환
  // 반환값: [{'uid': String, 'expiresAt': String}, ...]
  static Future<List<Map<String, dynamic>>> getAdminList() async {
    if (!_enabled) return [];
    await removeExpired();
    return await _getList();
  }

  // ── 내부 ────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _getList() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_doc)
          .get();
      if (!doc.exists) return [];
      final data = doc.data()?[_field];
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<Map<String, dynamic>> list) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(_doc)
        .set({_field: list});
  }
}
