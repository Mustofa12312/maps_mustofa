import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/prayer_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/notification_service.dart';
import '../../core/constants/app_constants.dart';
import 'qibla_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  PrayerTime? _prayerTime;
  bool _loading = true;
  PrayerMethod _method = PrayerMethod.kemenag;
  bool _notificationsEnabled = true;
  final NotificationService _notif = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifState();
    _loadPrayerTime();
  }

  Future<void> _loadNotifState() async {
    final enabled = await _notif.notificationsEnabled;
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _loadPrayerTime() async {
    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();

    if (pos != null) {
      final pt = await PrayerService.getPrayerTimes(
        lat: pos.latitude,
        lng: pos.longitude,
        method: _method,
      );
      if (mounted) {
        setState(() {
          _prayerTime = pt;
          _loading = false;
        });
        // Schedule notifications if enabled
        if (pt != null && _notificationsEnabled) {
          await _notif.schedulePrayerNotifications(
            fajr: pt.fajr,
            dhuhr: pt.dhuhr,
            asr: pt.asr,
            maghrib: pt.maghrib,
            isha: pt.isha,
            isSafar: false,
          );
        }
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Waktu Salat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Notification toggle
          GestureDetector(
            onTap: () async {
              final newVal = !_notificationsEnabled;
              await _notif.setNotificationsEnabled(newVal);
              setState(() => _notificationsEnabled = newVal);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newVal
                        ? '🔔 Notifikasi salat aktif'
                        : '🔕 Notifikasi salat dimatikan'),
                    backgroundColor:
                        newVal ? AppColors.success : AppColors.textOnDarkSecondary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              if (newVal && _prayerTime != null) {
                await _notif.schedulePrayerNotifications(
                  fajr: _prayerTime!.fajr,
                  dhuhr: _prayerTime!.dhuhr,
                  asr: _prayerTime!.asr,
                  maghrib: _prayerTime!.maghrib,
                  isha: _prayerTime!.isha,
                  isSafar: false,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _notificationsEnabled
                    ? AppColors.primary
                    : AppColors.textOnDarkSecondary,
              ),
            ),
          ),
          // Method selector
          PopupMenuButton<PrayerMethod>(
            icon: const Icon(Icons.tune),
            color: AppColors.cardDark,
            onSelected: (m) {
              setState(() {
                _method = m;
                _loading = true;
              });
              _loadPrayerTime();
            },
            itemBuilder: (_) => PrayerMethod.values.map((m) {
              return PopupMenuItem(
                value: m,
                child: Row(
                  children: [
                    if (m == _method)
                      const Icon(Icons.check, color: AppColors.primary, size: 16),
                    if (m != _method) const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(m.displayName,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _prayerTime == null
              ? const Center(
                  child: Text('Gagal memuat waktu salat',
                      style: TextStyle(color: Colors.white70)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_prayerTime == null) return const SizedBox();

    final nextPrayer = _prayerTime!.getNextPrayer();
    final timeToNext = _prayerTime!.getTimeToNextPrayer();

    final prayers = [
      _PrayerEntry('Subuh', _prayerTime!.fajr, '🌙', 0),
      _PrayerEntry('Syuruq', _prayerTime!.sunrise, '🌅', 1),
      _PrayerEntry('Dzuhur', _prayerTime!.dhuhr, '☀️', 2),
      _PrayerEntry('Ashar', _prayerTime!.asr, '🌤️', 3),
      _PrayerEntry('Maghrib', _prayerTime!.maghrib, '🌆', 4),
      _PrayerEntry('Isya', _prayerTime!.isha, '🌃', 5),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Notification status banner
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _notificationsEnabled
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _notificationsEnabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _notificationsEnabled
                    ? AppColors.primary
                    : AppColors.textOnDarkSecondary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _notificationsEnabled
                      ? 'Pengingat salat aktif — Anda akan diberitahu setiap waktu salat'
                      : 'Pengingat salat dimatikan — Ketuk 🔕 untuk aktifkan',
                  style: TextStyle(
                    color: _notificationsEnabled
                        ? AppColors.primary
                        : AppColors.textOnDarkSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Next prayer banner
        if (nextPrayer != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00875A), Color(0xFF003D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salat Berikutnya',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPrayer[1],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nextPrayer[2],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
                    if (timeToNext != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${timeToNext.inHours > 0 ? '${timeToNext.inHours}j ' : ''}${timeToNext.inMinutes % 60}m lagi',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                // Quick notification bell for next prayer
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    if (_prayerTime != null) {
                      await _notif.showPrayerReminder(
                        prayerName: nextPrayer[1],
                        time: nextPrayer[2],
                        isSafar: false,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('🔔 Test notifikasi dikirim!')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Test Notifikasi',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Method info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Metode: ${_method.displayName}',
                style: const TextStyle(
                    color: AppColors.textOnDarkSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Qibla Button
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QiblaScreen()),
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: const Row(
              children: [
                Icon(Icons.explore, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cari Arah Kiblat',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.textOnDarkSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Prayer list
        ...prayers.map((p) {
          final isNext = nextPrayer != null && nextPrayer[0] == p.index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNext
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNext ? AppColors.primary : AppColors.borderDark,
                  width: isNext ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      p.name,
                      style: TextStyle(
                        color:
                            isNext ? AppColors.primary : Colors.white,
                        fontSize: 16,
                        fontWeight: isNext
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isNext)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Berikutnya',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    p.time,
                    style: TextStyle(
                      color: isNext ? AppColors.primary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PrayerEntry {
  final String name;
  final String time;
  final String emoji;
  final int index;
  const _PrayerEntry(this.name, this.time, this.emoji, this.index);
}
