// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Z:GUM';

  @override
  String get tabNow => '지금';

  @override
  String get tabYesterday => '어제';

  @override
  String get panelTitle => '지금';

  @override
  String momentCount(int count) {
    return '$count개의 순간';
  }

  @override
  String get noMomentsNearby => '주변에 진행 중인 순간이 없습니다';

  @override
  String walkingMinutes(int minutes) {
    return '도보 $minutes분';
  }

  @override
  String get partnerBadge => '지금';

  @override
  String get checkInButton => '지금';

  @override
  String get navigate => '안내';

  @override
  String get timerEnded => '종료됨';

  @override
  String timerDaysLeft(int days, int hours) {
    return '$days일 $hours시간 남음';
  }

  @override
  String get checkInMemoHint => '이 순간을 기록하세요 (선택)';

  @override
  String get addPhoto => '사진 추가 (선택)';

  @override
  String get cancel => '취소';

  @override
  String get camera => '카메라';

  @override
  String get gallery => '갤러리';

  @override
  String get isFree => '무료 입장';

  @override
  String get isPaid => '유료 입장';

  @override
  String get navigateStop => '안내 종료';

  @override
  String get routeSearching => '경로 탐색 중...';

  @override
  String get routeError => '경로를 불러오지 못했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get dataError => '데이터를 불러오지 못했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get retry => '재시도';

  @override
  String get searchHint => '공연명 또는 장소 검색';

  @override
  String get searchEmpty => '검색 결과가 없습니다';

  @override
  String get settings => '설정';

  @override
  String get settingIdentity => '본인인증';

  @override
  String get settingNotifications => '알림';

  @override
  String get settingAppInfo => '앱 정보';

  @override
  String get settingLanguage => '언어';

  @override
  String get languageTitle => '언어 선택';

  @override
  String get langKo => '한국어';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langZh => '中文';

  @override
  String get identityVerified => '인증 완료';

  @override
  String get identityNotVerified => '미인증';

  @override
  String get identityReset => '인증 초기화';

  @override
  String get checkInEmpty => '아직 기록된 순간이 없습니다';

  @override
  String get checkInDelete => '삭제';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryMovie => '영화';

  @override
  String get categoryTheater => '연극';

  @override
  String get categoryExhibition => '전시';

  @override
  String get categoryShow => '관람';

  @override
  String get categoryConcert => '공연';

  @override
  String get categoryPartner => '지금';

  @override
  String get adultOnly => '19+';
}
