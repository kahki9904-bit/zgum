// Firestore 연동 포인트: 컬렉션 'audit_logs'
// 전환 시: server_transition_providers.dart 에서 MockAuditLogRepository → FirebaseAuditLogRepository 교체
import '../data/models/admin/audit_log.dart';
import '../data/repositories/admin/audit_log_repository.dart';

class FirebaseAuditLogRepository implements AuditLogRepository {
  @override
  Future<List<AuditLog>> fetchRecent({int limit = 100}) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<AuditLog>> fetchByTarget(
          String targetId, AuditTargetType targetType) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<AuditLog>> fetchByAdmin(String adminId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> write(AuditLog log) =>
      throw UnimplementedError('Firestore 연동 후 구현');
}
