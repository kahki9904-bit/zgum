import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/alert/models/partner_event.dart';
import '../../../core/providers/admin_mode_provider.dart';
import '../../../core/providers/active_partner_event_provider.dart';
import '../../../core/providers/partner_my_events_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../promotions/free_use/free_use_service.dart';
import '../../../services/location_service.dart';
import '../../../services/device_id_service.dart';
import '../../../services/firestore_partner_event_service.dart';
import '../../widgets/dialogs/zgum_dialog.dart';
import '../../widgets/dialogs/photo_viewer_popup.dart';
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
  final _contentCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();
  final _picker = ImagePicker();
  final List<File> _photos = [];
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
    if (!mounted) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() => _photos.add(File(picked.path)));
  }

  void _deletePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _openPhotoViewer(int index) async {
    if (_photos.isEmpty) return;
    await showPhotoViewerPopup(context, _photos, initialIndex: index);
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

    final photoList = _photos.map((f) => PartnerPhoto(path: f.path)).toList();

    final now = DateTime.now();
    final deviceId = await DeviceIdService.getId();
    final event = PartnerEvent(
      id: now.millisecondsSinceEpoch.toString(),
      partnerId: deviceId,
      title: title,
      venue: title,
      message:
          _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
      location: locationResult.position,
      geoHash: 'mock',
      startsAt: now,
      expiresAt: now.add(Duration(minutes: _selectedMinutes)),
      photos: photoList,
      representativeIndex: 0,
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
                    Text('등록 실패', style: ZGumDialogTextStyles.sectionTitle),
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
    ref.read(shellPageProvider.notifier).state = 1;
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _contentFocus.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvent = ref.watch(activePartnerEventProvider);
    if (activeEvent != null) {
      return _ActiveEventWaitingView(
          event: activeEvent, onClose: widget.onClose);
    }

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 100;
    final compactInput = Platform.isIOS;
    final formTopPadding = Platform.isIOS ? 18.0 : kShellPanelHandleContentGap;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final titleVerticalPadding = compactInput ? 8.0 : 12.0;
    final contentVerticalPadding = compactInput ? 8.0 : 14.0;
    final inputGap = compactInput ? 4.0 : 8.0;
    final photoTopGap = compactInput ? 8.0 : 14.0;
    final timeTopGap = compactInput ? 8.0 : 16.0;

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
              keyboardVisible ? 16 : 82 + bottomSafe,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleCtrl,
                  focusNode: _titleFocus,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  cursorColor: const Color(0xFF16213E),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _contentFocus.requestFocus(),
                  decoration: InputDecoration(
                    hintText: '제목 (필수)',
                    hintStyle:
                        const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: titleVerticalPadding),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF16213E), width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
                SizedBox(height: inputGap),
                TextField(
                  controller: _contentCtrl,
                  focusNode: _contentFocus,
                  maxLines: compactInput ? 1 : 2,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _contentFocus.unfocus(),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
                  cursorColor: const Color(0xFF16213E),
                  decoration: InputDecoration(
                    hintText: '내용',
                    hintStyle:
                        const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: contentVerticalPadding),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF16213E), width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: photoTopGap),
                _buildPhotoRow(),
                if (!keyboardVisible) ...[
                  SizedBox(height: timeTopGap),
                  _buildTimeSelection(),
                ],
              ],
            ),
          ),
          if (!keyboardVisible)
            Positioned(
              left: 24,
              right: 24,
              bottom: 18 + bottomSafe,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  child: _buildRegisterButton(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow() {
    final compactHint = Platform.isIOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildPhotoSlot(i),
                ),
              ),
            ],
          ],
        ),
        if (_photos.length > 1) ...[
          SizedBox(height: compactHint ? 2 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: compactHint ? 10 : 13,
                color: const Color(0xFFBBBBBB),
              ),
              const SizedBox(width: 4),
              Text(
                '자리이동',
                style: TextStyle(
                  fontSize: compactHint ? 8 : 10,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSlot(int i) {
    if (i < _photos.length) {
      return LayoutBuilder(builder: (context, constraints) {
        final size = constraints.maxWidth;
        return DragTarget<int>(
          onAcceptWithDetails: (details) {
            final from = details.data;
            if (from == i) return;
            setState(() {
              final item = _photos.removeAt(from);
              _photos.insert(i, item);
            });
          },
          builder: (context, candidateData, _) {
            return GestureDetector(
              onTap: () => _openPhotoViewer(i),
              behavior: HitTestBehavior.opaque,
              child: Draggable<int>(
                data: i,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.08,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_photos[i], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E4EC),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFB0B8CC), width: 1.5),
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: candidateData.isNotEmpty
                        ? Border.all(color: const Color(0xFF1A1A2E), width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_photos[i], fit: BoxFit.cover),
                        if (i == 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              color: const Color(0xFF1A1A2E)
                                  .withValues(alpha: 0.7),
                              alignment: Alignment.center,
                              child: const Text(
                                '표지',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
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
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      });
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
                    size: 22, color: Color(0xFFAAAAAA)),
                if (i == 0) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '필수',
                    style: TextStyle(fontSize: 10, color: Color(0xFFCC3333)),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    '+',
                    style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: i > 0
          ? const Text(
              '+',
              style: TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
            )
          : null,
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: [60, 120, 180].map((min) {
        final selected = _selectedMinutes == min;
        final isLast = min == 180;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMinutes = min),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.actionGoldSoft
                      : const Color(0xFFF4F4F7),
                  borderRadius: BorderRadius.circular(7),
                  border: selected
                      ? Border.all(color: AppColors.actionGoldBorder, width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${min ~/ 60}시간',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.actionGoldText
                        : const Color(0xFF888888),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegisterButton() {
    return FutureBuilder<(bool, bool)>(
      future: () async {
        final isAdmin = ref.read(adminModeProvider);
        if (isAdmin) return (true, true);
        final active = await FreeUseService.instance.isActive();
        final canRegister =
            active ? await FreeUseService.instance.canRegisterToday() : true;
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
              color: disabled ? const Color(0xFFCCCCCC) : AppColors.actionGold,
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
    if (widget.event.extensionCount >= 1) return;
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
      final extendedEvent = widget.event.copyWith(
        expiresAt: newExpiresAt,
        extensionCount: widget.event.extensionCount + 1,
      );
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
                    onTap: (_extending || widget.event.extensionCount >= 1)
                        ? null
                        : _showExtendConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: (_extending || widget.event.extensionCount >= 1)
                            ? const Color(0xFFAAAAAA)
                            : AppColors.actionGold,
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
                            color: AppColors.actionGoldText,
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
