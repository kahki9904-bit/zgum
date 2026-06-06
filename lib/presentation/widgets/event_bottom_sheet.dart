import 'package:flutter/material.dart';
import '../../data/models/cultural_event.dart';

class EventBottomSheet extends StatelessWidget {
  final CulturalEvent event;

  const EventBottomSheet({super.key, required this.event});

  static void show(BuildContext context, CulturalEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventBottomSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.28,
      maxChildSize: 0.88,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _DragHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, MediaQuery.of(context).padding.bottom + 24),
                children: [
                  _CategoryBadge(event.category),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.venue,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDateRange(event),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: event.isFree ? Icons.check_circle_outline : Icons.confirmation_number_outlined,
                    text: event.isFree ? '무료 입장' : '유료',
                    color: event.isFree ? const Color(0xFF50C878) : null,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.map_outlined,
                    text: event.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateRange(CulturalEvent e) {
    String f(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${f(e.startDate)} ~ ${f(e.endDateTime)}';
  }
}

// ── 내부 위젯 ────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _CategoryBadge extends StatelessWidget {
  final EventCategory category;

  static const _palette = <EventCategory, Color>{
    EventCategory.movie: Color(0xFF4A90D9),
    EventCategory.theater: Color(0xFF9B59B6),
    EventCategory.exhibition: Color(0xFFD4AF37),
    EventCategory.show: Color(0xFF50C878),
    EventCategory.concert: Color(0xFFE74C3C),
    EventCategory.partner: Color(0xFFFF8C00),
    EventCategory.all: Color(0xFF888888),
  };

  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) {
    final color = _palette[category] ?? Colors.grey;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          category.label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final TextStyle? style;

  const _InfoRow({required this.icon, required this.text, this.color, this.style});

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: (style ?? defaultStyle)?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
