import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Kein Profil gefunden.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                  child: profile.photoUrl == null
                      ? Text(profile.displayName.isNotEmpty
                          ? profile.displayName.substring(0, 1).toUpperCase()
                          : '?')
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(profile.displayName, style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(
                child: Chip(label: Text(profile.role.label)),
              ),
              if (profile.role == UserRole.driver) ...[
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(profile.ratingCount == 0
                          ? 'Noch keine Bewertungen'
                          : '${profile.averageRating.toStringAsFixed(1)} '
                            '(${profile.ratingCount} Bewertungen)'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                Text('Über mich', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(profile.bio!),
                const SizedBox(height: 24),
              ],
              if (profile.role == UserRole.driver && profile.vehicle != null) ...[
                Text('Fahrzeug', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car_filled_outlined),
                    title: Text('${profile.vehicle!.make} ${profile.vehicle!.model}'),
                    subtitle: Text(
                      '${profile.vehicle!.color} · ${profile.vehicle!.seatsAvailable} freie Plätze',
                    ),
                  ),
                ),
                if (profile.vehicle!.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: profile.vehicle!.features
                        .map((f) => Chip(label: Text(f)))
                        .toList(),
                  ),
                ],
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}
