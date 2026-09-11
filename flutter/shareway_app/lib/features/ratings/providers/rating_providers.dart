import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../domain/rating.dart';

final driverRatingsProvider =
    StreamProvider.family<List<Rating>, String>((ref, driverId) {
  return ref.watch(ratingRepositoryProvider).watchRatingsForDriver(driverId);
});
