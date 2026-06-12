import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/free_use_status.dart';
import '../../../core/providers/free_use_provider.dart';
import '../../../core/services/free_use_service.dart';
import '../../../dev/mock_partner_event_store.dart';
import '../../../features/alert/providers/event_stats_provider.dart';

class PartnerDashboardScreen extends ConsumerStatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  ConsumerState<PartnerDashboardScreen> createState() =>
      _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState
    extends ConsumerState<PartnerDashboardScreen> {
  int _remainingCount = 0;

  // TODO(admin): Firebase/Provider 권한값으로 교체 — ref.watch(adminPermissionProvider)
  static const bool _adminUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await FreeUseService.instance.canRegisterToday()
        ? FreeUseService.instance.todayRemainingCount
        : 0;
    if (mounted) setState(() => _remainingCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final freeStatus = ref.watch(freeUseProvider);
    final isFreeActive = freeStatus == FreeUseStatus.active;
    final events = ref.watch(mockPartnerEventStoreProvider);
    final statsMap = ref.watch(eventStatsProvider);

    final now = DateTime.now();
    final activeCount = events.where((e) => e.endDateTime.isAfter(now)).length;
    final expiredCount = events.length - activeCount;

    int totalVisitor = 0;
    int totalTrace = 0;
    for (final e in events) {
      final s = statsMap[e.id];
      if (s != null) {
        totalVisitor += s.visitorCount;
        totalTrace += s.traceCount;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: topPad + 20),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '현황',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ── 기본 권한 항목 ─────────────────────────────────────
                _sectionLabel('기본 현황'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        label: '무료이용',
                        value: isFreeActive ? '활성' : '비활성',
                        valueColor: isFreeActive
                            ? const Color(0xFF16213E)
                            : const Color(0xFFAAAAAA),
                        icon: Icons.card_giftcard_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        label: '오늘 등록 가능',
                        value: isFreeActive ? '$_remainingCount회' : '-',
                        icon: Icons.edit_calendar_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        label: '진행 중',
                        value: '$activeCount건',
                        icon: Icons.campaign_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        label: '종료',
                        value: '$expiredCount건',
                        icon: Icons.history_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        label: '누적 방문',
                        value: totalVisitor > 0 ? '$totalVisitor' : '-',
                        icon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        label: '누적 흔적',
                        value: totalTrace > 0 ? '$totalTrace' : '-',
                        icon: Icons.pets_outlined,
                      ),
                    ),
                  ],
                ),
                if (_adminUnlocked) ...[
                  const SizedBox(height: 32),
                  _sectionLabel('확장 데이터'),
                  const SizedBox(height: 12),
                  _lockedCard('상세 조회 데이터'),
                  const SizedBox(height: 8),
                  _lockedCard('지역 / 시간대 데이터'),
                  const SizedBox(height: 8),
                  _lockedCard('by Z:GUM 확장 데이터'),
                  const SizedBox(height: 8),
                  _lockedCard('관리자 전용 분석'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFFAAAAAA),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFAAAAAA)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedCard(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 15, color: Color(0xFFCCCCCC)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
          const Text(
            '준비 중',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFDDDDDD),
            ),
          ),
        ],
      ),
    );
  }
}
