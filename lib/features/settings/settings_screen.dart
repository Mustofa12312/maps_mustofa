import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Mazhab _mazhab = Mazhab.syafii;
  VehicleType _vehicle = VehicleType.motor;
  PrayerMethod _prayerMethod = PrayerMethod.kemenag;
  bool _voiceEnabled = true;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mazhabName = prefs.getString(AppConstants.keyMazhab) ?? 'syafii';
    final vehicleName = prefs.getString(AppConstants.keyVehicleType) ?? 'motor';
    final prayerMethodId = prefs.getInt(AppConstants.keyPrayerMethod) ?? 20;
    setState(() {
      _mazhab = Mazhab.values.firstWhere(
        (m) => m.name == mazhabName,
        orElse: () => Mazhab.syafii,
      );
      _vehicle = VehicleType.values.firstWhere(
        (v) => v.name == vehicleName,
        orElse: () => VehicleType.motor,
      );
      _prayerMethod = PrayerMethod.values.firstWhere(
        (p) => p.methodId == prayerMethodId,
        orElse: () => PrayerMethod.kemenag,
      );
      _voiceEnabled = prefs.getBool(AppConstants.keyVoiceEnabled) ?? true;
      _darkMode = prefs.getBool(AppConstants.keyThemeMode) ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMazhab, _mazhab.name);
    await prefs.setString(AppConstants.keyVehicleType, _vehicle.name);
    await prefs.setInt(AppConstants.keyPrayerMethod, _prayerMethod.methodId);
    await prefs.setBool(AppConstants.keyVoiceEnabled, _voiceEnabled);
    await prefs.setBool(AppConstants.keyThemeMode, _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('🕌 Fitur Islam', [
            _buildDropdownTile<Mazhab>(
              icon: Icons.book,
              title: 'Mazhab',
              subtitle: 'Menentukan jarak safar',
              value: _mazhab,
              items: Mazhab.values,
              displayName: (m) => m.displayName,
              onChanged: (v) {
                setState(() => _mazhab = v!);
                _save();
              },
            ),
            _buildDropdownTile<PrayerMethod>(
              icon: Icons.access_time,
              title: 'Metode Waktu Salat',
              subtitle: 'Perhitungan jadwal salat',
              value: _prayerMethod,
              items: PrayerMethod.values,
              displayName: (m) => m.displayName,
              onChanged: (v) {
                setState(() => _prayerMethod = v!);
                _save();
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('🚗 Navigasi', [
            _buildDropdownTile<VehicleType>(
              icon: Icons.directions_car,
              title: 'Jenis Kendaraan',
              subtitle: 'Mempengaruhi rute yang dihitung',
              value: _vehicle,
              items: VehicleType.values,
              displayName: (v) => v.displayName,
              onChanged: (v) {
                setState(() => _vehicle = v!);
                _save();
              },
            ),
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: 'Suara Navigasi',
              subtitle: 'Instruksi belok dengan suara',
              value: _voiceEnabled,
              onChanged: (v) {
                setState(() => _voiceEnabled = v);
                _save();
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('🎨 Tampilan', [
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Mode Gelap',
              subtitle: 'Hemat baterai dan nyaman di malam hari',
              value: _darkMode,
              onChanged: (v) {
                setState(() => _darkMode = v);
                _save();
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('ℹ️ Tentang', [
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'Safar Maps',
              subtitle: 'Versi ${AppConstants.appVersion}',
            ),
            _buildInfoTile(
              icon: Icons.map,
              title: 'Peta',
              subtitle: '© OpenStreetMap contributors (CartoDB)',
            ),
            _buildInfoTile(
              icon: Icons.route,
              title: 'Routing',
              subtitle: 'OSRM — Open Source Routing Machine',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required String Function(T) displayName,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textOnDarkSecondary, fontSize: 12)),
              ],
            ),
          ),
          DropdownButton<T>(
            value: value,
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(displayName(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textOnDarkSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textOnDarkSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textOnDarkSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
