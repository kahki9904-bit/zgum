/// 앱 전체 API 키 및 외부 설정 관리.
///
/// ## 사용 방법
/// 빌드 시 --dart-define 으로 값을 주입합니다:
///
/// ```bash
/// flutter run \
///   --dart-define=TOUR_API_KEY=your_key \
///   --dart-define=NAVER_CLIENT_ID=your_id \
///   --dart-define=NAVER_CLIENT_SECRET=your_secret \
///   --dart-define=KAKAO_API_KEY=your_key
/// ```
///
/// VS Code 사용 시 .vscode/launch.json 에 args 로 추가하세요:
/// ```json
/// {
///   "args": [
///     "--dart-define=TOUR_API_KEY=your_key",
///     "--dart-define=NAVER_CLIENT_ID=your_id"
///   ]
/// }
/// ```
///
/// 값을 소스에 직접 커밋하지 마세요. .gitignore 에 launch.json 을 추가하거나
/// CI/CD 환경 변수로 관리하는 것을 권장합니다.
abstract final class AppConfig {
  // ── 한국관광공사 Tour API (공공데이터포털) ──────────────────────────────────
  static const String tourApiKey = String.fromEnvironment(
    'TOUR_API_KEY',
    defaultValue: '',
  );

  static const String tourApiBaseUrl =
      'https://apis.data.go.kr/B551011/KorService1';

  // ── 네이버 개발자 센터 (developers.naver.com) ───────────────────────────────
  /// 네이버 지역 검색, 영화 정보, 블로그 검색 API 등에 사용
  static const String naverClientId = String.fromEnvironment(
    'NAVER_CLIENT_ID',
    defaultValue: '',
  );

  static const String naverClientSecret = String.fromEnvironment(
    'NAVER_CLIENT_SECRET',
    defaultValue: '',
  );

  // ── 카카오 개발자 센터 (developers.kakao.com) ───────────────────────────────
  /// 카카오 로컬 API (장소 검색, 주소 변환 등) 에 사용
  static const String kakaoApiKey = String.fromEnvironment(
    'KAKAO_API_KEY',
    defaultValue: '',
  );

  // ── 소상공인시장진흥공단 상가(상권)정보 API ──────────────────────────────────
  static const String sdscApiKey = String.fromEnvironment(
    'SDSC_API_KEY',
    defaultValue: '',
  );

  static const String sdscApiBaseUrl =
      'https://apis.data.go.kr/B553077/api/open/sdsc2';

  // ── 키 등록 여부 확인 헬퍼 ────────────────────────────────────────────────
  static bool get hasTourApiKey => tourApiKey.isNotEmpty;
  static bool get hasSdscKey => sdscApiKey.isNotEmpty;
  static bool get hasNaverKey => naverClientId.isNotEmpty;
  static bool get hasKakaoKey => kakaoApiKey.isNotEmpty;
}
