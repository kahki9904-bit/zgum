enum FriendDuration {
  oneDay,
  threeMonths,
  sixMonths,
  oneYear;

  Duration get duration => switch (this) {
        FriendDuration.oneDay => const Duration(hours: 24),
        FriendDuration.threeMonths => const Duration(days: 90),
        FriendDuration.sixMonths => const Duration(days: 180),
        FriendDuration.oneYear => const Duration(days: 365),
      };

  String get label => switch (this) {
        FriendDuration.oneDay => '오늘 하루',
        FriendDuration.threeMonths => '3개월',
        FriendDuration.sixMonths => '6개월',
        FriendDuration.oneYear => '1년',
      };

  String get chipLabel => switch (this) {
        FriendDuration.oneDay => '하루',
        FriendDuration.threeMonths => '3개월',
        FriendDuration.sixMonths => '6개월',
        FriendDuration.oneYear => '1년',
      };
}
