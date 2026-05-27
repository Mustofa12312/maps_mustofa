// Models
class LocationModel {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  final String? placeId;
  final LocationType type;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.placeId,
    this.type = LocationType.general,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['display_name']?.toString().split(',').first,
      address: json['display_name'],
      placeId: json['place_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'address': address,
        'placeId': placeId,
        'type': type.name,
      };

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? address,
    String? placeId,
    LocationType? type,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      type: type ?? this.type,
    );
  }
}

enum LocationType {
  general,
  home,
  masjid,
  restArea,
  spbu,
  rumahMakan,
  hotel,
  wisata,
  rumahSakit,
  favorite,
}

class RouteModel {
  final List<List<double>> coordinates; // [lng, lat] pairs
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;
  final String routeGeometry;

  const RouteModel({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
    this.routeGeometry = '',
  });

  double get distanceKm => distanceMeters / 1000;
  int get durationMinutes => (durationSeconds / 60).round();

  String get formattedDistance {
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      return '${h}j ${m}m';
    }
    return '${durationMinutes}m';
  }

  factory RouteModel.fromOsrm(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final legs = route['legs'] as List;
    final allSteps = <RouteStep>[];

    for (final leg in legs) {
      for (final step in (leg['steps'] as List)) {
        allSteps.add(RouteStep.fromOsrm(step));
      }
    }

    // Decode geometry
    final geometry = route['geometry'];
    final coords = _decodePolyline(geometry['coordinates'] != null
        ? geometry
        : null);

    return RouteModel(
      coordinates: coords,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
      steps: allSteps,
      routeGeometry: '',
    );
  }

  static List<List<double>> _decodePolyline(Map<String, dynamic>? geometry) {
    if (geometry == null) return [];
    final coords = geometry['coordinates'] as List? ?? [];
    return coords.map<List<double>>((c) {
      return [(c[0] as num).toDouble(), (c[1] as num).toDouble()];
    }).toList();
  }
}

class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String maneuverModifier;
  final List<double>? location; // [lng, lat]

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    this.maneuverModifier = '',
    this.location,
  });

  factory RouteStep.fromOsrm(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final location = maneuver['location'] as List?;
    return RouteStep(
      instruction: _buildInstruction(maneuver),
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
      maneuverType: maneuver['type']?.toString() ?? '',
      maneuverModifier: maneuver['modifier']?.toString() ?? '',
      location: location != null
          ? [(location[0] as num).toDouble(), (location[1] as num).toDouble()]
          : null,
    );
  }

  static String _buildInstruction(Map<String, dynamic> maneuver) {
    final type = maneuver['type']?.toString() ?? '';
    final modifier = maneuver['modifier']?.toString() ?? '';

    switch (type) {
      case 'depart':
        return 'Mulai perjalanan';
      case 'arrive':
        return 'Anda telah tiba di tujuan';
      case 'turn':
        switch (modifier) {
          case 'left':
            return 'Belok kiri';
          case 'right':
            return 'Belok kanan';
          case 'slight left':
            return 'Sedikit belok kiri';
          case 'slight right':
            return 'Sedikit belok kanan';
          case 'sharp left':
            return 'Belok tajam ke kiri';
          case 'sharp right':
            return 'Belok tajam ke kanan';
          case 'uturn':
            return 'Putar balik';
          default:
            return 'Belok';
        }
      case 'continue':
        return 'Tetap lurus';
      case 'merge':
        return 'Gabung ke jalan';
      case 'roundabout':
        return 'Masuk bundaran';
      case 'exit roundabout':
        return 'Keluar bundaran';
      default:
        return 'Lanjutkan';
    }
  }

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}

class SafarStatus {
  final double distanceKm;
  final bool isSafar;
  final String mazhab;
  final double requiredDistanceKm;
  final bool canQasar;
  final bool canJamak;

  const SafarStatus({
    required this.distanceKm,
    required this.isSafar,
    required this.mazhab,
    required this.requiredDistanceKm,
    required this.canQasar,
    required this.canJamak,
  });

  String get statusText => isSafar ? 'Status Musafir' : 'Bukan Musafir';
  String get qasarText => canQasar ? 'Boleh Qasar' : 'Tidak Boleh Qasar';
  String get jamakText => canJamak ? 'Boleh Jamak' : 'Tidak Boleh Jamak';
}

class MosqueModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final String? address;
  final bool hasWudu;
  final bool hasParking;

  const MosqueModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.address,
    this.hasWudu = false,
    this.hasParking = false,
  });

  factory MosqueModel.fromOverpass(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final lat = (element['lat'] as num?)?.toDouble() ??
        (element['center']?['lat'] as num?)?.toDouble() ?? 0;
    final lon = (element['lon'] as num?)?.toDouble() ??
        (element['center']?['lon'] as num?)?.toDouble() ?? 0;

    return MosqueModel(
      id: element['id']?.toString() ?? '',
      name: tags['name'] ?? tags['name:id'] ?? 'Masjid',
      latitude: lat,
      longitude: lon,
      address: tags['addr:full'] ?? tags['addr:street'],
      hasWudu: tags['amenity'] == 'place_of_worship',
      hasParking: tags['parking'] != null,
    );
  }
}
