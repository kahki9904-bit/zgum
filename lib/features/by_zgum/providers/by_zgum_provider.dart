import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/by_zgum_space.dart';

/// by Z:GUM 사업장 목록.
/// Firebase 전환 시 Firestore 'by_zgum_spaces' 컬렉션으로 교체.
final byZGumSpacesProvider = StateProvider<List<ByZGumSpace>>((ref) => []);

/// 현재 사용자 위치에서 가장 가까운 by Z:GUM 사업장.
/// Firebase 연동 후 구현.
final nearestByZGumSpaceProvider = Provider<ByZGumSpace?>((ref) {
  final spaces = ref.watch(byZGumSpacesProvider);
  if (spaces.isEmpty) return null;
  return null; // 위치 기반 정렬 Firebase 연동 후 구현
});
