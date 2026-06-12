import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../services/location_service.dart';
import '../../../core/models/free_use_status.dart';
import '../../../core/providers/free_use_provider.dart';
import '../../../core/services/free_use_service.dart';
import '../../../data/models/cultural_event.dart';
import '../../../core/providers/partner_focus_provider.dart';
import '../../../core/providers/shell_page_provider.dart';
import '../../../dev/mock_partner_event_store.dart';
import '../../../features/alert/models/partner_event.dart';
import '../../../features/alert/providers/event_stats_provider.dart';
import 'partner_dashboard_screen.dart';

class PartnerRoomScreen extends ConsumerStatefulWidget {
  const PartnerRoomScreen({super.key});

  @override
  ConsumerState<PartnerRoomScreen> createState() => _PartnerRoomScreenState();
}

class _PartnerRoomScreenState extends ConsumerState<PartnerRoomScreen> {
  final List<PartnerEvent> _myEvents = [];
  bool _newestFirst = true;

  void _openRegisterSheet() async {
    final freeService = FreeUseService.instance;
    final isFreeActive = ref.read(freeUseProvider) == FreeUseStatus.active;

    // 무료이용 활성화 상태이고 오늘 한도가 남아 있으면 결제 없이 등록
    if (isFreeActive) {
      final messenger = ScaffoldMessenger.of(context);
      final canRegister = await freeService.canRegisterToday();
      if (!canRegister) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('오늘 등록 가능 횟수(3회)를 모두 사용했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // 등록 전 GPS 위치 획득. 실패 시 fallback 위치 사용 (테스트용 임시 처리)
    final locationResult = await LocationService().acquireLocation();
    if (!mounted) return;
    final registerLocation = locationResult.position;

    PartnerEvent? pending;
    await _PartnerEventSheet.show(
      context,
      isFreeUse: isFreeActive,
      registerLocation: registerLocation,
      onSubmit: (e) { pending = e; },
    );
    if (pending == null || !mounted) return;

    // 무료이용: 결제 시트 건너뜀
    if (isFreeActive) {
      await freeService.recordRegistration();
      final freeEvent = pending!.copyWith(
        paymentStatus: PaymentStatus.paid,
        paidAt: DateTime.now(),
      );
      setState(() => _myEvents.insert(0, freeEvent));
      _applyToMap(freeEvent);
      return;
    }

    // 기존 결제 흐름
    // 등록 시트 종료 애니메이션(280ms)이 끝난 뒤 결제 시트를 열어야 정상 표시됨
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final paid = await _MockPaymentSheet.show(context, pending!);
    if (!paid || !mounted) return;
    final paidEvent = pending!.copyWith(
      paymentStatus: PaymentStatus.paid,
      paidAt: DateTime.now(),
    );
    setState(() => _myEvents.insert(0, paidEvent));
    _applyToMap(paidEvent);
  }

  // DEV/MOCK ONLY: PartnerEvent를 CulturalEvent로 변환해 지도에 즉시 반영
  // 운영 전환 시 삭제 → Firebase 결제 검증 후 Firestore 저장으로 대체
  void _applyToMap(PartnerEvent event) {
    final mockCultural = CulturalEvent(
      id: event.id,
      title: event.title,
      venue: event.venue,
      address: '현재 위치',
      description: event.message ?? event.title,
      startDate: event.startsAt,
      endDateTime: event.expiresAt,
      location: event.location,
      category: EventCategory.partner,
      isFree: false,
      source: EventSource.partner,
      partnerMessage: event.message,
    );
    ref.read(mockPartnerEventStoreProvider.notifier).state = [
      ...ref.read(mockPartnerEventStoreProvider),
      mockCultural,
    ];
    // 등록 완료 후 지도 탭으로 전환 + 해당 이벤트 포커스 요청
    ref.read(partnerFocusPendingProvider.notifier).state = true;
    ref.read(partnerFocusProvider.notifier).state = mockCultural;
    ref.read(shellPageProvider.notifier).state = 1;
  }

  void _seedPreviewData() {
    final now = DateTime.now();
    final seeds = [
      PartnerEvent(
        id: 'seed-001',
        partnerId: 'local-device',
        title: '오늘 한정 50% 할인',
        venue: '홍대 카페 VIBE',
        message: '지금 오시면 아메리카노 반값!',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(minutes: 20)),
      ),
      PartnerEvent(
        id: 'seed-002',
        partnerId: 'local-device',
        title: '버스킹 공연 시작',
        venue: '홍대 걷고싶은거리',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(minutes: 55)),
      ),
      PartnerEvent(
        id: 'seed-003',
        partnerId: 'local-device',
        title: '팝업 전시 오픈',
        venue: '연남동 갤러리 ONE',
        message: '오늘만 무료 입장',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.subtract(const Duration(minutes: 5)),
      ),
      PartnerEvent(
        id: 'seed-004',
        partnerId: 'local-device',
        title: '라이브 재즈 공연',
        venue: '마포 재즈바 BLUE',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(minutes: 20)),
        expiresAt: now.add(const Duration(minutes: 40)),
      ),
      PartnerEvent(
        id: 'seed-005',
        partnerId: 'local-device',
        title: '플리마켓 진행 중',
        venue: '상수동 광장',
        message: '핸드메이드 소품 판매',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(minutes: 30)),
      ),
      PartnerEvent(
        id: 'seed-006',
        partnerId: 'local-device',
        title: '신메뉴 무료 시식',
        venue: '이태원 레스토랑 NOMA',
        location: AppConstants.defaultLocation,
        geoHash: 'mock',
        startsAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(minutes: 45)),
      ),
    ];
    setState(() => _myEvents
      ..clear()
      ..addAll(seeds));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;
    final sorted = _newestFirst
        ? List<PartnerEvent>.from(_myEvents)
        : _myEvents.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad + 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        '이벤트',
                        style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (_myEvents.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () =>
                            setState(() => _newestFirst = !_newestFirst),
                        child: Text(
                          _newestFirst ? '최신순' : '과거순',
                          style: const TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const PartnerDashboardScreen()),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: const Icon(
                          Icons.bar_chart_outlined,
                          size: 20,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const Center(
                        child: Text(
                          '등록된 이벤트가 없습니다',
                          style: TextStyle(
                              color: Color(0xFFCCCCCC), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _seedPreviewData,
                          child: const Text(
                            '미리보기 데이터 채우기',
                            style: TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, botPad + 88),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 200,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _EventTile(
                      event: sorted[index],
                    ),
                  ),
                ),
            ],
          ),

          // 지금 버튼 → ShellScreen 공통 하단 탭으로 통합 예정, 임시 숨김

        ],
      ),
    );
  }
}

