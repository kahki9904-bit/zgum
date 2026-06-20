import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../features/user_room/providers/auth_provider.dart';

enum _Step { location, identity, done }

/// 앱 진입 필수 프로세스 가드.
///
/// - 위치 동의 → 본인 인증 안내 후 [child]로 진입합니다.
/// - 본인 인증 상태는 [authStateProvider]에 저장됩니다.
/// - 인증 없이도 앱 진입 가능. 인증 시 전체 콘텐츠 접근 가능.
class ConsentGuard extends ConsumerStatefulWidget {
  final Widget child;

  const ConsentGuard({super.key, required this.child});

  @override
  ConsumerState<ConsentGuard> createState() => _ConsentGuardState();
}

class _ConsentGuardState extends ConsumerState<ConsentGuard> {
  _Step _step = _Step.location;

  Future<void> _confirmIdentity() async {
    await ref.read(authStateProvider.notifier).adminVerify();
    if (mounted) setState(() => _step = _Step.location);
  }

  void _skipIdentity() => setState(() => _step = _Step.location);

  Future<void> _requestLocation() async {
    await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() => _step = _Step.done);
  }

  void _denyLocation() => setState(() => _step = _Step.done);

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.done) return widget.child;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: _step == _Step.identity
              ? _IdentityCard(
                  onConfirm: _confirmIdentity,
                  onSkip: _skipIdentity,
                )
              : _LocationCard(
                  onAllow: _requestLocation,
                  onDeny: _denyLocation,
                ),
        ),
      ),
    );
  }
}

// ── 공통 글라스 카드 ──────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.70),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── 위치 동의 카드 ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _LocationCard({required this.onAllow, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Z:GUM',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '개인정보를 수집하지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.deepBlue.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 20),
          const Text(
            '위치 정보 사용 동의',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '주변을 발견하는 역할만 합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onDeny,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: BorderSide(
                        color: AppTheme.deepBlue.withValues(alpha: 0.30),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '미동의',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '동의',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

// ── 본인 인증 카드 ────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  const _IdentityCard({required this.onConfirm, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '본인 인증',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '인증 후 모든 콘텐츠를\n이용할 수 있습니다.\n인증은 앱내 설정에서\n변경 가능합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.deepBlue.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: BorderSide(
                        color: AppTheme.deepBlue.withValues(alpha: 0.30),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '나중에',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '인증하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
