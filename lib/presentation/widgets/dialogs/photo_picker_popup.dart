import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_chooser_popup.dart';

Future<List<File>?> showPhotoPickerPopup(
  BuildContext context,
  List<File> currentPhotos,
) {
  return showGeneralDialog<List<File>>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) =>
        _PhotoPickerDialog(initialPhotos: currentPhotos),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _PhotoPickerDialog extends StatefulWidget {
  final List<File> initialPhotos;
  const _PhotoPickerDialog({required this.initialPhotos});

  @override
  State<_PhotoPickerDialog> createState() => _PhotoPickerDialogState();
}

class _PhotoPickerDialogState extends State<_PhotoPickerDialog> {
  final _picker = ImagePicker();
  late final List<File?> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List<File?>.filled(3, null, growable: false);
    for (int i = 0; i < widget.initialPhotos.length && i < 3; i++) {
      _slots[i] = widget.initialPhotos[i];
    }
  }

  Future<void> _addPhoto(int slot) async {
    final shown = await isCameraChooserPopupShown();
    if (!shown && mounted) await showCameraChooserPopup(context);
    if (!mounted) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() => _slots[slot] = File(picked.path));
  }

  void _removePhoto(int slot) => setState(() => _slots[slot] = null);

  List<File> get _result => _slots.whereType<File>().toList();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = (screenSize.width - 40).clamp(0.0, 360.0);

    return Center(
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '사진 추가',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '최대 3장까지 추가할 수 있어요',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: _buildSlot(i),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_result),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(int i) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: _slots[i] != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_slots[i]!, fit: BoxFit.cover),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
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
            )
          : GestureDetector(
              onTap: () => _addPhoto(i),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F7),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
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
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFFCC3333)),
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