// ── 이벤트 그리드 타일 ─────────────────────────────────────────────────────────

class _EventTile extends ConsumerWidget {
  final PartnerEvent event;
  const _EventTile({required this.event});

  void _openDetail(BuildContext context, EventStats? stats) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _EventDetailPopup(event: event, stats: stats),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(eventStatsProvider)[event.id];
    final repPhoto = event.representativePhotoPath;
    final hasStats = stats != null &&
        (stats.visitorCount > 0 || stats.traceCount > 0);

    return GestureDetector(
      onTap: () => _openDetail(context, stats),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: repPhoto != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(repPhoto),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _textTile(hasStats, stats),
                  ),
                  if (hasStats)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '방문 ${stats.visitorCount}  |  흔적 ${stats.traceCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : _textTile(hasStats, stats),
      ),
    );
  }


  Widget _textTile(bool hasStats, EventStats? stats) {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFF16213E),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (hasStats && stats != null) ...[
            const SizedBox(height: 10),
            Text(
              '방문 ${stats.visitorCount}  |  흔적 ${stats.traceCount}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 이벤트 상세 팝업 ────────────────────────────────────────────────────────────

class _EventDetailPopup extends StatelessWidget {
  final PartnerEvent event;
  final EventStats? stats;
  const _EventDetailPopup({required this.event, this.stats});

  String _formatDateTime(DateTime dt) =>
      '${dt.year}년 ${dt.month}월 ${dt.day}일  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _durationLabel() {
    final hours = event.expiresAt.difference(event.startsAt).inHours;
    return '$hours시간';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isExpired = DateTime.now().isAfter(event.expiresAt);
    final repPhoto = event.representativePhotoPath;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.72,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: repPhoto != null
                ? Image.file(
                    File(repPhoto),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _noPhotoHeader(),
                  )
                : _noPhotoHeader(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? const Color(0xFFEEEEEE)
                              : const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isExpired ? '종료' : '진행 중',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isExpired
                                ? const Color(0xFF888888)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _durationLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.venue,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                  if (stats != null &&
                      (stats!.visitorCount > 0 || stats!.traceCount > 0)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statChip('방문', stats!.visitorCount),
                        const SizedBox(width: 8),
                        _statChip('흔적', stats!.traceCount),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  _infoRow('시작', _formatDateTime(event.startsAt)),
                  const SizedBox(height: 6),
                  _infoRow('종료', _formatDateTime(event.expiresAt)),
                  if (event.message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      event.message!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                        height: 1.85,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _noPhotoHeader() {
    return Container(
      color: const Color(0xFF16213E),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        event.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }
}

// ── 이벤트 등록 팝업 ────────────────────────────────────────────────────────────

class _PartnerEventSheet {
  const _PartnerEventSheet._();

  static Future<void> show(
    BuildContext context, {
    required void Function(PartnerEvent) onSubmit,
    bool isFreeUse = false,
    required LatLng registerLocation,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, __, ___) => GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _RegisterContent(
                onSubmit: onSubmit,
                isFreeUse: isFreeUse,
                initialLocation: registerLocation,
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _RegisterContent extends StatefulWidget {
  final void Function(PartnerEvent) onSubmit;
  final bool isFreeUse;
  final LatLng initialLocation;
  const _RegisterContent({
    required this.onSubmit,
    required this.initialLocation,
    this.isFreeUse = false,
  });

  @override
  State<_RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<_RegisterContent> {
  final _titleCtrl = TextEditingController();
  final _picker = ImagePicker();
  int _selectedMinutes = 60;
  final List<File> _photos = [];
  final List<TextEditingController> _photoCtrls = [];
  int _repIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _photoCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _photos.add(File(picked.path));
      _photoCtrls.add(TextEditingController());
    });
  }

  void _deletePhoto(int index) {
    setState(() {
      _photoCtrls[index].dispose();
      _photos.removeAt(index);
      _photoCtrls.removeAt(index);
      if (_photos.isEmpty) {
        _repIndex = 0;
      } else if (index == _repIndex) {
        _repIndex = 0;
      } else if (index < _repIndex) {
        _repIndex--;
      }
    });
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    if (_photos.isEmpty) return;

    final photoList = List.generate(
      _photos.length,
      (i) => PartnerPhoto(
        path: _photos[i].path,
        title: _photoCtrls[i].text.trim().isEmpty
            ? null
            : _photoCtrls[i].text.trim(),
      ),
    );

    final now = DateTime.now();
    final orderId = 'order-${now.millisecondsSinceEpoch}';
    final event = PartnerEvent(
      id: now.millisecondsSinceEpoch.toString(),
      partnerId: 'local-device',
      title: title,
      venue: title,
      message: null,
      // TEST: GPS 위치 사용. 획득 실패 시 LocationService가 fallback 반환
      location: widget.initialLocation,
      geoHash: 'mock',
      startsAt: now,
      expiresAt: now.add(Duration(minutes: _selectedMinutes)),
      photos: photoList,
      representativeIndex: _repIndex.clamp(0, photoList.length - 1),
      orderId: orderId,
      paymentStatus: PaymentStatus.pending,
    );

    Navigator.pop(context);
    widget.onSubmit(event);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Material(
      color: Colors.transparent,
      child: Container(
      width: double.infinity,
      height: screenHeight * 0.72,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 현장 사진 (최소 1장, 최대 3장) ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildPartnerCell(i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: i < _photos.length
                          ? _buildPhotoTitleField(i)
                          : const SizedBox(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── 기간 선택 (무료이용은 1시간 고정, 나머지는 비활성 표시) ──
            const Text(
              '노출시간',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [60, 120, 180].map((min) {
                final isLocked = widget.isFreeUse && min != 60;
                final selected = _selectedMinutes == min;
                final label = '${min ~/ 60}시간';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: isLocked ? null : () => setState(() => _selectedMinutes = min),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? const Color(0xFFF4F4F7)
                            : selected
                                ? const Color(0xFF16213E)
                                : const Color(0xFFF4F4F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? const Color(0xFFDDDDDD)
                              : selected
                                  ? Colors.white
                                  : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // ── 제목 (필수) ────────────────────────────────────────────
            const Text(
              '제목',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            _buildField(_titleCtrl, '필수'),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16213E),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '등록',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      cursorColor: const Color(0xFF16213E),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPartnerCell(int i) {
    if (i < _photos.length) {
      final isRep = i == _repIndex;
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_photos[i], fit: BoxFit.cover),
            Positioned(
              top: 6,
              left: 6,
              child: GestureDetector(
                onTap: () => setState(() => _repIndex = i),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isRep
                        ? const Color(0xFF16213E)
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRep ? Icons.star : Icons.star_border,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (i == _photos.length && _photos.length < 3) {
      return GestureDetector(
        onTap: _takePhoto,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined,
                size: 20, color: Color(0xFFAAAAAA)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildPhotoTitleField(int i) {
    return TextField(
      controller: _photoCtrls[i],
      maxLength: 12,
      style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: '사진 제목',
        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        counterStyle:
            const TextStyle(fontSize: 9, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}

// ── 가상 결제 팝업 ──────────────────────────────────────────────────────────────

class _MockPaymentSheet {
  const _MockPaymentSheet._();

  static Future<bool> show(BuildContext context, PartnerEvent event) async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (dialogContext, __, ___) => GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: _MockPaymentContent(event: event),
                ),
              ),
            ),
          ),
          transitionBuilder: (_, animation, __, child) => ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ) ??
        false;
  }
}

class _MockPaymentContent extends StatelessWidget {
  final PartnerEvent event;
  const _MockPaymentContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final hours = event.expiresAt.difference(event.startsAt).inHours;
    const unitPrice = 5000;
    final totalPrice = hours * unitPrice;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.72,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '결제',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.orderId ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCCCCCC),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // ── 주문 요약 ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('이벤트', event.title),
                  const SizedBox(height: 12),
                  _row('장소', event.venue),
                  const SizedBox(height: 12),
                  _row('노출시간', '$hours시간'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Color(0xFFF0F0F0)),
                  ),
                  _row('단가', '$unitPrice원 / 시간'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '총 결제금액',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Text(
                        '${_formatPrice(totalPrice)}원',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16213E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '테스트 모드 — 실제 결제가 발생하지 않습니다',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF996600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── 버튼 ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16213E),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '결제하기',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
