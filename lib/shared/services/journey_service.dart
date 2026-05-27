import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JourneyRecord {
  final String id;
  final String destinationName;
  final double distanceKm;
  final int durationMinutes;
  final DateTime startTime;
  final bool wasSafar;

  const JourneyRecord({
    required this.id,
    required this.destinationName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.startTime,
    required this.wasSafar,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'destinationName': destinationName,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'startTime': startTime.toIso8601String(),
        'wasSafar': wasSafar,
      };

  factory JourneyRecord.fromJson(Map<String, dynamic> j) => JourneyRecord(
        id: j['id'],
        destinationName: j['destinationName'],
        distanceKm: j['distanceKm'],
        durationMinutes: j['durationMinutes'],
        startTime: DateTime.parse(j['startTime']),
        wasSafar: j['wasSafar'] ?? false,
      );
}

class JourneyService {
  static const String _key = 'journey_history';

  static Future<List<JourneyRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => JourneyRecord.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> saveJourney(JourneyRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.insert(0, jsonEncode(record.toJson()));
    if (existing.length > 50) existing.removeLast();
    await prefs.setStringList(_key, existing);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final history = await getHistory();
    final totalKm = history.fold<double>(0, (sum, r) => sum + r.distanceKm);
    final safarTrips = history.where((r) => r.wasSafar).length;
    return {
      'totalTrips': history.length,
      'totalKm': totalKm,
      'safarTrips': safarTrips,
    };
  }
}
