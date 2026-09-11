import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

/// Ein geografischer Punkt mit lesbarer Adresse (aus TomTom Geocoding).
class GeoPoint2 {
  final double lat;
  final double lng;
  final String address;

  const GeoPoint2({required this.lat, required this.lng, required this.address});

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'address': address};

  factory GeoPoint2.fromMap(Map<String, dynamic> map) => GeoPoint2(
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        address: map['address'] ?? '',
      );
}

/// Eine vom Fahrer angebotene Fahrt.
class Ride {
  final String id;
  final String driverId;
  final GeoPoint2 origin;
  final GeoPoint2 destination;
  final DateTime departureTime;
  final DateTime desiredArrivalTime;
  final int availableSeats;
  final List<String> requirements; // z.B. "Nichtraucher", "Kein Gepäck"
  final RideStatus status;
  final DateTime createdAt;

  const Ride({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.desiredArrivalTime,
    required this.availableSeats,
    this.requirements = const [],
    this.status = RideStatus.open,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'origin': origin.toMap(),
        'destination': destination.toMap(),
        'departureTime': Timestamp.fromDate(departureTime),
        'desiredArrivalTime': Timestamp.fromDate(desiredArrivalTime),
        'availableSeats': availableSeats,
        'requirements': requirements,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Ride.fromMap(String id, Map<String, dynamic> map) => Ride(
        id: id,
        driverId: map['driverId'] ?? '',
        origin: GeoPoint2.fromMap(Map<String, dynamic>.from(map['origin'])),
        destination:
            GeoPoint2.fromMap(Map<String, dynamic>.from(map['destination'])),
        departureTime: (map['departureTime'] as Timestamp).toDate(),
        desiredArrivalTime: (map['desiredArrivalTime'] as Timestamp).toDate(),
        availableSeats: map['availableSeats'] ?? 0,
        requirements: List<String>.from(map['requirements'] ?? const []),
        status: RideStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => RideStatus.open,
        ),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory Ride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Ride.fromMap(doc.id, doc.data()!);
}

/// Anfrage eines Mitfahrers für eine bestimmte Fahrt.
///
/// Enthält den vom Mitfahrer gewünschten Abhol- und Zielort, damit der
/// Fahrer beurteilen kann, ob der Umweg akzeptabel ist – und damit der
/// Tarif (Grundstrecke vs. Umweg-Zuschlag) berechnet werden kann.
class RideRequest {
  final String id;
  final String riderId;
  final GeoPoint2 pickup;
  final GeoPoint2 dropoff;
  final RideRequestStatus status;

  /// Zusätzliche Kilometer, die der Fahrer NUR wegen dieses Mitfahrers
  /// fährt (Abholung + Umweg zum Ziel). Wird bei "accepted" gesetzt,
  /// z.B. über eine Cloud Function anhand der TomTom Routing-API.
  final double? detourKm;
  final double? estimatedFare;
  final DateTime createdAt;

  const RideRequest({
    required this.id,
    required this.riderId,
    required this.pickup,
    required this.dropoff,
    this.status = RideRequestStatus.pending,
    this.detourKm,
    this.estimatedFare,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'riderId': riderId,
        'pickup': pickup.toMap(),
        'dropoff': dropoff.toMap(),
        'status': status.name,
        'detourKm': detourKm,
        'estimatedFare': estimatedFare,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory RideRequest.fromMap(String id, Map<String, dynamic> map) =>
      RideRequest(
        id: id,
        riderId: map['riderId'] ?? '',
        pickup: GeoPoint2.fromMap(Map<String, dynamic>.from(map['pickup'])),
        dropoff: GeoPoint2.fromMap(Map<String, dynamic>.from(map['dropoff'])),
        status: RideRequestStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => RideRequestStatus.pending,
        ),
        detourKm: (map['detourKm'] as num?)?.toDouble(),
        estimatedFare: (map['estimatedFare'] as num?)?.toDouble(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory RideRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RideRequest.fromMap(doc.id, doc.data()!);
}
