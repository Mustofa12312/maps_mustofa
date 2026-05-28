import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/geocoding_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/routing_service.dart';
import '../../shared/models/models.dart';
import '../navigation/route_preview_screen.dart';

class MosqueScreen extends StatefulWidget {
  /// If provided, shows mosques along this route
  final LocationModel? destination;

  const MosqueScreen({super.key, this.destination});

  @override
  State<MosqueScreen> createState() => _MosqueScreenState();
}

class _MosqueScreenState extends State<MosqueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Nearby mosques
  List<MosqueModel> _nearbyMosques = [];
  bool _loadingNearby = true;

  // Along-route mosques
  List<MosqueModel> _routeMosques = [];
  bool _loadingRoute = false;
  bool _showRouteMap = false;
  RouteModel? _route;

  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.destination != null ? 2 : 1,
      vsync: this,
    );
    _loadNearbyMosques();
    if (widget.destination != null) {
      _loadRouteAndMosques();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyMosques() async {
    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();

    if (pos != null) {
      final mosques = await MosqueService.findNearbyMosques(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusMeters: 5000,
      );
      if (mounted) {
        setState(() {
          _nearbyMosques = mosques;
          _loadingNearby = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _loadRouteAndMosques() async {
    if (widget.destination == null) return;
    setState(() => _loadingRoute = true);

    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();
    if (pos == null) {
      setState(() => _loadingRoute = false);
      return;
    }

    // Get route
    final route = await RoutingService.getRoute(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: widget.destination!.latitude,
      endLng: widget.destination!.longitude,
    );

    if (route == null || !mounted) {
      setState(() => _loadingRoute = false);
      return;
    }

    setState(() => _route = route);

    // Sample points along route (every ~20 coords)
    final coords = route.coordinates;
    final Set<String> added = {};
    final List<MosqueModel> routeMosques = [];

    final step = (coords.length / 5).ceil().clamp(1, coords.length);
    for (int i = 0; i < coords.length; i += step) {
      final c = coords[i];
      final lat = c[1];
      final lng = c[0];

      final mosques = await MosqueService.findNearbyMosques(
        lat: lat, lng: lng, radiusMeters: 2000,
      );
      for (final m in mosques) {
        if (!added.contains(m.id)) {
          added.add(m.id);

          // Calculate position along route (0–100%)
          final pct = (i / coords.length * 100).round();
          final dist = LocationService.calculateDistance(
            pos.latitude, pos.longitude, m.latitude, m.longitude,
          );
          routeMosques.add(MosqueModel(
            id: m.id,
            name: m.name,
            latitude: m.latitude,
            longitude: m.longitude,
            address: '$pct% dari rute (±${dist.toStringAsFixed(1)} km)',
            hasWudu: m.hasWudu,
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _routeMosques = routeMosques;
        _loadingRoute = false;
      });
    }
  }

  double _distanceTo(MosqueModel mosque) {
    final pos = context.read<LocationService>().currentPosition;
    if (pos == null) return 0;
    return LocationService.calculateDistance(
      pos.latitude, pos.longitude, mosque.latitude, mosque.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTwoTabs = widget.destination != null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Masjid & Musholla'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!hasTwoTabs || _tabController.index == 0)
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          if (hasTwoTabs && _tabController.index == 1)
            IconButton(
              icon: Icon(_showRouteMap ? Icons.list : Icons.map_outlined),
              onPressed: () => setState(() => _showRouteMap = !_showRouteMap),
            ),
        ],
        bottom: hasTwoTabs
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textOnDarkSecondary,
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'Terdekat'),
                  Tab(text: 'Sepanjang Rute'),
                ],
              )
            : null,
      ),
      body: hasTwoTabs
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildNearbyTab(),
                _buildRouteTab(),
              ],
            )
          : _buildNearbyTab(),
    );
  }

  // ─────────────────────────── NEARBY TAB ───────────────────────────

  Widget _buildNearbyTab() {
    if (_loadingNearby) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text('Mencari masjid terdekat...', style: TextStyle(color: Colors.white60)),
        ]),
      );
    }
    if (_nearbyMosques.isEmpty) return _buildEmpty('Tidak ada masjid ditemukan\ndalam radius 5 km');
    if (_showMap) return _buildMapView(_nearbyMosques);
    return _buildListView(_nearbyMosques);
  }

  // ─────────────────────────── ROUTE TAB ────────────────────────────

  Widget _buildRouteTab() {
    if (_loadingRoute) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text('Mencari masjid di sepanjang rute...', style: TextStyle(color: Colors.white60)),
        ]),
      );
    }
    if (_routeMosques.isEmpty) {
      return _buildEmpty('Tidak ada masjid ditemukan\ndi sepanjang rute ini');
    }
    if (_showRouteMap) return _buildRouteMapView();
    return _buildRouteListView();
  }

  Widget _buildRouteListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routeMosques.length,
      itemBuilder: (_, i) {
        final mosque = _routeMosques[i];
        return _buildMosqueCard(mosque, isRoute: true);
      },
    );
  }

  Widget _buildRouteMapView() {
    final pos = context.read<LocationService>().currentPosition;
    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 11),
      children: [
        TileLayer(
          urlTemplate: AppConstants.cartoTileUrl,
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mustofa.maps_ibadah',
        ),
        // Route polyline
        if (_route != null && _route!.coordinates.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.coordinates.map((c) => LatLng(c[1], c[0])).toList(),
                color: AppColors.routeLine.withValues(alpha: 0.7),
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (pos != null)
              Marker(
                point: LatLng(pos.latitude, pos.longitude),
                width: 32, height: 32,
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            if (widget.destination != null)
              Marker(
                point: LatLng(widget.destination!.latitude, widget.destination!.longitude),
                width: 36, height: 36,
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: const Icon(Icons.flag, color: Colors.white, size: 18),
                ),
              ),
            ..._routeMosques.map((m) => Marker(
              point: LatLng(m.latitude, m.longitude),
              width: 44, height: 44,
              child: GestureDetector(
                onTap: () => _navigateToMosque(m),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(child: Text('🕌', style: TextStyle(fontSize: 20))),
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────── SHARED ──────────────────────────────

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🕌', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildListView(List<MosqueModel> mosques) {
    final sorted = [...mosques]
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _buildMosqueCard(sorted[i]),
    );
  }

  Widget _buildMosqueCard(MosqueModel mosque, {bool isRoute = false}) {
    final dist = _distanceTo(mosque);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _navigateToMosque(mosque),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🕌', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mosque.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    if (mosque.address != null)
                      Text(mosque.address!,
                          style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!isRoute)
                          _miniChip(
                            dist < 1
                                ? '${(dist * 1000).round()} m'
                                : '${dist.toStringAsFixed(1)} km',
                            AppColors.primary,
                          ),
                        if (isRoute) _miniChip('Di rute', AppColors.accent),
                        if (mosque.hasWudu) ...[
                          const SizedBox(width: 6),
                          _miniChip('Tempat Wudhu', AppColors.info),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.navigation, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _navigateToMosque(MosqueModel mosque) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoutePreviewScreen(
        destination: LocationModel(
          latitude: mosque.latitude,
          longitude: mosque.longitude,
          name: mosque.name,
          address: mosque.address,
          type: LocationType.masjid,
        ),
      ),
    ));
  }

  Widget _buildMapView(List<MosqueModel> mosques) {
    final pos = context.read<LocationService>().currentPosition;
    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: AppConstants.cartoTileUrl,
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mustofa.maps_ibadah',
        ),
        MarkerLayer(
          markers: [
            if (pos != null)
              Marker(
                point: LatLng(pos.latitude, pos.longitude),
                width: 32, height: 32,
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ...mosques.map((m) => Marker(
              point: LatLng(m.latitude, m.longitude),
              width: 44, height: 44,
              child: GestureDetector(
                onTap: () => _navigateToMosque(m),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(child: Text('🕌', style: TextStyle(fontSize: 20))),
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }
}
