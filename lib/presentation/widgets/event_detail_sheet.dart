import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/cultural_event.dart';

/// 이벤트 상세 정보창 — 독립 컴포넌트.
///
/// 어느 화면에서든 [show]를 호출해 표시할 수 있습니다.
/// 추후 기능 추가 시 이 파일만 수정합니다.
class EventDetailSheet extends StatelessWidget {
  final CulturalEvent event;

  const EventDetailSheet({super.key, required this.event});

  static Future<void> show(BuildContext context, CulturalEvent event) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.30,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => _SheetBody(
        event: event,
        scrollController: scrollCtrl,
      ),
    );
  }
}

// ── 시트 본문 ─────────────────────────────────────────────────────────────────

class _SheetBody extends StatelessWidget {
  final CulturalEvent event;
  final ScrollController scrollController;

  const _SheetBody({required this.event, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _DragHandle(),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 28),
              children: [
                _ImageArea(event: event),
                const SizedBox(height: 16),
                _CategoryBadge(event.category),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppTheme.deepBlue,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: event.venue,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _dateRange(event),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: event.isFree
                      ? Icons.check_circle_outline
                      : Icons.confirmation_number_outlined,
                  text: event.isFree ? '무료 입장' : '유료',
                  color: event.isFree ? const Color(0xFF50C878) : null,
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.75,
                      color: AppTheme.deepBlue.withValues(alpha: 0.72),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.map_outlined,
                  text: event.address,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.black38),
                ),
                if (event.ticketUrl != null) ...[
                  const SizedBox(height: 22),
                  _TicketButton(url: event.ticketUrl!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dateRange(CulturalEvent e) {
    String f(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${f(e.startDate)} ~ ${f(e.endDateTime)}';
  }
}

// ── 이미지 영역 ───────────────────────────────────────────────────────────────

class _ImageArea extends StatelessWidget {
  final CulturalEvent event;
  const _ImageArea({required this.event});

  static const _palette = <EventCategory, Color>{
    EventCategory.movie: Color(0xFF4A90D9),
    EventCategory.theater: Color(0xFF9B59B6),
    EventCategory.exhibition: Color(0xFFD4AF37),
    EventCategory.show: Color(0xFF50C878),
    EventCategory.concert: Color(0xFFE74C3C),
    EventCategory.partner: Color(0xFFFF8C00),
    EventCategory.all: Color(0xFF888888),
  };

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          event.imageUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final color = _palette[event.category] ?? Colors.grey.shade300;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Center(
        child: Text(
          event.category.label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── 보조 위젯 ─────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black12,
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Text(
          category.label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black45;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: (style ?? Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _TicketButton extends StatelessWidget {
  final String url;
  const _TicketButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // TODO: url_launcher 연동
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deepBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          '티켓 구매',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
