import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class PhotoSaveService {
  static const _channel = MethodChannel('com.zgum.app/photo_save');
  static final Set<String> _savedKeys = <String>{};
  static final Set<String> _savingKeys = <String>{};

  static Future<PhotoSaveResult> saveImage(String path) async {
    final key = _keyFor(path);
    if (_savedKeys.contains(key) || _savingKeys.contains(key)) {
      return PhotoSaveResult.alreadySaved;
    }
    _savingKeys.add(key);
    final bytes = await _loadBytes(path);
    final fileName = _fileName(path);
    final mimeType = _mimeType(fileName);
    try {
      final ok = await _channel.invokeMethod<bool>('saveImage', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      if (ok != true) {
        throw StateError('photo save failed');
      }
      _savedKeys.add(key);
      return PhotoSaveResult.saved;
    } finally {
      _savingKeys.remove(key);
    }
  }

  static String _keyFor(String path) => path.trim();

  static Future<Uint8List> _loadBytes(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final res = await Dio().get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const []);
    }
    return File(path).readAsBytes();
  }

  static String _fileName(String path) {
    final uri = Uri.tryParse(path);
    final raw = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : path.split(Platform.pathSeparator).last;
    final clean = raw.split('?').first;
    if (clean.trim().isEmpty || !clean.contains('.')) {
      return 'zgum_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return clean;
  }

  static String _mimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

enum PhotoSaveResult {
  saved,
  alreadySaved,
}
