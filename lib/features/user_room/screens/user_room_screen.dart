import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/check_in_record.dart';
import '../../../services/device_id_service.dart';
import '../../../services/notification_service.dart';
import '../providers/check_in_provider.dart';
import '../../friend/data/models/friend_duration.dart';
import '../../friend/data/models/friend_request.dart';
import '../../friend/data/repositories/friend_repository.dart';
import '../../friend/providers/friend_provider.dart';
import 'settings_screen.dart';

class UserRoomScreen extends ConsumerWidget {
  const UserRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
          children: [
            _ProfileSection(),
            const SizedBox(height: 32),
            const _Rule(),
            const SizedBox(height: 32),
            const _FriendButton(),
            const SizedBox(height: 20),
            _CheckInTimelineSection(
              records: ref.watch(checkInProvider),
              onDelete: (id) => ref.read(checkInProvider.notifier).delete(id),
            ),
            const SizedBox(height: 32),
            const _Rule(),
            const SizedBox(height: 32),
            const _SettingsSection(),
          ],
        ),
      ),
    );
  }
}

// ── 구역 1: 프로필 ─────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 구역 2: 친구 신청/수락 버튼 ────────────────────────────────────────────────

class _FriendButton extends ConsumerStatefulWidget {
  const _FriendButton();

  @override
  ConsumerState<_FriendButton> createState() => _FriendButtonState();
}

