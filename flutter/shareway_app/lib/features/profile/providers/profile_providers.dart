import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../domain/user_profile.dart';

/// Beobachtet ein beliebiges Profil anhand der uid (z.B. das eines Fahrers
/// auf der Fahrtdetailseite) – nicht zu verwechseln mit
/// [currentUserProfileProvider], das das eigene Profil liefert.
final profileByIdProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});
