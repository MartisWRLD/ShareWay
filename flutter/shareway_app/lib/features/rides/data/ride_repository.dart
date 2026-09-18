import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/ride.dart';

class RideRepository {
  RideRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection(AppConstants.ridesCollection);

  /// Fahrer legt eine neue Fahrt an.
  Future<String> createRide(Ride ride) async {
    final doc = await _rides.add(ride.toMap());
    return doc.id;
  }

  Stream<Ride> watchRide(String rideId) =>
      _rides.doc(rideId).snapshots().map((d) => Ride.fromDoc(d));

  /// Einfache Suche: Fahrten, die noch offen sind und ungefähr im
  /// gewünschten Zeitfenster ankommen. Für eine echte geografische Suche
  /// (Umkreis um Start/Ziel) empfiehlt sich später z.B. Geoflutterfire /
  /// eine Cloud Function mit TomTom-Distanzberechnung.
  Stream<List<Ride>> searchRides({
    DateTime? earliestDeparture,
    DateTime? latestArrival,
  }) {
    Query<Map<String, dynamic>> query =
        _rides.where('status', isEqualTo: RideStatus.open.name);

    if (earliestDeparture != null) {
      query = query.where(
        'departureTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(earliestDeparture),
      );
    }
    if (latestArrival != null) {
      query = query.where(
        'desiredArrivalTime',
        isLessThanOrEqualTo: Timestamp.fromDate(latestArrival),
      );
    }

    return query.orderBy('departureTime').snapshots().map(
          (snap) => snap.docs.map(Ride.fromDoc).toList(),
        );
  }

  Stream<List<Ride>> watchDriverRides(String driverId) => _rides
      .where('driverId', isEqualTo: driverId)
      .orderBy('departureTime', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Ride.fromDoc).toList());

  Future<void> updateRideStatus(String rideId, RideStatus status) =>
      _rides.doc(rideId).update({'status': status.name});

  // --- Ride Requests (Mitfahr-Anfragen) ---

  CollectionReference<Map<String, dynamic>> _requestsOf(String rideId) =>
      _rides.doc(rideId).collection(AppConstants.rideRequestsSubcollection);

  Future<String> requestToJoin(String rideId, RideRequest request) async {
    final doc = await _requestsOf(rideId).add(request.toMap());
    return doc.id;
  }

  Stream<List<RideRequest>> watchRequests(String rideId) => _requestsOf(rideId)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(RideRequest.fromDoc).toList());

  /// Fahrer bestätigt/lehnt ab, optional mit berechnetem Umweg & Tarif
  /// (z.B. per Cloud Function anhand der TomTom Routing-API ermittelt).
  Future<void> respondToRequest(
    String rideId,
    String requestId, {
    required RideRequestStatus status,
    double? detourKm,
    double? estimatedFare,
  }) {
    final changes = <String, dynamic>{'status': status.name};
    if (detourKm != null) changes['detourKm'] = detourKm;
    if (estimatedFare != null) changes['estimatedFare'] = estimatedFare;
    return _requestsOf(rideId).doc(requestId).update(changes);
  }
}
