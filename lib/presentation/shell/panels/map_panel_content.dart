import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../data/models/cultural_event.dart';
import '../../../dev/mock_partner_event_store.dart';
import '../../../core/providers/partner_focus_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../shell_constants.dart';

class MapPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final bool isOpen;
  const MapPanelContent({super.key, required this.onClose, required this.isOpen});

  @override
  ConsumerState<MapPanelContent> createState() => _MapPanelContentState();
}

class _MapPanelContentState extends ConsumerState<MapPanelContent> {
  final _shownIds = <String>{};
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime? _lastShake;

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _startShake() {
    if (_accelSub != null) return;
    _accelSub = accelerometerEventStream().listen((event) {
      if (!widget.isOpen) return;
      final mag =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mag > 18) {
        final now = DateTime.now();
        if (_lastShake == null ||
            now.difference(_lastShake!) > const Duration(milliseconds: 1500)) {
          _lastShake = now;
          _onShake();
        }
      }
    });
  }

  void _stopShake() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void _onShake() {
    final now = DateTime.now();
    var candidates = ref
        .read(mapEventsProvider)
        .where((e) => e.endDateTime.isAfter(now))
        .toList();
    if (candidates.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }
    final unseen = candidates.where((e) => !_shownIds.contains(e.id)).toList();
    if (unseen.isEmpty) {
      _shownIds.clear();
    } else {
      candidates = unseen;
    }
    candidates.shuffle();
    final picked = candidates.first;
    _shownIds.add(picked.id);
    HapticFeedback.heavyImpact();
    _tapEvent(picked);
  }

  void _tapEvent(CulturalEvent event) {
    widget.onClose();
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = event;
    ref.read(shellPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final myEvents = (ref
        .watch(partnerMyEventsProvider)
        .where((e) => e.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt)));

    final culturalMap = {
      for (final e in ref.watch(mockPartnerEventStoreProvider)) e.id: e,
    };

    final partnerMode = ref.watch(nowPanelPartnerModeProvider);

    if (myEvents.isEmpty) {
      if (partnerMode) {
        _stopShake();
        return const Center(
          child: Text(
            'Z:GUM 등록된 이벤트가 없습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
          ),
        );
      }
      final publicEvents = ref
          .watch(mapEventsProvider)
          .where((e) =>
              e.source == EventSource.public && e.endDateTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.endDateTime.compareTo(b.endDateTime));
      if (publicEvents.isEmpty) {
        _startShake();
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vibration, size: 32, color: Color(0xFFCCCCCC)),
              SizedBox(height: 12),
              Text(
                '기기를 흔들어보세요',
                style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        );
      }
      _stopShake();
      return _PublicEventList(events: publicEvents, onTap: (e) => _tapEvent(e));
    }
    _stopShake();

    final featured = myEvents.first;
    final featuredCultural = culturalMap[featured.id];
    final rest = myEvents
        .skip(1)
        .where((e) => culturalMap.containsKey(e.id))
        .take(2)
        .toList();

    String timeLeft(e) {
      final remaining = e.expiresAt.difference(now);
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      return h > 0 ? '$h시간 $m분 남음' : '$m분 남음';
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final panelH = constraints.maxHeight;
        const topPad = kShellCapsuleHeight + 14.0;
        const botPad = 16.0;
        final totalH = panelH - topPad - botPad;
        final sectionH = totalH / 5;
        const itemH = 40.0;
        const itemGap = 8.0;
        final bottomH =
            rest.isNotEmpty ? rest.length * (itemH + itemGap) : sectionH;
        final featuredH = (totalH - bottomH).clamp(sectionH * 2, sectionH * 4);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, topPad, 16, botPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: featuredCultural != null
                    ? () => _tapEvent(featuredCultural)
                    : null,
                child: Container(
                  height: featuredH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              featured.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLeft(featured),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (featured.representativePhotoPath != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: double.infinity,
                              child: Image.file(
                                File(featured.representativePhotoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(height: 6),
                      Text(
                        featured.venue,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              ...rest.map((e) {
                final cultural = culturalMap[e.id]!;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tapEvent(cultural),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: e.representativePhotoPath != null
                                ? Image.file(
                                    File(e.representativePhotoPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(color: Color(0xFFE0E0E0)),
                                  )
                                : const ColoredBox(color: Color(0xFFE0E0E0)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.venue,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFAAAAAA),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PublicEventList extends StatelessWidget {
  final List<CulturalEvent> events;
  final void Function(CulturalEvent) onTap;

  const _PublicEventList({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, kShellCapsuleHeight + 14, 16, 16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = events[i];
        final remaining = e.endDateTime.difference(now);
        final label = remaining.inDays > 0
            ? '${remaining.inDays}일 남음'
            : remaining.inHours > 0
                ? '${remaining.inHours}시간 남음'
                : '${remaining.inMinutes}분 남음';
        return InkWell(
          onTap: () => onTap(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.venue,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFAAAAAA)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
