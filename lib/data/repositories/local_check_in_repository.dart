import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_in_record.dart';
import 'check_in_repository.dart';

class LocalCheckInRepository implements CheckInRepository {
  static const _key = 'zgum_check_in_records';

  @override
  Future<List<CheckInRecord>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => CheckInRecord.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));
  }

  @override
  Future<void> save(CheckInRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, raw);
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return json['id'] == id;
    });
    await prefs.setStringList(_key, raw);
  }
}
