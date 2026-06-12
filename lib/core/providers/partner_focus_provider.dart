import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cultural_event.dart';

/// 파트너 이벤트 등록 완료 후 지도에서 해당 이벤트를 포커스하기 위한 요청 저장소.
/// 등록 완료 시 CulturalEvent를 set → 지도가 _focusEvent 호출 후 null로 초기화.
final partnerFocusProvider = StateProvider<CulturalEvent?>((ref) => null);

/// _focusEvent 완료 전까지 ShellScreen의 recenterOnUser 호출을 차단하는 플래그.
final partnerFocusPendingProvider = StateProvider<bool>((ref) => false);
