import '../data/models/admin/audit_log.dart';
import '../data/repositories/admin/audit_log_repository.dart';

class MockAuditLogRepository implements AuditLogRepository {
  final List<AuditLog> _logs = [];

  @override
  Future<List<AuditLog>> fetchRecent({int limit = 100}) async =>
      _logs.reversed.take(limit).toList();

  @override
  Future<List<AuditLog>> fetchByTarget(
      String targetId, AuditTargetType targetType) async =>
      _logs
          .where((l) => l.targetId == targetId && l.targetType == targetType)
          .toList();

  @override
  Future<List<AuditLog>> fetchByAdmin(String adminId) async =>
      _logs.where((l) => l.adminId == adminId).toList();

  @override
  Future<void> write(AuditLog log) async => _logs.add(log);
}
