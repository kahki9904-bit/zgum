import 'dart:async';
import 'dart:io';
import '../../../core/event_fade.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/geo_utils.dart' show walkingMinutes, directionLabel, haversineKm;
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
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.topCenter,
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
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
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

class _SheetWrapper extends StatefulWidget {
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
  State<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends State<_SheetWrapper> {
  bool _alarmSet = false;

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

  int? get _walkingMinutes {
    if (widget.userLocation == null) return null;
    return walkingMinutes(widget.userLocation!, widget.event.location);
  }

  String? get _dirLabel {
    if (widget.userLocation == null) return null;
    return directionLabel(widget.userLocation!, widget.event.location);
  }

  double? get _distanceKm {
    if (widget.userLocation == null) return null;
    return haversineKm(widget.userLocation!, widget.event.location);
  }

  Future<void> _showCheckInDialog() async {
    final memoCtrl = TextEditingController();
    File? photo;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _CheckInDialog(
        event: widget.event,
        memoCtrl: memoCtrl,
        initialPhoto: photo,
        onPhotoPicked: (f) => photo = f,
        onConfirm: () {
          Navigator.pop(dialogCtx);
          widget.onCheckIn?.call(
            memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim(),
            photo?.path,
          );
          if (mounted) Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(dialogCtx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final walkMins = _walkingMinutes;
    final dir = _dirLabel;
    final dist = _distanceKm;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: DraggableScrollableSheet(
        initialChildSize: 0.48,
        minChildSize: 0.28,
        maxChildSize: 0.90,
        builder: (_, controller) => GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _DragHandle(),

                // 파트너 현장 메시지
                if (widget.event.source == EventSource.partner &&
                    widget.event.partnerMessage != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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

                // 친구 흔적 배지
                if (widget.friendTraceCount > 0)
                  _FriendTraceBadge(count: widget.friendTraceCount),

                // 파트너 공간 예약 — Firebase 연동 후 파트너 전용 콘텐츠로 교체
                const SizedBox.shrink(),

                // 정보 바
                if (showTimer || walkMins != null)
                  _InfoBar(
                    endDateTime: widget.event.endDateTime,
                    timeService: widget.timeService,
                    walkingMinutes: walkMins,
                    directionLabel: dir,
                    distanceKm: dist,
                    showTimer: showTimer,
                  ),

                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    children: [content],
                  ),
                ),

                // 하단 버튼
                if (widget.onCheckIn != null)
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
                    child: FilledButton.icon(
                      onPressed:
                          widget.isCheckedIn ? null : _showCheckInDialog,
                      icon: Icon(
                        widget.isCheckedIn
                            ? Icons.check_circle_outline
                            : Icons.where_to_vote_outlined,
                        size: 18,
                      ),
                      label: Text(context.l10n.checkInButton),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 96),
                        backgroundColor: widget.isCheckedIn
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF16213E),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 체크인 다이얼로그 ─────────────────────────────────────────────────────────

class _CheckInDialog extends StatefulWidget {
  final CulturalEvent event;
  final TextEditingController memoCtrl;
  final File? initialPhoto;
  final void Function(File) onPhotoPicked;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CheckInDialog({
    required this.event,
    required this.memoCtrl,
    required this.initialPhoto,
    required this.onPhotoPicked,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  File? _photo;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    setState(() => _photo = file);
    widget.onPhotoPicked(file);
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이벤트 정보
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.event.venue,
              style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 16),

            // 메모
            TextField(
              controller: widget.memoCtrl,
              maxLines: 3,
              maxLength: 100,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: context.l10n.checkInMemoHint,
                hintStyle:
                    const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
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
            const SizedBox(height: 12),

            // 사진
            GestureDetector(
              onTap: _showPhotoOptions,
              child: _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.file(
                            _photo!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _photo = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              size: 22, color: Color(0xFFCCCCCC)),
                          const SizedBox(height: 4),
                          Text(context.l10n.addPhoto,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFCCCCCC))),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: Color(0xFFAAAAAA))),
        ),
        FilledButton(
          onPressed: widget.onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16213E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(context.l10n.checkInButton),
        ),
      ],
    );
  }
}

// ── 정보 바 ────────────────────────────────────────────────────────────────────

class _InfoBar extends StatefulWidget {
  final DateTime endDateTime;
  final TimeService timeService;
  final int? walkingMinutes;
  final String? directionLabel;
  final double? distanceKm;
  final bool showTimer;

  const _InfoBar({
    required this.endDateTime,
    required this.timeService,
    required this.walkingMinutes,
    this.directionLabel,
    this.distanceKm,
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
    const walkColor = Color(0xFF4ECDC4);
    final showWalk = widget.walkingMinutes != null;
    final showTimer = widget.showTimer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: showTimer
            ? timerColor.withValues(alpha: 0.08)
            : walkColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: showTimer
                ? timerColor.withValues(alpha: 0.2)
                : walkColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showWalk) ...[
            const Icon(Icons.near_me_outlined, size: 14, color: walkColor),
            const SizedBox(width: 4),
            Text(
              [
                if (widget.directionLabel != null)
                  '${widget.directionLabel} 방향',
                if (widget.distanceKm != null)
                  '${widget.distanceKm!.toStringAsFixed(1)}km',
                '도보 약 ${widget.walkingMinutes}분',
              ].join(' · '),
              style: const TextStyle(
                color: walkColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showTimer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 1,
                  height: 14,
                  color: timerColor.withValues(alpha: 0.35),
                ),
              ),
          ],
          if (showTimer) ...[
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
        ],
      ),
    );
  }
}

// ── 드래그 핸들 ────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
        ),
      );
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
            const SizedBox(
              width: 16,
              height: 16,
              child: CustomPaint(painter: _FootprintPainter(Color(0xFF3A5FCD))),
            ),
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

class _FootprintPainter extends CustomPainter {
  final Color color;
  const _FootprintPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 발 본체
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.38, size.width * 0.64, size.height * 0.60),
      paint,
    );

    // 발가락 5개
    final toes = [
      Offset(size.width * 0.14, size.height * 0.26),
      Offset(size.width * 0.30, size.height * 0.15),
      Offset(size.width * 0.50, size.height * 0.11),
      Offset(size.width * 0.68, size.height * 0.16),
      Offset(size.width * 0.82, size.height * 0.28),
    ];
    for (final t in toes) {
      canvas.drawCircle(t, size.width * 0.10, paint);
    }
  }

  @override
  bool shouldRepaint(_FootprintPainter old) => old.color != color;
}
