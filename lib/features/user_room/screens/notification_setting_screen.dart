import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEventRadiusKey = 'zgum_notif_event_radius_m';
const _kFriendRadiusKey = 'zgum_notif_friend_radius_m';

const _kEventOptions = [1000, 3000, 5000];
const _kFriendOptions = [100, 300, 500];

String _formatDistance(int m) => m < 1000 ? '${m}m' : '${m ~/ 1000}km';

class NotificationSettingScreen extends ConsumerStatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  ConsumerState<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState
    extends ConsumerState<NotificationSettingScreen> with WidgetsBindingObserver {
  bool _notifGranted = false;
  int? _eventRadiusM;
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
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final status = await Permission.notification.status;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifGranted = status.isGranted;
      _eventRadiusM = prefs.getInt(_kEventRadiusKey);
      _friendRadiusM = prefs.getInt(_kFriendRadiusKey);
    });
  }

  Future<void> _setEventRadius(int? m) async {
    setState(() => _eventRadiusM = m);
    final prefs = await SharedPreferences.getInstance();
    if (m == null) { prefs.remove(_kEventRadiusKey); }
    else { prefs.setInt(_kEventRadiusKey, m); }
  }

  Future<void> _setFriendRadius(int? m) async {
    setState(() => _friendRadiusM = m);
    final prefs = await SharedPreferences.getInstance();
    if (m == null) { prefs.remove(_kFriendRadiusKey); }
    else { prefs.setInt(_kFriendRadiusKey, m); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림',
          style: TextStyle(color: Color(0xFF333333), fontSize: 16, fontWeight: FontWeight.w600),
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
                  onToggle: openAppSettings,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: _Rule(),
                ),
                _DistanceRow(
                  icon: Icons.event_outlined,
                  label: '최신이벤트알림',
                  options: _kEventOptions,
                  selected: _eventRadiusM,
                  onChanged: _setEventRadius,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: _Rule(),
                ),
                _DistanceRow(
                  icon: Icons.people_outline,
                  label: '친구 감지',
                  options: _kFriendOptions,
                  selected: _friendRadiusM,
                  onChanged: _setFriendRadius,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                    style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: (v) => onChanged(v ? options[0] : null),
                  activeThumbColor: const Color(0xFF16213E),
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
                    activeTrackColor: const Color(0xFF1A1A2E),
                    thumbColor: const Color(0xFF1A1A2E),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    overlayColor: const Color(0x221A1A2E),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                          color: active ? const Color(0xFF1A1A2E) : const Color(0xFFBBBBBB),
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: const Color(0xFF16213E),
            ),
          ],
        ),
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
