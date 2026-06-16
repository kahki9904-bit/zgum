import 'package:flutter/material.dart';
import '../../../data/models/cultural_event.dart';
import '../../../services/time_service.dart';

/// 이벤트 상세 콘텐츠 위젯의 추상 기반 클래스.
///
/// 새 이벤트 유형 추가 시:
/// 1. 이 클래스를 상속받는 위젯을 생성합니다.
/// 2. [EventDetailSheet.contentFor] 팩토리에 케이스를 추가합니다.
abstract class EventContentBase extends StatelessWidget {
  final CulturalEvent event;
  final TimeService timeService;
  final bool interestSet;
  final VoidCallback? onInterestTap;
  final VoidCallback? onNavigateTap;

  const EventContentBase({
    super.key,
    required this.event,
    required this.timeService,
    this.interestSet = false,
    this.onInterestTap,
    this.onNavigateTap,
  });
}

// ── 공용 헬퍼 위젯 ─────────────────────────────────────────────────────────────

class EventCategoryBadge extends StatelessWidget {
  final EventCategory category;
  final bool isAdultOnly;

  static const _palette = <EventCategory, Color>{
    EventCategory.movie: Color(0xFF4A90D9),
    EventCategory.theater: Color(0xFF9B59B6),
    EventCategory.exhibition: Color(0xFFD4AF37),
    EventCategory.show: Color(0xFF50C878),
    EventCategory.concert: Color(0xFFE74C3C),
    EventCategory.partner: Color(0xFFFF8C00),
    EventCategory.all: Color(0xFF888888),
  };

  const EventCategoryBadge(this.category, {super.key, this.isAdultOnly = false});

  @override
  Widget build(BuildContext context) {
    final color = _palette[category] ?? Colors.grey;
    return Wrap(
      spacing: 6,
      children: [
        _Chip(label: category.label, color: color),
        if (isAdultOnly)
          const _Chip(label: '19+', color: Color(0xFFE74C3C), icon: Icons.lock_outline),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final TextStyle? style;

  const EventInfoRow(this.icon, this.text, {super.key, this.color, this.style});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = color ?? cs.onSurface.withValues(alpha: 0.55);
    final textStyle = style ??
        Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: color ?? cs.onSurface.withValues(alpha: 0.85));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: textStyle)),
      ],
    );
  }
}

class EndingSoonBadge extends StatelessWidget {
  final String label;
  final bool isUrgent;

  const EndingSoonBadge({super.key, required this.label, this.isUrgent = false});

  @override
  Widget build(BuildContext context) {
    final color = isUrgent ? const Color(0xFFE74C3C) : const Color(0xFFD4AF37);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
