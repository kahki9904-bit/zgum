import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin/user_role.dart';

// 기존 테스트용 — Firebase 연동 전까지 유지
final adminModeProvider = StateProvider<bool>((ref) => true);

// Firebase 연동 시: 서버에서 역할 조회 후 설정
// 이스터에그 진입 → 비밀번호 → 서버 확인 → superadmin 설정
final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.user);

// 총괄이 특정 관리자에게 웹 접근 권한을 열어준 상태
// Firebase 연동 시: Firestore webAdminAccess 필드로 교체
final webAdminAccessProvider = StateProvider<bool>((ref) => false);
