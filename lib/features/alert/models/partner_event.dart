import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum PaymentStatus {
  pending,
  paid,
  expired,
}

class PartnerPhoto {
  final String path;
  final String? title;

  const PartnerPhoto({required this.path, this.title});
}

class PartnerEvent extends Equatable {
  final String id;

  /// DeviceId (현재) → Firebase Auth UID (연동 후)
  final String partnerId;

  final String title;
  final String venue;
  final String? message;
  final LatLng location;

  /// Firestore geo 쿼리용 (Firebase 연동 시 geoflutterfire_plus 사용)
  final String geoHash;

  final DateTime startsAt;

  /// 서버 시간 기반 만료 (클라이언트 시계 오차 방지)
  final DateTime expiresAt;

  final bool seen;

  /// 스키마 마이그레이션 안전장치 — 클라이언트가 모르는 버전은 무시
  final int schemaVersion;

  /// 현장 촬영 사진 목록 (최소 1장, 최대 3장)
  final List<PartnerPhoto> photos;

  /// 대표사진 인덱스 (기본값 0 = 첫 번째 사진)
  final int representativeIndex;

  /// 결제 연동 자리 — Firebase 결제 시 이 ID로 주문 조회
  final String? orderId;

  /// 결제 상태 (pending: 등록완료·결제대기 / paid: 결제완료 / expired: 노출종료)
  final PaymentStatus paymentStatus;

  /// 결제 완료 시각 (Firebase 결제 연동 후 채워짐)
  final DateTime? paidAt;

  /// 성인 전용 이벤트 여부
  final bool isAdultOnly;

  const PartnerEvent({
    required this.id,
    required this.partnerId,
    required this.title,
    required this.venue,
    this.message,
    required this.location,
    required this.geoHash,
    required this.startsAt,
    required this.expiresAt,
    this.seen = false,
    this.schemaVersion = 1,
    this.photos = const [],
    this.representativeIndex = 0,
    this.orderId,
    this.paymentStatus = PaymentStatus.pending,
    this.paidAt,
    this.isAdultOnly = false,
  });

  /// 대표사진 경로. photos가 비어 있으면 null.
  String? get representativePhotoPath {
    if (photos.isEmpty) return null;
    final idx = representativeIndex.clamp(0, photos.length - 1);
    return photos[idx].path;
  }

  PartnerEvent copyWith({
    bool? seen,
    List<PartnerPhoto>? photos,
    int? representativeIndex,
    PaymentStatus? paymentStatus,
    DateTime? paidAt,
    DateTime? expiresAt,
    bool? isAdultOnly,
  }) {
    return PartnerEvent(
      id: id,
      partnerId: partnerId,
      title: title,
      venue: venue,
      message: message,
      location: location,
      geoHash: geoHash,
      startsAt: startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      seen: seen ?? this.seen,
      schemaVersion: schemaVersion,
      photos: photos ?? this.photos,
      representativeIndex: representativeIndex ?? this.representativeIndex,
      orderId: orderId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      isAdultOnly: isAdultOnly ?? this.isAdultOnly,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [id];
}
