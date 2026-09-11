import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../profile/domain/user_profile.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _saving = false;

  Future<void> _chooseRole(UserRole role) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? 'Neue*r Nutzer*in',
      email: user.email ?? '',
      role: role,
      createdAt: DateTime.now(),
    );
    await ref.read(profileRepositoryProvider).createProfile(profile);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Wie möchtest du ShareWay nutzen?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Du kannst dein Profil später jederzeit anpassen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_saving)
                const CircularProgressIndicator()
              else ...[
                _RoleCard(
                  icon: Icons.directions_car,
                  title: 'Ich bin Fahrer*in',
                  subtitle: 'Fahrten anbieten und Mitfahrer mitnehmen',
                  onTap: () => _chooseRole(UserRole.driver),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.emoji_people,
                  title: 'Ich bin Mitfahrer*in',
                  subtitle: 'Fahrten finden und mitfahren',
                  onTap: () => _chooseRole(UserRole.rider),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
