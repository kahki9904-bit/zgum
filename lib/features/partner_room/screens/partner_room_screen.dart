import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/grid_room_layout.dart';
import '../../../core/popup_layout.dart';
import '../../../core/providers/active_partner_event_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../features/alert/models/partner_event.dart';
import '../../../features/alert/providers/event_stats_provider.dart';
import '../../../presentation/shell/panels/partner_panel_content.dart';
import '../../../presentation/widgets/dialogs/zgum_dialog.dart';
import '../../../presentation/widgets/zgum_orb_button.dart';
import '../../../services/firestore_partner_event_service.dart';
import 'partner_dashboard_screen.dart';

class PartnerRoomScreen extends ConsumerStatefulWidget {
  const PartnerRoomScreen({super.key});

  @override
  ConsumerState<PartnerRoomScreen> createState() => _PartnerRoomScreenState();
}

class _PartnerRoomScreenState extends ConsumerState<PartnerRoomScreen> {
  bool _newestFirst = true;
  bool _singleColumn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyEvents());
  }

  Future<void> _loadMyEvents() async {
    if (!mounted) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final service = ref.read(firestorePartnerEventServiceProvider);
      final events = await service.watchByPartner(uid).first;
      if (mounted) {
        ref.read(partnerMyEventsProvider.notifier).state = events;
      }
    } catch (e) {
      debugPrint('[PartnerRoom] 이벤트 로드 실패: $e');
    }
  }

  void _openRegister(BuildContext context, PartnerEvent? activeEvent) {
    if (activeEvent != null) {
      ref.read(activePartnerEventProvider.notifier).state = activeEvent;
    }
    final popup = PopupLayoutSpec.current;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, __, ___) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height *
                    popup.registerFormFactor,
                margin: popup.registerFormMargin,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(popup.registerFormRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(popup.registerFormRadius),
                  child: ZGumFaintIconBackground(
                    child: PartnerPanelContent(
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;
    final layout = GridRoomLayoutSpec.current;
    final myEvents = ref.watch(partnerMyEventsProvider);
    final now = DateTime.now();
    final watchedActiveEvent = ref.watch(activePartnerEventProvider);
    PartnerEvent? fallbackActiveEvent;
    for (final event in myEvents) {
      if (event.paymentStatus == PaymentStatus.paid &&
          event.expiresAt.isAfter(now)) {
        fallbackActiveEvent = event;
        break;
      }
    }
    final activeEvent = watchedActiveEvent ?? fallbackActiveEvent;
    final latest = myEvents.isEmpty
        ? null
        : myEvents.reduce(
            (a, b) => a.startsAt.isAfter(b.startsAt) ? a : b,
          );
    final rest = myEvents.where((e) => e.id != latest?.id).toList()
      ..sort(
        (a, b) => _newestFirst
            ? b.startsAt.compareTo(a.startsAt)
            : a.startsAt.compareTo(b.startsAt),
      );
    final sorted = [
      if (latest != null) latest,
      ...rest,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + layout.topOffset),
          Padding(
            padding: layout.headerPadding,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RegisterOrb(
                      label: activeEvent == null ? '이곳' : '변경',
                      onTap: () => _openRegister(context, activeEvent),
                    ),
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
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: _HeaderHint(text: '기록을 남겨 보세요'),
                ),
              ],
            ),
          ),
          _PartnerGridControls(
            layout: layout,
            newestFirst: _newestFirst,
            singleColumn: _singleColumn,
            onToggleSort: () => setState(() => _newestFirst = !_newestFirst),
            onToggleColumn: () =>
                setState(() => _singleColumn = !_singleColumn),
          ),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 34),
              child: Center(
                child: Text(
                  '등록된 이벤트가 없습니다',
                  style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.only(top: 0, bottom: botPad + 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _singleColumn ? 1 : 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: sorted.length,
                itemBuilder: (context, index) => _EventGridTile(
                  event: sorted[index],
                  showDownloadMarker: index != 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderHint extends StatelessWidget {
  const _HeaderHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0x66765D35),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );
  }
}

class _RegisterOrb extends StatelessWidget {
  const _RegisterOrb({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ZGumOrbButton(label: label, onTap: onTap);
  }
}

class _PartnerGridControls extends StatelessWidget {
  const _PartnerGridControls({
    required this.layout,
    required this.newestFirst,
    required this.singleColumn,
    required this.onToggleSort,
    required this.onToggleColumn,
  });

  final GridRoomLayoutSpec layout;
  final bool newestFirst;
  final bool singleColumn;
  final VoidCallback onToggleSort;
  final VoidCallback onToggleColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.controlHeight,
      padding: layout.controlPadding,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF0F2F5)),
          bottom: BorderSide(color: Color(0xFFF0F2F5)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleSort,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: layout.controlHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newestFirst ? '최신순' : '오래된순',
                    style: const TextStyle(
                      color: Color(0xFF071426),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '정렬',
                    style: TextStyle(
                      color: Color(0xFFB5BEC7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _GridToolButton(
            icon: singleColumn ? Icons.grid_on_rounded : Icons.crop_square,
            onTap: onToggleColumn,
          ),
        ],
      ),
    );
  }
}

