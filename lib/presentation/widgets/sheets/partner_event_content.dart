import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/popup_layout.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
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
        EventInfoRow(
          Icons.schedule_outlined,
          '${_fmt(event.startDate)} ~ ${_fmt(event.endDateTime)}',
          style: EventDetailTextStyles.address,
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
