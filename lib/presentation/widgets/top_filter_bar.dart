import 'package:flutter/material.dart';
import '../../data/models/cultural_event.dart';

// ── 퀵 필터 (클라이언트 사이드 전용) ─────────────────────────────────────────

/// 지도 마커를 이벤트 출처별로 즉시 분류하는 3-탭 필터.
/// API 재호출 없이 이미 로드된 [_events] 목록을 클라이언트에서 필터링합니다.
enum QuickFilter {
  all('전체'),
  partner('🔥 깜짝 이벤트'),
  public('🎭 문화/공연/영화');

  const QuickFilter(this.label);
  final String label;
}

// ── 최상위 필터 바 ─────────────────────────────────────────────────────────────

class TopFilterBar extends StatelessWidget {
  final EventCategory selectedCategory;
  final double radiusKm;
  final bool isDefaultLocation;
  final QuickFilter quickFilter;
  final ValueChanged<EventCategory> onCategoryChanged;
  final VoidCallback onLocationTap;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<QuickFilter> onQuickFilterChanged;

  const TopFilterBar({
    super.key,
    required this.selectedCategory,
    required this.radiusKm,
    required this.isDefaultLocation,
    required this.quickFilter,
    required this.onCategoryChanged,
    required this.onLocationTap,
    required this.onRadiusChanged,
    required this.onQuickFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 행 1: 위치 + 반경 pill ─────────────────────────────────────
            Row(
              children: [
                _PillButton(
                  icon: isDefaultLocation
                      ? Icons.location_off_outlined
                      : Icons.my_location,
                  label: isDefaultLocation ? '위치 설정' : '현재 위치',
                  highlighted: isDefaultLocation,
                  onTap: onLocationTap,
                ),
                const SizedBox(width: 8),
                _RadiusPillButton(
                  radiusKm: radiusKm,
                  onChanged: onRadiusChanged,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 행 2: 퀵 필터 3-탭 ─────────────────────────────────────────
            _QuickFilterChips(
              selected: quickFilter,
              onSelected: onQuickFilterChanged,
            ),

            // ── 행 3: 세부 카테고리 (퀵 필터 '전체' 선택 시에만 노출) ───────
            if (quickFilter == QuickFilter.all) ...[
              const SizedBox(height: 6),
              _CategoryChips(
                selected: selectedCategory,
                onSelected: onCategoryChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 퀵 필터 칩 (전체 / 깜짝 이벤트 / 문화·공연) ──────────────────────────────

class _QuickFilterChips extends StatelessWidget {
  final QuickFilter selected;
  final ValueChanged<QuickFilter> onSelected;

  const _QuickFilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QuickFilter.values.map((f) {
          final isSelected = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              backgroundColor: cs.surface.withValues(alpha: 0.92),
              selectedColor: cs.primary.withValues(alpha: 0.15),
              checkmarkColor: cs.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
              side: BorderSide(
                color:
                    isSelected ? cs.primary : Colors.transparent,
                width: 1.5,
              ),
              elevation: isSelected ? 0 : 2,
              shadowColor: Colors.black38,
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 공통 pill 버튼 ──────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = highlighted
        ? cs.primary.withValues(alpha: 0.15)
        : cs.surface.withValues(alpha: 0.92);
    final fg = highlighted ? cs.primary : cs.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border:
              highlighted ? Border.all(color: cs.primary, width: 1.5) : null,
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

class _RadiusPillButton extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  static const _options = [1.0, 3.0, 5.0, 10.0, 20.0];

  const _RadiusPillButton({required this.radiusKm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, size: 15, color: cs.onSurface),
            const SizedBox(width: 5),
            Text('${radiusKm.toStringAsFixed(0)}km',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('탐색 반경',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _options
                  .map((km) => ChoiceChip(
                        label: Text('${km.toStringAsFixed(0)}km'),
                        selected: radiusKm == km,
                        onSelected: (_) {
                          onChanged(km);
                          Navigator.pop(ctx);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 세부 카테고리 칩 ──────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final EventCategory selected;
  final ValueChanged<EventCategory> onSelected;

  static const _categories = EventCategory.values;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories
            .map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat.label),
                    selected: selected == cat,
                    onSelected: (_) => onSelected(cat),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
