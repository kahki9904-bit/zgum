// Firestore 연동 포인트: 컬렉션 'trace_queue/{userId}/pending'
// 전환 시: server_transition_providers.dart 에서 MockTraceSyncQueue → FirebaseTraceSyncQueue 교체
import '../data/models/pending_trace.dart';
import '../data/repositories/trace_repository.dart';
import '../data/repositories/trace_sync_queue.dart';

class FirebaseTraceSyncQueue implements TraceSyncQueue {
  @override
  Future<void> enqueue(PendingTrace trace) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<PendingTrace>> getPending() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<PendingTrace>> getAll() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> markSynced(String clientAttemptId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> markFailed(String clientAttemptId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> updateNonce(
    String clientAttemptId, {
    required String nonce,
    required DateTime expiresAt,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> clearSynced() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> retryAll(TraceRepository traceRepo) =>
      throw UnimplementedError('Firestore 연동 후 구현');
}
