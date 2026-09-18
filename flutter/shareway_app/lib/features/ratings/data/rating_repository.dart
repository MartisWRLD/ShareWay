import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/rating.dart';

class RatingRepository {
  RatingRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection(AppConstants.ratingsCollection);

  Stream<List<Rating>> watchRatingsForDriver(String driverId) => _ratings
      .where('driverId', isEqualTo: driverId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Rating.fromDoc).toList());

  /// Legt die Bewertung an und aktualisiert den aggregierten Schnitt im
  /// Fahrerprofil transaktional, damit Anzeige (averageRating/ratingCount)
  /// immer konsistent bleibt.
  Future<void> submitRating(Rating rating) async {
    final userRef =
        _firestore.collection(AppConstants.usersCollection).doc(rating.driverId);
    final ratingRef = _ratings.doc();

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final data = userSnap.data() ?? {};
      final currentAvg = (data['averageRating'] ?? 0).toDouble();
      final currentCount = (data['ratingCount'] ?? 0) as int;

      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating.stars) / newCount;

      tx.set(ratingRef, rating.toMap());
      tx.update(userRef, {
        'averageRating': newAvg,
        'ratingCount': newCount,
      });
    });
  }
}
