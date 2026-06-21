import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../../../core/extensions/context_extensions.dart';
import 'event_content_base.dart';

class PartnerEventContent extends EventContentBase {
  const PartnerEventContent({
    super.key,
    required super.event,
    required super.timeService,
    super.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: Marquee(
            text: event.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                event.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            if (onNavigateTap != null)
              GestureDetector(
                onTap: onNavigateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
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
