import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../../../dev/mock_partner_event_store.dart';
import '../../../features/alert/providers/event_stats_provider.dart';
import '../../../promotions/free_use/free_use_service.dart';

class PartnerDashboardScreen extends ConsumerStatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  ConsumerState<PartnerDashboardScreen> createState() =>
      _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState
    extends ConsumerState<PartnerDashboardScreen> {
  int _remainingDays = 0;
  bool _freeActive = false;
  bool _canRegisterToday = false;

  @override
  void initState() {
    super.initState();
    _loadFreeUseStatus();
  }

  Future<void> _loadFreeUseStatus() async {
    final isAdmin = ref.read(adminModeProvider);
    if (isAdmin) {
      setState(() {
        _remainingDays = 999;
        _freeActive = true;
        _canRegisterToday = true;
      });
      return;
    }
    final days = await FreeUseService.instance.remainingDays();
    final active = await FreeUseService.instance.isActive();
    final canReg = await FreeUseService.instance.canRegisterToday();
    if (!mounted) return;
    setState(() {
      _remainingDays = days;
      _freeActive = active;
      _canRegisterToday = canReg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isAdmin = ref.watch(adminModeProvider);
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
                _sectionLabel('무료이용'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        label: '무료이용 상태',
                        value: _freeActive ? '활성' : '비활성',
                        icon: Icons.card_giftcard_outlined,
                        valueColor: _freeActive
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        label: '오늘 등록 가능',
                        value: _freeActive
                            ? (_canRegisterToday ? '가능' : '한도 초과')
                            : '-',
                        icon: Icons.today_outlined,
                        valueColor: _canRegisterToday && _freeActive
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoCard(
                  label: '무료이용 잔여',
                  value: _freeActive ? '$_remainingDays일' : '-',
                  icon: Icons.hourglass_empty_outlined,
                  wide: true,
                ),
                const SizedBox(height: 24),
                _sectionLabel('기본 현황'),
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
                const SizedBox(height: 24),
                _sectionLabel('확장 데이터'),
                const SizedBox(height: 12),
                _lockedCard('상세 조회 데이터'),
                const SizedBox(height: 8),
                _lockedCard('지역 / 시간대 데이터'),
                const SizedBox(height: 8),
                _lockedCard('by Z:GUM 확장 데이터'),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  _lockedCard('관리자 전용 분석'),
                ],
                const SizedBox(height: 32),
                _sectionLabel('개발자'),
                const SizedBox(height: 12),
                const _AdminModeToggle(),
                const SizedBox(height: 8),
                const _NowPanelModeToggle(),
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
    bool wide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: wide
          ? Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFFAAAAAA)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? const Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            )
          : Column(
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
              style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
            ),
          ),
          const Text(
            '준비 중',
            style: TextStyle(fontSize: 11, color: Color(0xFFDDDDDD)),
          ),
        ],
      ),
    );
  }
}

class _AdminModeToggle extends ConsumerWidget {
  const _AdminModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(adminModeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAdmin ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              size: 17,
              color: isAdmin ? Colors.white : const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '관리자 모드',
              style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          Switch(
            value: isAdmin,
            onChanged: (v) => ref.read(adminModeProvider.notifier).state = v,
            activeThumbColor: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }
}

class _NowPanelModeToggle extends ConsumerWidget {
  const _NowPanelModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerMode = ref.watch(nowPanelPartnerModeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: partnerMode ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune,
              size: 16,
              color: partnerMode ? Colors.white : const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '지금 패널 파트너 전용',
              style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
            ),
          ),
          Switch(
            value: partnerMode,
            onChanged: (v) => ref.read(nowPanelPartnerModeProvider.notifier).state = v,
            activeThumbColor: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }
}