class _FriendButtonState extends ConsumerState<_FriendButton> {
  String? _myUserId;
  FriendRequest? _myBroadcast;
  FriendRequest? _incomingRequest;
  Timer? _broadcastTimer;
  Timer? _pollTimer;
  int _secondsLeft = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    DeviceIdService.getId().then((id) {
      if (!mounted) return;
      setState(() => _myUserId = id);
      _checkOnLaunch(id);
      _startPolling(id);
    });
  }

  Future<void> _checkOnLaunch(String userId) async {
    final repo = ref.read(friendRepositoryProvider);
    // 같은 기기 테스트: 자기 신청도 보이도록 다른 ID로 조회
    final requests = await repo.getNearbyRequests(
      myLocation: const LatLng(37.5665, 126.9780),
      myUserId: '${userId}_b',
    );
    if (!mounted || requests.isEmpty) return;
    setState(() => _incomingRequest = requests.first);
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling(String userId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _myBroadcast != null) return;
      final repo = ref.read(friendRepositoryProvider);
      final requests = await repo.getNearbyRequests(
        myLocation: const LatLng(37.5665, 126.9780),
        myUserId: userId,
      );
      if (!mounted) return;
      setState(() {
        _incomingRequest = requests.isEmpty ? null : requests.first;
      });
    });
  }

  void _cancelBroadcast() {
    _broadcastTimer?.cancel();
    setState(() => _myBroadcast = null);
  }

  // A: 기간 칩 + 코드 입력 통합 팝업 (2단계)
  void _showRequestPopup() {
    FriendDuration selectedDuration = FriendDuration.oneDay;
    FriendRequest? broadcastedReq;
    final tokenCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final sent = broadcastedReq != null;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              sent ? '상대방 번호 입력' : '친구 신청',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16213E)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 기간 칩
                Row(
                  children: FriendDuration.values.map((d) {
                    final on = d == selectedDuration;
                    return Expanded(
                      child: GestureDetector(
                        onTap: sent
                            ? null
                            : () => setDialog(() => selectedDuration = d),
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: on
                                ? const Color(0xFF16213E)
                                : const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d.chipLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: on
                                  ? Colors.white
                                  : (sent
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFF555555)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (sent) ...[
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '상대방이 알려주는 숫자 2자리를 입력하세요.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFAAAAAA),
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tokenCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 12,
                      color: Color(0xFF16213E),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '--',
                      hintStyle: const TextStyle(
                        color: Color(0xFFDDDDDD),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _cancelBroadcast();
                },
                child: const Text('취소',
                    style: TextStyle(color: Color(0xFFAAAAAA))),
              ),
              FilledButton(
                onPressed: sent
                    ? () async {
                        final token = tokenCtrl.text.trim();
                        if (token.length != 2) return;
                        Navigator.pop(ctx);
                        setState(() => _loading = true);
                        final repo = ref.read(friendRepositoryProvider);
                        final friend = await repo.confirmRequest(
                          requestId: broadcastedReq!.id,
                          responseToken: token,
                          myUserId: _myUserId ?? 'test_requester',
                          myLocation: const LatLng(37.5665, 126.9780),
                        );
                        if (!mounted) return;
                        setState(() {
                          _loading = false;
                          if (friend != null) {
                            _myBroadcast = null;
                            _broadcastTimer?.cancel();
                          }
                        });
                        if (friend != null) {
                          ref.invalidate(activeFriendsProvider);
                          await NotificationService.instance
                              .showFriendRegisteredNotification();
                        }
                      }
                    : () async {
                        if (_myUserId == null) return;
                        final repo = ref.read(friendRepositoryProvider);
                        setState(() => _loading = true);
                        final request = await repo.broadcastRequest(
                          myUserId: _myUserId!,
                          myLocation: const LatLng(37.5665, 126.9780),
                          duration: selectedDuration,
                        );
                        _broadcastTimer?.cancel();
                        setState(() {
                          _myBroadcast = request;
                          _secondsLeft =
                              FriendRepository.requestTtl.inSeconds;
                          _loading = false;
                        });
                        _broadcastTimer = Timer.periodic(
                            const Duration(seconds: 1), (_) {
                          if (!mounted) return;
                          if (_secondsLeft <= 0) {
                            _broadcastTimer?.cancel();
                            setState(() => _myBroadcast = null);
                            if (ctx.mounted) Navigator.pop(ctx);
                            return;
                          }
                          setState(() => _secondsLeft--);
                        });
                        setDialog(() => broadcastedReq = request);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(sent ? '확인' : '신청'),
              ),
            ],
          );
        },
      ),
    );
  }

  // B: 기간 칩 + 코드 생성 통합 팝업 (2단계)
  void _showRespondPopup(FriendRequest request) {
    FriendDuration selectedDuration = FriendDuration.oneDay;
    String? generatedToken;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final responded = generatedToken != null;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              responded ? '상대방에게 알려주세요' : '친구 수락',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16213E)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 기간 칩
                Row(
                  children: FriendDuration.values.map((d) {
                    final on = d == selectedDuration;
                    return Expanded(
                      child: GestureDetector(
                        onTap: responded
                            ? null
                            : () => setDialog(() => selectedDuration = d),
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: on
                                ? const Color(0xFF16213E)
                                : const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            d.chipLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: on
                                  ? Colors.white
                                  : (responded
                                      ? const Color(0xFFCCCCCC)
                                      : const Color(0xFF555555)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (responded) ...[
                  const SizedBox(height: 20),
                  Text(
                    generatedToken!,
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 20,
                      color: Color(0xFF16213E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '이 번호를 상대방에게 알려주세요.',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ],
            ),
            actions: [
              if (!responded)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소',
                      style: TextStyle(color: Color(0xFFAAAAAA))),
                ),
              FilledButton(
                onPressed: responded
                    ? () => Navigator.pop(ctx)
                    : () async {
                        setState(() => _loading = true);
                        final repo = ref.read(friendRepositoryProvider);
                        final token = await repo.respondToRequest(
                          requestId: request.id,
                          myUserId: _myUserId ?? 'test_responder',
                          myLocation: const LatLng(37.5665, 126.9780),
                          skipProximityCheck: true,
                        );
                        if (!mounted) return;
                        setState(() {
                          _loading = false;
                          if (token != null) _incomingRequest = null;
                        });
                        if (token != null) {
                          setDialog(() => generatedToken = token);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(responded ? '완료' : '수락'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_incomingRequest != null) {
      return _buildAcceptButton();
    }
    return _buildRequestButton();
  }

  void _onRequestTap() {
    if (_myBroadcast != null) {
      _showRequestPopup();
    } else {
      _showRequestPopup();
    }
  }

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _loading ? null : _onRequestTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16213E),
          disabledBackgroundColor: const Color(0xFF16213E).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                '지금',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }


  Widget _buildAcceptButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _loading ? null : () => _showRespondPopup(_incomingRequest!),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16213E),
          disabledBackgroundColor:
              const Color(0xFF16213E).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                '수락',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ── 구역 3: 체크인 타임라인 ────────────────────────────────────────────────────

class _CheckInTimelineSection extends StatelessWidget {
  final List<CheckInRecord> records;
  final void Function(String id) onDelete;

  const _CheckInTimelineSection({
    required this.records,
    required this.onDelete,
  });

  Map<String, List<CheckInRecord>> _grouped() {
    final map = <String, List<CheckInRecord>>{};
    for (final r in records) {
      final key = _dateLabel(r.checkedInAt);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  static String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${dt.month}월 ${dt.day}일';
  }

  static String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('어제'),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '아직 기록한 순간이 없습니다',
                style:
                    TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              ),
            ),
          )
        else
          ..._grouped().entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF16213E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...entry.value.map((r) => _CheckInCard(
                      record: r,
                      timeLabel: _timeLabel(r.checkedInAt),
                      onDelete: onDelete,
                    )),
              ],
            );
          }),
      ],
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckInRecord record;
  final String timeLabel;
  final void Function(String id) onDelete;

  const _CheckInCard({
    required this.record,
    required this.timeLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.eventTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.venue}  $timeLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: Color(0xFFCCCCCC)),
                    onPressed: () => _confirmDelete(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            if (record.memo != null && record.memo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  record.memo!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ),
            if (record.photoPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(record.photoPath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기록 삭제',
            style: TextStyle(fontSize: 16)),
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

// ── 구역 4: 설정 버튼 ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      size: 17, color: Color(0xFFAAAAAA)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '설정',
                    style: TextStyle(
                        color: Color(0xFF333333), fontSize: 15),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFDDDDDD), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 공통 ──────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }
}
