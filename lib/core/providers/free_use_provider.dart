import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/free_use_status.dart';
import '../services/free_use_service.dart';

class FreeUseNotifier extends StateNotifier<FreeUseStatus> {
  FreeUseNotifier() : super(FreeUseService.instance.status);

  Future<void> activateFreeUse() async {
    await FreeUseService.instance.activateFreeUse();
    state = FreeUseStatus.active;
  }

  void resetState() {
    state = FreeUseStatus.ended;
  }

  Future<void> endByNotificationOff() async {
    await FreeUseService.instance.endByNotificationOff();
    state = FreeUseStatus.ended;
  }
}

final freeUseProvider =
    StateNotifierProvider<FreeUseNotifier, FreeUseStatus>(
  (ref) => FreeUseNotifier(),
);
