enum AccountStatusFlag {
  active,             // 활성
  suspended,          // 정지 — 관리자 조치
  withdrawalPending,  // 탈퇴 처리중 — 데이터 보존 기간 경과 후 삭제
}

extension AccountStatusFlagX on AccountStatusFlag {
  bool get isAccessAllowed => this == AccountStatusFlag.active;

  String get label => switch (this) {
        AccountStatusFlag.active => '활성',
        AccountStatusFlag.suspended => '정지',
        AccountStatusFlag.withdrawalPending => '탈퇴 처리중',
      };

  String toJson() => name;

  static AccountStatusFlag fromJson(String value) =>
      AccountStatusFlag.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AccountStatusFlag.suspended,
      );
}
