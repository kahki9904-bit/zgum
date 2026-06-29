import '../dialogs/camera_chooser_popup.dart';
import '../popups/once/trace_intro_popup.dart';
import '../../../core/popup_layout.dart';
import '../../../core/providers/shell_page_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:marquee/marquee.dart';
import '../../../data/models/cultural_event.dart';
import '../../../core/theme/app_colors.dart';
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
    bool isMyEvent = false,
    void Function(String? memo, String? photoPath)? onCheckIn,
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
                isMyEvent: isMyEvent,
                onCheckIn: onCheckIn,
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
    bool isMyEvent = false,
    VoidCallback? onInterestTap,
    VoidCallback? onNavigateTap,
  }) {
    return switch (event.source) {
      EventSource.partner => PartnerEventContent(
          event: event,
          timeService: timeService,
          isMyEvent: isMyEvent,
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
  final bool isMyEvent;
  final void Function(String? memo, String? photoPath)? onCheckIn;

  const _SheetWrapper({
    required this.event,
    required this.timeService,
    this.userLocation,
    this.onNavigate,
    this.isCheckedIn = false,
    this.isMyEvent = false,
    this.onCheckIn,
  });

  @override
  ConsumerState<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends ConsumerState<_SheetWrapper> {
  bool _interestSet = false;

  // 흔적 폼 상태
  bool _showForm = false;
  File? _capturedPhoto;
  final _memoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTraceIntroIfNeeded();
    });
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _showTraceIntroIfNeeded() async {
    if (widget.onCheckIn == null) return;
    final shown = await isTraceIntroShown();
    if (shown || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    await showTraceIntroPopup(context);
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
      barrierDismissible: true,
      builder: (dialogCtx) {
        final dialog = AlertDialog(
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
                  color: AppColors.actionGoldText,
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
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle:
                      const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
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
                result = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
                Navigator.pop(dialogCtx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionGold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('완료'),
            ),
          ],
        );
        if (!PopupLayoutSpec.current.removeViewInsetsOnDialog) return dialog;
        return MediaQuery(
          data: MediaQuery.of(dialogCtx).copyWith(viewInsets: EdgeInsets.zero),
          child: dialog,
        );
      },
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
    final popup = PopupLayoutSpec.current;
    final heightFactor =
        Platform.isIOS ? popup.eventDetailFactor : popup.registerFormFactor;

    return Container(
      width: double.infinity,
      height: screenHeight * heightFactor,
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
    final isIOS = Platform.isIOS;
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
      isMyEvent: widget.isMyEvent,
      onInterestTap: () => setState(() => _interestSet = true),
      onNavigateTap: navigateCallback,
    );

    return Column(
      children: [
        if (widget.event.source == EventSource.partner &&
            widget.event.partnerMessage != null)
          Container(
            margin: EdgeInsets.fromLTRB(20, isIOS ? 14 : 12, 20, 0),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isIOS ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD580)),
            ),
            child: Row(
              children: [
                Icon(Icons.store_outlined,
                    size: isIOS ? 16 : 18, color: const Color(0xFFFF8C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: isIOS ? 29 : 36,
                    child: Marquee(
                      text: widget.event.partnerMessage!,
                      style: TextStyle(
                        fontSize: isIOS ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                        height: 1.25,
                      ),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 200,
                      velocity: 30,
                      startAfter: const Duration(milliseconds: 900),
                      pauseAfterRound: const Duration(milliseconds: 900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, isIOS ? 20 : 16, 20, 8),
            children: [content],
          ),
        ),
        if (widget.onCheckIn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.5,
                child: GestureDetector(
                  onTap: widget.isCheckedIn ? null : _openCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: widget.isCheckedIn
                          ? const Color(0xFFCCCCCC)
                          : AppColors.actionGold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '지금',
                      style: TextStyle(
                        color: widget.isCheckedIn
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
              color: AppColors.actionGoldText,
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _capturedPhoto != null
                  ? Image.file(_capturedPhoto!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFF4F4F7)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memoCtrl,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            decoration: InputDecoration(
              hintText: '한 줄 메모 (선택)',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelTrace,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.actionGoldText,
                    side: const BorderSide(color: AppColors.actionGoldBorder),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('취소',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _saveTrace,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.actionGold,
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
                      : const Text('지금',
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
