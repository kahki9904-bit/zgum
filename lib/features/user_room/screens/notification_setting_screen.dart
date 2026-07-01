import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

const _kEventRadiusKey = 'zgum_notif_event_radius_m';
const _kFriendRadiusKey = 'zgum_notif_friend_radius_m';

// ignore: unused_element
const _kEventOptions = [1000, 3000, 5000];
// ignore: unused_element
const _kFriendOptions = [100, 300, 500];

String _formatDistance(int m) => m < 1000 ? '${m}m' : '${m ~/ 1000}km';

class NotificationSettingScreen extends ConsumerStatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  ConsumerState<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState
    extends ConsumerState<NotificationSettingScreen>
    with WidgetsBindingObserver {
  bool _notifGranted = false;
  // ignore: unused_field
  int? _eventRadiusM;
  // ignore: unused_field
  int? _friendRadiusM;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }

  Future<void> _onResume() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadSettings();
  }

  Future<void> _onToggleNotif() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await openAppSettings();
    } else {
      final result = await FirebaseMessaging.instance.requestPermission();
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await _loadSettings();
      } else {
        await openAppSettings();
      }
    }
  }

  Future<void> _loadSettings() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      _eventRadiusM = prefs.getInt(_kEventRadiusKey);
      _friendRadiusM = prefs.getInt(_kFriendRadiusKey);
    });
  }

  // ignore: unused_element
  Future<void> _setEventRadius(int? m) async {
    setState(() => _eventRadiusM = m);
    final prefs = await SharedPreferences.getInstance();
    if (m == null) {
      prefs.remove(_kEventRadiusKey);
    } else {
      prefs.setInt(_kEventRadiusKey, m);
    }
  }

  // ignore: unused_element
  Future<void> _setFriendRadius(int? m) async {
    setState(() => _friendRadiusM = m);
    final prefs = await SharedPreferences.getInstance();
    if (m == null) {
      prefs.remove(_kFriendRadiusKey);
    } else {
      prefs.setInt(_kFriendRadiusKey, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF333333), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  label: '알림 허용',
                  value: _notifGranted,
                  onToggle: _onToggleNotif,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: _Rule(),
                ),
                const _InfoRow(
                  icon: Icons.people_outline,
                  label: '이어진 친구를 감지 합니다.',
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: _Rule(),
                ),
                const _InfoRow(
                  icon: Icons.campaign_outlined,
                  label: '새로운 이벤트를 알려줍니다.',
                ),
                // [최신이벤트알림 — 비활성화]
                // 파트너 이벤트 등록 시 반경 내 사용자에게 FCM 푸시를 보내는 기능.
                // Cloud Functions(Firebase Blaze 플랜)이 필요하여 유료 전환 전까지 UI 숨김.
                // 설정값 저장 로직(_setEventRadius / _kEventRadiusKey)은 그대로 유지.
                // 유료 전환 후 아래 주석 해제하면 즉시 복원됨.
                //
                // _DistanceRow(
                //   icon: Icons.event_outlined,
                //   label: '최신이벤트알림',
                //   options: _kEventOptions,
                //   selected: _eventRadiusM,
                //   onChanged: _setEventRadius,
                // ),
                // const Padding(
                //   padding: EdgeInsets.only(left: 58),
                //   child: _Rule(),
                // ),

                // [친구 감지 — 비활성화]
                // 이음으로 연결된 친구가 반경 내에 있을 때 FCM 푸시를 보내는 기능.
                // Firestore 위치 저장 + Cloud Functions 필요, 유료 전환 전까지 UI 숨김.
                // 설정값 저장 로직(_setFriendRadius / _kFriendRadiusKey)은 그대로 유지.
                // 유료 전환 후 아래 주석 해제하면 즉시 복원됨.
                //
                // _DistanceRow(
                //   icon: Icons.people_outline,
                //   label: '친구 감지',
                //   options: _kFriendOptions,
                //   selected: _friendRadiusM,
                //   onChanged: _setFriendRadius,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _DistanceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<int> options;
  final int? selected;
  final ValueChanged<int?> onChanged;

  const _DistanceRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = selected != null;
    final rawIndex = selected != null ? options.indexOf(selected!) : -1;
    final sliderIndex = rawIndex >= 0 ? rawIndex : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
                  child: Icon(icon, size: 17, color: const Color(0xFFAAAAAA)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style:
                        const TextStyle(color: Color(0xFF333333), fontSize: 15),
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: (v) => onChanged(v ? options[0] : null),
                  activeThumbColor: AppColors.actionGold,
                ),
              ],
            ),
          ),
        ),
        if (isOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.actionGold,
                    thumbColor: AppColors.actionGold,
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    overlayColor: AppColors.actionGold.withValues(alpha: 0.14),
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    min: 0,
                    max: (options.length - 1).toDouble(),
                    divisions: options.length - 1,
                    value: sliderIndex.toDouble(),
                    onChanged: (v) => onChanged(options[v.round()]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: options.map((m) {
                      final active = selected == m;
                      return Text(
                        _formatDistance(m),
                        style: TextStyle(
                          color: active
                              ? AppColors.actionGoldText
                              : const Color(0xFFBBBBBB),
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child: Icon(icon, size: 17, color: const Color(0xFFAAAAAA)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: (_) => onToggle(),
              activeTrackColor: AppColors.actionGoldBright,
              inactiveTrackColor: const Color(0xFFE0E0E0),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: const Color(0xFFAAAAAA)),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }
}
