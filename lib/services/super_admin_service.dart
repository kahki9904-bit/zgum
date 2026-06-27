// ═══════════════════════════════════════════════════════════════════════════════
// [이스터에그] 총괄 관리자 인증 시스템
//
// 작동 방식:
//   지도 검색창에 13자리 숫자 입력 → 해시 비교 → 일치 시 Firebase에 현재 기기 등록
//   총괄 단말기는 1대만 유지. 새 기기에서 인증 시 이전 기기 자동 해제.
//
// 현재 상태: 비활성화 (_enabled = false)
//   개발 단계에서는 건드리지 않습니다.
//   출시 직전 _enabled = true 로 변경하여 활성화합니다.
//
// [다른 Claude 세션에 알림]
//   이 파일은 이스터에그 전용입니다. 다른 작업 중 임의로 수정하거나 삭제하지 마세요.
//   _secretHash 값을 절대 변경하지 마세요.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'device_id_service.dart';

class SuperAdminService {
  SuperAdminService._();

  // [비활성화 스위치] 출시 직전 true 로 변경
  static const bool _enabled = false;

  // 총괄 인증 해시값 — 수정 금지
  // [출시 전 삭제] 위 줄의 설명 주석은 출시 직전 반드시 삭제할 것
  static const String _secretHash =
      '9e96189e5ef81a578e023ee47df50fa1752ddfe8a1835b26733cd51e3c75d8c5';

  static const String _collection = 'admin';
  static const String _docId = 'super';
  static const String _field = 'deviceId';

  // 13자리 숫자인지 확인 — 비활성화 시 항상 false 반환
  static bool isCandidate(String query) {
    if (!_enabled) return false;
    if (query.length != 13) return false;
    return RegExp(r'^\d{13}$').hasMatch(query);
  }

  // 인증 시도 — 일치 시 Firebase에 현재 기기 등록, 이전 기기 자동 해제
  static Future<void> tryActivate(String query) async {
    if (!_enabled) return;
    final bytes = utf8.encode(query);
    final hash = sha256.convert(bytes).toString();
    if (hash != _secretHash) return;

    final deviceId = await DeviceIdService.getId();
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(_docId)
        .set({_field: deviceId});
  }

  // 현재 기기가 총괄인지 확인 — 앱 상태와 연동 시 사용
  static Future<bool> isCurrentDeviceAdmin() async {
    if (!_enabled) return false;
    try {
      final deviceId = await DeviceIdService.getId();
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_docId)
          .get();
      if (!doc.exists) return false;
      return doc.data()?[_field] == deviceId;
    } catch (_) {
      return false;
    }
  }
}
