import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/alert/models/partner_event.dart';

/// 현재 진행중인 파트너 이벤트.
/// 등록 완료 시 설정 → 종료/만료 시 null 로 초기화.
/// null 이면 등록 폼, not-null 이면 대기 패널을 표시.
final activePartnerEventProvider = StateProvider<PartnerEvent?>((ref) => null);
