import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../features/friend/data/models/friend_duration.dart';
import '../../../features/friend/data/models/friend_request.dart';
import '../../../features/friend/data/repositories/friend_repository.dart';
import 'zgum_dialog.dart';

class IeumAcceptDialog extends StatefulWidget {
  final FriendRequest request;
  final LatLng location;
  final FriendRepository repo;
  const IeumAcceptDialog({super.key, required this.request, required this.location, required this.repo});

  @override
  State<IeumAcceptDialog> createState() => _IeumAcceptDialogState();
}

class _IeumAcceptDialogState extends State<IeumAcceptDialog> {
  FriendDuration? _duration;
  String? _generatedCode;
  Timer? _timer;
  int _secondsLeft = 120;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.request.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 120);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    try {
      final code = await widget.repo.respondToRequest(
        requestId: widget.request.id,
        myUserId: 'mock_user',
        myLocation: widget.location,
        duration: _duration!,
        skipProximityCheck: true,
      );
      if (mounted) setState(() => _generatedCode = code ?? '??');
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ZGumDialog(
        actions: ZGumButton(
          label: _generatedCode == null ? '확인' : '닫기',
          onTap: _generatedCode == null
              ? (_loading || _duration == null ? null : _confirm)
              : () => Navigator.pop(context),
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
                Text(_timerText, style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
              ],
            ),
            const SizedBox(height: 20),
            if (_generatedCode == null) ...[
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
              Center(
                child: Text(
                  _generatedCode!,
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), letterSpacing: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('이 코드를 상대방에게 알려주세요',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
