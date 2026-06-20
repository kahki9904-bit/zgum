import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/check_in_record.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/firebase_check_in_repository.dart';
import '../../../data/repositories/local_check_in_repository.dart';

class CheckInNotifier extends StateNotifier<List<CheckInRecord>> {
  final CheckInRepository _repo;

  CheckInNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> save(CheckInRecord record) async {
    await _repo.save(record);
    state = [record, ...state];
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.where((r) => r.id != id).toList();
  }

  Future<void> cleanupExpired() async {
    final now = DateTime.now();
    final expired = state
        .where((r) => now.difference(r.checkedInAt).inHours >= 24)
        .toList();
    for (final r in expired) {
      await _repo.delete(r.id);
    }
    state =
        state.where((r) => now.difference(r.checkedInAt).inHours < 24).toList();
  }

  Set<String> get checkedInEventIds => state.map((r) => r.eventId).toSet();
}

final checkInRepositoryProvider = Provider<CheckInRepository>(
  (_) => FirebaseCheckInRepository(local: LocalCheckInRepository()),
);

final checkInProvider =
    StateNotifierProvider<CheckInNotifier, List<CheckInRecord>>(
  (ref) => CheckInNotifier(ref.read(checkInRepositoryProvider)),
);
