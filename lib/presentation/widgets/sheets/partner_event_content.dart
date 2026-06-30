import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/popup_layout.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../dialogs/zgum_dialog.dart';
import 'event_content_base.dart';

class PartnerEventContent extends EventContentBase {
  final bool isMyEvent;

  const PartnerEventContent({
    super.key,
    required super.event,
    required super.timeService,
    this.isMyEvent = false,
    super.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMyEvent)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.4)),
            ),
            child: const Text(
              '나의 이벤트',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF8C00),
              ),
            ),
          ),
        if (event.photoUrls.isNotEmpty) ...[
          _PhotoSection(
            photoUrls: event.photoUrls,
            height: isIOS ? 128 : 180,
            onTap: () => _showPhotoViewer(context, event.photoUrls),
          ),
          const SizedBox(height: 14),
        ],
        if (event.description.isNotEmpty) ...[
          Text(
            event.description,
            style: EventDetailTextStyles.description,
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                event.address,
                style: EventDetailTextStyles.address,
              ),
            ),
            if (onNavigateTap != null)
              GestureDetector(
                onTap: onNavigateTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.actionGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.navigate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: EventInfoRow(
                Icons.schedule_outlined,
                '${_fmt(event.startDate)} ~ ${_fmt(event.endDateTime)}',
                style: EventDetailTextStyles.address,
              ),
            ),
            const SizedBox(width: 8),
            _EventFeedbackButton(
              onTap: () => _showEventFeedbackDialog(
                context,
                eventId: event.id,
                eventTitle: event.title,
              ),
            ),
          ],
        ),
        if (event.isAdultOnly) ...[
          const SizedBox(height: 6),
          const EventInfoRow(
            Icons.lock_outline,
            '신분증 확인 이벤트',
            color: Color(0xFFE74C3C),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $h:$m';
  }
}

void _showEventFeedbackDialog(
  BuildContext context, {
  required String eventId,
  required String eventTitle,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, _, __) {
      return GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: _EventFeedbackDialog(
              eventId: eventId,
              eventTitle: eventTitle,
            ),
          ),
        ),
      );
    },
  );
}

void _showPhotoViewer(BuildContext context, List<String> urls) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) => _PhotoViewer(urls: urls),
  );
}

class _PhotoSection extends StatelessWidget {
  final List<String> photoUrls;
  final double height;
  final VoidCallback onTap;

  const _PhotoSection({
    required this.photoUrls,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: _imageWidget(photoUrls[0]),
            ),
          ),
          if (photoUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '+${photoUrls.length - 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventFeedbackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EventFeedbackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.actionGoldSoft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.actionGoldBorder.withValues(alpha: 0.45),
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '의견 보내기',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.actionGoldText,
          ),
        ),
      ),
    );
  }
}

class _EventFeedbackDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const _EventFeedbackDialog({
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<_EventFeedbackDialog> createState() => _EventFeedbackDialogState();
}

class _EventFeedbackDialogState extends State<_EventFeedbackDialog> {
  static const _items = [
    '정보가 다름',
    '위치가 다름',
    '부적절함',
    '이미 종료됨',
  ];

  int? _selectedIndex;
  bool _sending = false;
  bool _sent = false;

  Future<void> _onSend() async {
    if (_selectedIndex == null) return;
    setState(() => _sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('event_feedbacks').add({
        'eventId': widget.eventId,
        'eventTitle': widget.eventTitle,
        'category': _items[_selectedIndex!],
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _sending = false; _sent = true; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZGumDialog(
      heightFactor: PopupLayoutSpec.current.introShortFactor,
      contentPadding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
      actionsPadding: const EdgeInsets.fromLTRB(26, 14, 26, 26),
      actions: Row(
        children: [
          Expanded(
            child: ZGumButton(
              label: '닫기',
              onTap: () => Navigator.of(context).pop(),
              color: const Color(0xFFF1F1F2),
              textColor: const Color(0xFF777777),
              widthFactor: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ZGumButton(
              label: _sent ? '전송됨' : (_sending ? '전송 중...' : '보내기'),
              onTap: (_sending || _sent || _selectedIndex == null) ? () {} : _onSend,
              widthFactor: 1,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이벤트 의견 보내기', style: ZGumDialogTextStyles.title),
          const SizedBox(height: 12),
          const Text(
            '이 이벤트에 대해 확인이 필요한 내용을 운영자에게 보낼 수 있습니다.',
            style: ZGumDialogTextStyles.body,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _FeedbackChoiceChip(
                  label: _items[0],
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackChoiceChip(
                  label: _items[1],
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FeedbackChoiceChip(
                  label: _items[2],
                  selected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackChoiceChip(
                  label: _items[3],
                  selected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '이벤트 제목, 위치, 등록 시간이 함께 전달될 수 있습니다.',
            style: ZGumDialogTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _FeedbackChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.actionGoldSoft : const Color(0xFFF6F6F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.actionGoldBorder : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color:
                selected ? AppColors.actionGoldText : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

Widget _imageWidget(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http')) {
    return Image.network(path,
        fit: fit, errorBuilder: (_, __, ___) => const _PhotoPlaceholder());
  }
  return Image.file(File(path),
      fit: fit, errorBuilder: (_, __, ___) => const _PhotoPlaceholder());
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFCCCCCC), size: 40),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;

  const _PhotoViewer({required this.urls});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final popup = PopupLayoutSpec.current;
    final viewerHeight = Platform.isIOS
        ? size.height * popup.eventDetailFactor
        : size.height * 0.65;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: size.width - 40,
            height: viewerHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: widget.urls.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _imageWidget(widget.urls[i], fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                if (widget.urls.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.urls.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _current == i ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? AppColors.actionGold
                              : AppColors.actionGoldBorder
                                  .withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
