import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum PendingTraceStatus {
  pending,      // 네트워크 대기 중
  uploading,    // 전송 시도 중
  nonceExpired, // nonce 만료 → 재발급 필요
  failed,       // 재시도 한도 초과
  synced,       // 서버 확정 → 삭제 가능
}

class PendingTrace {
  static const int currentSchemaVersion = 1;

  final String clientAttemptId;
  final String eventId;
  final DateTime capturedAt;
  final LatLng capturedLocation;
  final String? photoLocalPath;
  final String? uploadedPhotoUrl;
  final String? memo;
  final String? nonce;
  final DateTime? nonceExpiresAt;
  final int retryCount;
  final DateTime? lastTriedAt;
  final PendingTraceStatus status;
  final int schemaVersion;

  const PendingTrace({
    required this.clientAttemptId,
    required this.eventId,
    required this.capturedAt,
    required this.capturedLocation,
    this.photoLocalPath,
    this.uploadedPhotoUrl,
    this.memo,
    this.nonce,
    this.nonceExpiresAt,
    this.retryCount = 0,
    this.lastTriedAt,
    this.status = PendingTraceStatus.pending,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isNonceValid =>
      nonce != null &&
      nonceExpiresAt != null &&
      nonceExpiresAt!.isAfter(DateTime.now());

  PendingTrace copyWith({
    String? nonce,
    DateTime? nonceExpiresAt,
    int? retryCount,
    DateTime? lastTriedAt,
    PendingTraceStatus? status,
    String? uploadedPhotoUrl,
  }) =>
      PendingTrace(
        clientAttemptId: clientAttemptId,
        eventId: eventId,
        capturedAt: capturedAt,
        capturedLocation: capturedLocation,
        photoLocalPath: photoLocalPath,
        uploadedPhotoUrl: uploadedPhotoUrl ?? this.uploadedPhotoUrl,
        memo: memo,
        nonce: nonce ?? this.nonce,
        nonceExpiresAt: nonceExpiresAt ?? this.nonceExpiresAt,
        retryCount: retryCount ?? this.retryCount,
        lastTriedAt: lastTriedAt ?? this.lastTriedAt,
        status: status ?? this.status,
        schemaVersion: schemaVersion,
      );

  Map<String, dynamic> toJson() => {
        'clientAttemptId': clientAttemptId,
        'eventId': eventId,
        'capturedAt': capturedAt.toIso8601String(),
        'lat': capturedLocation.latitude,
        'lng': capturedLocation.longitude,
        'photoLocalPath': photoLocalPath,
        'uploadedPhotoUrl': uploadedPhotoUrl,
        'memo': memo,
        'nonce': nonce,
        'nonceExpiresAt': nonceExpiresAt?.toIso8601String(),
        'retryCount': retryCount,
        'lastTriedAt': lastTriedAt?.toIso8601String(),
        'status': status.name,
        'schemaVersion': schemaVersion,
      };

  factory PendingTrace.fromJson(Map<String, dynamic> json) => PendingTrace(
        clientAttemptId: json['clientAttemptId'] as String,
        eventId: json['eventId'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        capturedLocation: LatLng(json['lat'] as double, json['lng'] as double),
        photoLocalPath: json['photoLocalPath'] as String?,
        uploadedPhotoUrl: json['uploadedPhotoUrl'] as String?,
        memo: json['memo'] as String?,
        nonce: json['nonce'] as String?,
        nonceExpiresAt: json['nonceExpiresAt'] == null
            ? null
            : DateTime.parse(json['nonceExpiresAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        lastTriedAt: json['lastTriedAt'] == null
            ? null
            : DateTime.parse(json['lastTriedAt'] as String),
        status: PendingTraceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PendingTraceStatus.pending,
        ),
        schemaVersion: json['schemaVersion'] as int? ?? 1,
      );

  static List<PendingTrace> listFromJson(String raw) =>
      (jsonDecode(raw) as List).map((e) => PendingTrace.fromJson(e as Map<String, dynamic>)).toList();

  static String listToJson(List<PendingTrace> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());
}
