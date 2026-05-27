import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const String _keyNotifEnabled = 'prayer_notifications_enabled';
  static const String _keyAlarmEnabled = 'adzan_alarm_enabled';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> get notificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifEnabled) ?? true;
  }

  Future<bool> get alarmEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAlarmEnabled) ?? false;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifEnabled, value);
    if (!value) await cancelAllPrayerNotifications();
  }

  Future<void> setAlarmEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlarmEnabled, value);
  }

  /// Show immediate prayer reminder notification
  Future<void> showPrayerReminder({
    required String prayerName,
    required String time,
    required bool isSafar,
  }) async {
    final enabled = await notificationsEnabled;
    if (!enabled) return;

    final body = isSafar
        ? 'Waktu $prayerName pukul $time — Anda sedang safar, boleh qasar & jamak'
        : 'Waktu $prayerName pukul $time — Cari masjid terdekat';

    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Waktu Salat',
      channelDescription: 'Notifikasi pengingat waktu salat',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFF00875A),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      prayerName.hashCode,
      '🕌 $prayerName',
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Show navigation safar alert
  Future<void> showSafarAlert({required String message}) async {
    const androidDetails = AndroidNotificationDetails(
      'safar_channel',
      'Status Safar',
      channelDescription: 'Notifikasi status safar & perjalanan',
      importance: Importance.defaultImportance,
      color: Color(0xFFFFAB00),
    );

    await _plugin.show(
      1001,
      '✈️ Status Safar',
      message,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Schedule prayer notifications for today based on prayer times
  Future<void> schedulePrayerNotifications({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    required bool isSafar,
  }) async {
    final enabled = await notificationsEnabled;
    if (!enabled) return;

    await cancelAllPrayerNotifications();

    final prayers = [
      ('Subuh', fajr, 100),
      ('Dzuhur', dhuhr, 101),
      ('Ashar', asr, 102),
      ('Maghrib', maghrib, 103),
      ('Isya', isha, 104),
    ];

    for (final (name, time, id) in prayers) {
      final scheduledTime = _parseTimeToday(time);
      if (scheduledTime == null) continue;
      if (scheduledTime.isBefore(DateTime.now())) continue;

      // Notify 10 minutes before
      final notifyAt = scheduledTime.subtract(const Duration(minutes: 10));
      if (notifyAt.isAfter(DateTime.now())) {
        await _scheduleAt(
          id: id,
          title: '🕌 $name dalam 10 menit',
          body: isSafar
              ? '$name pukul $time. Anda musafir — boleh qasar & jamak'
              : '$name pukul $time. Segera cari masjid terdekat',
          scheduledTime: notifyAt,
        );
      }
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'prayer_scheduled',
      'Jadwal Salat',
      channelDescription: 'Notifikasi terjadwal waktu salat',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF00875A),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime.toLocal().toUtc() as dynamic,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  DateTime? _parseTimeToday(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelAllPrayerNotifications() async {
    for (final id in [100, 101, 102, 103, 104]) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  // Simple color stub needed in pure Dart context
  // ignore: unused_element
  static int _colorToArgb(int r, int g, int b) => 0xFF000000 | (r << 16) | (g << 8) | b;
}

// Simple Color stub for notification color
class Color {
  final int value;
  const Color(this.value);
}
