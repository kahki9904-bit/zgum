import 'dart:async';
import 'dart:io';
import '../dialogs/camera_chooser_popup.dart';
import '../../../core/event_fade.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/shell_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/cultural_event.dart';
import '../../../services/notification_service.dart';
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
    void Function(String? memo, String? photoPath)? onCheckIn,
    int friendTraceCount = 0,
  }) async {
    if (!context.mounted) return;

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
              child: _SheetWrapper(
                event: event,
                timeService: timeService,
                userLocation: userLocation,
                onNavigate: onNavigate,
                isCheckedIn: isCheckedIn,
                onCheckIn: onCheckIn,
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
    bool alarmSet = false,
    VoidCallback? onAlarmTap,
    VoidCallback? onNavigateTap,
  }) {
    return switch (event.source) {
      EventSource.partner => PartnerEventContent(
          event: event,
          timeService: timeService,
          alarmSet: alarmSet,
          onAlarmTap: onAlarmTap,
          onNavigateTap: onNavigateTap,
        ),
      EventSource.public => PublicEventContent(
          event: event,
          timeService: timeService,
          alarmSet: alarmSet,
          onAlarmTap: onAlarmTap,
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
  final void Function(String? memo, String? photoPath)? onCheckIn;
  final int friendTraceCount;

  const _SheetWrapper({
    required this.event,
    required this.timeService,
    this.userLocation,
    this.onNavigate,
    this.isCheckedIn = false,
    this.onCheckIn,
    this.friendTraceCount = 0,
  });

  @override
  ConsumerState<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends ConsumerState<_SheetWrapper> {
  bool _alarmSet = false;

  // 흔적 폼 상태
  bool _showForm = false;
  File? _capturedPhoto;
  final _memoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAlarmSlider() async {
    final remaining = widget.event.endDateTime.difference(DateTime.now());
    if (remaining <= Duration.zero) return;

    // 슬라이더 범위: 10분 ~ min(남은시간, 3시간)
    final maxMinutes = remaining.inMinutes.clamp(10, 180).toDouble();

    double selectedMinutes = (maxMinutes / 2).clamp(10, maxMinutes);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final h = (selectedMinutes / 60).floor();
          final m = (selectedMinutes % 60).round();
          final label = h > 0
              ? (m > 0
                  ? ctx.l10n.alarmBeforeHourMin(h, m)
                  : ctx.l10n.alarmBeforeHour(h))
              : ctx.l10n.alarmBeforeMinutes(m);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctx.l10n.alarmSheetTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ctx.l10n.alarmSheetSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16213E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(ctx.l10n.alarmMin10,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                    Expanded(
                      child: Slider(
                        value: selectedMinutes,
                        min: 10,
                        max: maxMinutes,
                        divisions: ((maxMinutes - 10) / 5).round().clamp(1, 34),
                        activeColor: const Color(0xFF16213E),
                        inactiveColor: const Color(0xFFEEEEEE),
                        onChanged: (v) =>
                            setModalState(() => selectedMinutes = v),
                      ),
                    ),
                    Text(
                      maxMinutes >= 60
                          ? ctx.l10n.alarmBeforeHour((maxMinutes / 60).floor())
                          : ctx.l10n.alarmBeforeMinutes(maxMinutes.round()),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final granted =
                        await NotificationService.instance.requestPermission();
                    if (!granted) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.alarmPermissionDenied),
                          ),
                        );
                      }
                      return;
                    }
                    final notifyAt = widget.event.endDateTime
                        .subtract(Duration(minutes: selectedMinutes.round()));
                    await NotificationService.instance.scheduleEventAlarm(
                      eventId: widget.event.id,
                      eventTitle: widget.event.title,
                      notifyAt: notifyAt,
                    );
                    if (mounted) setState(() => _alarmSet = true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(ctx.l10n.alarmConfirm),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
    if (!mounted) return;

    final message = await _showMessagePopup();
    if (!mounted) return;

    setState(() {
      _capturedPhoto = picked != null ? File(picked.path) : null;
      _memoCtrl.text = message ?? '';
      _showForm = true;
    });
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

  Future<void> _saveTrace() async {
    setState(() => _saving = true);
    widget.onCheckIn?.call(
      _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      _capturedPhoto?.path,
    );
    final pageNotifier = ref.read(shellPageProvider.notifier);
    if (!mounted) return;
    Navigator.pop(context);
    // 다이얼로그 종료 애니메이션(280ms)이 완전히 끝난 뒤 페이지 이동
    await Future.delayed(const Duration(milliseconds: 350));
    pageNotifier.state = 0;
  }

  void _cancelTrace() {
    setState(() {
      _showForm = false;
      _capturedPhoto = null;
      _memoCtrl.clear();
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
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
      child: _showForm ? _traceFormView() : _detailView(context),
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
      alarmSet: _alarmSet,
      onAlarmTap: _showAlarmSlider,
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
        if (widget.onCheckIn != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton.icon(
              onPressed: widget.isCheckedIn ? null : _openCamera,
              icon: Icon(
                widget.isCheckedIn
                    ? Icons.check_circle_outline
                    : Icons.where_to_vote_outlined,
                size: 18,
              ),
              label: Text(context.l10n.checkInButton),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: widget.isCheckedIn
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF16213E),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _traceFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.event.venue,
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: i == 0 && _capturedPhoto != null
                          ? Image.file(_capturedPhoto!, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFF4F4F7)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoCtrl,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            decoration: InputDecoration(
              hintText: '한 줄 메모 (선택)',
              hintStyle: const TextStyle(
                  color: Color(0xFFCCCCCC), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
              counterStyle:
                  const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelTrace,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF888888),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('취소',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _saveTrace,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('흔적',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
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
            content: Text('친구 $count명이 이 장소에 흔적을 남겼습니다'),
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
