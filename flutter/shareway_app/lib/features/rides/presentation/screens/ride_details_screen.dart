import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../chat/domain/chat_message.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../domain/ride.dart';
import '../widgets/ride_request_card.dart';

class RideDetailsScreen extends ConsumerWidget {
  const RideDetailsScreen({super.key, required this.rideId});
  final String rideId;

  Future<void> _requestToJoin(BuildContext context, WidgetRef ref, String riderId) async {
    final pickupCtrl = TextEditingController();
    final dropoffCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mitfahren anfragen', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: pickupCtrl,
              decoration: const InputDecoration(labelText: 'Gewünschter Abholort'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dropoffCtrl,
              decoration: const InputDecoration(labelText: 'Gewünschter Zielort'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Anfrage senden'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || pickupCtrl.text.trim().isEmpty || dropoffCtrl.text.trim().isEmpty) {
      return;
    }

    // Hinweis: Adressen würden hier per TomTomService.searchAddress() in
    // echte Koordinaten aufgelöst; hier vereinfachte Platzhalter-Koordinaten.
    await ref.read(rideRepositoryProvider).requestToJoin(
      rideId,
      RideRequest(
        id: '',
        riderId: riderId,
        pickup: GeoPoint2(lat: 0, lng: 0, address: pickupCtrl.text.trim()),
        dropoff: GeoPoint2(lat: 0, lng: 0, address: dropoffCtrl.text.trim()),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Fahrer akzeptiert eine Anfrage. Umweg-Kilometer und Tarif würden hier
  /// über eine Cloud Function per TomTom Routing-API berechnet – siehe
  /// TomTomService.calculateRoute / TomTomService.calculateFare.
  Future<void> _acceptRequest(WidgetRef ref, RideRequest request) async {
    await ref.read(rideRepositoryProvider).respondToRequest(
      rideId, request.id,
      status: RideRequestStatus.accepted,
    );
  }

  Future<void> _declineRequest(WidgetRef ref, RideRequest request) async {
    await ref.read(rideRepositoryProvider).respondToRequest(
      rideId, request.id,
      status: RideRequestStatus.declined,
    );
  }

  Future<void> _openChat(
    BuildContext context, WidgetRef ref, String userAId, String userBId,
  ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final threadId = chatRepo.threadIdFor(rideId: rideId, userAId: userAId, userBId: userBId);
    await chatRepo.ensureThread(ChatThread(
      id: threadId, rideId: rideId, participantIds: [userAId, userBId],
    ));
    if (context.mounted) context.push(AppRoutes.chatThreadPath(threadId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(rideRepositoryProvider).watchRide(rideId);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final dateFormat = DateFormat('EEE, dd.MM.yyyy · HH:mm', 'de_DE');

    return Scaffold(
      appBar: AppBar(title: const Text('Fahrtdetails')),
      body: StreamBuilder<Ride>(
        stream: rideAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ride = snapshot.data!;
          final isDriver = profile?.uid == ride.driverId;
          final driverProfile = ref.watch(profileByIdProvider(ride.driverId)).valueOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.trip_origin, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ride.origin.address)),
                      ]),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(height: 20, child: VerticalDivider()),
                      ),
                      Row(children: [
                        const Icon(Icons.place, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ride.destination.address)),
                      ]),
                      const Divider(height: 24),
                      Text('Ankunft bis: ${dateFormat.format(ride.desiredArrivalTime)}'),
                      Text('${ride.availableSeats} freie Plätze'),
                      if (ride.requirements.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: ride.requirements.map((r) => Chip(label: Text(r))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (driverProfile != null)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: driverProfile.photoUrl != null
                          ? NetworkImage(driverProfile.photoUrl!)
                          : null,
                      child: driverProfile.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(driverProfile.displayName),
                    subtitle: driverProfile.ratingCount > 0
                        ? Text('★ ${driverProfile.averageRating.toStringAsFixed(1)} '
                            '(${driverProfile.ratingCount})')
                        : const Text('Noch keine Bewertungen'),
                    trailing: driverProfile.vehicle != null
                        ? Text('${driverProfile.vehicle!.make} ${driverProfile.vehicle!.model}')
                        : null,
                  ),
                ),
              const SizedBox(height: 16),
              if (ride.status == RideStatus.ongoing)
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.liveTrackingPath(rideId)),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Live-Standort ansehen'),
                ),
              const SizedBox(height: 16),
              if (isDriver) ...[
                Text('Anfragen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                StreamBuilder<List<RideRequest>>(
                  stream: ref.watch(rideRepositoryProvider).watchRequests(rideId),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? [];
                    if (requests.isEmpty) {
                      return const Text('Noch keine Anfragen.');
                    }
                    return Column(
                      children: requests.map((req) {
                        final riderProfile = ref.watch(profileByIdProvider(req.riderId)).valueOrNull;
                        return RideRequestCard(
                          request: req,
                          riderName: riderProfile?.displayName ?? 'Mitfahrer*in',
                          onAccept: () => _acceptRequest(ref, req),
                          onDecline: () => _declineRequest(ref, req),
                          onOpenChat: () => _openChat(context, ref, ride.driverId, req.riderId),
                        );
                      }).toList(),
                    );
                  },
                ),
              ] else if (profile != null) ...[
                FilledButton.icon(
                  onPressed: () => _requestToJoin(context, ref, profile.uid),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Mitfahren anfragen'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openChat(context, ref, ride.driverId, profile.uid),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Fahrer kontaktieren'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
