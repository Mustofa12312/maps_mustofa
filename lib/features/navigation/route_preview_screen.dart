import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/routing_service.dart';
import '../../shared/services/prayer_service.dart';
import '../../shared/services/favorites_service.dart';
import 'navigation_screen.dart';

class RoutePreviewScreen extends StatefulWidget {
  final LocationModel destination;
  const RoutePreviewScreen({super.key, required this.destination});

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  final MapController _mapController = MapController();
  RouteModel? _route;
  RouteModel? _altRoute;
  bool _loading = true;
  String _error = '';
  SafarStatus? _safarStatus;
  PrayerTime? _prayerTime;
  VehicleType _selectedVehicle = VehicleType.motor;
  bool _showAltRoute = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateRoute());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final vehicleName = prefs.getString(AppConstants.keyVehicleType) ?? 'motor';
    final isFav = await FavoritesService.isFavorite(widget.destination.name ?? '');
    if (mounted) {
      setState(() {
        _selectedVehicle = VehicleType.values.firstWhere(
          (v) => v.name == vehicleName,
          orElse: () => VehicleType.motor,
        );
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _loading = true;
      _error = '';
      _route = null;
      _altRoute = null;
    });

    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();

    if (pos == null) {
      setState(() {
        _error = 'GPS tidak ditemukan';
        _loading = false;
      });
      return;
    }

    // Main route
    final route = await RoutingService.getRoute(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: widget.destination.latitude,
      endLng: widget.destination.longitude,
      profile: _selectedVehicle.osrmProfile,
    );

    // Alt route (walking for comparison if not already walking)
    RouteModel? alt;
    if (_selectedVehicle != VehicleType.jalan) {
      alt = await RoutingService.getRoute(
        startLat: pos.latitude,
        startLng: pos.longitude,
        endLat: widget.destination.latitude,
        endLng: widget.destination.longitude,
        profile: 'foot',
      );
    }

    if (mounted) {
      if (route != null) {
        final mazhabName = (await SharedPreferences.getInstance())
            .getString(AppConstants.keyMazhab) ?? 'syafii';
        final mazhab = Mazhab.values.firstWhere(
          (m) => m.name == mazhabName,
          orElse: () => Mazhab.syafii,
        );
        final safar = SafarService.calculateStatus(
          distanceKm: route.distanceKm,
          mazhab: mazhab,
        );
        final pt = await PrayerService.getPrayerTimes(
          lat: pos.latitude,
          lng: pos.longitude,
        );

        setState(() {
          _route = route;
          _altRoute = alt;
          _safarStatus = safar;
          _prayerTime = pt;
          _loading = false;
        });

        if (route.coordinates.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(
            route.coordinates.map((c) => LatLng(c[1], c[0])).toList(),
          );
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
          );
        }
      } else {
        setState(() {
          _error = 'Rute tidak ditemukan';
          _loading = false;
        });
      }
    }
  }

  void _toggleFavorite() async {
    final name = widget.destination.name ?? '';
    if (_isFavorite) {
      await FavoritesService.removeFavorite(name);
    } else {
      await FavoritesService.addFavorite(widget.destination);
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _startNavigation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(destination: widget.destination),
      ),
    );
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
            top: 0, left: 0, right: 0,
            child: _buildTopBar(),
          ),
          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final pos = context.read<LocationService>().currentPosition;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        ),
        initialZoom: AppConstants.overviewZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.cartoTileUrl,
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mustofa.maps_ibadah',
        ),
        // Alt route (dim)
        if (_altRoute != null && _showAltRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _altRoute!.coordinates
                    .map((c) => LatLng(c[1], c[0]))
                    .toList(),
                color: AppColors.routeLineAlt,
                strokeWidth: 5,
              ),
            ],
          ),
        // Main route
        if (_route != null && _route!.coordinates.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.coordinates
                    .map((c) => LatLng(c[1], c[0]))
                    .toList(),
                color: AppColors.routeLine,
                strokeWidth: 6,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: [
            // Destination
            Marker(
              point: LatLng(widget.destination.latitude, widget.destination.longitude),
              width: 48, height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 22),
              ),
            ),
            // User position
            if (pos != null)
              Marker(
                point: LatLng(pos.latitude, pos.longitude),
                width: 36, height: 36,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgDark.withValues(alpha: 0.97),
            AppColors.bgDark.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Menuju', style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 12)),
                    Text(
                      widget.destination.name ?? 'Tujuan',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.error : AppColors.textOnDarkSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 16,
          ),
          child: _loading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text('Menghitung rute...', style: TextStyle(color: Colors.white70)),
                    ],
                  )),
                )
              : _error.isNotEmpty
                  ? SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                            const SizedBox(height: 8),
                            Text(_error, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _calculateRoute,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildRouteContent(),
        ),
      ),
    );
  }

  Widget _buildRouteContent() {
    if (_route == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle selector
        Row(
          children: VehicleType.values.map((v) {
            final selected = v == _selectedVehicle;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedVehicle = v);
                  _calculateRoute();
                },
                child: Container(
                  margin: EdgeInsets.only(right: v != VehicleType.jalan ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.borderDark,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        v == VehicleType.motor ? Icons.two_wheeler :
                        v == VehicleType.mobil ? Icons.directions_car : Icons.directions_walk,
                        color: selected ? Colors.white : AppColors.textOnDarkSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.displayName,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textOnDarkSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Route stats
        Row(
          children: [
            _buildStatCard(Icons.route, _route!.formattedDistance, 'Jarak', AppColors.primary),
            const SizedBox(width: 10),
            _buildStatCard(Icons.access_time, _route!.formattedDuration, 'Waktu', AppColors.accent),
            if (_safarStatus != null) ...[
              const SizedBox(width: 10),
              _buildStatCard(
                Icons.flight,
                _safarStatus!.isSafar ? 'Musafir' : 'Mukim',
                'Status',
                _safarStatus!.isSafar ? AppColors.warning : AppColors.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Safar info box
        if (_safarStatus != null && _safarStatus!.isSafar)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('✈️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Status Safar Aktif', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• ${_safarStatus!.qasarText} — sholat dipendekkan dari 4 rakaat jadi 2\n'
                  '• ${_safarStatus!.jamakText} — dapat menggabungkan sholat\n'
                  '• Mazhab: ${_safarStatus!.mazhab} (min. ${_safarStatus!.requiredDistanceKm.toStringAsFixed(0)} km)',
                  style: const TextStyle(color: AppColors.warning, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        if (_safarStatus != null && _safarStatus!.isSafar) const SizedBox(height: 12),

        // Prayer info
        if (_prayerTime != null)
          Builder(builder: (_) {
            final next = _prayerTime!.getNextPrayer();
            final dur = _prayerTime!.getTimeToNextPrayer();
            if (next == null || dur == null) return const SizedBox();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Salat ${next[1]} pukul ${next[2]} (${dur.inHours > 0 ? '${dur.inHours}j ' : ''}${dur.inMinutes % 60}m lagi)',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }),

        // Alt route toggle
        if (_altRoute != null)
          GestureDetector(
            onTap: () => setState(() => _showAltRoute = !_showAltRoute),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _showAltRoute ? AppColors.routeLineAlt.withValues(alpha: 0.1) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showAltRoute ? AppColors.routeLineAlt : AppColors.borderDark,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.alt_route,
                    color: _showAltRoute ? AppColors.routeLineAlt : AppColors.textOnDarkSecondary,
                    size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rute alternatif (Jalan kaki): ${_altRoute!.formattedDistance} — ${_altRoute!.formattedDuration}',
                      style: TextStyle(
                        color: _showAltRoute ? Colors.white : AppColors.textOnDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    _showAltRoute ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textOnDarkSecondary, size: 16,
                  ),
                ],
              ),
            ),
          ),

        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startNavigation,
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: const Text('Mulai Navigasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
