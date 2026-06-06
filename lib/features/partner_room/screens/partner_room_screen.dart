import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/location_service.dart';

class PartnerRoomScreen extends StatefulWidget {
  const PartnerRoomScreen({super.key});

  @override
  State<PartnerRoomScreen> createState() => _PartnerRoomScreenState();
}

class _PartnerRoomScreenState extends State<PartnerRoomScreen> {
  final _locationService = LocationService();

  _RegisterStep _step = _RegisterStep.idle;
  LocationResult? _locationResult;

  // 주변 장소 목록 (실제 API 연동 전 구조 준비)
  List<_NearbyPlace> _nearbyPlaces = [];
  _NearbyPlace? _selectedPlace;

  // 주소 직접 입력
  final _addressCtrl = TextEditingController();
  bool _showAddressInput = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _startLocationAcquire() async {
    setState(() {
      _step = _RegisterStep.acquiring;
      _nearbyPlaces = [];
      _selectedPlace = null;
      _showAddressInput = false;
    });

    final result = await _locationService.acquireLocation();
    if (!mounted) return;

    if (result.step == LocationStep.manual) {
      // GPS·네트워크 모두 실패 → 주소 직접 입력으로
      setState(() {
        _step = _RegisterStep.addressInput;
        _showAddressInput = true;
      });
      return;
    }

    // 위치 확보 → 주변 장소 조회 (mock, 실제 API로 교체 예정)
    final places = await _fetchNearbyPlaces(result.position);
    if (!mounted) return;

    setState(() {
      _locationResult = result;
      _nearbyPlaces = places;
      _step = _RegisterStep.confirm;
    });
  }

  // 실제 카카오 로컬 API로 교체 예정
  Future<List<_NearbyPlace>> _fetchNearbyPlaces(LatLng pos) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      _NearbyPlace(name: '이 위치 근처 (정확한 장소를 선택해 주세요)', address: ''),
    ];
  }

  void _confirmPlace(_NearbyPlace place) {
    setState(() {
      _selectedPlace = place;
      _step = _RegisterStep.ready;
    });
  }

  void _retry() {
    _startLocationAcquire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Z:GUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 56),
                  const Text(
                    '파트너 룸',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _RegisterStep.idle:
        return _buildIdle();
      case _RegisterStep.acquiring:
        return _buildAcquiring();
      case _RegisterStep.confirm:
        return _buildConfirm();
      case _RegisterStep.addressInput:
        return _buildAddressInput();
      case _RegisterStep.ready:
        return _buildReady();
    }
  }

  // ── 초기 화면 ──────────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이벤트를 등록하려면\n현재 위치가 필요합니다.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.75,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _startLocationAcquire,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF16213E),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              '이벤트 등록 시작',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── 위치 획득 중 ────────────────────────────────────────────────────────────

  Widget _buildAcquiring() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            '위치를 확인하는 중...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── 주변 장소 확인 ──────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    final result = _locationResult;
    final stepLabel = result?.step == LocationStep.lastKnown
        ? '이전 위치 기준'
        : result?.step == LocationStep.network
            ? '대략적인 위치'
            : 'GPS 위치';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  stepLabel,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '이 위치가 맞습니까?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _nearbyPlaces.length,
              separatorBuilder: (_, __) => const Divider(
                  color: Colors.white12, height: 1),
              itemBuilder: (_, i) {
                final place = _nearbyPlaces[i];
                return ListTile(
                  onTap: () => _confirmPlace(place),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined,
                      color: Colors.white54, size: 20),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                  ),
                  subtitle: place.address.isNotEmpty
                      ? Text(place.address,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12))
                      : null,
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.white30, size: 20),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('위치 다시 잡기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _showAddressInput = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('주소 직접 입력'),
                ),
              ),
            ],
          ),
          if (_showAddressInput) ...[
            const SizedBox(height: 16),
            _buildAddressField(),
          ],
        ],
      ),
    );
  }

  // ── 주소 직접 입력 ──────────────────────────────────────────────────────────

  Widget _buildAddressInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '위치를 찾지 못했습니다.\n주소를 직접 입력해 주세요.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 24),
          _buildAddressField(),
          const Spacer(),
          OutlinedButton(
            onPressed: _retry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('위치 다시 잡기'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return TextField(
      controller: _addressCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: '예) 서울 마포구 홍대입구',
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.white54, size: 20),
          onPressed: () {
            if (_addressCtrl.text.trim().isNotEmpty) {
              setState(() => _step = _RegisterStep.ready);
            }
          },
        ),
      ),
    );
  }

  // ── 등록 준비 완료 ──────────────────────────────────────────────────────────

  Widget _buildReady() {
    final label = _selectedPlace?.name.isNotEmpty == true
        ? _selectedPlace!.name
        : _addressCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _startLocationAcquire,
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white54, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '이벤트 등록 기능은\n준비 중입니다.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.75,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              '이벤트 정보 입력 →',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RegisterStep { idle, acquiring, confirm, addressInput, ready }

class _NearbyPlace {
  final String name;
  final String address;
  const _NearbyPlace({required this.name, required this.address});
}
