import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/check_in_record.dart';
import '../../../features/friend/data/models/friend_request.dart';
import '../../../features/friend/providers/friend_provider.dart';
import '../../../features/user_room/providers/check_in_provider.dart';
import '../../../core/providers/user_location_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../widgets/dialogs/ieum_accept_dialog.dart';
import '../../widgets/dialogs/ieum_request_dialog.dart';
import '../../widgets/popups/confirm/forget_confirm_popup.dart';
import '../shell_constants.dart';

class UserPanelContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const UserPanelContent({super.key, required this.onClose});

  @override
  ConsumerState<UserPanelContent> createState() => _UserPanelContentState();
}

class _UserPanelContentState extends ConsumerState<UserPanelContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkInProvider.notifier).cleanupExpired();
      _checkPendingRequest();
    });
  }

  Future<void> _checkPendingRequest() async {
    if (!mounted) return;
    final repo = ref.read(friendRepositoryProvider);
    final location = ref.read(userLocationProvider);
    try {
      final requests = await repo.getNearbyRequests(
        myLocation: location,
        myUserId: 'mock_user',
      );
      if (requests.isNotEmpty && mounted) {
        _showAcceptDialog(requests.first);
      }
    } catch (_) {}
  }

  Future<void> _showRequestDialog() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IeumRequestDialog(
        location: ref.read(userLocationProvider),
        repo: ref.read(friendRepositoryProvider),
      ),
    );
  }

  void _showAcceptDialog(FriendRequest request) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IeumAcceptDialog(
        request: request,
        location: ref.read(userLocationProvider),
        repo: ref.read(friendRepositoryProvider),
      ),
    );
  }

  void _confirmForget(CheckInRecord record) {
    showForgetConfirmPopup(context).then((confirmed) {
      if (confirmed == true) {
        ref.read(checkInProvider.notifier).delete(record.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(checkInProvider);
    final now = DateTime.now();
    final latest = records.isNotEmpty &&
            now.difference(records.first.checkedInAt).inHours < 24
        ? records.first
        : null;
    final friendCount = ref.watch(friendCountProvider);
    final count = friendCount.whenOrNull(data: (v) => v) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 500;
        final traceHeight = compact ? 200.0 : 240.0;
        final bottomPad = 20.0 + MediaQuery.paddingOf(context).bottom;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            kShellPanelHandleContentGap,
            20,
            bottomPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: traceHeight,
                width: double.infinity,
                child: latest != null
                    ? _RecentTraceCard(record: latest)
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '아직 남긴 흔적이 없습니다',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              if (latest != null)
                Row(
                  children: [
                    _SmallAction(
                      label: '남기기',
                      color: const Color(0xFF1A1A2E),
                      onTap: () {
                        widget.onClose();
                        ref.read(shellPageProvider.notifier).state = 0;
                      },
                    ),
                    const SizedBox(width: 8),
                    _SmallAction(
                      label: '잊기',
                      color: const Color(0xFFAAAAAA),
                      onTap: () => _confirmForget(latest),
                    ),
                  ],
                )
              else
                const SizedBox(height: 32),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFF0F0F0)),
              const SizedBox(height: 14),
              Text(
                '$count명과 이어졌습니다.',
                style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  child: GestureDetector(
                    onTap: _showRequestDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '이음',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTraceCard extends StatelessWidget {
  final CheckInRecord record;
  const _RecentTraceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null;
    final dt = record.checkedInAt;
    final dateStr = '${dt.month}.${dt.day.toString().padLeft(2, '0')}';
    final hasMemo = record.memo != null && record.memo!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoWidth = (constraints.maxHeight * 0.72)
            .clamp(108.0, constraints.maxWidth * 0.42);
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEDF1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPhoto)
                SizedBox(
                  width: photoWidth,
                  child: Image.file(
                    File(record.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.eventTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                      if (hasMemo) ...[
                        const SizedBox(height: 8),
                        Text(
                          record.memo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
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
      },
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallAction(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
