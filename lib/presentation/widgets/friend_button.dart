import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../services/device_id_service.dart';
import '../../services/notification_service.dart';
import '../../features/friend/data/models/friend_duration.dart';
import '../../features/friend/data/models/friend_request.dart';
import '../../features/friend/data/repositories/friend_repository.dart';
import '../../features/friend/providers/friend_provider.dart';
import '../../features/alert/models/partner_event.dart';
import '../../features/alert/providers/geofence_provider.dart';
import 'trace_checkin_dialog.dart';

class FriendButton extends ConsumerStatefulWidget {
  const FriendButton({super.key});

  @override
  ConsumerState<FriendButton> createState() => _FriendButtonState();
}

class _FriendButtonState extends ConsumerState<FriendButton>
    with SingleTickerProviderStateMixin {
  String? _myUserId;
  FriendRequest? _myBroadcast;
  String? _respondedRequestId;
  Timer? _broadcastTimer;
  Timer? _pollTimer;
  int _secondsLeft = 0;
  bool _loading = false;
  bool _bPopupShown = false;

  // 팝업 내부 타이머 텍스트 갱신용
  StateSetter? _capturedSetDialog;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    DeviceIdService.getId().then((id) {
      if (!mounted) return;
      setState(() => _myUserId = id);
      _checkOnLaunch(id);
      _startPolling(id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPulse();
    });
  }

  // 같은 기기 테스트용: 자기 신청을 B 입장으로 감지
  Future<void> _checkOnLaunch(String userId) async {
    final repo = ref.read(friendRepositoryProvider);
    final requests = await repo.getNearbyRequests(
      myLocation: const LatLng(37.5665, 126.9780),
      myUserId: '${userId}_b',
    );
    if (!mounted || requests.isEmpty) return;
    final request = requests.first;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_bPopupShown) _maybeShowBPopup(request);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _broadcastTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _syncPulse({PartnerEvent? geofenceEvent}) {
    final geoActive = geofenceEvent != null ||
        (mounted ? ref.read(geofenceProvider) != null : false);
    if (geoActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startPolling(String userId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;

      // B가 응답한 경우: A의 확인 완료 여부 체크
      if (_respondedRequestId != null) {
        await _checkCompletion(userId);
        return;
      }

      // A가 브로드캐스트 중이면 B 감지 스킵
      if (_myBroadcast != null) return;

      final repo = ref.read(friendRepositoryProvider);
      final requests = await repo.getNearbyRequests(
        myLocation: const LatLng(37.5665, 126.9780),
        myUserId: userId,
      );
      if (!mounted) return;

      final newRequest = requests.isEmpty ? null : requests.first;

      // 새 요청 감지 → 자동 팝업
      if (newRequest != null && !_bPopupShown) {
        _maybeShowBPopup(newRequest);
      }
    });
  }

  // A가 코드 확인 완료했는지 체크 (요청이 삭제됐으면 완료)
  Future<void> _checkCompletion(String userId) async {
    final repo = ref.read(friendRepositoryProvider);
    final requests = await repo.getNearbyRequests(
      myLocation: const LatLng(37.5665, 126.9780),
      myUserId: userId,
    );
    if (!mounted) return;

    final gone = requests.every((r) => r.id != _respondedRequestId);
    if (gone) {
      setState(() {
        _respondedRequestId = null;
        _bPopupShown = false;
      });
      ref.invalidate(activeFriendsProvider);
      _showCompletionPopup();
    }
  }

  void _maybeShowBPopup(FriendRequest request) {
    if (_bPopupShown) return;
    _bPopupShown = true;
    _showRespondPopup(request);
  }

  void _cancelBroadcast() {
    _broadcastTimer?.cancel();
    _capturedSetDialog = null;
    setState(() => _myBroadcast = null);
  }

  void _onTap() {
    final geofenceEvent = ref.read(geofenceProvider);
    if (geofenceEvent != null) {
      showTraceCheckInDialog(context, geofenceEvent);
    } else {
      _showRequestPopup();
    }
  }

  // ── 완료 팝업 (A, B 공통) ─────────────────────────────────────────────────

  void _showCompletionPopup() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '이음이 이어졌어요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16213E),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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

  // ── A: 이음 신청 팝업 ─────────────────────────────────────────────────────

  void _showRequestPopup() {
    FriendDuration selectedDuration = FriendDuration.oneDay;
    FriendRequest? broadcastedReq;
    final codeCtrl = TextEditingController();
    bool hasError = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        return Center(
          child: StatefulBuilder(
            builder: (ctx, setDialog) {
              _capturedSetDialog = setDialog;
              final sent = broadcastedReq != null;
              return Material(
                color: Colors.transparent,
                child: Container(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '이음',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: FriendDuration.values.map((d) {
                            final on = d == selectedDuration;
                            return Expanded(
                              child: GestureDetector(
                                onTap: sent
                                    ? null
                                    : () => setDialog(() => selectedDuration = d),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                          Center(
                            child: Text(
                              '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _secondsLeft <= 20
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF888888),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '상대방이 불러주는 번호를 입력하세요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFAAAAAA),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: codeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            onChanged: (_) => setDialog(() => hasError = false),
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
                          if (hasError) ...[
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                '번호가 맞지 않아요.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _cancelBroadcast();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF888888),
                                  side: const BorderSide(
                                      color: Color(0xFFDDDDDD)),
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: sent
                                    ? () async {
                                        final code = codeCtrl.text.trim();
                                        if (code.length != 2) return;
                                        setState(() => _loading = true);
                                        final repo = ref.read(
                                            friendRepositoryProvider);
                                        final friend =
                                            await repo.confirmRequest(
                                          requestId: broadcastedReq!.id,
                                          responseCode: code,
                                          myUserId: _myUserId ?? '',
                                          myLocation: const LatLng(
                                              37.5665, 126.9780),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          _loading = false;
                                          if (friend != null) {
                                            _myBroadcast = null;
                                            _broadcastTimer?.cancel();
                                            _capturedSetDialog = null;
                                          }
                                        });
                                        if (friend != null) {
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          ref.invalidate(activeFriendsProvider);
                                          await NotificationService.instance
                                              .showFriendRegisteredNotification();
                                          _showCompletionPopup();
                                        } else {
                                          setDialog(() => hasError = true);
                                        }
                                      }
                                    : () async {
                                        if (_myUserId == null) return;
                                        final repo = ref.read(
                                            friendRepositoryProvider);
                                        setState(() => _loading = true);
                                        final request =
                                            await repo.broadcastRequest(
                                          myUserId: _myUserId!,
                                          myLocation: const LatLng(
                                              37.5665, 126.9780),
                                          duration: selectedDuration,
                                        );
                                        _broadcastTimer?.cancel();
                                        setState(() {
                                          _myBroadcast = request;
                                          _secondsLeft = FriendRepository
                                              .requestTtl.inSeconds;
                                          _loading = false;
                                        });
                                        _broadcastTimer = Timer.periodic(
                                          const Duration(seconds: 1),
                                          (_) {
                                            if (!mounted) return;
                                            if (_secondsLeft <= 0) {
                                              _broadcastTimer?.cancel();
                                              _capturedSetDialog = null;
                                              setState(
                                                  () => _myBroadcast = null);
                                              if (ctx.mounted) {
                                                Navigator.pop(ctx);
                                              }
                                              return;
                                            }
                                            setState(
                                                () => _secondsLeft--);
                                            _capturedSetDialog
                                                ?.call(() {});
                                          },
                                        );
                                        setDialog(
                                            () => broadcastedReq = request);
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF16213E),
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  sent ? '확인' : '신청',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    ).then((_) {
      _capturedSetDialog = null;
      if (_myBroadcast != null) _cancelBroadcast();
    });
  }

  // ── B: 이음 수락 팝업 (자동 표시) ────────────────────────────────────────

  void _showRespondPopup(FriendRequest request) {
    FriendDuration selectedDuration = FriendDuration.oneDay;
    String? generatedCode;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        return Center(
          child: StatefulBuilder(
            builder: (ctx, setDialog) {
              final responded = generatedCode != null;
              return Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints:
                      BoxConstraints(maxHeight: screenHeight * 0.85),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          responded ? '상대방에게 알려주세요' : '이음 요청이 왔습니다',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: FriendDuration.values.map((d) {
                            final on = d == selectedDuration;
                            return Expanded(
                              child: GestureDetector(
                                onTap: responded
                                    ? null
                                    : () => setDialog(
                                        () => selectedDuration = d),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
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
                          Center(
                            child: Text(
                              generatedCode!,
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 20,
                                color: Color(0xFF16213E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              '이 번호를 상대방에게 알려주세요.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFAAAAAA)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            if (!responded) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => _bPopupShown = false);
                                    Navigator.pop(ctx);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF888888),
                                    side: const BorderSide(
                                        color: Color(0xFFDDDDDD)),
                                    minimumSize:
                                        const Size(double.infinity, 52),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: const Text(
                                    '취소',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: FilledButton(
                                onPressed: responded
                                    ? () {
                                        setState(
                                            () => _bPopupShown = false);
                                        Navigator.pop(ctx);
                                      }
                                    : () async {
                                        setState(() => _loading = true);
                                        final repo = ref.read(
                                            friendRepositoryProvider);
                                        final code =
                                            await repo.respondToRequest(
                                          requestId: request.id,
                                          myUserId: _myUserId ?? '',
                                          myLocation: const LatLng(
                                              37.5665, 126.9780),
                                          duration: selectedDuration,
                                          skipProximityCheck: true,
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          _loading = false;
                                          if (code != null) {
                                            _respondedRequestId =
                                                request.id;
                                          }
                                        });
                                        if (code != null) {
                                          setDialog(
                                              () => generatedCode = code);
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF16213E),
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  responded ? '완료' : '수락',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    ).then((_) {
      setState(() => _bPopupShown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PartnerEvent?>(geofenceProvider, (prev, next) {
      _syncPulse(geofenceEvent: next);
    });

    final geofenceEvent = ref.watch(geofenceProvider);
    final hasGeofence = geofenceEvent != null;

    // 점멸: 지오펜스 이벤트만
    final color = hasGeofence
        ? const Color(0xFFF97316)
        : const Color(0xFF16213E);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final alpha = hasGeofence ? _pulseAnim.value : 0.2;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _loading ? null : _onTap,
            style: FilledButton.styleFrom(
              backgroundColor: color.withValues(alpha: alpha),
              disabledBackgroundColor:
                  const Color(0xFF16213E).withValues(alpha: 0.08),
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
      },
    );
  }
}
