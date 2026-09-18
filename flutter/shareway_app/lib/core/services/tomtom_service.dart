import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class TomTomPlace {
  final String address;
  final double lat;
  final double lng;

  const TomTomPlace({required this.address, required this.lat, required this.lng});
}

class TomTomRoute {
  final double distanceMeters;
  final int travelTimeSeconds;
  final List<(double lat, double lng)> points;

  const TomTomRoute({
    required this.distanceMeters,
    required this.travelTimeSeconds,
    required this.points,
  });

  double get distanceKm => distanceMeters / 1000;
}

/// Kapselt alle Aufrufe an die TomTom REST APIs (Geocoding + Routing).
/// Erfordert [AppConstants.tomTomApiKey] (via --dart-define gesetzt).
class TomTomService {
  final http.Client _client;
  TomTomService({http.Client? client}) : _client = client ?? http.Client();

  /// Adresssuche → Liste von Vorschlägen mit Koordinaten (für die
  /// Autovervollständigung in der Suchleiste).
  Future<List<TomTomPlace>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
      '${AppConstants.tomTomSearchBaseUrl}/${Uri.encodeComponent(query)}.json'
      '?key=${AppConstants.tomTomApiKey}&limit=5',
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((r) {
      final pos = r['position'] as Map<String, dynamic>;
      return TomTomPlace(
        address: r['address']?['freeformAddress'] ?? query,
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lon'] as num).toDouble(),
      );
    }).toList();
  }

  /// Route zwischen zwei Punkten – wird u.a. genutzt, um den Umweg
  /// (Distanz zum Mitfahrer + zusätzliche Strecke) zu bestimmen und
  /// daraus den Tarif zu berechnen.
  Future<TomTomRoute?> calculateRoute({
    required (double lat, double lng) from,
    required (double lat, double lng) to,
  }) async {
    final locations = '${from.$1},${from.$2}:${to.$1},${to.$2}';
    final uri = Uri.parse(
      '${AppConstants.tomTomRoutingBaseUrl}/$locations/json'
      '?key=${AppConstants.tomTomApiKey}',
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final summary = route['summary'] as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>;
    final points = <(double, double)>[];
    for (final leg in legs) {
      for (final p in (leg['points'] as List<dynamic>)) {
        points.add(((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()));
      }
    }

    return TomTomRoute(
      distanceMeters: (summary['lengthInMeters'] as num).toDouble(),
      travelTimeSeconds: summary['travelTimeInSeconds'] as int,
      points: points,
    );
  }

  /// Berechnet den Fahrpreis für einen Mitfahrer:
  /// Grundstrecke (die der Fahrer ohnehin fährt) günstiger, zusätzliche
  /// Umweg-Kilometer (nur wegen Abholung/Absetzung des Mitfahrers) teurer.
  static double calculateFare({
    required double baseRouteKm,
    required double detourKm,
  }) {
    return (baseRouteKm * AppConstants.baseFarePerKm) +
        (detourKm * AppConstants.detourSurchargePerKm);
  }
}
