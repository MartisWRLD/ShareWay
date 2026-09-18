/// Ein einzelner Positions-Update während einer laufenden Fahrt.
/// Wird in der Firebase Realtime Database unter
/// `tracking/{rideId}/{userId}` gespeichert (niedrige Latenz, günstig für
/// häufige Schreibzugriffe – im Gegensatz zu Firestore).
class LocationPoint {
  final double lat;
  final double lng;
  final double? heading; // Blickrichtung in Grad, für Richtungspfeil auf Karte
  final int timestamp; // Millisekunden seit Epoch

  const LocationPoint({
    required this.lat,
    required this.lng,
    this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'timestamp': timestamp,
      };

  factory LocationPoint.fromMap(Map<dynamic, dynamic> map) => LocationPoint(
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        timestamp: map['timestamp'] as int,
      );
}
