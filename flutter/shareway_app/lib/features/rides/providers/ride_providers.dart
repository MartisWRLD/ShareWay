import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../home/presentation/widgets/ride_search_bar.dart';
import '../domain/ride.dart';

/// Aktuell aktive Suchanfrage von der Homescreen-Suchleiste.
final rideSearchQueryProvider = StateProvider<RideSearchQuery?>((ref) => null);

/// Fahrten passend zur aktuellen Suche (bzw. alle offenen Fahrten,
/// solange noch nicht gesucht wurde).
final searchedRidesProvider = StreamProvider<List<Ride>>((ref) {
  final query = ref.watch(rideSearchQueryProvider);
  final repo = ref.watch(rideRepositoryProvider);

  return repo.searchRides(
    earliestDeparture: query?.departureTime,
    latestArrival: query?.arrivalTime,
  );
});

/// Fahrten, die der aktuell eingeloggte Fahrer selbst angeboten hat.
final myRidesAsDriverProvider = StreamProvider<List<Ride>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return const Stream.empty();
  return ref.watch(rideRepositoryProvider).watchDriverRides(profile.uid);
});
