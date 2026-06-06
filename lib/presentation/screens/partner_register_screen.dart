import 'package:flutter/material.dart';
import '../../data/models/cultural_event.dart';

// ── 이벤트 지속 시간 선택지 ────────────────────────────────────────────────────

enum _EventDuration {
  one('1시간 동안', Duration(hours: 1)),
  two('2시간 동안', Duration(hours: 2)),
  three('3시간 동안', Duration(hours: 3)),
  four('4시간 동안', Duration(hours: 4)),
  untilClose('오늘 영업 마감까지', null);

  const _EventDuration(this.label, this.duration);
  final String label;

  /// null = '오늘 영업 마감까지' 선택 → 별도 마감 시각 입력
  final Duration? duration;
}

// ── 화면 ──────────────────────────────────────────────────────────────────────

/// 파트너(소상공인) 반짝 이벤트 등록 폼.
///
/// 추후 연동 포인트:
/// - [_PartnerRegisterScreenState._submit] → 서버 API 호출로 교체
class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const PartnerRegisterScreen());

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── 컨트롤러 ────────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── 상태 ────────────────────────────────────────────────────────────────────
  EventCategory _category = EventCategory.partner;
  _EventDuration _selectedDuration = _EventDuration.two;
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  bool _isAdultOnly = false;
  bool _isSubmitting = false;

  /// 선택된 지속 시간으로부터 종료 시각 계산
  DateTime get _computedEndDateTime {
    final now = DateTime.now();
    if (_selectedDuration.duration != null) {
      return now.add(_selectedDuration.duration!);
    }
    return DateTime(
      now.year, now.month, now.day,
      _closingTime.hour, _closingTime.minute,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── 빌드 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반짝 이벤트 등록'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBar: _SubmitBar(
        isLoading: _isSubmitting,
        onSubmit: _submit,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── 섹션 1: 이벤트 정보 ────────────────────────────────────────
            _FormCard(
              icon: Icons.campaign_outlined,
              title: '이벤트 정보',
              children: [
                _InputField(
                  controller: _titleCtrl,
                  label: '이벤트 제목 *',
                  hint: '예) 금요일 저녁 라이브 공연',
                  validator: _required('제목을 입력하세요'),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _descCtrl,
                  label: '내용 *',
                  hint: '예) 오늘 저녁 7시부터 어쿠스틱 라이브 공연이 있습니다.',
                  maxLines: 3,
                  validator: _required('내용을 입력하세요'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 섹션 2: 업장 정보 ────────────────────────────────────────
            _FormCard(
              icon: Icons.storefront_outlined,
              title: '업장 정보',
              children: [
                _InputField(
                  controller: _venueCtrl,
                  label: '업장명 *',
                  hint: '예) 포장마차 을지로점',
                  validator: _required('업장명을 입력하세요'),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _addressCtrl,
                  label: '주소 *',
                  hint: '예) 서울 중구 을지로 12',
                  validator: _required('주소를 입력하세요'),
                ),
                const SizedBox(height: 14),
                _CategorySelector(
                  selected: _category,
                  onChanged: (c) => setState(() => _category = c),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 섹션 3: 이벤트 지속 시간 ────────────────────────────────
            _FormCard(
              icon: Icons.hourglass_empty_outlined,
              title: '이벤트 지속 시간',
              children: [
                RadioGroup<_EventDuration>(
                  groupValue: _selectedDuration,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedDuration = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _EventDuration.values
                        .map((d) => _DurationRadioTile(value: d))
                        .toList(),
                  ),
                ),

                if (_selectedDuration == _EventDuration.untilClose) ...[
                  const SizedBox(height: 4),
                  _ClosingTimeTile(
                    time: _closingTime,
                    onChanged: (t) => setState(() => _closingTime = t),
                  ),
                ],

                const SizedBox(height: 10),
                _EndTimePreview(endDateTime: _computedEndDateTime),
              ],
            ),

            const SizedBox(height: 12),

            // ── 섹션 4: 추가 설정 ────────────────────────────────────────
            _FormCard(
              icon: Icons.tune_outlined,
              title: '추가 설정',
              children: [
                SwitchListTile.adaptive(
                  title: const Text('만 19세 이상 전용'),
                  subtitle: const Text(
                    '활성화 시 상세 진입 전 본인 인증 팝업이 표시됩니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isAdultOnly,
                  onChanged: (v) => setState(() => _isAdultOnly = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 로직 ────────────────────────────────────────────────────────────────────

  String? Function(String?) _required(String msg) =>
      (v) => (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final end = _computedEndDateTime;
    if (_selectedDuration == _EventDuration.untilClose &&
        end.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('영업 마감 시간이 현재 시각보다 이전입니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // TODO: PartnerEventRepository.register() API 호출로 교체
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final endStr =
        '오늘 ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('등록 신청 완료'),
        content: Text('이벤트 등록이 접수됐습니다.\n종료 예정: $endStr'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// ── 공용 폼 카드 ──────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── 텍스트 입력 필드 ──────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        border: border,
        enabledBorder: border,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── 카테고리 선택 칩 ──────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final EventCategory selected;
  final ValueChanged<EventCategory> onChanged;

  static const _options = [
    EventCategory.partner,
    EventCategory.show,
    EventCategory.concert,
    EventCategory.exhibition,
    EventCategory.movie,
    EventCategory.theater,
  ];

  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _options
              .map((c) => FilterChip(
                    label: Text(c.label),
                    selected: selected == c,
                    onSelected: (_) => onChanged(c),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── 지속 시간 라디오 타일 ─────────────────────────────────────────────────────

class _DurationRadioTile extends StatelessWidget {
  final _EventDuration value;

  const _DurationRadioTile({required this.value});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_EventDuration>(
      value: value,
      title: Text(value.label, style: const TextStyle(fontSize: 14)),
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
    );
  }
}

// ── 영업 마감 시각 직접 입력 타일 ─────────────────────────────────────────────

class _ClosingTimeTile extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _ClosingTimeTile({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: InkWell(
        onTap: () async {
          final picked =
              await showTimePicker(context: context, initialTime: time);
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 18),
              const SizedBox(width: 10),
              const Text('영업 마감 시각'),
              const Spacer(),
              Text(
                formatted,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 종료 예정 시각 미리보기 ────────────────────────────────────────────────────

class _EndTimePreview extends StatelessWidget {
  final DateTime endDateTime;

  const _EndTimePreview({required this.endDateTime});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = endDateTime.hour.toString().padLeft(2, '0');
    final m = endDateTime.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: cs.primary),
          const SizedBox(width: 7),
          Text(
            '이벤트 종료 예정  오늘 $h:$m',
            style: TextStyle(
              color: cs.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 고정 등록 버튼 바 ────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.isLoading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: FilledButton(
          onPressed: isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  '이벤트 등록 신청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
