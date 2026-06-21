// Firestore 연동 포인트: 컬렉션 'traces/{userId}/records'
// 전환 시: server_transition_providers.dart 에서 MockTraceRepository → FirebaseTraceRepository 교체
import 'package:latlong2/latlong.dart';
import '../data/repositories/trace_repository.dart';

class FirebaseTraceRepository implements TraceRepository {
  @override
  Future<({String nonce, DateTime expiresAt})> requestNonce(String eventId) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<TraceEligibility> validateEligibility({
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<TraceResult> createTrace({
    required String clientAttemptId,
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
    required String nonce,
    String? memo,
    String? photoLocalPath,
  }) =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<List<Map<String, dynamic>>> getMyTraces() =>
      throw UnimplementedError('Firestore 연동 후 구현');

  @override
  Future<void> deleteTrace(String traceId) =>
      throw UnimplementedError('Firestore 연동 후 구현');
}
