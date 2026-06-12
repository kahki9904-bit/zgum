import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'Z:GUM'**
  String get appName;

  /// No description provided for @tabNow.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get tabNow;

  /// No description provided for @tabYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get tabYesterday;

  /// No description provided for @panelTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get panelTitle;

  /// No description provided for @momentCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 순간'**
  String momentCount(int count);

  /// No description provided for @noMomentsNearby.
  ///
  /// In ko, this message translates to:
  /// **'주변에 진행 중인 순간이 없습니다'**
  String get noMomentsNearby;

  /// No description provided for @walkingMinutes.
  ///
  /// In ko, this message translates to:
  /// **'도보 {minutes}분'**
  String walkingMinutes(int minutes);

  /// No description provided for @partnerBadge.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get partnerBadge;

  /// No description provided for @checkInButton.
  ///
  /// In ko, this message translates to:
  /// **'흔적'**
  String get checkInButton;

  /// No description provided for @alarmSet.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get alarmSet;

  /// No description provided for @alarmSetDone.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정됨'**
  String get alarmSetDone;

  /// No description provided for @navigate.
  ///
  /// In ko, this message translates to:
  /// **'안내'**
  String get navigate;

  /// No description provided for @alarmSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간 설정'**
  String get alarmSheetTitle;

  /// No description provided for @alarmSheetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 종료 몇 분 전에 알림을 받을까요?'**
  String get alarmSheetSubtitle;

  /// No description provided for @alarmConfirm.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get alarmConfirm;

  /// No description provided for @alarmMin10.
  ///
  /// In ko, this message translates to:
  /// **'10분'**
  String get alarmMin10;

  /// No description provided for @alarmBeforeMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전 알림'**
  String alarmBeforeMinutes(int minutes);

  /// No description provided for @alarmBeforeHourMin.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분 전 알림'**
  String alarmBeforeHourMin(int hours, int minutes);

  /// No description provided for @alarmBeforeHour.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전 알림'**
  String alarmBeforeHour(int hours);

  /// No description provided for @alarmPermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 필요합니다. 설정에서 허용해 주세요.'**
  String get alarmPermissionDenied;

  /// No description provided for @timerEnded.
  ///
  /// In ko, this message translates to:
  /// **'종료됨'**
  String get timerEnded;

  /// No description provided for @timerDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 {hours}시간 남음'**
  String timerDaysLeft(int days, int hours);

  /// No description provided for @checkInMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'이 순간을 기록하세요 (선택)'**
  String get checkInMemoHint;

  /// No description provided for @addPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 (선택)'**
  String get addPhoto;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @camera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get gallery;

  /// No description provided for @isFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 입장'**
  String get isFree;

  /// No description provided for @isPaid.
  ///
  /// In ko, this message translates to:
  /// **'유료 입장'**
  String get isPaid;

  /// No description provided for @navigateStop.
  ///
  /// In ko, this message translates to:
  /// **'안내 종료'**
  String get navigateStop;

  /// No description provided for @routeSearching.
  ///
  /// In ko, this message translates to:
  /// **'경로 탐색 중...'**
  String get routeSearching;

  /// No description provided for @routeError.
  ///
  /// In ko, this message translates to:
  /// **'경로를 불러오지 못했습니다. 잠시 후 다시 시도하세요.'**
  String get routeError;

  /// No description provided for @dataError.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했습니다. 잠시 후 다시 시도하세요.'**
  String get dataError;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'재시도'**
  String get retry;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'공연명 또는 장소 검색'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get searchEmpty;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @settingIdentity.
  ///
  /// In ko, this message translates to:
  /// **'본인인증'**
  String get settingIdentity;

  /// No description provided for @settingNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingNotifications;

  /// No description provided for @settingAppInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingAppInfo;

  /// No description provided for @settingLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingLanguage;

  /// No description provided for @languageTitle.
  ///
  /// In ko, this message translates to:
  /// **'언어 선택'**
  String get languageTitle;

  /// No description provided for @langKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get langKo;

  /// No description provided for @langEn.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langJa.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get langJa;

  /// No description provided for @langZh.
  ///
  /// In ko, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @identityVerified.
  ///
  /// In ko, this message translates to:
  /// **'인증 완료'**
  String get identityVerified;

  /// No description provided for @identityNotVerified.
  ///
  /// In ko, this message translates to:
  /// **'미인증'**
  String get identityNotVerified;

  /// No description provided for @identityReset.
  ///
  /// In ko, this message translates to:
  /// **'인증 초기화'**
  String get identityReset;

  /// No description provided for @checkInEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록된 순간이 없습니다'**
  String get checkInEmpty;

  /// No description provided for @checkInDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get checkInDelete;

  /// No description provided for @categoryAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get categoryAll;

  /// No description provided for @categoryMovie.
  ///
  /// In ko, this message translates to:
  /// **'영화'**
  String get categoryMovie;

  /// No description provided for @categoryTheater.
  ///
  /// In ko, this message translates to:
  /// **'연극'**
  String get categoryTheater;

  /// No description provided for @categoryExhibition.
  ///
  /// In ko, this message translates to:
  /// **'전시'**
  String get categoryExhibition;

  /// No description provided for @categoryShow.
  ///
  /// In ko, this message translates to:
  /// **'관람'**
  String get categoryShow;

  /// No description provided for @categoryConcert.
  ///
  /// In ko, this message translates to:
  /// **'공연'**
  String get categoryConcert;

  /// No description provided for @categoryPartner.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get categoryPartner;

  /// No description provided for @adultOnly.
  ///
  /// In ko, this message translates to:
  /// **'19+'**
  String get adultOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
