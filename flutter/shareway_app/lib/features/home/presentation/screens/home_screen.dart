import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../rides/providers/ride_providers.dart';
import '../widgets/ride_map_widget.dart';
import '../widgets/ride_search_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(searchedRidesProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isDriver = profile?.role == UserRole.driver;

    return Scaffold(
      body: Stack(
        children: [
          ridesAsync.when(
            data: (rides) => RideMapWidget(
              rides: rides,
              onRideTap: (ride) => context.push(AppRoutes.rideDetailsPath(ride.id)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler beim Laden der Fahrten: $e')),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RideSearchBar(
                onSearch: (query) =>
                    ref.read(rideSearchQueryProvider.notifier).state = query,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isDriver
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createRide),
              icon: const Icon(Icons.add),
              label: const Text('Fahrt anbieten'),
            )
          : null,
    );
  }
}
