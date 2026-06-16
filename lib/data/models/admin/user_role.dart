enum UserRole {
  superadmin, // 총괄 — 앱 전체 권한, 이스터에그로 진입
  admin, // 관리자 — 총괄이 지정, 웹에서만 작업
  user, // 일반 사용자
}

extension UserRoleX on UserRole {
  bool get isSuperadmin => this == UserRole.superadmin;
  bool get isAdmin => this == UserRole.admin || this == UserRole.superadmin;

  String get label => switch (this) {
        UserRole.superadmin => '총괄',
        UserRole.admin => '관리자',
        UserRole.user => '일반',
      };

  String toJson() => name;

  static UserRole fromJson(String value) => UserRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRole.user,
      );
}
