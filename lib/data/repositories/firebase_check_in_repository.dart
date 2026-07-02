import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../services/device_id_service.dart';
import '../models/check_in_record.dart';
import 'check_in_repository.dart';
import 'local_check_in_repository.dart';

class FirebaseCheckInRepository implements CheckInRepository {
  FirebaseCheckInRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    LocalCheckInRepository? local,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _local = local ?? LocalCheckInRepository();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LocalCheckInRepository _local;

  CollectionReference<Map<String, dynamic>> _recordsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('check_ins');

  @override
  Future<List<CheckInRecord>> getAll() async {
    try {
      final userId = await _currentUserId();
      final snapshot = await _recordsRef(userId)
          .orderBy('checkedInAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CheckInRecord.fromJson(doc.data()))
            .toList();
      }
      return await _local.getAll();
    } catch (error) {
      debugPrint('Firebase check-in load failed: $error');
      return _local.getAll();
    }
  }

  @override
  Future<void> save(CheckInRecord record) async {
    await _local.save(record);

    try {
      final userId = await _currentUserId();
      final deviceId = await DeviceIdService.getId();

      // Firestore 저장 먼저
      await _recordsRef(userId).doc(record.id).set({
        ...record.toJson(),
        'userId': userId,
        'deviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 사진 업로드는 별도 시도 (실패해도 Firestore 저장엔 영향 없음)
      try {
        final photoUrl = await _uploadPhotoIfNeeded(userId, record);
        if (photoUrl != null) {
          await _recordsRef(userId).doc(record.id).update({'photoPath': photoUrl});
        }
      } catch (_) {}
    } catch (error) {
      debugPrint('Firebase check-in save failed: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);

    try {
      final userId = await _currentUserId();
      await _recordsRef(userId).doc(id).delete();
    } catch (error) {
      debugPrint('Firebase check-in delete failed: $error');
    }
  }

  Future<String> _currentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid ?? await DeviceIdService.getId();
  }

  Future<String?> _uploadPhotoIfNeeded(
    String userId,
    CheckInRecord record,
  ) async {
    final path = record.photoPath;
    if (path == null || path.startsWith('http')) return path;

    final file = File(path);
    if (!await file.exists()) return null;

    final ref = _storage
        .ref()
        .child('check_ins')
        .child(userId)
        .child('${record.id}.jpg');

    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
