import 'package:latlong2/latlong.dart';

enum TraceEligibility {
  eligible,        // 흔적 남기기 가능
  tooFar,          // 현장에서 너무 멀리 있음
  expired,         // 이벤트 종료 후 시간 초과
  alreadyCheckedIn,// 이미 흔적 존재
  serverError,     // 서버 판단 불가
}

enum TraceResultStatus { confirmed, rejected, pending }

class TraceResult {
  final TraceResultStatus status;
  final String? traceId;       // 서버 확정 시 발급
  final String? rejectReason;

  const TraceResult({required this.status, this.traceId, this.rejectReason});
}

/// 서버와 흔적을 주고받는 창구.
///
/// 현재: [MockTraceRepository]
/// 추후: ApiTraceRepository (REST + 클라우드 스토리지)
abstract class TraceRepository {
  // 서버로부터 1회용 nonce 발급 (흔적 시도 직전 호출)
  Future<({String nonce, DateTime expiresAt})> requestNonce(String eventId);

  // 서버가 흔적 가능 여부 사전 판단
  Future<TraceEligibility> validateEligibility({
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
  });

  // 흔적 생성 요청 (서버가 최종 판단)
  Future<TraceResult> createTrace({
    required String clientAttemptId,
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
    required String nonce,
    String? memo,
    String? photoLocalPath,
  });

  // 내 흔적 목록 조회
  Future<List<Map<String, dynamic>>> getMyTraces();

  // 흔적 삭제
  Future<void> deleteTrace(String traceId);
}
