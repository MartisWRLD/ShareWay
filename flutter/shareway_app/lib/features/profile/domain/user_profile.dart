import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

/// Fahrzeugdaten – nur für Fahrer relevant.
class VehicleInfo {
  final String make; // Marke, z.B. "VW"
  final String model; // Modell, z.B. "Golf"
  final String color;
  final int seatsAvailable;
  final String? licensePlate;
  final List<String> features; // z.B. "Klimaanlage", "Nichtraucher", "Hund erlaubt"

  const VehicleInfo({
    required this.make,
    required this.model,
    required this.color,
    required this.seatsAvailable,
    this.licensePlate,
    this.features = const [],
  });

  Map<String, dynamic> toMap() => {
        'make': make,
        'model': model,
        'color': color,
        'seatsAvailable': seatsAvailable,
        'licensePlate': licensePlate,
        'features': features,
      };

  factory VehicleInfo.fromMap(Map<String, dynamic> map) => VehicleInfo(
        make: map['make'] ?? '',
        model: map['model'] ?? '',
        color: map['color'] ?? '',
        seatsAvailable: map['seatsAvailable'] ?? 1,
        licensePlate: map['licensePlate'],
        features: List<String>.from(map['features'] ?? const []),
      );
}

/// Gemeinsames + rollenspezifisches Nutzerprofil.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? bio;
  final UserRole role;
  final VehicleInfo? vehicle; // nur gesetzt wenn role == driver
  final double averageRating; // aggregiert, nur für Fahrer relevant
  final int ratingCount;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.bio,
    this.vehicle,
    this.averageRating = 0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  bool get isDriver => role == UserRole.driver;

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    VehicleInfo? vehicle,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      vehicle: vehicle ?? this.vehicle,
      averageRating: averageRating,
      ratingCount: ratingCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'bio': bio,
        'role': role.name,
        'vehicle': vehicle?.toMap(),
        'averageRating': averageRating,
        'ratingCount': ratingCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        displayName: map['displayName'] ?? '',
        email: map['email'] ?? '',
        photoUrl: map['photoUrl'],
        bio: map['bio'],
        role: UserRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => UserRole.rider,
        ),
        vehicle: map['vehicle'] != null
            ? VehicleInfo.fromMap(Map<String, dynamic>.from(map['vehicle']))
            : null,
        averageRating: (map['averageRating'] ?? 0).toDouble(),
        ratingCount: map['ratingCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserProfile.fromMap({...doc.data()!, 'uid': doc.id});
}
