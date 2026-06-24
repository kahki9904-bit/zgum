import 'dart:io';
import 'package:flutter/material.dart';

Future<void> showPhotoViewerPopup(
  BuildContext context,
  List<File> photos, {
  int initialIndex = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) => _PhotoViewerDialog(
      photos: photos,
      initialIndex: initialIndex,
    ),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;

  const _PhotoViewerDialog({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = (screenSize.width - 40).clamp(0.0, 360.0);
    final height = screenSize.height * 0.38;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.photos.length == 1
                        ? Image.file(
                            widget.photos[0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : PageView.builder(
                            controller: _ctrl,
                            itemCount: widget.photos.length,
                            onPageChanged: (i) =>
                                setState(() => _current = i),
                            itemBuilder: (_, i) => Image.file(
                              widget.photos[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                if (widget.photos.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.photos.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _current ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == _current
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
