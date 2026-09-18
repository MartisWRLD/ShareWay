import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/location_point.dart';

/// Live-Position eines bestimmten Nutzers während einer Fahrt.
final trackedLocationProvider = StreamProvider.family
    .autoDispose<LocationPoint?, ({String rideId, String userId})>((ref, args) {
  return ref.watch(trackingRepositoryProvider).watchLocation(args.rideId, args.userId);
});

/// Startet das periodische Senden der eigenen Position für eine Fahrt.
/// Wird auf dem LiveTrackingScreen sowohl vom Fahrer als auch vom
/// Mitfahrer aktiviert, solange die Fahrt läuft.
class OwnLocationBroadcaster {
  OwnLocationBroadcaster(this._ref, this.rideId, this.userId);
  final Ref _ref;
  final String rideId;
  final String userId;
  StreamSubscription<Position>? _sub;

  Future<void> start() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return;
      }
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Meter, bevor ein neues Update gesendet wird
      ),
    ).listen((position) {
      _ref.read(trackingRepositoryProvider).pushLocation(
        rideId,
        userId,
        LocationPoint(
          lat: position.latitude,
          lng: position.longitude,
          heading: position.heading,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

final ownLocationBroadcasterProvider = Provider.autoDispose
    .family<OwnLocationBroadcaster, ({String rideId, String userId})>((ref, args) {
  final broadcaster = OwnLocationBroadcaster(ref, args.rideId, args.userId);
  ref.onDispose(broadcaster.stop);
  return broadcaster;
});
