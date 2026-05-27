import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/geocoding_service.dart';
import '../../shared/services/prayer_service.dart';
import '../../shared/models/models.dart';
import '../search/search_screen.dart';
import '../prayer/prayer_screen.dart';
import '../settings/settings_screen.dart';
import '../navigation/navigation_screen.dart';
import '../mosque/mosque_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isFollowing = true;
  PrayerTime? _prayerTime;
  List<MosqueModel> _nearbyMosques = [];

  LatLng _mapCenter = const LatLng(
    AppConstants.defaultLat,
    AppConstants.defaultLng,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final locationService = context.read<LocationService>();
    await locationService.requestPermission();
    final pos = await locationService.getCurrentPosition();
    if (pos != null && mounted) {
      _mapCenter = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_mapCenter, AppConstants.defaultZoom);
      locationService.startTracking();
      _loadPrayerTime(pos.latitude, pos.longitude);
      _loadNearbyMosques(pos.latitude, pos.longitude);
    }
  }

  Future<void> _loadPrayerTime(double lat, double lng) async {
    final pt = await PrayerService.getPrayerTimes(lat: lat, lng: lng);
    if (mounted) setState(() => _prayerTime = pt);
  }

  Future<void> _loadNearbyMosques(double lat, double lng) async {
    final mosques = await MosqueService.findNearbyMosques(lat: lat, lng: lng);
    if (mounted) {
      setState(() {
        _nearbyMosques = mosques.take(5).toList();
      });
    }
  }

  void _recenterMap() {
    final pos = context.read<LocationService>().currentPosition;
    if (pos != null) {
      _mapCenter = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_mapCenter, AppConstants.defaultZoom);
      setState(() => _isFollowing = true);
    }
  }

  void _openSearch() async {
    final result = await Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (result != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NavigationScreen(destination: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Map
          _buildMap(),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
          // Prayer time widget
          if (_prayerTime != null)
            Positioned(
              top: 120,
              right: 16,
              child: _buildPrayerWidget(),
            ),
          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
          // FAB buttons
          Positioned(
            right: 16,
            bottom: 220,
            child: _buildFabButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<LocationService>(
      builder: (_, locationService, __) {
        final pos = locationService.currentPosition;

        if (pos != null && _isFollowing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(pos.latitude, pos.longitude),
              _mapController.camera.zoom,
            );
          });
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: AppConstants.defaultZoom,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _isFollowing) {
                setState(() => _isFollowing = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.cartoTileUrl,
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.mustofa.maps_ibadah',
            ),
            // Mosque markers
            MarkerLayer(
              markers: _nearbyMosques.map((m) {
                return Marker(
                  point: LatLng(m.latitude, m.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text('🕌', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              }).toList(),
            ),
            // User location marker
            if (pos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 60,
                    height: 60,
                    child: _UserLocationMarker(heading: locationService.heading),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgDark.withOpacity(0.95),
            AppColors.bgDark.withOpacity(0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: GestureDetector(
            onTap: _openSearch,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cari tempat, alamat...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerWidget() {
    final next = _prayerTime?.getNextPrayer();
    final timeToNext = _prayerTime?.getTimeToNextPrayer();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrayerScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  next != null ? next[1] : 'Selesai',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 2),
              Text(
                next[2],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (timeToNext != null)
                Text(
                  '${timeToNext.inHours}j ${timeToNext.inMinutes % 60}m lagi',
                  style: TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Quick access
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _buildQuickAction(
                  icon: '🕌',
                  label: 'Masjid',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MosqueScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  icon: '🙏',
                  label: 'Salat',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrayerScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  icon: '⚙️',
                  label: 'Pengaturan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  icon: '🔍',
                  label: 'Cari',
                  onTap: _openSearch,
                ),
              ],
            ),
          ),
          // Navigation button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                label: const Text('Mulai Navigasi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFab(
          icon: _isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed,
          color: _isFollowing ? AppColors.primary : AppColors.textOnDarkSecondary,
          onTap: _recenterMap,
        ),
      ],
    );
  }

  Widget _buildFab({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  final double heading;
  const _UserLocationMarker({required this.heading});

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        // Direction arrow
        Transform.rotate(
          angle: widget.heading * 3.14159 / 180,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}
