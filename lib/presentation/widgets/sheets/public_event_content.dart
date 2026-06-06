import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'event_content_base.dart';

/// 공공 문화 행사 상세 레이아웃.
/// 표시 요소: 카테고리·날짜·장소·설명·길찾기
class PublicEventContent extends EventContentBase {
  const PublicEventContent({
    super.key,
    required super.event,
    required super.timeService,
    super.alarmSet,
    super.onAlarmTap,
    super.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventCategoryBadge(event.category, isAdultOnly: event.isAdultOnly),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                event.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
              ),
            ),
            GestureDetector(
              onTap: alarmSet ? null : onAlarmTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  alarmSet
                      ? Icons.notifications_active
                      : Icons.notifications_none_outlined,
                  size: 22,
                  color: alarmSet
                      ? const Color(0xFF16213E)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ),
            if (onNavigateTap != null)
              GestureDetector(
                onTap: onNavigateTap,
                child: Container(
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, size: 13, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        context.l10n.navigate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        EventInfoRow(Icons.location_on_outlined, event.venue),
        const SizedBox(height: 5),
        EventInfoRow(Icons.calendar_today_outlined, _dateRange()),
        const SizedBox(height: 5),
        EventInfoRow(
          event.isFree
              ? Icons.check_circle_outline
              : Icons.confirmation_number_outlined,
          event.isFree ? context.l10n.isFree : context.l10n.isPaid,
          color: event.isFree ? const Color(0xFF50C878) : null,
        ),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 16),

        Text(
          event.description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
        ),
        const SizedBox(height: 14),
        EventInfoRow(
          Icons.map_outlined,
          event.address,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  String _dateRange() {
    String f(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${f(event.startDate)} ~ ${f(event.endDateTime)}';
  }
}
