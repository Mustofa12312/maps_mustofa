import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/geocoding_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/models/models.dart';
import '../navigation/navigation_screen.dart';

class MosqueScreen extends StatefulWidget {
  const MosqueScreen({super.key});

  @override
  State<MosqueScreen> createState() => _MosqueScreenState();
}

class _MosqueScreenState extends State<MosqueScreen> {
  List<MosqueModel> _mosques = [];
  bool _loading = true;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _loadMosques();
  }

  Future<void> _loadMosques() async {
    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();

    if (pos != null) {
      final mosques = await MosqueService.findNearbyMosques(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusMeters: 5000,
      );
      if (mounted) setState(() {
        _mosques = mosques;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  double _distanceTo(MosqueModel mosque) {
    final pos = context.read<LocationService>().currentPosition;
    if (pos == null) return 0;
    return LocationService.calculateDistance(
      pos.latitude,
      pos.longitude,
      mosque.latitude,
      mosque.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Masjid Terdekat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _mosques.isEmpty
              ? _buildEmpty()
              : _showMap
                  ? _buildMapView()
                  : _buildListView(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🕌', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'Tidak ada masjid ditemukan\ndalam radius 5 km',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final sorted = [..._mosques]
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final mosque = sorted[i];
        final dist = _distanceTo(mosque);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NavigationScreen(
                destination: LocationModel(
                  latitude: mosque.latitude,
                  longitude: mosque.longitude,
                  name: mosque.name,
                  address: mosque.address,
                  type: LocationType.masjid,
                ),
              ),
            )),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🕌', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (mosque.address != null)
                          Text(
                            mosque.address!,
                            style: const TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dist < 1
                                    ? '${(dist * 1000).round()} m'
                                    : '${dist.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.navigation,
                      color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final pos = context.read<LocationService>().currentPosition;
    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

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
                width: 32,
                height: 32,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ..._mosques.map((m) => Marker(
                  point: LatLng(m.latitude, m.longitude),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        destination: LocationModel(
                          latitude: m.latitude,
                          longitude: m.longitude,
                          name: m.name,
                          type: LocationType.masjid,
                        ),
                      ),
                    )),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text('🕌', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}
