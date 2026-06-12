import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../data/repositories/trace_repository.dart';

class MockTraceRepository implements TraceRepository {
  final _rand = Random();

  @override
  Future<({String nonce, DateTime expiresAt})> requestNonce(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final nonce = List.generate(16, (_) => _rand.nextInt(16).toRadixString(16)).join();
    return (nonce: nonce, expiresAt: DateTime.now().add(const Duration(minutes: 10)));
  }

  @override
  Future<TraceEligibility> validateEligibility({
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return TraceEligibility.eligible;
  }

  @override
  Future<TraceResult> createTrace({
    required String clientAttemptId,
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
    required String nonce,
    String? memo,
    String? photoLocalPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final traceId = 'trace_${DateTime.now().millisecondsSinceEpoch}';
    return TraceResult(status: TraceResultStatus.confirmed, traceId: traceId);
  }

  @override
  Future<List<Map<String, dynamic>>> getMyTraces() async => [];

  @override
  Future<void> deleteTrace(String traceId) async {}
}
