import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../features/friend/data/models/friend_duration.dart';
import '../../../features/friend/data/repositories/friend_repository.dart';
import 'zgum_dialog.dart';

class IeumRequestDialog extends StatefulWidget {
  final LatLng location;
  final FriendRepository repo;
  const IeumRequestDialog({super.key, required this.location, required this.repo});

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

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) { t.cancel(); if (mounted) Navigator.pop(context); }
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirm() async {
    if (_duration == null) return;
    setState(() => _loading = true);
    if (!_waiting) {
      try {
        final req = await widget.repo.broadcastRequest(
          myUserId: 'mock_user',
          myLocation: widget.location,
          duration: _duration!,
        );
        setState(() { _requestId = req.id; _waiting = true; _secondsLeft = 120; });
        _startTimer();
      } catch (_) {}
    } else {
      final code = _codeCtrl.text.trim();
      if (code.isNotEmpty && _requestId != null) {
        try {
          await widget.repo.confirmRequest(
            requestId: _requestId!,
            responseCode: code,
            myUserId: 'mock_user',
            myLocation: widget.location,
          );
          if (mounted) Navigator.pop(context);
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ZGumDialog(
        actions: ZGumButton(
          label: _waiting ? '확인' : '신청',
          onTap: _loading || _duration == null ? null : _confirm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('이음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                if (_waiting)
                  Text(_timerText, style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
              ],
            ),
            const SizedBox(height: 20),
            if (!_waiting) ...[
              Row(
                children: [FriendDuration.oneDay, FriendDuration.threeMonths, FriendDuration.sixMonths]
                    .map((d) {
                  final sel = _duration == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _duration = d),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF16213E) : const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(d.chipLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : const Color(0xFF555555),
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 2,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 12, color: Color(0xFF16213E)),
                decoration: InputDecoration(
                  hintText: '--',
                  hintStyle: const TextStyle(color: Color(0xFFDDDDDD), letterSpacing: 12, fontSize: 36, fontWeight: FontWeight.w800),
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
                  style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA), height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
