import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/shell_page_provider.dart';
import '../../data/models/check_in_record.dart';
import '../../features/alert/models/partner_event.dart';
import '../../features/alert/providers/event_stats_provider.dart';
import '../../features/alert/providers/geofence_provider.dart';
import '../../features/user_room/providers/check_in_provider.dart';

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

enum _TraceStage { intro, form }

class _TraceSheet extends ConsumerStatefulWidget {
  final PartnerEvent event;
  const _TraceSheet({required this.event});

  @override
  ConsumerState<_TraceSheet> createState() => _TraceSheetState();
}

class _TraceSheetState extends ConsumerState<_TraceSheet> {
  final _memoCtrl = TextEditingController();
  String? _photoPath;
  bool _loading = false;
  bool _done = false;
  _TraceStage _stage = _TraceStage.intro;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (!mounted) return;

    final message = await _showMessagePopup();
    if (!mounted) return;

    setState(() {
      _photoPath = file?.path;
      _memoCtrl.text = message ?? '';
      _stage = _TraceStage.form;
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

  Future<void> _submit() async {
    setState(() => _loading = true);

    final record = CheckInRecord(
      id: 'trace_${DateTime.now().millisecondsSinceEpoch}',
      eventId: widget.event.id,
      eventTitle: widget.event.title,
      venue: widget.event.venue,
      categoryLabel: '파트너 이벤트',
      checkedInAt: DateTime.now(),
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      photoPath: _photoPath,
    );

    await ref.read(checkInProvider.notifier).save(record);
    ref.read(eventStatsProvider.notifier).recordTrace(widget.event.id);
    ref.read(geofenceProvider.notifier).dismiss();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _done = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final pageNotifier = ref.read(shellPageProvider.notifier);
    Navigator.pop(context);
    // 다이얼로그 종료 애니메이션(280ms)이 완전히 끝난 뒤 페이지 이동
    await Future.delayed(const Duration(milliseconds: 350));
    pageNotifier.state = 0;
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
        child: _done
            ? _doneView()
            : (_stage == _TraceStage.intro ? _introView() : _formView()),
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
                    '흔적',
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

  Widget _formView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: i == 0 && _photoPath != null
                          ? Image.file(File(_photoPath!), fit: BoxFit.cover)
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
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '한 줄 메모 (선택)',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 24),
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
                    '취소',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '흔적',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
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
