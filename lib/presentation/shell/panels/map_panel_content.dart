import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cultural_event.dart';
import '../../../core/providers/partner_focus_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../core/providers/active_partner_event_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../shell_constants.dart';

class MapPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final bool isOpen;
  const MapPanelContent(
      {super.key, required this.onClose, required this.isOpen});

  @override
  ConsumerState<MapPanelContent> createState() => _MapPanelContentState();
}

class _MapPanelContentState extends ConsumerState<MapPanelContent> {
  void _tapEvent(CulturalEvent event) {
    widget.onClose();
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = event;
    ref.read(shellPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final events = ref
        .watch(mapEventsProvider)
        .where((e) => e.endDateTime.isAfter(now))
        .toList();
    final partnerEvents = events
        .where((e) => e.source == EventSource.partner)
        .toList()
      ..sort((a, b) => a.endDateTime.compareTo(b.endDateTime));

    if (partnerEvents.isNotEmpty) {
      final myEventIds =
          ref.watch(partnerMyEventsProvider).map((e) => e.id).toSet();
      final activeId = ref.watch(activePartnerEventProvider)?.id;
      return _PartnerEventPanel(
        events: partnerEvents,
        onTap: _tapEvent,
        myEventIds: myEventIds,
        activeEventId: activeId,
      );
    }

    return const SizedBox.shrink();
  }
}

class _PartnerEventPanel extends StatelessWidget {
  final List<CulturalEvent> events;
  final void Function(CulturalEvent) onTap;
  final Set<String> myEventIds;
  final String? activeEventId;

  const _PartnerEventPanel({
    required this.events,
    required this.onTap,
    required this.myEventIds,
    this.activeEventId,
  });

  @override
  Widget build(BuildContext context) {
    final featured = events.first;
    final rest = events.skip(1).toList();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topPad = kShellCapsuleHeight + 14 - bottomInset;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 18),
      child: Column(
        children: [
          SizedBox(
            height: 172,
            child: _PartnerNoticeCard(
              event: featured,
              onTap: () => onTap(featured),
              isMyEvent: myEventIds.contains(featured.id) ||
                  featured.id == activeEventId,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: events.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEDF0F4)),
              itemBuilder: (_, index) {
                final event = index == 0 ? featured : rest[index - 1];
                return _PartnerEventRow(
                  event: event,
                  onTap: () => onTap(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerNoticeCard extends StatelessWidget {
  const _PartnerNoticeCard({
    required this.event,
    required this.onTap,
    this.isMyEvent = false,
  });

  final CulturalEvent event;
  final VoidCallback onTap;
  final bool isMyEvent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _EventImage(event: event, darkFallback: true),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14071426),
                    Color(0x33071426),
                    Color(0xCC071426),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _NoticeBadge(text: isMyEvent ? '나의 이벤트' : '등록 이벤트'),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: _NoticeBadge(
                text: _timeLeft(event.endDateTime),
                dark: true,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event.partnerMessage?.isNotEmpty == true
                        ? event.partnerMessage!
                        : event.venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xC2FFFFFF),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerEventRow extends StatelessWidget {
  const _PartnerEventRow({required this.event, required this.onTap});

  final CulturalEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _EventImage(event: event),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.actionGoldText,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9AA4AD),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _timeLeft(event.endDateTime),
              style: const TextStyle(
                color: Color(0xFF9AA4AD),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event, this.darkFallback = false});

  final CulturalEvent event;
  final bool darkFallback;

  @override
  Widget build(BuildContext context) {
    final image = event.imageUrl;
    if (image != null && image.isNotEmpty) {
      if (image.startsWith('http://') || image.startsWith('https://')) {
        return Image.network(
          image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _EventImageFallback(
            dark: darkFallback,
          ),
        );
      }
      return Image.file(
        File(image),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _EventImageFallback(
          dark: darkFallback,
        ),
      );
    }
    return _EventImageFallback(dark: darkFallback);
  }
}

class _EventImageFallback extends StatelessWidget {
  const _EventImageFallback({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [AppColors.actionGold, AppColors.actionGoldText]
              : const [Color(0xFFD8E3E8), Color(0xFFAABDC7)],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 46,
          height: 46,
          margin: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x669EEEFF),
          ),
        ),
      ),
    );
  }
}

class _NoticeBadge extends StatelessWidget {
  const _NoticeBadge({required this.text, this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xB3071426)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white : AppColors.actionGoldText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _timeLeft(DateTime endDateTime) {
  final remaining = endDateTime.difference(DateTime.now());
  if (remaining.inDays > 0) return '${remaining.inDays}일 남음';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  if (hours > 0) return '$hours시간 $minutes분 남음';
  return '${max(0, remaining.inMinutes)}분 남음';
}
