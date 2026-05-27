import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class RoutingService {
  static Future<RouteModel?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving',
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.osrmBaseUrl}/$profile/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          return RouteModel.fromOsrm(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate if user is off-route (> 50m from route line)
  static bool isOffRoute(
    double userLat,
    double userLng,
    List<List<double>> routeCoords,
  ) {
    if (routeCoords.isEmpty) return false;
    double minDist = double.maxFinite;
    for (final coord in routeCoords) {
      final dist = _pointDistance(userLat, userLng, coord[1], coord[0]);
      if (dist < minDist) minDist = dist;
    }
    return minDist > 0.05; // 50 meters threshold
  }

  static double _pointDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLng = (lng2 - lng1) * 3.14159265358979 / 180;
    final a = dLat * dLat + dLng * dLng;
    return r * a;
  }

  /// Find the next upcoming step based on user's position
  static int findCurrentStepIndex(
    double userLat,
    double userLng,
    List<RouteStep> steps,
  ) {
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.location != null) {
        final dist = _pointDistance(
          userLat, userLng, step.location![1], step.location![0],
        );
        if (dist < 0.1) return i; // within 100m of step
      }
    }
    return 0;
  }
}
