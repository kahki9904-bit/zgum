import 'package:flutter/material.dart';
import 'dialogs/camera_chooser_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/shell_page_provider.dart';
import '../../data/models/check_in_record.dart';
import '../../features/alert/models/partner_event.dart';
import '../../features/alert/providers/geofence_provider.dart';

/// 지오펜스 3분 체류 감지 후 자동 표시되는 흔적 팝업
Future<void> showTraceCheckInDialog(
  BuildContext context,
  PartnerEvent event,
) {
  return showGeneralDialog<void>(
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
            child: _TraceSheet(event: event),
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

class _TraceSheet extends ConsumerStatefulWidget {
  final PartnerEvent event;
  const _TraceSheet({required this.event});

  @override
  ConsumerState<_TraceSheet> createState() => _TraceSheetState();
}

class _TraceSheetState extends ConsumerState<_TraceSheet> {
  bool _done = false;

  Future<void> _openCamera() async {
    final shown = await isCameraChooserPopupShown();
    if (!shown && mounted) await showCameraChooserPopup(context);
    if (!mounted) return;

    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    final message = await _showMessagePopup();
    if (!mounted) return;

    final record = CheckInRecord(
      id: 'trace_${DateTime.now().millisecondsSinceEpoch}',
      eventId: widget.event.id,
      eventTitle: widget.event.title,
      venue: widget.event.venue,
      categoryLabel: '파트너 이벤트',
      checkedInAt: DateTime.now(),
      memo: message,
      photoPath: file.path,
    );

    ref.read(panelPendingTraceProvider.notifier).state = record;
    ref.read(geofenceProvider.notifier).dismiss();

    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
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

  void _dismiss() {
    ref.read(geofenceProvider.notifier).dismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Material(
      color: Colors.transparent,
      child: Container(
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
        child: _done ? _doneView() : _introView(),
      ),
    );
  }

  Widget _introView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '근처에 계세요',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF97316),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.event.venue,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 20),
          const Text(
            '지금 이 순간을 흔적으로 남겨보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF888888),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '나중에',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _openCamera,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '지금',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: Color(0xFF16213E)),
          SizedBox(height: 16),
          Text(
            '흔적이 남겨졌습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
