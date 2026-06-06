import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

// ── 열거형 ───────────────────────────────────────────────────────────────────

enum EventSource {
  public,   // 공공데이터포털
  partner,  // 소상공인·파트너 직접 등록
}

enum EventCategory {
  all('전체'),
  movie('영화'),
  theater('연극'),
  exhibition('전시'),
  show('관람'),
  concert('공연'),
  partner('지금');  // 파트너 한정 이벤트

  const EventCategory(this.label);
  final String label;
}

// ── 이벤트 모델 ───────────────────────────────────────────────────────────────

class CulturalEvent extends Equatable {
  final String id;
  final String title;
  final String venue;
  final String address;
  final String description;
  final String? imageUrl;

  /// 이벤트 시작일 (표시용)
  final DateTime startDate;

  /// 이벤트 실제 종료 일시.
  /// TimeService.shouldShowEvent() 필터링의 기준이 됩니다.
  final DateTime endDateTime;

  final LatLng location;
  final EventCategory category;
  final bool isFree;
  final String? ticketUrl;

  /// 만 19세 이상 전용
  final bool isAdultOnly;

  final EventSource source;

  /// 파트너가 현장에서 남기는 실시간 상태 메시지
  final String? partnerMessage;

  const CulturalEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.address,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDateTime,
    required this.location,
    required this.category,
    required this.isFree,
    this.ticketUrl,
    this.isAdultOnly = false,
    this.source = EventSource.public,
    this.partnerMessage,
  });

  /// 공공데이터포털 JSON 응답 → CulturalEvent.
  factory CulturalEvent.fromJson(Map<String, dynamic> json) {
    final endRaw = json['endDate'] as String? ?? '';
    final endDate = DateTime.tryParse(endRaw) ?? DateTime.now().add(const Duration(days: 30));
    return CulturalEvent(
      id: json['seq']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      venue: json['place'] as String? ?? '',
      address: json['addr1'] as String? ?? '',
      description: json['contents1'] as String? ?? '',
      imageUrl: json['imgUrl'] as String?,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDateTime: endDate.copyWith(hour: 21, minute: 0, second: 0),
      location: LatLng(
        double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
        double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      ),
      category: _parseCategory(json['realmName'] as String?),
      isFree: (json['price'] as String? ?? '').contains('무료'),
      ticketUrl: json['ticketUrl'] as String?,
      source: EventSource.public,
    );
  }

  static EventCategory _parseCategory(String? realm) {
    if (realm == null) return EventCategory.show;
    if (realm.contains('영화')) return EventCategory.movie;
    if (realm.contains('연극') || realm.contains('뮤지컬')) return EventCategory.theater;
    if (realm.contains('전시') || realm.contains('미술')) return EventCategory.exhibition;
    if (realm.contains('음악') || realm.contains('클래식') || realm.contains('국악')) {
      return EventCategory.concert;
    }
    return EventCategory.show;
  }

  @override
  List<Object?> get props => [id];
}
