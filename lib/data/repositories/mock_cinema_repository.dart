import 'package:latlong2/latlong.dart';
import '../../core/geo_utils.dart';
import '../models/cinema_model.dart';
import 'cinema_repository.dart';

/// 테스트용 영화관 Mock 데이터.
///
/// 모든 상영 시각은 [DateTime.now()] 기준으로 동적으로 계산됩니다.
/// 앱을 실행할 때마다 '10분 후', '40분 후' 등이 항상 현재 시각 기준으로 맞습니다.
class MockCinemaRepository implements CinemaRepository {
  @override
  Future<List<CinemaModel>> fetchNearbyCinemas({
    required LatLng center,
    required double radiusKm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _buildCinemas()
        .where((c) => haversineKm(center, c.location) <= radiusKm)
        .toList();
  }

  List<CinemaModel> _buildCinemas() {
    final now = DateTime.now();
    // 분 단위로 깔끔하게 정렬하기 위해 현재 시각의 초·마이크로초 제거
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    // ── 영화관 1: CGV 을지로 ──────────────────────────────────────────────────
    final cgv = CinemaModel(
      id: 'cgv_euljiro',
      name: 'CGV 을지로',
      address: '서울 중구 을지로 30',
      location: const LatLng(37.5666, 126.9882),
      screenings: [
        ScreeningSchedule(
          movieTitle: '범죄도시 4',
          genre: '액션',
          ageRating: '15세',
          runtimeMinutes: 109,
          startAt: base.add(const Duration(minutes: 10)), // 10분 후 ★
        ),
        ScreeningSchedule(
          movieTitle: '파묘',
          genre: '공포',
          ageRating: '15세',
          runtimeMinutes: 134,
          startAt: base.add(const Duration(minutes: 40)), // 40분 후 ★
        ),
        ScreeningSchedule(
          movieTitle: '오펜하이머',
          genre: '드라마',
          ageRating: '15세',
          runtimeMinutes: 180,
          startAt: base.add(const Duration(hours: 2, minutes: 10)),
        ),
        // 이미 시작된 영화 (그레이 아웃 테스트용)
        ScreeningSchedule(
          movieTitle: '듄: 파트 2',
          genre: 'SF',
          ageRating: '12세',
          runtimeMinutes: 166,
          startAt: base.subtract(const Duration(minutes: 30)), // 30분 전 시작
        ),
      ],
    );

    // ── 영화관 2: 메가박스 신당 ───────────────────────────────────────────────
    final megabox = CinemaModel(
      id: 'megabox_sindang',
      name: '메가박스 신당',
      address: '서울 중구 다산로 262',
      location: const LatLng(37.5620, 127.0048),
      screenings: [
        ScreeningSchedule(
          movieTitle: '인사이드 아웃 2',
          genre: '애니메이션',
          ageRating: '전체',
          runtimeMinutes: 100,
          startAt: base.add(const Duration(minutes: 25)), // 25분 후 ★
        ),
        ScreeningSchedule(
          movieTitle: '인터스텔라',
          genre: 'SF',
          ageRating: '12세',
          runtimeMinutes: 169,
          startAt: base.add(const Duration(hours: 1, minutes: 30)),
        ),
        ScreeningSchedule(
          movieTitle: '밀수',
          genre: '범죄',
          ageRating: '15세',
          runtimeMinutes: 129,
          startAt: base.add(const Duration(hours: 2, minutes: 50)),
        ),
        // 상영 중 영화 테스트용
        ScreeningSchedule(
          movieTitle: '엘리멘탈',
          genre: '애니메이션',
          ageRating: '전체',
          runtimeMinutes: 101,
          startAt: base.subtract(const Duration(minutes: 20)), // 20분 전 시작
        ),
      ],
    );

    // ── 영화관 3: 롯데시네마 명동 ─────────────────────────────────────────────
    final lotte = CinemaModel(
      id: 'lotte_myeongdong',
      name: '롯데시네마 명동',
      address: '서울 중구 남대문로 81',
      location: const LatLng(37.5606, 126.9839),
      screenings: [
        ScreeningSchedule(
          movieTitle: '서울의 봄',
          genre: '드라마',
          ageRating: '12세',
          runtimeMinutes: 141,
          startAt: base.add(const Duration(minutes: 15)), // 15분 후 ★
        ),
        ScreeningSchedule(
          movieTitle: '소풍',
          genre: '드라마',
          ageRating: '전체',
          runtimeMinutes: 110,
          startAt: base.add(const Duration(minutes: 70)),
        ),
        ScreeningSchedule(
          movieTitle: '콘크리트 유토피아',
          genre: '재난',
          ageRating: '15세',
          runtimeMinutes: 130,
          startAt: base.add(const Duration(hours: 3, minutes: 20)),
        ),
      ],
    );

    return [cgv, megabox, lotte];
  }
}
