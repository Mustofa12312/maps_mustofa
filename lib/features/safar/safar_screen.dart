import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/prayer_service.dart';

class SafarScreen extends StatefulWidget {
  const SafarScreen({super.key});

  @override
  State<SafarScreen> createState() => _SafarScreenState();
}

class _SafarScreenState extends State<SafarScreen> {
  Mazhab _mazhab = Mazhab.syafii;
  double _customDistanceKm = 0;
  final _distanceController = TextEditingController();
  SafarStatus? _status;
  PrayerTime? _prayerTime;
  bool _loadingPrayer = false;

  @override
  void initState() {
    super.initState();
    _loadMazhab();
    _loadPrayerTime();
  }

  Future<void> _loadMazhab() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.keyMazhab) ?? 'syafii';
    if (mounted) {
      setState(() {
        _mazhab = Mazhab.values.firstWhere(
          (m) => m.name == name,
          orElse: () => Mazhab.syafii,
        );
      });
    }
  }

  Future<void> _loadPrayerTime() async {
    setState(() => _loadingPrayer = true);
    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();
    if (pos != null) {
      final pt = await PrayerService.getPrayerTimes(lat: pos.latitude, lng: pos.longitude);
      if (mounted) {
        setState(() {
          _prayerTime = pt;
          _loadingPrayer = false;
        });
      }
    } else {
      setState(() => _loadingPrayer = false);
    }
  }

  void _calculate() {
    final km = double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;
    if (km <= 0) return;
    setState(() {
      _customDistanceKm = km;
      _status = SafarService.calculateStatus(distanceKm: km, mazhab: _mazhab);
    });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Kalkulator Safar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003D2E), Color(0xFF00875A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✈️  Apa itu Safar?',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text(
                    'Safar (perjalanan) dalam fiqih Islam memiliki jarak minimum tertentu. '
                    'Jika memenuhi syarat, Anda boleh men-qasar (memendekkan) sholat 4 rakaat menjadi 2 '
                    'dan men-jamak (menggabungkan) dua waktu sholat.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mazhab selector
            Text('Pilih Mazhab', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: Mazhab.values.map((m) {
                final sel = m == _mazhab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() { _mazhab = m; _status = null; });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: m != Mazhab.hanbali ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.borderDark),
                      ),
                      child: Column(
                        children: [
                          Text(m.displayName,
                            style: TextStyle(color: sel ? Colors.white : AppColors.textOnDarkSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          Text('${m.safarDistanceKm.toStringAsFixed(0)} km',
                            style: TextStyle(color: sel ? Colors.white70 : AppColors.textOnDarkSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Mazhab comparison table
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  const Text('Perbandingan Jarak Safar Antar Mazhab',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 12),
                  ...Mazhab.values.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: m == _mazhab ? AppColors.primary : AppColors.borderDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(m.displayName,
                            style: TextStyle(
                              color: m == _mazhab ? AppColors.primary : Colors.white,
                              fontSize: 13, fontWeight: m == _mazhab ? FontWeight.w700 : FontWeight.w400,
                            )),
                        ),
                        Text('≥ ${m.safarDistanceKm.toStringAsFixed(0)} km',
                          style: TextStyle(color: m == _mazhab ? AppColors.primary : AppColors.textOnDarkSecondary, fontSize: 13)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calculator
            Text('Hitung Status Safar', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan jarak (km)',
                      suffixText: 'km',
                      suffixStyle: TextStyle(color: AppColors.textOnDarkSecondary),
                    ),
                    onSubmitted: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hitung'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Result
            if (_status != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status!.isSafar
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _status!.isSafar ? AppColors.primary : AppColors.borderDark,
                    width: _status!.isSafar ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_status!.isSafar ? AppColors.primary : AppColors.textOnDarkSecondary)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _status!.isSafar ? Icons.flight : Icons.home,
                            color: _status!.isSafar ? AppColors.primary : AppColors.textOnDarkSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _status!.isSafar ? 'Anda Memenuhi Syarat Safar' : 'Belum Memenuhi Syarat Safar',
                              style: TextStyle(
                                color: _status!.isSafar ? AppColors.primary : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Jarak: ${_customDistanceKm.toStringAsFixed(1)} km (min. ${_status!.requiredDistanceKm.toStringAsFixed(0)} km)',
                              style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_status!.isSafar) ...[
                      const Divider(color: AppColors.borderDark, height: 24),
                      _buildRulingRow('Qasar', _status!.canQasar, 'Sholat 4 rakaat jadi 2 rakaat'),
                      const SizedBox(height: 8),
                      _buildRulingRow('Jamak', _status!.canJamak, 'Gabung Dzuhur+Ashar atau Maghrib+Isya'),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Prayer times during travel
            if (_prayerTime != null || _loadingPrayer) ...[
              Text('Salat Selama Perjalanan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              if (_loadingPrayer)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: [
                      _buildPrayerRow('Subuh', _prayerTime!.fajr, '🌙'),
                      _buildPrayerRow('Dzuhur', _prayerTime!.dhuhr, '☀️'),
                      _buildPrayerRow('Ashar', _prayerTime!.asr, '🌤️'),
                      _buildPrayerRow('Maghrib', _prayerTime!.maghrib, '🌆'),
                      _buildPrayerRow('Isya', _prayerTime!.isha, '🌃'),
                      if (_status != null && _status!.isSafar)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            '✈️ Sebagai musafir: Anda boleh menjamak Dzuhur+Ashar dan Maghrib+Isya, serta mengqasar 4 rakaat menjadi 2 rakaat.',
                            style: TextStyle(color: AppColors.warning, fontSize: 12, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aplikasi ini memberikan panduan berdasarkan pilihan mazhab. '
                      'Untuk kepastian hukum, konsultasikan dengan ulama setempat.',
                      style: TextStyle(color: AppColors.info, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingRow(String label, bool allowed, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: allowed ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            allowed ? 'Boleh' : 'Tidak',
            style: TextStyle(
              color: allowed ? AppColors.success : AppColors.error,
              fontSize: 12, fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(description, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerRow(String name, String time, String emoji) {
    final next = _prayerTime?.getNextPrayer();
    final isNext = next != null && next[1] == name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: TextStyle(
              color: isNext ? AppColors.primary : Colors.white,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            )),
          ),
          Text(time, style: TextStyle(
            color: isNext ? AppColors.primary : Colors.white70,
            fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}
