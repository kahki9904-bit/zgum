import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../data/repositories/trace_repository.dart';

class FirebaseTraceRepository implements TraceRepository {
  FirebaseTraceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _rand = Random.secure();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인 필요');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _records =>
      _db.collection('traces').doc(_uid).collection('records');

  @override
  Future<({String nonce, DateTime expiresAt})> requestNonce(String eventId) async {
    final nonce = List.generate(32, (_) => _rand.nextInt(16).toRadixString(16)).join();
    return (nonce: nonce, expiresAt: DateTime.now().add(const Duration(minutes: 10)));
  }

  @override
  Future<TraceEligibility> validateEligibility({
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
  }) async {
    return TraceEligibility.eligible;
  }

  @override
  Future<TraceResult> createTrace({
    required String clientAttemptId,
    required String eventId,
    required LatLng userLocation,
    required DateTime capturedAt,
    required String nonce,
    String? memo,
    String? photoLocalPath,
  }) async {
    await _records.doc(clientAttemptId).set({
      'clientAttemptId': clientAttemptId,
      'eventId': eventId,
      'lat': userLocation.latitude,
      'lng': userLocation.longitude,
      'capturedAt': capturedAt.toIso8601String(),
      'nonce': nonce,
      'memo': memo,
      'photoLocalPath': photoLocalPath,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return TraceResult(status: TraceResultStatus.confirmed, traceId: clientAttemptId);
  }

  @override
  Future<List<Map<String, dynamic>>> getMyTraces() async {
    final snapshot = await _records.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> deleteTrace(String traceId) async {
    await _records.doc(traceId).delete();
  }
}
