import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import 'event_content_base.dart';

class PartnerEventContent extends EventContentBase {
  final bool isMyEvent;

  const PartnerEventContent({
    super.key,
    required super.event,
    required super.timeService,
    this.isMyEvent = false,
    super.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMyEvent)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.4)),
            ),
            child: const Text(
              '나의 이벤트',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF8C00),
              ),
            ),
          ),
        SizedBox(
          height: 36,
          child: Marquee(
            text: event.title,
            style: EventDetailTextStyles.title,
            scrollAxis: Axis.horizontal,
            blankSpace: 40.0,
            velocity: 40.0,
            startAfter: const Duration(seconds: 1),
            pauseAfterRound: const Duration(seconds: 1),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          event.description,
          style: EventDetailTextStyles.description,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                event.address,
                style: EventDetailTextStyles.address,
              ),
            ),
            if (onNavigateTap != null)
              GestureDetector(
                onTap: onNavigateTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.actionGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.navigate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
