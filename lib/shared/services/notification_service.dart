import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const String _keyNotifEnabled = 'prayer_notifications_enabled';
  static const String _keyAlarmEnabled = 'adzan_alarm_enabled';
  static const Color _primaryColor = Color(0xFF00875A);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
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

  AndroidNotificationDetails _buildAndroidDetails(
      String channelId, String channelName,
      {String? desc}) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: desc ?? channelName,
      importance: Importance.high,
      priority: Priority.high,
      color: _primaryColor,
    );
  }

  /// Show immediate prayer reminder notification
  Future<void> showPrayerReminder({
    required String prayerName,
    required String time,
    required bool isSafar,
  }) async {
    if (!await notificationsEnabled) return;

    final body = isSafar
        ? 'Waktu $prayerName pukul $time — Anda musafir, boleh qasar & jamak'
        : 'Waktu $prayerName pukul $time — Segera cari masjid terdekat';

    await _plugin.show(
      prayerName.hashCode & 0x7FFFFFFF,
      '🕌 $prayerName',
      body,
      NotificationDetails(
        android: _buildAndroidDetails(
            'prayer_channel', 'Waktu Salat',
            desc: 'Pengingat waktu salat'),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentSound: true),
      ),
    );
  }

  /// Show safar status alert
  Future<void> showSafarAlert({required String message}) async {
    await _plugin.show(
      1001,
      '✈️ Status Safar',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'safar_channel',
          'Status Safar',
          importance: Importance.defaultImportance,
          color: const Color(0xFFFFAB00),
        ),
      ),
    );
  }

  /// Schedule upcoming prayer notifications for today
  Future<void> schedulePrayerNotifications({
    required String fajr,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    required bool isSafar,
  }) async {
    if (!await notificationsEnabled) return;
    await cancelAllPrayerNotifications();

    final prayers = [
      (100, 'Subuh', fajr),
      (101, 'Dzuhur', dhuhr),
      (102, 'Ashar', asr),
      (103, 'Maghrib', maghrib),
      (104, 'Isya', isha),
    ];

    for (final (id, name, time) in prayers) {
      final scheduled = _parseTimeToday(time);
      if (scheduled == null) continue;
      // Notify at prayer time (not before — simpler for now)
      if (scheduled.isBefore(DateTime.now())) continue;

      final body = isSafar
          ? '$name pukul $time. Anda musafir — boleh qasar & jamak'
          : '$name pukul $time. Segera cari masjid terdekat.';

      // Show as immediate notification at prayer time via alarm-like approach
      // (zonedSchedule needs timezone pkg — using plain show with future check)
      _scheduleWithDelay(
        id: id,
        title: '🕌 Waktu $name',
        body: body,
        at: scheduled,
      );
    }
  }

  void _scheduleWithDelay({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) {
    final delay = at.difference(DateTime.now());
    if (delay.isNegative) return;
    Future.delayed(delay, () async {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: _buildAndroidDetails(
              'prayer_scheduled', 'Jadwal Salat',
              desc: 'Notifikasi terjadwal waktu salat'),
          iOS: const DarwinNotificationDetails(
              presentAlert: true, presentSound: true),
        ),
      );
    });
  }

  DateTime? _parseTimeToday(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;
      final now = DateTime.now();
      return DateTime(
          now.year, now.month, now.day,
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

  Future<void> cancelAll() async => _plugin.cancelAll();
}
