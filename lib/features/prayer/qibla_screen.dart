import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/location_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaDirection;

  @override
  void initState() {
    super.initState();
    _calculateQibla();
  }

  Future<void> _calculateQibla() async {
    final locationService = context.read<LocationService>();
    var pos = locationService.currentPosition;
    pos ??= await locationService.getCurrentPosition();

    if (pos != null && mounted) {
      // Mekkah coordinates
      const meccaLat = 21.422487;
      const meccaLng = 39.826206;

      final lat = pos.latitude;
      final lng = pos.longitude;

      final latRad = _toRadians(lat);
      final meccaLatRad = _toRadians(meccaLat);
      final lngDiffRad = _toRadians(meccaLng - lng);

      final y = math.sin(lngDiffRad);
      final x = math.cos(latRad) * math.tan(meccaLatRad) -
          math.sin(latRad) * math.cos(lngDiffRad);

      var qibla = math.atan2(y, x);
      qibla = _toDegrees(qibla);
      if (qibla < 0) {
        qibla += 360;
      }

      setState(() {
        _qiblaDirection = qibla;
      });
    }
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / math.pi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Arah Kiblat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _qiblaDirection == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Sensor kompas tidak tersedia di perangkat ini',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                double? direction = snapshot.data?.heading;

                if (direction == null) {
                  return const Center(
                    child: Text('Arah kompas tidak terdeteksi',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return _buildCompass(direction);
              },
            ),
    );
  }

  Widget _buildCompass(double currentHeading) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Derajat Kiblat: ${_qiblaDirection!.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Posisikan perangkat secara horizontal',
          style: TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 14),
        ),
        const SizedBox(height: 60),
        Stack(
          alignment: Alignment.center,
          children: [
            // Compass Dial
            Transform.rotate(
              angle: _toRadians(-currentHeading),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: const Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('U', style: TextStyle(color: AppColors.error, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('S', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('B', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('T', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Qibla Pointer
            Transform.rotate(
              angle: _toRadians(_qiblaDirection! - currentHeading),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 80,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
