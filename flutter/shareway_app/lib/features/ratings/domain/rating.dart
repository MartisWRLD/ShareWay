import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String rideId;
  final String driverId;
  final String riderId;
  final double stars; // 1.0 – 5.0
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.riderId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'rideId': rideId,
        'driverId': driverId,
        'riderId': riderId,
        'stars': stars,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Rating.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Rating(
      id: doc.id,
      rideId: map['rideId'] ?? '',
      driverId: map['driverId'] ?? '',
      riderId: map['riderId'] ?? '',
      stars: (map['stars'] as num).toDouble(),
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
