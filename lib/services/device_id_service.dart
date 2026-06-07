import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _key = 'zgum_device_id';

  static Future<String> getId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;

    final rand = Random();
    final id = 'u${List.generate(8, (_) => rand.nextInt(10)).join()}';
    await prefs.setString(_key, id);
    return id;
  }
}
