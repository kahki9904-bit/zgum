import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/check_in_record.dart';
import '../providers/check_in_provider.dart';
import 'settings_screen.dart';

class UserRoomScreen extends ConsumerStatefulWidget {
  const UserRoomScreen({super.key});

  @override
  ConsumerState<UserRoomScreen> createState() => _UserRoomScreenState();
}

class _UserRoomScreenState extends ConsumerState<UserRoomScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
          children: [
            _ProfileSection(),
            const SizedBox(height: 32),
            const _Rule(),
            const SizedBox(height: 32),
            _CheckInTimelineSection(
              records: ref.watch(checkInProvider),
              onDelete: (id) => ref.read(checkInProvider.notifier).delete(id),
            ),
            const SizedBox(height: 32),
            const _Rule(),
            const SizedBox(height: 32),
            const _SettingsSection(),
          ],
        ),
      ),
    );
  }
}

// ── 구역 1: 프로필 ─────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 구역 2: 체크인 타임라인 ────────────────────────────────────────────────────

class _CheckInTimelineSection extends StatelessWidget {
  final List<CheckInRecord> records;
  final void Function(String id) onDelete;

  const _CheckInTimelineSection({
    required this.records,
    required this.onDelete,
  });

  // 날짜별 그룹핑 (최신순)
  Map<String, List<CheckInRecord>> _grouped() {
    final map = <String, List<CheckInRecord>>{};
    for (final r in records) {
      final key = _dateLabel(r.checkedInAt);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  static String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${dt.month}월 ${dt.day}일';
  }

  static String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('어제'),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '아직 기록한 순간이 없습니다',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              ),
            ),
          )
        else
          ..._grouped().entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: Color(0xFF16213E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...entry.value.map((r) => _CheckInCard(
                      record: r,
                      timeLabel: _timeLabel(r.checkedInAt),
                      onDelete: onDelete,
                    )),
              ],
            );
          }),
      ],
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final CheckInRecord record;
  final String timeLabel;
  final void Function(String id) onDelete;

  const _CheckInCard({
    required this.record,
    required this.timeLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.eventTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.venue}  $timeLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFCCCCCC)),
                    onPressed: () => _confirmDelete(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            if (record.memo != null && record.memo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  record.memo!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ),
            if (record.photoPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(record.photoPath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기록 삭제', style: TextStyle(fontSize: 16)),
        content: const Text('이 기록을 삭제할까요?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(record.id);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }
}

// ── 구역 3: 설정 버튼 ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
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
                  child: const Icon(Icons.settings_outlined, size: 17, color: Color(0xFFAAAAAA)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '설정',
                    style: TextStyle(color: Color(0xFF333333), fontSize: 15),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFDDDDDD), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 공통 ──────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
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
