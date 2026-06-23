import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/alert/models/partner_event.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../../../core/providers/active_partner_event_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../promotions/free_use/free_use_service.dart';
import '../../../services/location_service.dart';
import '../../../services/device_id_service.dart';
import '../../../services/firestore_partner_event_service.dart';
import '../../widgets/dialogs/camera_chooser_popup.dart';
import '../../widgets/dialogs/zgum_dialog.dart';
import '../../widgets/popups/confirm/age_confirm_popup.dart';
import '../../widgets/popups/confirm/extend_confirm_popup.dart';
import '../../widgets/popups/confirm/terminate_confirm_popup.dart';
import '../shell_constants.dart';

class PartnerPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const PartnerPanelContent({super.key, required this.onClose});

  @override
  ConsumerState<PartnerPanelContent> createState() =>
      _PartnerPanelContentState();
}

class _PartnerPanelContentState extends ConsumerState<PartnerPanelContent> {
  final _titleCtrl = TextEditingController();
  final _picker = ImagePicker();
  OverlayEntry? _titleOverlay;
  FocusNode? _titleFocusNode;
  OverlayEntry? _descOverlay;
  FocusNode? _descFocusNode;
  final List<File> _photos = [];
  final List<TextEditingController> _photoCtrls = [];
  int _repIndex = 0;
  int _selectedMinutes = 60;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreActiveEvent());
  }

  Future<void> _restoreActiveEvent() async {
    if (!mounted) return;
    if (ref.read(activePartnerEventProvider) != null) return;
    try {
      final deviceId = await DeviceIdService.getId();
      final service = ref.read(firestorePartnerEventServiceProvider);
      final events = await service.watchByPartner(deviceId).first;
      final active = events.where((e) => !e.isExpired).toList();
      if (active.isNotEmpty && mounted) {
        ref.read(activePartnerEventProvider.notifier).state = active.first;
      }
    } catch (e) {
      debugPrint('[PartnerPanel] 활성 이벤트 복원 실패: $e');
    }
  }

  Future<void> _takePhoto() async {
    final shown = await isCameraChooserPopupShown();
    if (!shown && mounted) await showCameraChooserPopup(context);
    if (!mounted) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _photos.add(File(picked.path));
      _photoCtrls.add(TextEditingController());
    });
  }

  void _deletePhoto(int index) {
    setState(() {
      _photoCtrls[index].dispose();
      _photos.removeAt(index);
      _photoCtrls.removeAt(index);
      if (_photos.isEmpty) {
        _repIndex = 0;
      } else if (index == _repIndex) {
        _repIndex = 0;
      } else if (index < _repIndex) {
        _repIndex--;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    if (_photos.isEmpty) return;

    if (!mounted) return;
    final isAdultOnly = await showAgeConfirmPopup(context);
    if (isAdultOnly == null || !mounted) return;

    final isAdmin = ref.read(adminModeProvider);
    final isFreeActive = isAdmin || await FreeUseService.instance.isActive();
    if (!isAdmin && isFreeActive) {
      final canRegister = await FreeUseService.instance.canRegisterToday();
      if (!canRegister) return;
    }

    setState(() => _submitting = true);

    final locationResult = await LocationService().acquireLocation();
    if (!mounted) return;

    final photoList = List.generate(
      _photos.length,
      (i) => PartnerPhoto(
        path: _photos[i].path,
        title: _photoCtrls[i].text.trim().isEmpty
            ? null
            : _photoCtrls[i].text.trim(),
      ),
    );

    final now = DateTime.now();
    final deviceId = await DeviceIdService.getId();
    final event = PartnerEvent(
      id: now.millisecondsSinceEpoch.toString(),
      partnerId: deviceId,
      title: title,
      venue: title,
      message: null,
      location: locationResult.position,
      geoHash: 'mock',
      startsAt: now,
      expiresAt: now.add(Duration(minutes: _selectedMinutes)),
      photos: photoList,
      representativeIndex: _repIndex.clamp(0, photoList.length - 1),
      orderId: 'order-${now.millisecondsSinceEpoch}',
      paymentStatus: PaymentStatus.paid,
      isAdultOnly: isAdultOnly,
    );

    if (isFreeActive) await FreeUseService.instance.recordRegistration();

    final paidEvent =
        event.copyWith(paymentStatus: PaymentStatus.paid, paidAt: now);

    ref.read(activePartnerEventProvider.notifier).state = paidEvent;

    try {
      await ref.read(firestorePartnerEventServiceProvider).save(paidEvent);
    } catch (_) {
      if (mounted) ref.read(activePartnerEventProvider.notifier).state = null;
      if (!mounted) return;
      setState(() => _submitting = false);
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, __, ___) => GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: const ZGumDialog(
                heightFactor: 0.22,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '등록 실패',
                      style: ZGumDialogTextStyles.sectionTitle,
                    ),
                    SizedBox(height: 10),
                    Text(
                      '저장 중 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.',
                      style: ZGumDialogTextStyles.confirmBody,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        transitionBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );
      return;
    }

    if (!mounted) return;
    widget.onClose();
  }

  void _showDescOverlay(int index) {
    _descOverlay?.remove();
    _descFocusNode?.dispose();
    _descFocusNode = FocusNode();
    final node = _descFocusNode!;
    _descOverlay = OverlayEntry(
      builder: (_) => _TitleInputBar(
        controller: _photoCtrls[index],
        focusNode: node,
        onClose: _closeDescOverlay,
      ),
    );
    Overlay.of(context).insert(_descOverlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _closeDescOverlay() {
    FocusScope.of(context).unfocus();
    _descOverlay?.remove();
    _descOverlay = null;
    setState(() {});
  }

  void _showTitleOverlay() {
    _titleFocusNode?.dispose();
    _titleFocusNode = FocusNode();
    final node = _titleFocusNode!;
    _titleOverlay = OverlayEntry(
      builder: (_) => _TitleInputBar(
        controller: _titleCtrl,
        focusNode: node,
        onClose: _closeTitleOverlay,
      ),
    );
    Overlay.of(context).insert(_titleOverlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  void _closeTitleOverlay() {
    FocusScope.of(context).unfocus();
    _titleOverlay?.remove();
    _titleOverlay = null;
    setState(() {});
  }

  @override
  void dispose() {
    _titleOverlay?.remove();
    _titleFocusNode?.dispose();
    _descOverlay?.remove();
    _descFocusNode?.dispose();
    _titleCtrl.dispose();
    for (final c in _photoCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvent = ref.watch(activePartnerEventProvider);
    if (activeEvent != null) {
      return _ActiveEventWaitingView(
          event: activeEvent, onClose: widget.onClose);
    }
    final formTopPadding = Platform.isIOS ? 18.0 : kShellPanelHandleContentGap;
    final titleToPhotosGap = Platform.isIOS ? 14.0 : 40.0;
    final photosToControlsGap = Platform.isIOS ? 10.0 : 32.0;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              formTopPadding,
              24,
              82 + bottomSafe,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '제목',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showTitleOverlay,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _titleCtrl,
                      builder: (_, value, __) => Text(
                        value.text.isEmpty ? '필수' : value.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: value.text.isEmpty
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: titleToPhotosGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                          child: AspectRatio(
                              aspectRatio: 1.2, child: _buildPhotoCell(i))),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: i < _photos.length
                            ? _buildDescField(i)
                            : const SizedBox(height: 26),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: photosToControlsGap),
                Row(
                  children: [
                    const Text(
                      '노출시간',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555)),
                    ),
                    const SizedBox(width: 12),
                    ...[60, 120, 180].map((min) {
                      final selected = _selectedMinutes == min;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMinutes = min),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF16213E)
                                  : const Color(0xFFF4F4F7),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${min ~/ 60}시간',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF888888),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18 + bottomSafe,
            child: Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.5,
                child: FutureBuilder<(bool, bool)>(
                  future: () async {
                    final isAdmin = ref.read(adminModeProvider);
                    if (isAdmin) return (true, true);
                    final active = await FreeUseService.instance.isActive();
                    final canRegister = active
                        ? await FreeUseService.instance.canRegisterToday()
                        : true;
                    return (active, canRegister);
                  }(),
                  builder: (context, snapshot) {
                    final isFree = snapshot.data?.$1 == true;
                    final canRegister = snapshot.data?.$2 != false;
                    final disabled = _submitting || !canRegister;
                    return GestureDetector(
                      onTap: disabled ? null : _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: disabled
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isFree ? '무료이용' : '등록',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCell(int i) {
    if (i < _photos.length) {
      final isRep = i == _repIndex;
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_photos[i], fit: BoxFit.cover),
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: () => setState(() => _repIndex = i),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isRep
                        ? const Color(0xFF16213E)
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isRep ? Icons.star : Icons.star_border,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (i == _photos.length && _photos.length < 3) {
      return GestureDetector(
        onTap: _takePhoto,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_a_photo_outlined,
                    size: 20, color: Color(0xFFAAAAAA)),
                if (i == 0) ...[
                  const SizedBox(height: 4),
                  const Text('필수',
                      style: TextStyle(fontSize: 11, color: Color(0xFFCC3333))),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildDescField(int i) {
    return GestureDetector(
      onTap: () => _showDescOverlay(i),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _photoCtrls[i],
          builder: (_, value, __) => Text(
            value.text.isEmpty ? '내용' : value.text,
            style: TextStyle(
              fontSize: 11,
              color: value.text.isEmpty
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ── 제목/설명 입력 오버레이 바 ────────────────────────────────────────────────

class _TitleInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;
  const _TitleInputBar(
      {required this.controller,
      required this.focusNode,
      required this.onClose});

  @override
  State<_TitleInputBar> createState() => _TitleInputBarState();
}

class _TitleInputBarState extends State<_TitleInputBar> {
  @override
  Widget build(BuildContext context) {
    final bottom =
        Platform.isIOS ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: Material(
            color: Colors.white,
            elevation: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          decoration: TextDecoration.none),
                      cursorColor: const Color(0xFF16213E),
                      decoration: const InputDecoration(
                        hintText: '이벤트 제목',
                        hintStyle:
                            TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => widget.onClose(),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 이벤트 진행 중 대기 화면 ──────────────────────────────────────────────────

class _ActiveEventWaitingView extends ConsumerStatefulWidget {
  final PartnerEvent event;
  final VoidCallback onClose;
  const _ActiveEventWaitingView({required this.event, required this.onClose});

  @override
  ConsumerState<_ActiveEventWaitingView> createState() =>
      _ActiveEventWaitingViewState();
}

class _ActiveEventWaitingViewState
    extends ConsumerState<_ActiveEventWaitingView> {
  Timer? _timer;
  late Duration _remaining;
  bool _extending = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateRemaining);
      if (_remaining <= Duration.zero) _finish();
    });
  }

  void _updateRemaining() {
    final diff = widget.event.expiresAt.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  bool _withinRefundThreshold() {
    final total = widget.event.expiresAt.difference(widget.event.startsAt);
    final elapsed = DateTime.now().difference(widget.event.startsAt);
    final thresholdSeconds = total.inSeconds ~/ 6;
    return elapsed.inSeconds < thresholdSeconds;
  }

  void _showExtendConfirm() {
    showExtendConfirmPopup(context).then((confirmed) {
      if (confirmed == true) _extend();
    });
  }

  void _showTerminateConfirm() {
    final hours =
        widget.event.expiresAt.difference(widget.event.startsAt).inHours;
    final withinThreshold = _withinRefundThreshold();
    final message = withinThreshold
        ? '시간이 남아있습니다.\n$hours시간 재등록 1회 가능'
        : '${_formatDuration(_remaining)} 남아있습니다.\n종료하시겠습니까?';
    showTerminateConfirmPopup(context, message).then((confirmed) {
      if (confirmed == true) _terminate();
    });
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    unawaited(
        ref.read(firestorePartnerEventServiceProvider).expire(widget.event.id));
    final list = ref.read(partnerMyEventsProvider);
    ref.read(partnerMyEventsProvider.notifier).state = [widget.event, ...list];
    ref.read(activePartnerEventProvider.notifier).state = null;
    widget.onClose();
  }

  void _terminate() {
    _timer?.cancel();
    _timer = null;
    unawaited(
        ref.read(firestorePartnerEventServiceProvider).expire(widget.event.id));
    ref.read(activePartnerEventProvider.notifier).state = null;
    widget.onClose();
  }

  Future<void> _extend() async {
    if (_extending) return;
    setState(() => _extending = true);
    try {
      final isAdmin = ref.read(adminModeProvider);
      final isFreeActive = isAdmin || await FreeUseService.instance.isActive();
      if (!isAdmin && isFreeActive) {
        final canRegister = await FreeUseService.instance.canRegisterToday();
        if (!canRegister) return;
      }
      if (isFreeActive) await FreeUseService.instance.recordRegistration();

      final newExpiresAt = widget.event.expiresAt.add(const Duration(hours: 1));
      await ref
          .read(firestorePartnerEventServiceProvider)
          .extend(widget.event.id, newExpiresAt);
      final extendedEvent = widget.event.copyWith(expiresAt: newExpiresAt);
      ref.read(activePartnerEventProvider.notifier).state = extendedEvent;
    } finally {
      if (mounted) setState(() => _extending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining <= Duration.zero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            '이벤트 진행 중',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const Spacer(),
          Text(
            isExpired ? '종료됨' : _formatDuration(_remaining),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              color:
                  isExpired ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A2E),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isExpired ? '' : '남은 시간',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
          const Spacer(),
          if (isExpired)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                '종료 완료',
                style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _extending ? null : _showExtendConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _extending
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '연장',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTerminateConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '종료',
                        style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
