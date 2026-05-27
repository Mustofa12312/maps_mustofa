import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/prayer_service.dart';
import '../../shared/services/location_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPrayerTime();
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
      if (mounted) setState(() {
        _prayerTime = pt;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
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
                child: Text(m.displayName,
                    style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                Text(
                  'Salat Berikutnya',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPrayer[1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (timeToNext != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${timeToNext.inHours}j ${timeToNext.inMinutes % 60}m lagi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
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
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Qibla Button
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QiblaScreen()),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.explore, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cari Arah Kiblat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textOnDarkSecondary),
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
                    ? AppColors.primary.withOpacity(0.1)
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
                        color: isNext ? AppColors.primary : Colors.white,
                        fontSize: 16,
                        fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isNext)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
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
