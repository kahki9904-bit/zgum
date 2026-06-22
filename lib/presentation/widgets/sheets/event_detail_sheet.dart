import 'dart:async';
import '../dialogs/camera_chooser_popup.dart';
import '../../../core/event_fade.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/shell_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/check_in_record.dart';
import '../../../data/models/cultural_event.dart';
import '../../../services/time_service.dart';
import 'event_content_base.dart';
import 'partner_event_content.dart';
import 'public_event_content.dart';

class EventDetailSheet {
  const EventDetailSheet._();

  static Future<void> show(
    BuildContext context,
    CulturalEvent event, {
    required TimeService timeService,
    LatLng? userLocation,
    VoidCallback? onNavigate,
    bool isCheckedIn = false,
    bool canCheckIn = false,
    int friendTraceCount = 0,
  }) async {
    if (!context.mounted) return;

    await showGeneralDialog<void>(
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
              child: _SheetWrapper(
                event: event,
                timeService: timeService,
                userLocation: userLocation,
                onNavigate: onNavigate,
                isCheckedIn: isCheckedIn,
                canCheckIn: canCheckIn,
                friendTraceCount: friendTraceCount,
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

  static EventContentBase _contentFor(
    CulturalEvent event,
    TimeService timeService, {
    bool interestSet = false,
    VoidCallback? onInterestTap,
    VoidCallback? onNavigateTap,
  }) {
    return switch (event.source) {
      EventSource.partner => PartnerEventContent(
          event: event,
          timeService: timeService,
          onNavigateTap: onNavigateTap,
        ),
      EventSource.public => PublicEventContent(
          event: event,
          timeService: timeService,
          interestSet: interestSet,
          onInterestTap: onInterestTap,
          onNavigateTap: onNavigateTap,
        ),
    };
  }
}

// ── 시트 래퍼 (StatefulWidget — 체크인 다이얼로그 상태 관리) ─────────────────────

class _SheetWrapper extends ConsumerStatefulWidget {
  final CulturalEvent event;
  final TimeService timeService;
  final LatLng? userLocation;
  final VoidCallback? onNavigate;
  final bool isCheckedIn;
  final bool canCheckIn;
  final int friendTraceCount;

  const _SheetWrapper({
    required this.event,
    required this.timeService,
    this.userLocation,
    this.onNavigate,
    this.isCheckedIn = false,
    this.canCheckIn = false,
    this.friendTraceCount = 0,
  });

  @override
  ConsumerState<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends ConsumerState<_SheetWrapper> {
  bool _interestSet = false;

  bool get _showTimer {
    if (widget.event.source == EventSource.partner) return true;
    return widget.event.endDateTime.difference(widget.timeService.now()) <
        const Duration(hours: 24);
  }

  Future<void> _openCamera() async {
    final shown = await isCameraChooserPopupShown();
    if (!shown && mounted) await showCameraChooserPopup(context);
    if (!mounted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (!mounted || picked == null) return;

    final message = await _showMessagePopup();
    if (!mounted) return;

    final record = CheckInRecord.fromEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: widget.event.id,
      eventTitle: widget.event.title,
      venue: widget.event.venue,
      category: widget.event.category,
      checkedInAt: DateTime.now(),
      memo: message,
      photoPath: picked.path,
    );
    ref.read(panelPendingTraceProvider.notifier).state = record;
    final traceNotifier = ref.read(traceJustCompletedProvider.notifier);
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 350));
    traceNotifier.state = true;
  }

  Future<String?> _showMessagePopup() async {
    final ctrl = TextEditingController();
    String? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '한 줄 메시지',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLength: 100,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '이 순간을 기록해보세요',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFCCCCCC)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
                counterStyle: const TextStyle(
                    fontSize: 11, color: Color(0xFFCCCCCC)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = null;
              Navigator.pop(dialogCtx);
            },
            child: const Text('건너뛰기',
                style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          FilledButton(
            onPressed: () {
              result =
                  ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
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
      child: _detailView(context),
    );
  }

  Widget _detailView(BuildContext context) {
    final navigateCallback = widget.onNavigate != null
        ? () {
            Navigator.pop(context);
            widget.onNavigate!();
          }
        : null;
    final content = EventDetailSheet._contentFor(
      widget.event,
      widget.timeService,
      interestSet: _interestSet,
      onInterestTap: () => setState(() => _interestSet = true),
      onNavigateTap: navigateCallback,
    );
    final showTimer = _showTimer;

    return Column(
      children: [
        if (widget.event.source == EventSource.partner &&
            widget.event.partnerMessage != null)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD580)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 15, color: Color(0xFFFF8C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.partnerMessage!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF555555)),
                  ),
                ),
              ],
            ),
          ),
        if (widget.friendTraceCount > 0)
          _FriendTraceBadge(count: widget.friendTraceCount),
        if (showTimer)
          _InfoBar(
            endDateTime: widget.event.endDateTime,
            timeService: widget.timeService,
            showTimer: showTimer,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [content],
          ),
        ),
        if (widget.canCheckIn)
          Builder(builder: (context) {
            final pending = ref.watch(panelPendingTraceProvider);
            final blocked = widget.isCheckedIn || pending?.eventId == widget.event.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  child: GestureDetector(
                    onTap: blocked ? null : _openCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: blocked
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '지금',
                        style: TextStyle(
                          color: blocked
                              ? const Color(0xFF888888)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

}

// ── 정보 바 ────────────────────────────────────────────────────────────────────

class _InfoBar extends StatefulWidget {
  final DateTime endDateTime;
  final TimeService timeService;
  final bool showTimer;

  const _InfoBar({
    required this.endDateTime,
    required this.timeService,
    required this.showTimer,
  });

  @override
  State<_InfoBar> createState() => _InfoBarState();
}

class _InfoBarState extends State<_InfoBar> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    if (widget.showTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remaining = _calcRemaining());
      });
    }
  }

  Duration _calcRemaining() {
    return widget.endDateTime.difference(widget.timeService.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isUrgent =>
      _remaining > Duration.zero && _remaining < const Duration(hours: 1);

  String _timerLabel(BuildContext context) {
    if (_remaining > Duration.zero) {
      if (_remaining >= const Duration(days: 1)) {
        return context.l10n.timerDaysLeft(_remaining.inDays, _remaining.inHours % 24);
      }
      final h = _remaining.inHours;
      final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
      final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }
    final neg = EventFade.negativeLabel(widget.endDateTime, widget.timeService.now());
    return neg ?? context.l10n.timerEnded;
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _isUrgent
        ? const Color(0xFFE74C3C)
        : _remaining <= Duration.zero
            ? const Color(0xFF999999)
            : const Color(0xFF555555);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: timerColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: timerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: timerColor),
          const SizedBox(width: 7),
          Text(
            _timerLabel(context),
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 친구 흔적 배지 ────────────────────────────────────────────────────────────────

class _FriendTraceBadge extends StatelessWidget {
  final int count;

  const _FriendTraceBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count == 1 ? '친구가 이 장소에 흔적을 남겼습니다' : '친구들이 이 장소에 흔적을 남겼습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4FF),
          border: Border(
            bottom: BorderSide(color: Color(0xFFD8E2FF), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, size: 18, color: Color(0xFF3A5FCD)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3A5FCD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
