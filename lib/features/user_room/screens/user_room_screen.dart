import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/check_in_record.dart';
import '../providers/check_in_provider.dart';
import 'settings_screen.dart';
import 'trace_gallery_screen.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  const UserRoomScreen({super.key});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(checkInProvider);
    final sorted =
        _newestFirst ? records : records.reversed.toList();
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad + 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        '흔적',
                        style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (records.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(
                            () => _newestFirst = !_newestFirst),
                        child: Text(
                          _newestFirst ? '최신순' : '과거순',
                          style: const TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    const _SettingsSection(),
                  ],
                ),
              ),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: Text(
                      '아직 기록한 순간이 없습니다',
                      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, botPad + 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 200,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) =>
                        _GridTile(record: sorted[index]),
                  ),
                ),
            ],
          ),
          // FriendButton → ShellScreen 공통 지금 탭으로 통합 예정, 임시 숨김
        ],
      ),
    );
  }
}

// ── 구역 3: 그리드 타일 ───────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final CheckInRecord record;

  const _GridTile({required this.record});

  void _openDetail(BuildContext context) {
    showGeneralDialog<void>(
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
              child: _TraceDetailPopup(record: record),
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

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TraceGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null;

    return GestureDetector(
      onTap: () => _openDetail(context),
      onLongPress: () => _openGallery(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasPhoto
            ? Image.file(
                File(record.photoPath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _textTile(),
              )
            : _textTile(),
      ),
    );
  }

  Widget _textTile() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFF4F6FB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Text(
        record.eventTitle,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF3A5FCD),
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _TraceDetailPopup extends StatelessWidget {
  final CheckInRecord record;
  const _TraceDetailPopup({required this.record});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dt = record.checkedInAt;
    final dateStr =
        '${dt.year}년 ${dt.month}월 ${dt.day}일  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final hasMemo = record.memo != null && record.memo!.isNotEmpty;
    final hasPhoto = record.photoPath != null;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.72,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: hasPhoto
                ? Image.file(
                    File(record.photoPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _noPhotoHeader(),
                  )
                : _noPhotoHeader(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.eventTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$dateStr  ·  ${record.venue}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                  if (hasMemo) ...[
                    const SizedBox(height: 24),
                    Text(
                      record.memo!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        height: 1.85,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPhotoHeader() {
    return Container(
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
          height: 1.4,
        ),
      ),
    );
  }
}

// ── 구역 4: 설정 버튼 ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const Icon(
          Icons.settings_outlined,
          size: 20,
          color: Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}



