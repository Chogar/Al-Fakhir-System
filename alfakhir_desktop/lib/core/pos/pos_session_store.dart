import 'package:shared_preferences/shared_preferences.dart';

/// Session de caisse (compteur + filtre historique depuis le dernier décaissement).
final class PosSessionStore {
  PosSessionStore._();

  static const _shiftStartKey = 'pos_shift_started_at';

  static Future<DateTime> shiftStartedAt() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_shiftStartKey);
    if (raw != null && raw.isNotEmpty) {
      final d = DateTime.tryParse(raw);
      if (d != null) return d;
    }
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    await p.setString(_shiftStartKey, dayStart.toIso8601String());
    return dayStart;
  }

  static Future<void> resetShift() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_shiftStartKey, DateTime.now().toIso8601String());
  }

  /// Date/heure ISO pour filtrer l'historique depuis le dernier décaissement.
  static String toApiFrom(DateTime d) => d.toIso8601String();
}
