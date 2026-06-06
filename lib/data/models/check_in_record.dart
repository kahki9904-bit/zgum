import 'cultural_event.dart';

class CheckInRecord {
  final String id;
  final String eventId;
  final String eventTitle;
  final String venue;
  final String categoryLabel;
  final DateTime checkedInAt;
  final String? memo;

  // 현재: 로컬 파일 경로
  // 추후 클라우드 전환 시: CDN URL로 교체 (필드명 유지)
  final String? photoPath;

  const CheckInRecord({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.venue,
    required this.categoryLabel,
    required this.checkedInAt,
    this.memo,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'venue': venue,
        'categoryLabel': categoryLabel,
        'checkedInAt': checkedInAt.toIso8601String(),
        'memo': memo,
        'photoPath': photoPath,
      };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        eventTitle: json['eventTitle'] as String,
        venue: json['venue'] as String,
        categoryLabel: json['categoryLabel'] as String,
        checkedInAt: DateTime.parse(json['checkedInAt'] as String),
        memo: json['memo'] as String?,
        photoPath: json['photoPath'] as String?,
      );

  static CheckInRecord fromEvent({
    required String id,
    required String eventId,
    required String eventTitle,
    required String venue,
    required EventCategory category,
    required DateTime checkedInAt,
    String? memo,
    String? photoPath,
  }) =>
      CheckInRecord(
        id: id,
        eventId: eventId,
        eventTitle: eventTitle,
        venue: venue,
        categoryLabel: category.label,
        checkedInAt: checkedInAt,
        memo: memo,
        photoPath: photoPath,
      );
}
