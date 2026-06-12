import '../../models/admin/audit_log.dart';

abstract interface class AuditLogRepository {
  Future<List<AuditLog>> fetchRecent({int limit = 100});
  Future<List<AuditLog>> fetchByTarget(String targetId, AuditTargetType targetType);
  Future<List<AuditLog>> fetchByAdmin(String adminId);
  Future<void> write(AuditLog log);
}
