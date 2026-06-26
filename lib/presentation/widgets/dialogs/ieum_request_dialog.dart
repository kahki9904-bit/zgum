import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../features/friend/data/models/friend_duration.dart';
import '../../../features/friend/data/repositories/friend_repository.dart';
import '../../../core/theme/app_colors.dart';
import 'zgum_dialog.dart';

class IeumRequestDialog extends StatefulWidget {
  final LatLng location;
  final FriendRepository repo;
  const IeumRequestDialog(
      {super.key, required this.location, required this.repo});

  @override
  State<IeumRequestDialog> createState() => _IeumRequestDialogState();
}

class _IeumRequestDialogState extends State<IeumRequestDialog> {
  FriendDuration? _duration;
  final _codeCtrl = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 120;
  String? _requestId;
  bool _waiting = false;
  bool _loading = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirm() async {
    if (_duration == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    if (!_waiting) {
      try {
        final req = await widget.repo.broadcastRequest(
          myUserId: uid,
          myLocation: widget.location,
          duration: _duration!,
        );
        setState(() {
          _requestId = req.id;
          _waiting = true;
          _secondsLeft = 120;
        });
        _startTimer();
      } catch (_) {}
    } else {
      final code = _codeCtrl.text.trim();
      if (code.isNotEmpty && _requestId != null) {
        try {
          await widget.repo.confirmRequest(
            requestId: _requestId!,
            responseCode: code,
            myUserId: uid,
            myLocation: widget.location,
          );
          if (mounted) {
            setState(() {
              _resultMessage = '이음이 연결됐습니다';
              _resultSuccess = true;
            });
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) Navigator.pop(context);
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _resultMessage = '코드를 확인해 주세요';
              _resultSuccess = false;
            });
          }
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Center(
        child: ZGumDialog(
          actions: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_waiting) ...[
                const Text(
                  '지금 곁에 있지 않으면\n이어지지 않습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFAAAAAA),
                    height: 1.45,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    FriendDuration.oneDay,
                    FriendDuration.threeMonths,
                    FriendDuration.sixMonths
                  ].map((d) {
                    final sel = _duration == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _duration = d),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 44,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.actionGoldSoft
                                : const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(10),
                            border: sel
                                ? Border.all(
                                    color: AppColors.actionGoldBorder, width: 1)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(d.chipLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.actionGoldText
                                    : const Color(0xFF555555),
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],
              ZGumButton(
                label: _waiting ? '확인' : '신청',
                onTap: _loading || _duration == null ? null : _confirm,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('이음', style: ZGumDialogTextStyles.title),
                  if (_waiting)
                    Text(_timerText, style: ZGumDialogTextStyles.caption),
                ],
              ),
              const SizedBox(height: 20),
              if (!_waiting)
                ...[]
              else ...[
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 12,
                      color: AppColors.actionGoldText),
                  decoration: InputDecoration(
                    hintText: '--',
                    hintStyle: const TextStyle(
                        color: Color(0xFFDDDDDD),
                        letterSpacing: 12,
                        fontSize: 36,
                        fontWeight: FontWeight.w800),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('상대방이 불러주는 번호를 입력하세요.',
                    style: ZGumDialogTextStyles.caption),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _resultMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _resultSuccess
                          ? AppColors.actionGoldText
                          : const Color(0xFFCC3333),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
