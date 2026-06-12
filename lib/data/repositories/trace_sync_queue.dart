import '../models/pending_trace.dart';
import 'trace_repository.dart';

/// 오프라인 상태의 흔적 시도를 보관하고 재전송하는 대기열.
///
/// TraceRepository는 서버와 대화하는 창구,
/// TraceSyncQueue는 서버 연결이 안 될 때 임시 보관소.
abstract class TraceSyncQueue {
  // 실패한 흔적 시도를 대기열에 추가
  Future<void> enqueue(PendingTrace trace);

  // 전송 대기 중인 목록
  Future<List<PendingTrace>> getPending();

  // 전체 목록 (상태 무관)
  Future<List<PendingTrace>> getAll();

  // 서버 확정 → 대기열에서 제거
  Future<void> markSynced(String clientAttemptId);

  // 재시도 한도 초과 → 실패 처리
  Future<void> markFailed(String clientAttemptId);

  // nonce 만료 → 재발급 후 nonce 갱신
  Future<void> updateNonce(
    String clientAttemptId, {
    required String nonce,
    required DateTime expiresAt,
  });

  // 성공한 항목 일괄 정리
  Future<void> clearSynced();

  // 연결 복구 시 대기 항목 재전송 시도
  Future<void> retryAll(TraceRepository traceRepo);
}
