// DEV/MOCK ONLY ─────────────────────────────────────────────────────────────
// 파트너가 등록하고 mock 결제를 완료한 이벤트를 지도에 즉시 반영하기 위한 임시 저장소.
//
// 운영 전환 시 교체 지점:
//   partner_room_screen.dart  →  Firebase 결제 완료 콜백  →  Firestore 저장
//   map_room_screen.dart      →  Firestore 실시간 구독으로 대체
//   이 파일(provider)은 삭제하고 Repository 구현체로 교체하면 됩니다.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cultural_event.dart';

final mockPartnerEventStoreProvider =
    StateProvider<List<CulturalEvent>>((ref) => const []);
