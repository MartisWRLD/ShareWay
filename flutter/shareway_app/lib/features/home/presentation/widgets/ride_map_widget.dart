import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../rides/domain/ride.dart';

/// Zeigt eine Karte (TomTom-Kacheln) mit Markern für die anstehenden
/// Fahrten. Tippen auf einen Marker öffnet die Fahrtdetails.
class RideMapWidget extends StatelessWidget {
  const RideMapWidget({
    super.key,
    required this.rides,
    this.onRideTap,
    this.center,
  });

  final List<Ride> rides;
  final ValueChanged<Ride>? onRideTap;
  final LatLng? center;

  @override
  Widget build(BuildContext context) {
    final hasKey = AppConstants.tomTomApiKey.isNotEmpty;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center ?? const LatLng(48.2082, 16.3738), // Wien
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.tomTomTileUrl,
              userAgentPackageName: 'com.example.shareway',
            ),
            MarkerLayer(
              markers: rides.map((ride) {
                return Marker(
                  point: LatLng(ride.origin.lat, ride.origin.lng),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => onRideTap?.call(ride),
                    child: Tooltip(
                      message:
                          '${ride.origin.address} → ${ride.destination.address}',
                      child: const Icon(Icons.directions_car, size: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (!hasKey)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Kein TomTom API-Key gesetzt. Mit '
                  '--dart-define=TOMTOM_API_KEY=… starten, damit die '
                  'Kartenkacheln geladen werden.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