class _GridToolButton extends StatelessWidget {
  const _GridToolButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF0F4)),
        ),
        child: Icon(icon, size: 19, color: const Color(0xFF9AA4AD)),
      ),
    );
  }
}

// ── 이벤트 그리드 ─────────────────────────────────────────────────────────────

class _EventGridTile extends ConsumerWidget {
  final PartnerEvent event;
  final bool showDownloadMarker;

  const _EventGridTile({
    required this.event,
    required this.showDownloadMarker,
  });

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
              child: _EventDetailPopup(
                event: event,
                stats: stats,
                showDownloadMarker: showDownloadMarker,
              ),
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
    final isExpired = DateTime.now().isAfter(event.expiresAt);
    final dateStr =
        '${event.startsAt.month}.${event.startsAt.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _openDetail(context, stats),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            _PartnerEventPhoto(
              path: repPhoto,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          else
            const _EventTileFallback(),
          if (hasMultiplePhotos)
            Positioned(
              top: 8,
              right: 8,
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
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xCCEEEEEE)
                    : const Color(0xCC071426),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isExpired ? '종료' : '진행',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isExpired ? const Color(0xFF777777) : Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x99000000)],
                ),
              ),
              child: Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTileFallback extends StatelessWidget {
  const _EventTileFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFF4F6FB));
  }
}

class _PartnerEventPhoto extends StatelessWidget {
  const _PartnerEventPhoto({
    required this.path,
    required this.fit,
    this.width,
    this.height,
    this.fallback = const _EventTileFallback(),
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget fallback;

  bool get _isRemote =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _DownloadPhotoMarker extends StatelessWidget {
  const _DownloadPhotoMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: const Icon(
        Icons.download_rounded,
        size: 17,
        color: Colors.white,
      ),
    );
  }
}

// ── 이벤트 상세 팝업 ────────────────────────────────────────────────────────────

class _EventDetailPopup extends StatefulWidget {
  final PartnerEvent event;
  final EventStats? stats;
  final bool showDownloadMarker;
  const _EventDetailPopup({
    required this.event,
    this.stats,
    required this.showDownloadMarker,
  });

  @override
  State<_EventDetailPopup> createState() => _EventDetailPopupState();
}

class _EventDetailPopupState extends State<_EventDetailPopup> {
  late final PageController _photoCtrl;
  int _currentPhoto = 0;

  @override
  void initState() {
    super.initState();
    _photoCtrl = PageController();
  }

  @override
  void dispose() {
    _photoCtrl.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) => '${dt.year}년 ${dt.month}월 ${dt.day}일  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _durationLabel() {
    final hours =
        widget.event.expiresAt.difference(widget.event.startsAt).inHours;
    return '$hours시간';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final event = widget.event;
    final stats = widget.stats;
    final isExpired = DateTime.now().isAfter(event.expiresAt);
    final photos = event.photos;

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photos.isNotEmpty)
                  PageView.builder(
                    controller: _photoCtrl,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    itemBuilder: (_, i) {
                      final p = photos[i];
                      return _PartnerEventPhoto(
                        path: p.path,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        fallback: _noPhotoHeader(),
                      );
                    },
                  )
                else
                  _noPhotoHeader(),
                if (photos.isNotEmpty && widget.showDownloadMarker)
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: _DownloadPhotoMarker(),
                  ),
                if (photos.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _currentPhoto ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _currentPhoto
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xCCFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xCCFFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.34),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ON',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
                          if (stats != null &&
                              (stats.visitorCount > 0 ||
                                  stats.traceCount > 0)) ...[
                            const SizedBox(width: 8),
                            _statChip('방문', stats.visitorCount),
                            const SizedBox(width: 6),
                            _statChip('흔적', stats.traceCount),
                          ],
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
                      const SizedBox(height: 14),
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
            ),
          ),
          const SizedBox(height: 2),
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
        widget.event.title,
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
