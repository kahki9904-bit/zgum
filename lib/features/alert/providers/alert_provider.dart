import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_event.dart';
import '../services/firebase_partner_alert_service.dart';
import '../services/partner_alert_service.dart';
import '../../../services/firestore_partner_event_service.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../core/providers/active_partner_event_provider.dart';

// ── 구현체 교체 포인트 ──────────────────────────────────────────────────────────
// Mock → Polling → Firebase: 이 한 줄만 바꾸면 전체 UI가 따라감
final partnerAlertServiceProvider = Provider<PartnerAlertService>((ref) {
  final firestoreService = ref.watch(firestorePartnerEventServiceProvider);
  final service = FirebasePartnerAlertService(service: firestoreService);
  ref.onDispose(service.dispose);
  return service;
});

// ── StateNotifier ──────────────────────────────────────────────────────────────

class PartnerAlertNotifier extends StateNotifier<List<PartnerEvent>> {
  final PartnerAlertService _service;

  PartnerAlertNotifier(this._service) : super(_service.currentEvents) {
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

/// 미확인 알림 존재 여부 — 지금 버튼 점멸 조건 (내가 등록한 이벤트 제외)
final hasUnseenAlertProvider = Provider<bool>((ref) {
  final myEventIds = ref.watch(partnerMyEventsProvider).map((e) => e.id).toSet();
  final activeEvent = ref.watch(activePartnerEventProvider);
  if (activeEvent != null) myEventIds.add(activeEvent.id);
  return ref.watch(partnerAlertProvider).any(
    (e) => !e.seen && !e.isExpired && !myEventIds.contains(e.id),
  );
});
