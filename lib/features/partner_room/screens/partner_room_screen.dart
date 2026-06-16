import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../features/alert/models/partner_event.dart';
import '../../../features/alert/providers/event_stats_provider.dart';
import 'partner_dashboard_screen.dart';

class PartnerRoomScreen extends ConsumerStatefulWidget {
  const PartnerRoomScreen({super.key});

  @override
  ConsumerState<PartnerRoomScreen> createState() => _PartnerRoomScreenState();
}

class _PartnerRoomScreenState extends ConsumerState<PartnerRoomScreen> {
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;
    final myEvents = ref.watch(partnerMyEventsProvider);
    final sorted = _newestFirst
        ? List<PartnerEvent>.from(myEvents)
        : myEvents.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: SizedBox()),
                if (myEvents.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => setState(() => _newestFirst = !_newestFirst),
                    child: Text(
                      _newestFirst ? '최신순' : '과거순',
                      style: const TextStyle(
                          color: Color(0xFFAAAAAA), fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => const PartnerDashboardScreen()),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: const Icon(
                      Icons.bar_chart_outlined,
                      size: 20,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: Text(
                  '등록된 이벤트가 없습니다',
                  style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: botPad + 16),
                itemCount: sorted.length,
                itemBuilder: (context, index) =>
                    _EventFeedCard(event: sorted[index]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 이벤트 피드 카드 ────────────────────────────────────────────────────────────

class _EventFeedCard extends ConsumerWidget {
  final PartnerEvent event;
  const _EventFeedCard({required this.event});

  void _openDetail(BuildContext context, EventStats? stats) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _EventDetailPopup(event: event, stats: stats),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(eventStatsProvider)[event.id];
    final repPhoto = event.representativePhotoPath;
    final hasPhoto = repPhoto != null;
    final hasMultiplePhotos = event.photos.length > 1;
    final dt = event.startsAt;
    final dateStr = '${dt.month}.${dt.day.toString().padLeft(2, '0')}';
    final isExpired = DateTime.now().isAfter(event.expiresAt);
    final hasStats = stats != null &&
        (stats.visitorCount > 0 || stats.traceCount > 0);

    return GestureDetector(
      onTap: () => _openDetail(context, stats),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhoto)
            Stack(
              children: [
                Image.file(
                  File(repPhoto),
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                if (hasMultiplePhotos)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.collections_outlined,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? const Color(0xFFEEEEEE)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isExpired ? '종료' : '진행 중',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isExpired
                              ? const Color(0xFF888888)
                              : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasStats) ...[
                      Text(
                        '방문 ${stats.visitorCount}  |  흔적 ${stats.traceCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.venue}  ·  $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

// ── 이벤트 상세 팝업 ────────────────────────────────────────────────────────────

class _EventDetailPopup extends StatelessWidget {
  final PartnerEvent event;
  final EventStats? stats;
  const _EventDetailPopup({required this.event, this.stats});

  String _formatDateTime(DateTime dt) =>
      '${dt.year}년 ${dt.month}월 ${dt.day}일  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _durationLabel() {
    final hours = event.expiresAt.difference(event.startsAt).inHours;
    return '$hours시간';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isExpired = DateTime.now().isAfter(event.expiresAt);
    final photos = event.photos;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.72,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: photos.length,
                itemBuilder: (_, i) {
                  final p = photos[i];
                  return Image.file(
                    File(p.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _noPhotoHeader(),
                  );
                },
              ),
            )
          else
            SizedBox(height: 200, child: _noPhotoHeader()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? const Color(0xFFEEEEEE)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isExpired ? '종료' : '진행 중',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isExpired
                                ? const Color(0xFF888888)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _durationLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.venue,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                  if (stats != null &&
                      (stats!.visitorCount > 0 || stats!.traceCount > 0)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statChip('방문', stats!.visitorCount),
                        const SizedBox(width: 8),
                        _statChip('흔적', stats!.traceCount),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  _infoRow('시작', _formatDateTime(event.startsAt)),
                  const SizedBox(height: 6),
                  _infoRow('종료', _formatDateTime(event.expiresAt)),
                  if (event.message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      event.message!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        height: 1.85,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _noPhotoHeader() {
    return Container(
      color: const Color(0xFFF4F6FB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        event.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
          height: 1.4,
        ),
      ),
    );
  }
}
