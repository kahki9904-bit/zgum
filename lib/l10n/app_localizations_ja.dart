// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Z:GUM';

  @override
  String get tabNow => 'いま';

  @override
  String get tabYesterday => 'きのう';

  @override
  String get panelTitle => 'いま';

  @override
  String momentCount(int count) {
    return '$countの瞬間';
  }

  @override
  String get noMomentsNearby => '近くに進行中の瞬間はありません';

  @override
  String walkingMinutes(int minutes) {
    return '徒歩$minutes分';
  }

  @override
  String get partnerBadge => 'いま';

  @override
  String get checkInButton => 'いま';

  @override
  String get navigate => '案内';

  @override
  String get timerEnded => '終了';

  @override
  String timerDaysLeft(int days, int hours) {
    return 'あと$days日$hours時間';
  }

  @override
  String get checkInMemoHint => 'この瞬間を残す（任意）';

  @override
  String get addPhoto => '写真を追加（任意）';

  @override
  String get cancel => 'キャンセル';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get isFree => '入場無料';

  @override
  String get isPaid => '有料入場';

  @override
  String get navigateStop => '案内終了';

  @override
  String get routeSearching => 'ルート検索中...';

  @override
  String get routeError => 'ルートを取得できません。後でもう一度お試しください。';

  @override
  String get dataError => 'データを取得できません。後でもう一度お試しください。';

  @override
  String get retry => '再試行';

  @override
  String get searchHint => '公演名または場所を検索';

  @override
  String get searchEmpty => '検索結果がありません';

  @override
  String get settings => '設定';

  @override
  String get settingIdentity => '本人確認';

  @override
  String get settingNotifications => '通知';

  @override
  String get settingAppInfo => 'アプリ情報';

  @override
  String get settingLanguage => '言語';

  @override
  String get languageTitle => '言語を選択';

  @override
  String get langKo => '한국어';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langZh => '中文';

  @override
  String get identityVerified => '認証済み';

  @override
  String get identityNotVerified => '未認証';

  @override
  String get identityReset => '認証をリセット';

  @override
  String get checkInEmpty => 'まだ記録された瞬間はありません';

  @override
  String get checkInDelete => '削除';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categoryMovie => '映画';

  @override
  String get categoryTheater => '演劇';

  @override
  String get categoryExhibition => '展示';

  @override
  String get categoryShow => '観覧';

  @override
  String get categoryConcert => 'コンサート';

  @override
  String get categoryPartner => 'いま';

  @override
  String get adultOnly => '18+';
}
