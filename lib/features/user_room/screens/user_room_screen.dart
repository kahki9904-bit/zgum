import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/grid_room_layout.dart';
import '../../../core/providers/user_location_provider.dart';
import '../../../data/models/check_in_record.dart';
import '../../../features/friend/providers/friend_provider.dart';
import '../../../presentation/widgets/dialogs/ieum_request_dialog.dart';
import '../../../presentation/widgets/zgum_orb_button.dart';
import '../providers/check_in_provider.dart';
import 'settings_screen.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  const UserRoomScreen({super.key});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  bool _newestFirst = true;
  bool _singleColumn = false;
  bool _showTileText = false;

  void _showIeumRequestDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IeumRequestDialog(
        location: ref.read(userLocationProvider),
        repo: ref.read(friendRepositoryProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(checkInProvider);
    final latest = records.isEmpty
        ? null
        : records.reduce(
            (a, b) => a.checkedInAt.isAfter(b.checkedInAt) ? a : b,
          );
    final rest = records.where((r) => r.id != latest?.id).toList()
      ..sort(
        (a, b) => _newestFirst
            ? b.checkedInAt.compareTo(a.checkedInAt)
            : a.checkedInAt.compareTo(b.checkedInAt),
      );
    final sorted = [
      if (latest != null) latest,
      ...rest,
    ];
    final latestId = latest?.id;
    final layout = GridRoomLayoutSpec.current;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad + layout.topOffset),
              Padding(
                padding: layout.headerPadding,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: layout.headerMinHeight),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _IeumOrb(onTap: _showIeumRequestDialog),
                          const _SettingsSection(),
                        ],
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: _HeaderHint(text: '흔적을 남겨 보세요'),
                      ),
                    ],
                  ),
                ),
              ),
              _TraceGridControls(
                layout: layout,
                newestFirst: _newestFirst,
                singleColumn: _singleColumn,
                showTileText: _showTileText,
                onToggleSort: () =>
                    setState(() => _newestFirst = !_newestFirst),
                onToggleColumn: () =>
                    setState(() => _singleColumn = !_singleColumn),
                onToggleText: () =>
                    setState(() => _showTileText = !_showTileText),
              ),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 34),
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
                    padding: EdgeInsets.only(top: 0, bottom: botPad + 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _singleColumn ? 1 : 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _TraceGridTile(
                      record: sorted[index],
                      index: index,
                      totalCount: sorted.length,
                      showText: _showTileText,
                      showForget: sorted[index].id == latestId,
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

class _HeaderHint extends StatelessWidget {
  const _HeaderHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0x66765D35),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );
  }
}

class _IeumOrb extends StatelessWidget {
  const _IeumOrb({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ZGumOrbButton(label: '이음', onTap: onTap);
  }
}

class _TraceGridControls extends StatelessWidget {
  const _TraceGridControls({
    required this.layout,
    required this.newestFirst,
    required this.singleColumn,
    required this.showTileText,
    required this.onToggleSort,
    required this.onToggleColumn,
    required this.onToggleText,
  });

  final GridRoomLayoutSpec layout;
  final bool newestFirst;
  final bool singleColumn;
  final bool showTileText;
  final VoidCallback onToggleSort;
  final VoidCallback onToggleColumn;
  final VoidCallback onToggleText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: layout.controlHeight,
      padding: layout.controlPadding,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF0F2F5)),
          bottom: BorderSide(color: Color(0xFFF0F2F5)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleSort,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: layout.controlHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newestFirst ? '최신순' : '오래된순',
                    style: const TextStyle(
                      color: Color(0xFF071426),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '정렬',
                    style: TextStyle(
                      color: Color(0xFFB5BEC7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _GridToolButton(
            icon: singleColumn ? Icons.grid_on_rounded : Icons.crop_square,
            onTap: onToggleColumn,
          ),
          const SizedBox(width: 10),
          _GridToolButton(
            icon: showTileText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onTap: onToggleText,
          ),
        ],
      ),
    );
  }
}

class _GridToolButton extends StatelessWidget {
  const _GridToolButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF0F4)),
        ),
        child: Icon(icon, size: 19, color: const Color(0xFF9AA4AD)),
      ),
    );
  }
}

// ── 구역 3: 흔적 그리드 ─────────────────────────────────────────────────────

class _TraceGridTile extends StatelessWidget {
  final CheckInRecord record;
  final int index;
  final int totalCount;
  final bool showText;
  final bool showForget;

  const _TraceGridTile({
    required this.record,
    required this.index,
    required this.totalCount,
    required this.showText,
    required this.showForget,
  });

  void _openPhotoViewer(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _TracePhotoViewer(
                record: record,
                index: index,
                totalCount: totalCount,
                showForget: showForget,
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null;

    return GestureDetector(
      onTap: () => _openPhotoViewer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            _TracePhoto(
              path: record.photoPath!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: const Color(0xFFF4F6FB),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Text(
                record.eventTitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF16213E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          if (showText)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
                child: Text(
                  record.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TracePhotoViewer extends ConsumerWidget {
  const _TracePhotoViewer({
    required this.record,
    required this.index,
    required this.totalCount,
    required this.showForget,
  });

  final CheckInRecord record;
  final int index;
  final int totalCount;
  final bool showForget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = record.checkedInAt;
    final dateStr = '${dt.month}.${dt.day.toString().padLeft(2, '0')}';
    final hasMemo = record.memo != null && record.memo!.isNotEmpty;
    final hasPhoto = record.photoPath != null;
    final showDownloadMarker = hasPhoto && !showForget;

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  _TracePhoto(
                    path: record.photoPath!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: const Color(0xFFF4F6FB),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      record.eventTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF16213E),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xCCFFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showForget)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(checkInProvider.notifier).delete(record.id);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF071426).withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '잊기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showDownloadMarker)
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: _DownloadPhotoMarker(),
                  ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.eventTitle,
                          style: const TextStyle(
                            color: Color(0xFF071426),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEFBFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${index + 1} / $totalCount',
                          style: const TextStyle(
                            color: Color(0xFF16213E),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${record.venue}  ·  $dateStr',
                    style: const TextStyle(
                      color: Color(0xFF9AA4AD),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  if (hasMemo) ...[
                    const SizedBox(height: 10),
                    Text(
                      record.memo!,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _DownloadPhotoMarker extends StatelessWidget {
  const _DownloadPhotoMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: const Icon(
        Icons.download_rounded,
        size: 17,
        color: Colors.white,
      ),
    );
  }
}

class _TracePhoto extends StatelessWidget {
  const _TracePhoto({
    required this.path,
    required this.fit,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  bool get _isRemote =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
