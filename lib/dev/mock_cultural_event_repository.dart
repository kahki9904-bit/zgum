import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../data/models/cultural_event.dart';
import '../data/repositories/cultural_event_repository.dart';

/// 공공데이터포털 API 연동 전 사용하는 Mock 구현체.
/// 실제 API Repository로 교체 시 이 파일 대신 [ApiCulturalEventRepository]를 주입하세요.
///
/// endDateTime은 [DateTime.now()] 기준 동적으로 생성됩니다.
/// → TimeService 필터링 테스트 시 앱 재시작 없이도 현재 시각 반영.
class MockCulturalEventRepository implements CulturalEventRepository {
  @override
  Future<List<CulturalEvent>> fetchNearbyEvents({
    required LatLng center,
    required double radiusKm,
    required bool isIdentityVerified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return _buildEvents(center).where((e) {
      if (!isIdentityVerified && e.isAdultOnly) return false;
      // 파트너 이벤트는 거리 제한 없이 항상 포함
      if (e.source == EventSource.partner) return true;
      return _haversineKm(center, e.location) <= radiusKm;
    }).toList();
  }

  List<CulturalEvent> _buildEvents(LatLng center) {
    final now = DateTime.now();
    // 오늘 특정 시각 헬퍼
    DateTime todayAt(int h, [int m = 0]) =>
        DateTime(now.year, now.month, now.day, h, m);

    return [
      // ── 공공 문화 행사 ──────────────────────────────────────────────────
      CulturalEvent(
        id: 'pub-001',
        title: '국립현대미술관 특별전: 빛과 공간',
        venue: '국립현대미술관 서울관',
        address: '서울 종로구 삼청로 30',
        description: '국내외 현대미술 작가 20인의 설치미술 특별전.\n'
            '빛을 매개로 공간을 재해석한 몰입형 작품들이 펼쳐집니다.',
        startDate: DateTime(2026, 5, 1),
        endDateTime: DateTime(2026, 8, 31, 18, 0),
        location: const LatLng(37.5794, 126.9766),
        category: EventCategory.exhibition,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-002',
        title: '뮤지컬: 광화문 연가',
        venue: '세종문화회관 대극장',
        address: '서울 종로구 세종대로 175',
        description: '이영훈 작곡가의 명곡으로 엮은 뮤지컬. 2026 리뉴얼 버전.\n'
            '50년 서울의 낭만을 무대 위에 재현합니다.',
        startDate: DateTime(2026, 6, 1),
        endDateTime: DateTime(2026, 7, 15, 21, 0),
        location: const LatLng(37.5726, 126.9766),
        category: EventCategory.theater,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-003',
        title: '서울 국제영화제 상영작',
        venue: '메가박스 코엑스',
        address: '서울 강남구 영동대로 513',
        description: '아시아 최대 영화제 수상작 모음전.\n다양한 나라의 독립 장편·단편 상영.',
        startDate: DateTime(2026, 6, 5),
        endDateTime: DateTime(2026, 6, 15, 22, 0),
        location: const LatLng(37.5126, 127.0594),
        category: EventCategory.movie,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-004',
        title: '청계천 광장 야외 버스킹',
        venue: '청계천 광통교 야외무대',
        address: '서울 종로구 청계천로 24',
        description: '매주 토요일 오후 7시, 인디 밴드 및 버스킹 공연. 무료 입장.',
        startDate: DateTime(2026, 5, 1),
        endDateTime: todayAt(22, 0),  // 오늘 22시 마감 (TimeService 필터 테스트용)
        location: const LatLng(37.5697, 126.9847),
        category: EventCategory.show,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-005',
        title: '서울역사박물관: 조선의 도시',
        venue: '서울역사박물관',
        address: '서울 종로구 새문안로 55',
        description: '조선시대 한양의 생활상과 도시문화를 재현한 기획전.',
        startDate: DateTime(2026, 3, 1),
        endDateTime: DateTime(2026, 12, 31, 18, 0),
        location: const LatLng(37.5714, 126.9698),
        category: EventCategory.exhibition,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-006',
        title: '예술의전당 클래식 갈라 콘서트',
        venue: '예술의전당 콘서트홀',
        address: '서울 서초구 남부순환로 2406',
        description: '국립 교향악단과 세계적인 피아니스트 협연.\n베토벤·쇼팽 프로그램.',
        startDate: DateTime(2026, 6, 20),
        endDateTime: DateTime(2026, 6, 21, 21, 30),
        location: const LatLng(37.4782, 127.0154),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-007',
        title: '홍대 거리 문화 축제',
        venue: '홍대 걷고싶은거리',
        address: '서울 마포구 어울마당로',
        description: '인디 밴드·스트리트 아트·푸드마켓이 어우러진 주말 축제. 무료 입장.',
        startDate: DateTime(2026, 6, 7),
        endDateTime: DateTime(2026, 6, 8, 22, 0),
        location: const LatLng(37.5561, 126.9232),
        category: EventCategory.show,
        isFree: true,
        source: EventSource.public,
      ),

      // ── 검색 테스트용 추가 데이터 ──────────────────────────────────────────
      CulturalEvent(
        id: 'pub-008',
        title: '서울 거리예술축제',
        venue: '광화문 광장',
        address: '서울 종로구 세종대로 172',
        description: '도시 곳곳을 무대로 펼쳐지는 거리예술 퍼포먼스 페스티벌.',
        startDate: DateTime(2026, 6, 1),
        endDateTime: DateTime(2026, 6, 30, 22, 0),
        location: const LatLng(37.5752, 126.9769),
        category: EventCategory.show,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-009',
        title: '빛의 환영',
        venue: '동대문디자인플라자',
        address: '서울 중구 을지로 281',
        description: '미디어아트와 빛을 활용한 몰입형 환경 설치 작품.',
        startDate: DateTime(2026, 5, 15),
        endDateTime: DateTime(2026, 8, 15, 21, 0),
        location: const LatLng(37.5671, 127.0096),
        category: EventCategory.exhibition,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-010',
        title: '인디밴드 야외 콘서트',
        venue: '올림픽공원 88잔디마당',
        address: '서울 송파구 올림픽로 424',
        description: '국내 인디밴드 10팀이 참여하는 야외 음악 축제.',
        startDate: DateTime(2026, 6, 14),
        endDateTime: DateTime(2026, 6, 14, 22, 0),
        location: const LatLng(37.5207, 127.1218),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-011',
        title: '부산 비치 시네마',
        venue: '한강공원 반포지구',
        address: '서울 서초구 신반포로 11',
        description: '야외 대형 스크린으로 즐기는 영화 상영 이벤트.',
        startDate: DateTime(2026, 7, 1),
        endDateTime: DateTime(2026, 7, 31, 23, 0),
        location: const LatLng(37.5124, 126.9998),
        category: EventCategory.movie,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-012',
        title: '현대미술 기획전',
        venue: '국립현대미술관 과천관',
        address: '경기 과천시 광명로 313',
        description: '동시대 작가들의 회화·조각·미디어아트 기획 전시.',
        startDate: DateTime(2026, 4, 1),
        endDateTime: DateTime(2026, 9, 30, 18, 0),
        location: const LatLng(37.4278, 126.9888),
        category: EventCategory.exhibition,
        isFree: false,
        source: EventSource.public,
      ),

      CulturalEvent(
        id: 'pub-013',
        title: '청소년 음악회',
        venue: '예술회관 소극장',
        address: '서울 중구 을지로 157',
        description: '청소년 음악 영재들의 연주 무대. 클래식부터 재즈까지.',
        startDate: DateTime(2026, 6, 21),
        endDateTime: DateTime(2026, 6, 21, 20, 0),
        location: const LatLng(37.5550, 127.0050),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-014',
        title: '오픈 가든 파티',
        venue: '중앙공원 야외 광장',
        address: '서울 서대문구 통일로 100',
        description: '도심 속 정원에서 열리는 플리마켓과 라이브 공연.',
        startDate: DateTime(2026, 6, 28),
        endDateTime: DateTime(2026, 6, 28, 21, 0),
        location: const LatLng(37.5800, 126.9700),
        category: EventCategory.show,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-015',
        title: '야시장 페스티벌',
        venue: '시장 광장',
        address: '서울 중구 남대문로 1',
        description: '야간 푸드마켓과 버스킹이 어우러진 주말 야시장.',
        startDate: DateTime(2026, 7, 4),
        endDateTime: DateTime(2026, 7, 6, 23, 0),
        location: const LatLng(37.5600, 126.9950),
        category: EventCategory.show,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-016',
        title: '클래식의 밤',
        venue: '대강당',
        address: '서울 마포구 월드컵로 240',
        description: '현악 4중주와 피아노 소나타로 구성된 실내악 공연.',
        startDate: DateTime(2026, 7, 10),
        endDateTime: DateTime(2026, 7, 10, 21, 30),
        location: const LatLng(37.5450, 126.9650),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'pub-017',
        title: '어린이 인형극',
        venue: '문화센터 어린이관',
        address: '서울 종로구 자하문로 1',
        description: '창작 인형극 3편 연속 상영. 전 연령 관람 가능.',
        startDate: DateTime(2026, 7, 12),
        endDateTime: DateTime(2026, 7, 13, 17, 0),
        location: const LatLng(37.5750, 126.9700),
        category: EventCategory.show,
        isFree: false,
        source: EventSource.public,
      ),

      // ── 파트너 이벤트 ──────────────────────────────────────────────────
      CulturalEvent(
        id: 'par-001',
        title: '커피빈 광화문점 오늘의 순간',
        venue: '커피빈 광화문점',
        address: '서울 종로구 세종대로 149',
        description: '광화문 한복판, 지금 이 순간을 커피 한 잔과 함께.',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 4)),
        location: const LatLng(37.5720, 126.9757),
        category: EventCategory.partner,
        isFree: false,
        source: EventSource.partner,
        partnerMessage: '지금 이 순간, 광화문에서 잠깐 쉬어가세요.',
      ),
      CulturalEvent(
        id: 'par-002',
        title: '도미노피자 종로점 점심 시간',
        venue: '도미노피자 종로점',
        address: '서울 종로구 종로 12',
        description: '평일 점심, 종로에서 잠깐 쉬어가는 시간.',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 3)),
        location: const LatLng(37.5695, 126.9825),
        category: EventCategory.partner,
        isFree: false,
        source: EventSource.partner,
      ),
      CulturalEvent(
        id: 'par-003',
        title: 'Zen Spa 인사동 신규 오픈',
        venue: 'Zen Spa 인사동',
        address: '서울 종로구 인사동5길 18',
        description: '인사동 골목 새로 문을 연 스파. 오늘 첫 방문객을 맞이합니다.',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 8)),
        location: const LatLng(37.5741, 126.9862),
        category: EventCategory.partner,
        isFree: false,
        source: EventSource.partner,
        partnerMessage: '오늘 처음 문을 여는 공간입니다.',
      ),

      // ── 성인 전용 이벤트 (isAdultOnly: true) ────────────────────────────
      CulturalEvent(
        id: 'par-adult-001',
        title: '루프탑 바 Sky Lounge',
        venue: 'Sky Lounge 강남',
        address: '서울 강남구 테헤란로 152',
        description: '강남 루프탑에서 저녁 시간을 보내는 공간.\n만 19세 이상 입장 가능.',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 5)),
        location: const LatLng(37.5013, 127.0376),
        category: EventCategory.partner,
        isFree: false,
        isAdultOnly: true,
        source: EventSource.partner,
      ),
      CulturalEvent(
        id: 'par-adult-002',
        title: 'The Card Room 강남 오픈',
        venue: 'The Card Room 강남',
        address: '서울 강남구 논현로 508',
        description: '보드게임·카드게임 전문 성인 라운지. 신규 오픈.\n만 19세 이상만 이용 가능합니다.',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: const LatLng(37.5102, 127.0244),
        category: EventCategory.show,
        isFree: false,
        isAdultOnly: true,
        source: EventSource.partner,
      ),

      // ── 테스트용 가상 이벤트 (현재 위치 주변 고정 배치) ──────────────────────
      // 10분 도보 경계(약 667m) 안쪽
      CulturalEvent(
        id: 'test-001',
        title: '[테스트] 근처 전시 (5분)',
        venue: '테스트 갤러리',
        address: '현재 위치 북동쪽 약 350m',
        description: '테스트용. 현재 위치 기준 북동쪽 350m (도보 5분 이내)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude + 0.003, center.longitude + 0.002),
        category: EventCategory.exhibition,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'test-002',
        title: '[테스트] 근처 콘서트 (7분)',
        venue: '테스트 공연장',
        address: '현재 위치 북서쪽 약 450m',
        description: '테스트용. 현재 위치 기준 북서쪽 450m (도보 7분 이내)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude + 0.002, center.longitude - 0.004),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'test-003',
        title: '[테스트] 근처 영화 (8분)',
        venue: '테스트 영화관',
        address: '현재 위치 남동쪽 약 500m',
        description: '테스트용. 현재 위치 기준 남동쪽 500m (도보 8분 이내)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude - 0.004, center.longitude + 0.003),
        category: EventCategory.movie,
        isFree: false,
        source: EventSource.public,
      ),
      // 10분 도보 경계(약 667m) 바깥쪽 — 흐리게 표시되어야 함
      CulturalEvent(
        id: 'test-004',
        title: '[테스트] 원거리 공연 (흐림)',
        venue: '테스트 원거리 공연장',
        address: '현재 위치 북쪽 약 900m',
        description: '테스트용. 현재 위치 기준 북쪽 900m (도보 10분 초과 → 흐리게)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude + 0.008, center.longitude),
        category: EventCategory.theater,
        isFree: false,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'test-005',
        title: '[테스트] 원거리 전시 (흐림)',
        venue: '테스트 원거리 갤러리',
        address: '현재 위치 동쪽 약 950m',
        description: '테스트용. 현재 위치 기준 동쪽 950m (도보 10분 초과 → 흐리게)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude, center.longitude + 0.010),
        category: EventCategory.exhibition,
        isFree: true,
        source: EventSource.public,
      ),
      CulturalEvent(
        id: 'test-006',
        title: '[테스트] 원거리 콘서트 (흐림)',
        venue: '테스트 원거리 콘서트홀',
        address: '현재 위치 남서쪽 약 1km',
        description: '테스트용. 현재 위치 기준 남서쪽 1km (도보 10분 초과 → 흐리게)',
        startDate: now,
        endDateTime: now.add(const Duration(hours: 6)),
        location: LatLng(center.latitude - 0.007, center.longitude - 0.007),
        category: EventCategory.concert,
        isFree: false,
        source: EventSource.public,
      ),

    ];
  }

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  double _rad(double d) => d * pi / 180;
}
