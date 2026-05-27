import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

class PrayerTime {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final DateTime date;

  const PrayerTime({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  static const List<String> prayerNames = [
    'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha',
  ];
  static const List<String> prayerNamesId = [
    'Subuh', 'Syuruq', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya',
  ];

  List<String> get allTimes => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  /// Returns [index, name, time] of the next prayer
  List<dynamic>? getNextPrayer() {
    final now = DateTime.now();
    final times = allTimes;
    for (int i = 0; i < times.length; i++) {
      final t = _parseTime(times[i]);
      if (t != null && t.isAfter(now)) {
        return [i, prayerNamesId[i], times[i]];
      }
    }
    return null; // all prayers done for today
  }

  Duration? getTimeToNextPrayer() {
    final next = getNextPrayer();
    if (next == null) return null;
    final t = _parseTime(next[2]);
    if (t == null) return null;
    return t.difference(DateTime.now());
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  factory PrayerTime.fromApi(Map<String, dynamic> data) {
    final timings = data['timings'] as Map<String, dynamic>;
    final dateData = data['date'] as Map<String, dynamic>;
    final gregorian = dateData['gregorian'] as Map<String, dynamic>;
    final dateParts = gregorian['date']?.toString().split('-') ?? [];

    return PrayerTime(
      fajr: _cleanTime(timings['Fajr']),
      sunrise: _cleanTime(timings['Sunrise']),
      dhuhr: _cleanTime(timings['Dhuhr']),
      asr: _cleanTime(timings['Asr']),
      maghrib: _cleanTime(timings['Maghrib']),
      isha: _cleanTime(timings['Isha']),
      date: dateParts.length == 3
          ? DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]))
          : DateTime.now(),
    );
  }

  static String _cleanTime(dynamic t) {
    return t?.toString().replaceAll(RegExp(r'\s+.*$'), '') ?? '00:00';
  }
}

class PrayerService {
  static Future<PrayerTime?> getPrayerTimes({
    required double lat,
    required double lng,
    PrayerMethod method = PrayerMethod.kemenag,
    DateTime? date,
  }) async {
    try {
      final d = date ?? DateTime.now();
      final dateStr = DateFormat('dd-MM-yyyy').format(d);
      final url = Uri.parse(
        '${AppConstants.aladhanBaseUrl}/timings/$dateStr'
        '?latitude=$lat&longitude=$lng&method=${method.methodId}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['code'] == 200) {
          return PrayerTime.fromApi(body['data']);
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}

class SafarService {
  static bool isSafar({
    required double distanceKm,
    required Mazhab mazhab,
  }) {
    return distanceKm >= mazhab.safarDistanceKm;
  }

  static bool canQasar({
    required double distanceKm,
    required Mazhab mazhab,
  }) {
    return isSafar(distanceKm: distanceKm, mazhab: mazhab);
  }

  static bool canJamak({
    required double distanceKm,
    required Mazhab mazhab,
  }) {
    return isSafar(distanceKm: distanceKm, mazhab: mazhab);
  }

  static SafarStatus calculateStatus({
    required double distanceKm,
    required Mazhab mazhab,
  }) {
    final safar = isSafar(distanceKm: distanceKm, mazhab: mazhab);
    return SafarStatus(
      distanceKm: distanceKm,
      isSafar: safar,
      mazhab: mazhab.displayName,
      requiredDistanceKm: mazhab.safarDistanceKm,
      canQasar: safar,
      canJamak: safar,
    );
  }
}
