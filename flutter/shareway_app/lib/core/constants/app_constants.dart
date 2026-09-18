/// Zentrale, projektweite Konstanten.
class AppConstants {
  AppConstants._();

  // --- TomTom API ---
  // TODO: Eigenen TomTom API-Key eintragen (https://developer.tomtom.com/)
  // Aus Sicherheitsgründen NICHT hart codieren, sondern über --dart-define
  // oder eine .env-Datei injizieren, z.B.:
  //   flutter run --dart-define=TOMTOM_API_KEY=xxxxx
  static const String tomTomApiKey = String.fromEnvironment(
    'TOMTOM_API_KEY',
    defaultValue: '',
  );

  static const String tomTomTileUrl =
      'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png'
      '?key=$tomTomApiKey';

  static const String tomTomSearchBaseUrl =
      'https://api.tomtom.com/search/2/geocode';
  static const String tomTomRoutingBaseUrl =
      'https://api.tomtom.com/routing/1/calculateRoute';

  // --- Firestore Collections ---
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  static const String rideRequestsSubcollection = 'requests';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String ratingsCollection = 'ratings';

  // --- Realtime Database Pfade (Live-Tracking) ---
  static const String trackingPath = 'tracking'; // /tracking/{rideId}/{userId}

  // --- Business-Regeln ---
  /// Aufpreis pro Kilometer, der ausschließlich für den Umweg zum Mitfahrer
  /// (Abholung + zusätzliche Strecke zum Ziel) gefahren wird.
  static const double detourSurchargePerKm = 0.35; // €/km, konfigurierbar
  static const double baseFarePerKm = 0.20; // €/km für die "Ohnehin-Strecke"

  /// Wie oft (in Sekunden) die Position während des Trackings aktualisiert wird.
  static const int trackingUpdateIntervalSeconds = 5;
}

enum UserRole { driver, rider }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.driver => 'Fahrer',
        UserRole.rider => 'Mitfahrer',
      };
}

enum RideStatus { open, full, ongoing, completed, cancelled }

enum RideRequestStatus { pending, accepted, declined, cancelled }
