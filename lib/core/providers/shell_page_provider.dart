import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/check_in_record.dart';

final shellPageProvider = StateProvider<int>((ref) => 1);

// 흔적 저장 완료 신호 — shell_screen이 패널 자동 열기에 사용
final traceJustCompletedProvider = StateProvider<bool>((ref) => false);

// 패널 임시 보관 흔적 — 남기기/잊기 선택 전까지 그리드에 저장 안 됨
final panelPendingTraceProvider = StateProvider<CheckInRecord?>((ref) => null);
