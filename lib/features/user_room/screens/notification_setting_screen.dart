import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../promotions/free_use/free_use_service.dart';
import '../../../promotions/free_use/free_use_alert_popup.dart';
import '../../friend/providers/friend_provider.dart';
import '../../friend/widgets/friend_exploration_popup.dart';

class NotificationSettingScreen extends ConsumerStatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  ConsumerState<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState
    extends ConsumerState<NotificationSettingScreen> with WidgetsBindingObserver {
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifStatus();
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
    await _loadNotifStatus();
    final result = await FreeUseService.instance.syncNotificationStatus();
    if (!mounted) return;
    if (result == NotificationSyncResult.resumed) {
      showFreeUseResumedPopup(context);
    } else if (result == NotificationSyncResult.paused) {
      showFreeUseAlertPopup(context);
    }
  }

  Future<void> _loadNotifStatus() async {
    final status = await Permission.notification.status;
    if (mounted) setState(() => _notifGranted = status.isGranted);
  }

  Future<void> _toggleNotif() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final explorationOn = ref.watch(friendExplorationProvider);

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
                  onToggle: _toggleNotif,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: _Rule(),
                ),
                _ToggleRow(
                  icon: Icons.explore_outlined,
                  label: '친구탐험',
                  value: explorationOn,
                  onToggle: () {
                    if (!explorationOn) {
                      showFriendExplorationPopup(context).then((_) {
                        ref.read(friendExplorationProvider.notifier).toggle();
                      });
                    } else {
                      ref.read(friendExplorationProvider.notifier).toggle();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
