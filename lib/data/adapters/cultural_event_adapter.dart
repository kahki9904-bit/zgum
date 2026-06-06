import '../models/cultural_event.dart';
import '../models/map_marker_model.dart';

/// CulturalEvent → MapMarkerModel 변환 어댑터.
///
/// 지도 엔진은 CulturalEvent 를 직접 알 필요 없이
/// MapMarkerModel 만으로 마커를 렌더링합니다.
abstract final class CulturalEventAdapter {
  static MapMarkerModel toMarker(CulturalEvent event) {
    return MapMarkerModel(
      id: event.id,
      location: MapCoordinate(
        event.location.latitude,
        event.location.longitude,
      ),
      category: _toMarkerCategory(event.category),
      deadline: event.endDateTime,
      isAdultOnly: event.isAdultOnly,
      title: event.title,
      venue: event.venue,
      isPartner: event.source == EventSource.partner,
      payload: event,
    );
  }

  static List<MapMarkerModel> toMarkers(List<CulturalEvent> events) =>
      events.map(toMarker).toList();

  static MarkerCategory _toMarkerCategory(EventCategory category) {
    return switch (category) {
      EventCategory.movie => MarkerCategory.movie,
      EventCategory.theater => MarkerCategory.theater,
      EventCategory.exhibition => MarkerCategory.exhibition,
      EventCategory.show => MarkerCategory.show,
      EventCategory.concert => MarkerCategory.concert,
      EventCategory.partner => MarkerCategory.sale,
      EventCategory.all => MarkerCategory.other,
    };
  }
}
