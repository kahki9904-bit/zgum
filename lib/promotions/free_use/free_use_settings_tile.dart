import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'free_use_service.dart';

/// 설정 화면에 꽂히는 무료이용 상태 타일.
/// 행사 종료 시 이 파일과 settings_screen.dart 연결 2줄 제거.
class FreeUseSettingsTile extends StatefulWidget {
  const FreeUseSettingsTile({super.key});

  @override
  State<FreeUseSettingsTile> createState() => _FreeUseSettingsTileState();
}

class _FreeUseSettingsTileState extends State<FreeUseSettingsTile> {
  bool _active = false;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = FreeUseService.instance;
    final active = await svc.isActive();
    final remaining = await svc.remainingDays();
    if (mounted) {
      setState(() {
        _active = active;
        _remaining = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();

    final statusText = _active ? '이용 중' : '중단';
    final statusColor =
        _active ? AppColors.actionGoldText : const Color(0xFFAAAAAA);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 58),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
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
                  child: const Icon(Icons.card_giftcard_outlined,
                      size: 17, color: Color(0xFFAAAAAA)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '무료이용',
                    style: TextStyle(color: Color(0xFF333333), fontSize: 15),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_remaining > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$_remaining일',
                    style:
                        const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
