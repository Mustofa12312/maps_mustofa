import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FavoritesService {
  static const String _key = 'favorite_locations';

  static Future<List<LocationModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) {
      final j = jsonDecode(e);
      return LocationModel(
        latitude: j['lat'],
        longitude: j['lng'],
        name: j['name'],
        address: j['address'],
        type: LocationType.favorite,
      );
    }).toList();
  }

  static Future<void> addFavorite(LocationModel loc) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    final item = jsonEncode({
      'lat': loc.latitude,
      'lng': loc.longitude,
      'name': loc.name,
      'address': loc.address,
    });
    // Remove duplicate
    existing.removeWhere((e) {
      try {
        final j = jsonDecode(e);
        return j['name'] == loc.name;
      } catch (_) {
        return false;
      }
    });
    existing.insert(0, item);
    await prefs.setStringList(_key, existing);
  }

  static Future<void> removeFavorite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.removeWhere((e) {
      try {
        final j = jsonDecode(e);
        return j['name'] == name;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, existing);
  }

  static Future<bool> isFavorite(String name) async {
    final favs = await getFavorites();
    return favs.any((f) => f.name == name);
  }
}
