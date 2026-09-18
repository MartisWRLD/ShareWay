import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/location_point.dart';

/// Realtime Database statt Firestore, weil während einer Fahrt alle paar
/// Sekunden neue Positionen geschrieben werden – dafür ist RTDB latenzärmer
/// und günstiger als viele einzelne Firestore-Writes.
class TrackingRepository {
  TrackingRepository(this._db);
  final FirebaseDatabase _db;

  DatabaseReference _rideRef(String rideId) =>
      _db.ref('${AppConstants.trackingPath}/$rideId');

  /// Schreibt die eigene Position. Wird sowohl vom Fahrer als auch vom
  /// Mitfahrer während des Fahrtzeitraums periodisch aufgerufen.
  Future<void> pushLocation(
    String rideId,
    String userId,
    LocationPoint point,
  ) {
    return _rideRef(rideId).child(userId).set(point.toMap());
  }

  /// Live-Stream der Position eines bestimmten Nutzers (z.B. Fahrer sieht
  /// Mitfahrer, Mitfahrer sieht Fahrer).
  Stream<LocationPoint?> watchLocation(String rideId, String userId) {
    return _rideRef(rideId).child(userId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return LocationPoint.fromMap(Map<dynamic, dynamic>.from(value as Map));
    });
  }

  /// Beendet das Tracking und räumt die Positionsdaten der Fahrt auf.
  Future<void> clearTracking(String rideId) => _rideRef(rideId).remove();
}
