import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/check_in_record.dart';
import '../providers/check_in_provider.dart';

class TraceGalleryScreen extends ConsumerStatefulWidget {
  const TraceGalleryScreen({super.key});

  @override
  ConsumerState<TraceGalleryScreen> createState() =>
      _TraceGalleryScreenState();
}

class _TraceGalleryScreenState extends ConsumerState<TraceGalleryScreen> {
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(checkInProvider);
    final sorted =
        _newestFirst ? records : records.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '흔적',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => _newestFirst = !_newestFirst),
            child: Text(
              _newestFirst ? '과거순' : '최신순',
              style: const TextStyle(
                  color: Color(0xFFAAAAAA), fontSize: 13),
            ),
          ),
        ],
      ),
      body: sorted.isEmpty
          ? const Center(
              child: Text(
                '아직 기록한 순간이 없습니다',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              ),
            )
          : ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) => _FeedPost(
                record: sorted[index],
                onDelete: (id) =>
                    ref.read(checkInProvider.notifier).delete(id),
              ),
            ),
    );
  }
}

class _FeedPost extends StatelessWidget {
  final CheckInRecord record;
  final void Function(String id) onDelete;

  const _FeedPost({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null;
    final hasMemo = record.memo != null && record.memo!.isNotEmpty;
    final dt = record.checkedInAt;
    final dateStr =
        '${dt.month}월 ${dt.day}일  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            if (hasPhoto)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        _FullscreenPhotoScreen(record: record),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                ),
                child: Hero(
                  tag: 'trace_photo_${record.id}',
                  child: Image.file(
                    File(record.photoPath!),
                    width: double.infinity,
                    height: 360,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _textTile(),
                  ),
                ),
              )
            else
              _textTile(),
            Positioned(
              top: 12,
              right: 12,
              child: _DeleteButton(onTap: () => _confirmDelete(context)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.eventTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$dateStr  ·  ${record.venue}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFAAAAAA)),
              ),
              if (hasMemo) ...[
                const SizedBox(height: 10),
                Text(
                  record.memo!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF444444),
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF2F2F2)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _textTile() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFF4F6FB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        record.eventTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3A5FCD),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기록 삭제', style: TextStyle(fontSize: 16)),
        content: const Text('이 기록을 삭제할까요?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(record.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.close, size: 14, color: Colors.white),
      ),
    );
  }
}

class _FullscreenPhotoScreen extends StatelessWidget {
  final CheckInRecord record;
  const _FullscreenPhotoScreen({required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Hero(
                tag: 'trace_photo_${record.id}',
                child: Image.file(
                  File(record.photoPath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
