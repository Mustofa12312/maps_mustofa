import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/favorites_service.dart';
import '../../shared/services/journey_service.dart';
import '../../shared/models/models.dart';
import '../navigation/route_preview_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JourneyRecord> _history = [];
  List<LocationModel> _favorites = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await JourneyService.getHistory();
    final favorites = await FavoritesService.getFavorites();
    final stats = await JourneyService.getStats();
    if (mounted) {
      setState(() {
        _history = history;
        _favorites = favorites;
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Profil & Riwayat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textOnDarkSecondary,
          tabs: const [
            Tab(text: 'Riwayat Perjalanan'),
            Tab(text: 'Favorit'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Stats header
                _buildStatsHeader(),
                // Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(),
                      _buildFavoritesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    final totalTrips = _stats['totalTrips'] ?? 0;
    final totalKm = (_stats['totalKm'] ?? 0.0) as double;
    final safarTrips = _stats['safarTrips'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          _buildStat('$totalTrips', 'Perjalanan', Icons.route, AppColors.primary),
          _buildStat('${totalKm.toStringAsFixed(0)} km', 'Total Jarak', Icons.map_outlined, AppColors.accent),
          _buildStat('$safarTrips', 'Safar', Icons.flight, AppColors.warning),
          _buildStat('${_favorites.length}', 'Favorit', Icons.favorite, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Belum ada riwayat perjalanan',
              style: TextStyle(color: Colors.white60, fontSize: 15)),
            SizedBox(height: 8),
            Text('Mulai navigasi untuk merekam perjalanan Anda',
              style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final record = _history[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: (record.wasSafar ? AppColors.warning : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  record.wasSafar ? Icons.flight : Icons.directions_car,
                  color: record.wasSafar ? AppColors.warning : AppColors.primary, size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.destinationName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniChip('${record.distanceKm.toStringAsFixed(1)} km', AppColors.primary),
                        const SizedBox(width: 6),
                        _buildMiniChip('${record.durationMinutes}m', AppColors.accent),
                        if (record.wasSafar) ...[
                          const SizedBox(width: 6),
                          _buildMiniChip('Musafir', AppColors.warning),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('d MMM', 'id').format(record.startTime),
                style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('❤️', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Belum ada lokasi favorit',
              style: TextStyle(color: Colors.white60, fontSize: 15)),
            SizedBox(height: 8),
            Text('Saat preview rute, tekan ❤️ untuk menyimpan lokasi',
              style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (_, i) {
        final loc = _favorites[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite, color: AppColors.error, size: 22),
            ),
            title: Text(loc.name ?? 'Lokasi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: loc.address != null
                ? Text(loc.address!, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.navigation, color: AppColors.primary, size: 22),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RoutePreviewScreen(destination: loc)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textOnDarkSecondary, size: 20),
                  onPressed: () async {
                    await FavoritesService.removeFavorite(loc.name ?? '');
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
