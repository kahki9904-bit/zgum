import '../models/space_model.dart';
import '../models/map_marker_model.dart';

/// SpaceModel → MapMarkerModel 변환 어댑터.
///
/// SpaceModel 은 isRealtime(targetTime != null) 인 경우에만
/// 지도 마커로 표시합니다.
abstract final class SpaceModelAdapter {
  static MapMarkerModel toMarker(SpaceModel space) {
    return MapMarkerModel(
      id: space.id,
      location: MapCoordinate(space.lat, space.lng),
      category: _toMarkerCategory(space.category),
      deadline: space.targetTime,
      isAdultOnly: false,
      title: space.title,
      venue: null,
      isPartner: space.ownerId != 'system',
      payload: space,
    );
  }

  /// isRealtime 인 항목만 변환합니다.
  static List<MapMarkerModel> toMarkers(List<SpaceModel> spaces) =>
      spaces.where((s) => s.isRealtime).map(toMarker).toList();

  static MarkerCategory _toMarkerCategory(String category) {
    return switch (category) {
      SpaceCategories.movie => MarkerCategory.movie,
      SpaceCategories.culture => MarkerCategory.theater,
      SpaceCategories.food => MarkerCategory.other,
      SpaceCategories.cafe => MarkerCategory.other,
      SpaceCategories.shopping => MarkerCategory.sale,
      SpaceCategories.sport => MarkerCategory.show,
      SpaceCategories.partner => MarkerCategory.partner,
      _ => MarkerCategory.other,
    };
  }
}
