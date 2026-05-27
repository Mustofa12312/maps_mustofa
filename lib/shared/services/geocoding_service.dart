import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class GeocodingService {
  static Future<List<LocationModel>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse(
        '${AppConstants.nominatimUrl}/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=10&countrycodes=id'
        '&accept-language=id',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SafarMaps/1.0 maps.ibadah@gmail.com'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => LocationModel.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  static Future<LocationModel?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '${AppConstants.nominatimUrl}/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=id',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SafarMaps/1.0 maps.ibadah@gmail.com'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LocationModel.fromJson(data);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}

class MosqueService {
  static Future<List<MosqueModel>> findNearbyMosques({
    required double lat,
    required double lng,
    double radiusMeters = 3000,
  }) async {
    try {
      const query = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:{radius},{lat},{lng});
  way["amenity"="place_of_worship"]["religion"="muslim"](around:{radius},{lat},{lng});
);
out body center;
''';

      final body = query
          .replaceAll('{radius}', radiusMeters.round().toString())
          .replaceAll('{lat}', lat.toString())
          .replaceAll('{lng}', lng.toString());

      final response = await http
          .post(
            Uri.parse(AppConstants.overpassUrl),
            body: {'data': body},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List? ?? [];
        return elements.map((e) => MosqueModel.fromOverpass(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
