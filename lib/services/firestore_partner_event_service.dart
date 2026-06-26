import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/alert/models/partner_event.dart';

class FirestorePartnerEventService {
  FirestorePartnerEventService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('partner_events');

  Future<void> save(PartnerEvent event) async {
    final data = event.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(event.id).set(data);
  }

  Future<void> expire(String eventId) async {
    await _col.doc(eventId).update({
      'expiresAtMs': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> extend(String eventId, DateTime newExpiry) async {
    await _col.doc(eventId).update({
      'expiresAtMs': newExpiry.millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PartnerEvent>> watchActive() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return _col
        .where('expiresAtMs', isGreaterThan: nowMs)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PartnerEvent.fromMap(doc.data()))
            .toList());
  }

  Stream<List<PartnerEvent>> watchByPartner(String partnerId) {
    return _col
        .where('partnerId', isEqualTo: partnerId)
        .orderBy('startsAtMs', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PartnerEvent.fromMap(doc.data()))
            .toList());
  }
}

final firestorePartnerEventServiceProvider =
    Provider<FirestorePartnerEventService>(
  (_) => FirestorePartnerEventService(),
);

final activePartnerEventsStreamProvider =
    StreamProvider<List<PartnerEvent>>((ref) {
  return ref
      .watch(firestorePartnerEventServiceProvider)
      .watchActive();
});

final myPartnerEventsStreamProvider =
    StreamProvider<List<PartnerEvent>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestorePartnerEventServiceProvider).watchByPartner(uid);
});
