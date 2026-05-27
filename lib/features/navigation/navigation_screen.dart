import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/routing_service.dart';
import '../../shared/services/prayer_service.dart';
import '../../shared/services/voice_service.dart';

class NavigationScreen extends StatefulWidget {
  final LocationModel destination;
  const NavigationScreen({super.key, required this.destination});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  RouteModel? _route;
  bool _loading = true;
  bool _navigationActive = false;
  int _currentStepIndex = 0;
  PrayerTime? _prayerTime;
  SafarStatus? _safarStatus;
  String _error = '';
  final VoiceNavigationService _voice = VoiceNavigationService();
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _voice.init();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateRoute());
  }

  Future<void> _calculateRoute() async {
    final locationService = context.read<LocationService>();
    final pos = locationService.currentPosition;

    if (pos == null) {
      setState(() {
        _error = 'Posisi GPS tidak ditemukan';
        _loading = false;
      });
      return;
    }

    final route = await RoutingService.getRoute(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: widget.destination.latitude,
      endLng: widget.destination.longitude,
    );

    if (mounted) {
      if (route != null) {
        final pt = await PrayerService.getPrayerTimes(
          lat: pos.latitude,
          lng: pos.longitude,
        );

        // Load mazhab from prefs
        final prefs = await _getPrefs();
        final mazhabName = prefs;
        final mazhab = _getMazhab(mazhabName);
        final safar = SafarService.calculateStatus(
          distanceKm: route.distanceKm,
          mazhab: mazhab,
        );

        setState(() {
          _route = route;
          _loading = false;
          _prayerTime = pt;
          _safarStatus = safar;
        });

        // Fit map to route
        if (route.coordinates.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(
            route.coordinates
                .map((c) => LatLng(c[1], c[0]))
                .toList(),
          );
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Rute tidak ditemukan. Periksa koneksi internet.';
          _loading = false;
        });
      }
    }
  }

  Future<String> _getPrefs() async {
    // Return default mazhab
    return 'syafii';
  }

  Mazhab _getMazhab(String name) {
    return Mazhab.values.firstWhere(
      (m) => m.name == name,
      orElse: () => Mazhab.syafii,
    );
  }

  void _startNavigation() {
    setState(() => _navigationActive = true);
    if (_route != null && _route!.steps.isNotEmpty) {
      _voice.speak('Navigasi dimulai. ${_route!.steps[0].instruction}');
    }
    context.read<LocationService>().startTracking();
  }

  void _stopNavigation() {
    setState(() => _navigationActive = false);
    _voice.stop();
  }

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Map
          _buildMap(),
          // Top instruction banner (during active navigation)
          if (_navigationActive && _route != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildInstructionBanner(),
            ),
          // Back button
          if (!_navigationActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: _buildBackButton(),
            ),
          // Voice toggle (during navigation)
          if (_navigationActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              right: 16,
              child: _buildVoiceToggle(),
            ),
          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<LocationService>(
      builder: (_, locationService, __) {
        final pos = locationService.currentPosition;

        if (_navigationActive && pos != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(pos.latitude, pos.longitude),
              AppConstants.navigationZoom,
            );
            // Check off-route
            if (_route != null) {
              final offRoute = RoutingService.isOffRoute(
                pos.latitude,
                pos.longitude,
                _route!.coordinates,
              );
              if (offRoute) {
                _voice.speakRerouting();
                _calculateRoute();
              }

              // Update step
              final stepIdx = RoutingService.findCurrentStepIndex(
                pos.latitude,
                pos.longitude,
                _route!.steps,
              );
              if (stepIdx != _currentStepIndex) {
                setState(() => _currentStepIndex = stepIdx);
                if (stepIdx < _route!.steps.length) {
                  final step = _route!.steps[stepIdx];
                  _voice.speakInstruction(
                    step.instruction,
                    step.distanceMeters,
                  );
                }
              }
            }
          });
        }

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
            // Route polyline
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
            // Destination marker
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    widget.destination.latitude,
                    widget.destination.longitude,
                  ),
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            // User marker
            if (pos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: locationService.heading * 3.14159 / 180,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionBanner() {
    if (_route == null || _route!.steps.isEmpty) return const SizedBox();
    final step = _currentStepIndex < _route!.steps.length
        ? _route!.steps[_currentStepIndex]
        : _route!.steps.last;
    final nextStep = _currentStepIndex + 1 < _route!.steps.length
        ? _route!.steps[_currentStepIndex + 1]
        : null;

    return Container(
      color: AppColors.bgDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getManeuverIcon(step.maneuverType, step.maneuverModifier),
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.instruction,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        Text(
                          step.formattedDistance,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (nextStep != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: AppColors.textOnDarkSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Lalu: ${nextStep.instruction}',
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getManeuverIcon(String type, String modifier) {
    switch (type) {
      case 'turn':
        if (modifier.contains('left')) return Icons.turn_left;
        if (modifier.contains('right')) return Icons.turn_right;
        if (modifier.contains('uturn')) return Icons.u_turn_left;
        return Icons.straight;
      case 'arrive':
        return Icons.location_on;
      case 'depart':
        return Icons.play_arrow;
      default:
        return Icons.straight;
    }
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildVoiceToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _voiceEnabled = !_voiceEnabled);
        _voice.setEnabled(_voiceEnabled);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(
          _voiceEnabled ? Icons.volume_up : Icons.volume_off,
          color: _voiceEnabled ? AppColors.primary : AppColors.textOnDarkSecondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('Menghitung rute...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = '';
                  });
                  _calculateRoute();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_route == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination name
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.destination.name ?? 'Tujuan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Route info
            Row(
              children: [
                _buildInfoChip(
                  Icons.route,
                  _route!.formattedDistance,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.access_time,
                  _route!.formattedDuration,
                  AppColors.accent,
                ),
                if (_safarStatus != null) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.flight,
                    _safarStatus!.isSafar ? 'Musafir' : 'Mukim',
                    _safarStatus!.isSafar ? AppColors.warning : AppColors.success,
                  ),
                ],
              ],
            ),
            // Safar info
            if (_safarStatus != null && _safarStatus!.isSafar) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🕌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_safarStatus!.qasarText} • ${_safarStatus!.jamakText} (${_safarStatus!.mazhab})',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Prayer reminder
            if (_prayerTime != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (_) {
                final next = _prayerTime!.getNextPrayer();
                final dur = _prayerTime!.getTimeToNextPrayer();
                if (next == null || dur == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${next[1]} pukul ${next[2]} — ${dur.inHours}j ${dur.inMinutes % 60}m lagi',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            // Action button
            SizedBox(
              width: double.infinity,
              child: _navigationActive
                  ? ElevatedButton.icon(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.stop, color: Colors.white),
                      label: const Text('Stop Navigasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text('Mulai Navigasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
