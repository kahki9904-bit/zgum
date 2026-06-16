// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Z:GUM';

  @override
  String get tabNow => 'NOW';

  @override
  String get tabYesterday => 'Yesterday';

  @override
  String get panelTitle => 'NOW';

  @override
  String momentCount(int count) {
    return '$count moments';
  }

  @override
  String get noMomentsNearby => 'No moments nearby right now';

  @override
  String walkingMinutes(int minutes) {
    return '$minutes min walk';
  }

  @override
  String get partnerBadge => 'NOW';

  @override
  String get checkInButton => 'NOW';

  @override
  String get navigate => 'Go';

  @override
  String get timerEnded => 'Ended';

  @override
  String timerDaysLeft(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String get checkInMemoHint => 'Capture this moment (optional)';

  @override
  String get addPhoto => 'Add photo (optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get isFree => 'Free entry';

  @override
  String get isPaid => 'Paid entry';

  @override
  String get navigateStop => 'Stop';

  @override
  String get routeSearching => 'Finding route...';

  @override
  String get routeError => 'Could not load route. Please try again.';

  @override
  String get dataError => 'Could not load data. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get searchHint => 'Search events or venues';

  @override
  String get searchEmpty => 'No results found';

  @override
  String get settings => 'Settings';

  @override
  String get settingIdentity => 'Identity Verification';

  @override
  String get settingNotifications => 'Notifications';

  @override
  String get settingAppInfo => 'About';

  @override
  String get settingLanguage => 'Language';

  @override
  String get languageTitle => 'Select Language';

  @override
  String get langKo => '한국어';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langZh => '中文';

  @override
  String get identityVerified => 'Verified';

  @override
  String get identityNotVerified => 'Not verified';

  @override
  String get identityReset => 'Reset verification';

  @override
  String get checkInEmpty => 'No moments recorded yet';

  @override
  String get checkInDelete => 'Delete';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryMovie => 'Film';

  @override
  String get categoryTheater => 'Theater';

  @override
  String get categoryExhibition => 'Exhibition';

  @override
  String get categoryShow => 'Show';

  @override
  String get categoryConcert => 'Concert';

  @override
  String get categoryPartner => 'NOW';

  @override
  String get adultOnly => '19+';
}
