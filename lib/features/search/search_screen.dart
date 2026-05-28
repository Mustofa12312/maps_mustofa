import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/geocoding_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<LocationModel> _results = [];
  List<LocationModel> _recentSearches = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = raw.map((e) {
        final json = jsonDecode(e);
        return LocationModel(
          latitude: json['lat'],
          longitude: json['lng'],
          name: json['name'],
          address: json['address'],
        );
      }).toList();
    });
  }

  Future<void> _saveRecentSearch(LocationModel loc) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('recent_searches') ?? [];
    final item = jsonEncode({
      'lat': loc.latitude,
      'lng': loc.longitude,
      'name': loc.name,
      'address': loc.address,
    });
    existing.removeWhere((e) {
      try {
        final j = jsonDecode(e);
        return j['name'] == loc.name;
      } catch (_) {
        return false;
      }
    });
    existing.insert(0, item);
    if (existing.length > 10) existing.removeLast();
    await prefs.setStringList('recent_searches', existing);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await GeocodingService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  void _selectLocation(LocationModel loc) async {
    await _saveRecentSearch(loc);
    if (mounted) Navigator.of(context).pop(loc);
  }

  void _searchCategory(String category) {
    _controller.text = category;
    setState(() => _query = category);
    _search(category);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari tempat atau alamat...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textOnDarkSecondary),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _query = '';
                                    _results = [];
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) {
                        setState(() => _query = q);
                        Future.delayed(
                            const Duration(milliseconds: 500), () {
                          if (_controller.text == q) _search(q);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Current location option
            Consumer<LocationService>(
              builder: (_, locationService, __) {
                final pos = locationService.currentPosition;
                if (pos == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildLocationTile(
                    icon: Icons.my_location,
                    iconColor: AppColors.primary,
                    title: 'Lokasi Saya',
                    subtitle:
                        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                    onTap: () => _selectLocation(
                      LocationModel(
                        latitude: pos.latitude,
                        longitude: pos.longitude,
                        name: 'Lokasi Saya',
                      ),
                    ),
                  ),
                );
              },
            ),
            // Quick Categories
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('⛽', 'SPBU', () => _searchCategory('SPBU')),
                  _buildCategoryChip('☕', 'Rest Area', () => _searchCategory('Rest Area')),
                  _buildCategoryChip('🍽️', 'Rumah Makan', () => _searchCategory('Rumah Makan')),
                  _buildCategoryChip('🏨', 'Hotel', () => _searchCategory('Hotel')),
                  _buildCategoryChip('🏥', 'Rumah Sakit', () => _searchCategory('Rumah Sakit')),
                  _buildCategoryChip('🏖️', 'Tempat Wisata', () => _searchCategory('Tempat Wisata')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Results or recents
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _results.isNotEmpty
                      ? _buildResultsList()
                      : _query.isEmpty
                          ? _buildRecentsList()
                          : const Center(
                              child: Text(
                                'Tidak ada hasil ditemukan',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final loc = _results[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildLocationTile(
            icon: Icons.place,
            iconColor: AppColors.error,
            title: loc.name ?? 'Tempat',
            subtitle: loc.address ?? '',
            onTap: () => _selectLocation(loc),
          ),
        );
      },
    );
  }

  Widget _buildRecentsList() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Cari tempat atau alamat tujuan',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Pencarian Terakhir',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (_, i) {
              final loc = _recentSearches[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildLocationTile(
                  icon: Icons.history,
                  iconColor: AppColors.textOnDarkSecondary,
                  title: loc.name ?? 'Tempat',
                  subtitle: loc.address ?? '',
                  onTap: () => _selectLocation(loc),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textOnDarkSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
