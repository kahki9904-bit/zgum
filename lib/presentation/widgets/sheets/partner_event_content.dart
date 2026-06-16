import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'event_content_base.dart';

/// 파트너(소상공인) 이벤트 상세 레이아웃.
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

        EventInfoRow(Icons.storefront_outlined, event.venue),
        const SizedBox(height: 5),
        EventInfoRow(Icons.map_outlined, event.address),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 16),

        Text(
          event.description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
        ),
      ],
    );
  }
}
