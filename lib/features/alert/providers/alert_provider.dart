import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_event.dart';
import '../../../dev/mock_partner_alert_service.dart';
import '../services/partner_alert_service.dart';

// ── 구현체 교체 포인트 ──────────────────────────────────────────────────────────
// Mock → Polling → Firebase: 이 한 줄만 바꾸면 전체 UI가 따라감
final partnerAlertServiceProvider = Provider<PartnerAlertService>((ref) {
  final service = MockPartnerAlertService();
  ref.onDispose(service.dispose);
  return service;
});

// ── StateNotifier ──────────────────────────────────────────────────────────────

class PartnerAlertNotifier extends StateNotifier<List<PartnerEvent>> {
  final PartnerAlertService _service;

  PartnerAlertNotifier(this._service) : super([]) {
    _service.events.listen((events) {
      if (mounted) state = events;
    });
  }

  Future<void> markAsSeen(String eventId) => _service.markAsSeen(eventId);

  Future<void> markAllAsSeen() => _service.markAllAsSeen();

  Future<void> refresh() => _service.refresh();
}

final partnerAlertProvider =
    StateNotifierProvider<PartnerAlertNotifier, List<PartnerEvent>>((ref) {
  final service = ref.watch(partnerAlertServiceProvider);
  return PartnerAlertNotifier(service);
});

// ── 파생 Provider ──────────────────────────────────────────────────────────────

/// 미확인 알림 존재 여부 — 지금 버튼 점멸 조건
final hasUnseenAlertProvider = Provider<bool>((ref) {
  return ref.watch(partnerAlertProvider).any((e) => !e.seen && !e.isExpired);
});
