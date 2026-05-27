class AppConstants {
  // App Info
  static const String appName = 'Safar Maps';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Navigasi & Ibadah dalam Satu Genggaman';

  // Map Tiles
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttributions =
      '© OpenStreetMap contributors';
  static const String cartoTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  static const String cartoLightTileUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';

  // OSRM Routing
  static const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1';
  static const String osrmProfileDriving = 'driving';
  static const String osrmProfileWalking = 'foot';
  static const String osrmProfileCycling = 'bike';

  // Nominatim Geocoding
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';

  // Overpass API (for mosque, SPBU, etc.)
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  // Prayer Times API
  static const String aladhanBaseUrl = 'https://api.aladhan.com/v1';

  // Safar Rules (in km)
  static const double safarDistanceSyafii = 81.0; // 81 km (~4 barid)
  static const double safarDistanceHanafi = 78.0; // 78 km
  static const double safarDistanceMaliki = 81.0;
  static const double safarDistanceHanbali = 81.0;

  // Map defaults
  static const double defaultZoom = 15.0;
  static const double navigationZoom = 17.0;
  static const double overviewZoom = 12.0;

  // Indonesia default center
  static const double defaultLat = -6.2088;
  static const double defaultLng = 106.8456;

  // GPS
  static const int locationUpdateIntervalMs = 1000;
  static const double locationDistanceFilterM = 5.0;

  // SharedPreferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyMazhab = 'mazhab';
  static const String keyVoiceEnabled = 'voice_enabled';
  static const String keyVehicleType = 'vehicle_type';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyFavoriteLocations = 'favorite_locations';
  static const String keyPrayerMethod = 'prayer_method';
  static const String keyOnboardingDone = 'onboarding_done';
}

enum Mazhab {
  syafii('Syafi\'i', 81.0),
  hanafi('Hanafi', 78.0),
  maliki('Maliki', 81.0),
  hanbali('Hanbali', 81.0);

  final String displayName;
  final double safarDistanceKm;
  const Mazhab(this.displayName, this.safarDistanceKm);
}

enum VehicleType {
  motor('Motor', 'driving'),
  mobil('Mobil', 'driving'),
  jalan('Jalan Kaki', 'foot');

  final String displayName;
  final String osrmProfile;
  const VehicleType(this.displayName, this.osrmProfile);
}

enum PrayerMethod {
  kemenag('Kemenag (Indonesia)', 20),
  mwl('Muslim World League', 3),
  ummAlQura('Umm al-Qura', 4);

  final String displayName;
  final int methodId;
  const PrayerMethod(this.displayName, this.methodId);
}
