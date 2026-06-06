// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Z:GUM';

  @override
  String get tabNow => '此刻';

  @override
  String get tabYesterday => '昨天';

  @override
  String get panelTitle => '此刻';

  @override
  String momentCount(int count) {
    return '$count个时刻';
  }

  @override
  String get noMomentsNearby => '附近暂无进行中的时刻';

  @override
  String walkingMinutes(int minutes) {
    return '步行$minutes分钟';
  }

  @override
  String get partnerBadge => '此刻';

  @override
  String get checkInButton => '此刻';

  @override
  String get alarmSet => '设置提醒';

  @override
  String get alarmSetDone => '已设置';

  @override
  String get navigate => '出发';

  @override
  String get alarmSheetTitle => '设置提醒时间';

  @override
  String get alarmSheetSubtitle => '活动结束前多久提醒您？';

  @override
  String get alarmConfirm => '设置提醒';

  @override
  String get alarmMin10 => '10分钟';

  @override
  String alarmBeforeMinutes(int minutes) {
    return '$minutes分钟前提醒';
  }

  @override
  String alarmBeforeHourMin(int hours, int minutes) {
    return '$hours小时$minutes分钟前提醒';
  }

  @override
  String alarmBeforeHour(int hours) {
    return '$hours小时前提醒';
  }

  @override
  String get alarmPermissionDenied => '需要通知权限，请在设置中允许。';

  @override
  String get timerEnded => '已结束';

  @override
  String timerDaysLeft(int days, int hours) {
    return '剩余$days天$hours小时';
  }

  @override
  String get checkInMemoHint => '记录这一刻（选填）';

  @override
  String get addPhoto => '添加照片（选填）';

  @override
  String get cancel => '取消';

  @override
  String get camera => '相机';

  @override
  String get gallery => '相册';

  @override
  String get isFree => '免费入场';

  @override
  String get isPaid => '付费入场';

  @override
  String get navigateStop => '结束导航';

  @override
  String get routeSearching => '正在规划路线...';

  @override
  String get routeError => '无法获取路线，请稍后重试。';

  @override
  String get dataError => '无法加载数据，请稍后重试。';

  @override
  String get retry => '重试';

  @override
  String get searchHint => '搜索活动或场馆';

  @override
  String get searchEmpty => '没有搜索结果';

  @override
  String get settings => '设置';

  @override
  String get settingIdentity => '身份验证';

  @override
  String get settingNotifications => '通知';

  @override
  String get settingAppInfo => '关于';

  @override
  String get settingLanguage => '语言';

  @override
  String get languageTitle => '选择语言';

  @override
  String get langKo => '한국어';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langZh => '中文';

  @override
  String get identityVerified => '已验证';

  @override
  String get identityNotVerified => '未验证';

  @override
  String get identityReset => '重置验证';

  @override
  String get checkInEmpty => '还没有记录的时刻';

  @override
  String get checkInDelete => '删除';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryMovie => '电影';

  @override
  String get categoryTheater => '戏剧';

  @override
  String get categoryExhibition => '展览';

  @override
  String get categoryShow => '演出';

  @override
  String get categoryConcert => '音乐';

  @override
  String get categoryPartner => '此刻';

  @override
  String get adultOnly => '18+';
}
