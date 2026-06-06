import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cultural_event.dart';

class MapFilterState {
  final int walkingMinutes;
  final String searchQuery;

  const MapFilterState({
    this.walkingMinutes = 30,
    this.searchQuery = '',
  });

  bool passes(CulturalEvent event) {
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      if (!event.title.toLowerCase().contains(q) &&
          !event.venue.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }

  MapFilterState copyWith({
    int? walkingMinutes,
    String? searchQuery,
  }) =>
      MapFilterState(
        walkingMinutes: walkingMinutes ?? this.walkingMinutes,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());

  void clearAll() => state = const MapFilterState();

  void setWalkingMinutes(int minutes) =>
      state = state.copyWith(walkingMinutes: minutes);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);
}

final mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilterState>(
  (ref) => MapFilterNotifier(),
);
