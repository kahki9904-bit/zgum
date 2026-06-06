import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_model.dart';

// ── 상태 ──────────────────────────────────────────────────────────────────────

class PartnerState {
  /// 현재 유효한 파트너 이벤트 목록.
  /// Provider 가 주기적으로 만료 항목을 제거하므로 항상 '깨끗한 상태'입니다.
  final List<AppModel> events;
  final bool isLoading;
  final String? errorMessage;

  const PartnerState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PartnerState copyWith({
    List<AppModel>? events,
    bool? isLoading,
    String? errorMessage,
  }) =>
      PartnerState(
        events: events ?? this.events,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PartnerNotifier extends StateNotifier<PartnerState> {
  /// 만료 데이터를 자동으로 정화하는 타이머 (1분 주기).
  Timer? _purgeTimer;

  PartnerNotifier() : super(const PartnerState()) {
    _startPurgeTimer();
  }

  // ── 타이머 ──────────────────────────────────────────────────────────────────

  void _startPurgeTimer() {
    _purgeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => purgeExpired(),
    );
  }

  @override
  void dispose() {
    _purgeTimer?.cancel();
    super.dispose();
  }

  // ── 만료 정화 ─────────────────────────────────────────────────────────────────

  /// 현재 시각 기준 만료된 이벤트를 상태에서 제거합니다.
  ///
  /// Timer 에 의해 1분마다 자동 호출됩니다.
  /// UI 는 이 메서드를 직접 호출할 필요가 없습니다.
  void purgeExpired() {
    if (!mounted) return;
    final now = DateTime.now();
    final valid = state.events.where((e) => !e.isExpired(now: now)).toList();
    if (valid.length != state.events.length) {
      state = state.copyWith(events: valid);
    }
  }

  // ── 데이터 로드 ──────────────────────────────────────────────────────────────

  /// 파트너 이벤트 목록을 불러옵니다.
  ///
  /// 로드 시점에도 만료 항목을 걸러냅니다.
  /// TODO: 실서버 API 연동 시 PartnerRepository.fetchMyEvents() 호출로 교체.
  Future<void> loadEvents({required bool isAdultVerified}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: PartnerRepository.fetchMyEvents(isAdultVerified: isAdultVerified)
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      final loaded = <AppModel>[];
      // 로드 즉시 만료 항목 제거 — 항상 깨끗한 상태로 저장
      final valid = loaded.where((e) => !e.isExpired(now: now)).toList();
      state = state.copyWith(isLoading: false, events: valid);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '이벤트를 불러오지 못했습니다.',
      );
    }
  }

  // ── 이벤트 등록 ──────────────────────────────────────────────────────────────

  /// 새 파트너 이벤트를 등록합니다.
  /// TODO: 실서버 API 연동 시 PartnerRepository.register(event) 호출로 교체.
  Future<void> registerEvent(AppModel event) async {
    state = state.copyWith(events: [...state.events, event]);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final partnerProvider =
    StateNotifierProvider<PartnerNotifier, PartnerState>(
  (ref) => PartnerNotifier(),
);
