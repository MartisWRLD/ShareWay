import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../domain/rating.dart';

/// Zeigt einen Dialog, in dem der Mitfahrer den Fahrer nach Abschluss
/// einer Fahrt bewerten kann. Aufruf z.B. vom RideDetailsScreen, sobald
/// `ride.status == RideStatus.completed`.
Future<void> showRatingDialog(
  BuildContext context,
  WidgetRef ref, {
  required String rideId,
  required String driverId,
  required String riderId,
}) async {
  double stars = 5;
  final commentCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Fahrer bewerten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (ctx, setState) => RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              itemSize: 36,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (v) => setState(() => stars = v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: commentCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Kommentar (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () async {
            await ref.read(ratingRepositoryProvider).submitRating(Rating(
                  id: const Uuid().v4(),
                  rideId: rideId,
                  driverId: driverId,
                  riderId: riderId,
                  stars: stars,
                  comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Bewertung senden'),
        ),
      ],
    ),
  );
}
