import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Read-only Sterne-Anzeige, z.B. auf dem Fahrer-Profil oder in der
/// Fahrtdetailansicht.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 18});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemCount: 5,
      itemSize: size,
      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
    );
  }
}
