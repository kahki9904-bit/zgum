import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/pending_trace.dart';
import '../data/repositories/trace_repository.dart';
import '../data/repositories/trace_sync_queue.dart';

class FirebaseTraceSyncQueue implements TraceSyncQueue {
  static const _key = 'zgum_pending_traces';
  static const int _maxRetry = 5;

  Future<List<PendingTrace>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return PendingTrace.listFromJson(raw);
  }

  Future<void> _save(List<PendingTrace> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PendingTrace.listToJson(list));
  }

  @override
  Future<void> enqueue(PendingTrace trace) async {
    final list = await _load();
    final exists = list.any((e) => e.clientAttemptId == trace.clientAttemptId);
    if (!exists) {
      list.add(trace);
      await _save(list);
    }
  }

  @override
  Future<List<PendingTrace>> getPending() async {
    final list = await _load();
    return list
        .where((e) =>
            e.status == PendingTraceStatus.pending ||
            e.status == PendingTraceStatus.nonceExpired)
        .toList();
  }

  @override
  Future<List<PendingTrace>> getAll() => _load();

  @override
  Future<void> markSynced(String clientAttemptId) async {
    final list = await _load();
    final idx = list.indexWhere((e) => e.clientAttemptId == clientAttemptId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(status: PendingTraceStatus.synced);
    await _save(list);
  }

  @override
  Future<void> markFailed(String clientAttemptId) async {
    final list = await _load();
    final idx = list.indexWhere((e) => e.clientAttemptId == clientAttemptId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(status: PendingTraceStatus.failed);
    await _save(list);
  }

  @override
  Future<void> updateNonce(
    String clientAttemptId, {
    required String nonce,
    required DateTime expiresAt,
  }) async {
    final list = await _load();
    final idx = list.indexWhere((e) => e.clientAttemptId == clientAttemptId);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      nonce: nonce,
      nonceExpiresAt: expiresAt,
      status: PendingTraceStatus.pending,
    );
    await _save(list);
  }

  @override
  Future<void> clearSynced() async {
    final list = await _load();
    await _save(list.where((e) => e.status != PendingTraceStatus.synced).toList());
  }

  @override
  Future<void> retryAll(TraceRepository traceRepo) async {
    final pending = await getPending();
    for (final trace in pending) {
      if (trace.retryCount >= _maxRetry) {
        await markFailed(trace.clientAttemptId);
        continue;
      }

      String nonce = trace.nonce ?? '';
      DateTime? nonceExp = trace.nonceExpiresAt;

      if (!trace.isNonceValid) {
        try {
          final fresh = await traceRepo.requestNonce(trace.eventId);
          nonce = fresh.nonce;
          nonceExp = fresh.expiresAt;
          await updateNonce(trace.clientAttemptId, nonce: nonce, expiresAt: nonceExp);
        } catch (_) {
          continue;
        }
      }

      try {
        final result = await traceRepo.createTrace(
          clientAttemptId: trace.clientAttemptId,
          eventId: trace.eventId,
          userLocation: trace.capturedLocation,
          capturedAt: trace.capturedAt,
          nonce: nonce,
          memo: trace.memo,
          photoLocalPath: trace.photoLocalPath,
        );
        if (result.status == TraceResultStatus.confirmed) {
          await markSynced(trace.clientAttemptId);
        } else {
          final list = await _load();
          final idx = list.indexWhere((e) => e.clientAttemptId == trace.clientAttemptId);
          if (idx >= 0) {
            list[idx] = list[idx].copyWith(
              retryCount: trace.retryCount + 1,
              lastTriedAt: DateTime.now(),
            );
            await _save(list);
          }
        }
      } catch (_) {
        final list = await _load();
        final idx = list.indexWhere((e) => e.clientAttemptId == trace.clientAttemptId);
        if (idx >= 0) {
          list[idx] = list[idx].copyWith(
            retryCount: trace.retryCount + 1,
            lastTriedAt: DateTime.now(),
          );
          await _save(list);
        }
      }
    }
  }
}
