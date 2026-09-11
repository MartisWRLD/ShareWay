import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../providers/tracking_providers.dart';

/// Zeigt während des Fahrtzeitraums die Position von Fahrer und Mitfahrer
/// gegenseitig auf einer Karte. Beide Seiten senden dabei kontinuierlich
/// ihre eigene Position (siehe [OwnLocationBroadcaster]) und sehen
/// gleichzeitig die Position der jeweils anderen Person.
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key, required this.rideId});
  final String rideId;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (myId == null) return;
      ref
          .read(ownLocationBroadcasterProvider((rideId: widget.rideId, userId: myId)))
          .start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authRepositoryProvider).currentUser?.uid;
    final ride = ref.watch(rideRepositoryProvider).watchRide(widget.rideId);

    return Scaffold(
      appBar: AppBar(title: const Text('Live-Tracking')),
      body: StreamBuilder(
        stream: ride,
        builder: (context, rideSnap) {
          if (!rideSnap.hasData) return const Center(child: CircularProgressIndicator());
          final r = rideSnap.data!;
          // Der "andere" Teilnehmer: Wenn ich der Fahrer bin, will ich den
          // Mitfahrer sehen (hier vereinfachend über die aktive Anfrage);
          // ansonsten sehe ich den Fahrer.
          final otherUserId = myId == r.driverId ? null : r.driverId;

          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(48.2082, 16.3738),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.tomTomTileUrl,
                    userAgentPackageName: 'com.example.shareway',
                  ),
                  if (myId != null)
                    Consumer(
                      builder: (context, ref, _) {
                        final myLoc = ref.watch(
                          trackedLocationProvider((rideId: widget.rideId, userId: myId)),
                        ).valueOrNull;
                        final otherLoc = otherUserId != null
                            ? ref.watch(
                                trackedLocationProvider(
                                  (rideId: widget.rideId, userId: otherUserId),
                                ),
                              ).valueOrNull
                            : null;

                        return MarkerLayer(markers: [
                          if (myLoc != null)
                            Marker(
                              point: LatLng(myLoc.lat, myLoc.lng),
                              child: const Icon(Icons.my_location, color: Colors.blue),
                            ),
                          if (otherLoc != null)
                            Marker(
                              point: LatLng(otherLoc.lat, otherLoc.lng),
                              child: const Icon(Icons.directions_car, color: Colors.deepOrange),
                            ),
                        ]);
                      },
                    ),
                ],
              ),
              const Positioned(
                left: 12, right: 12, top: 12,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Blau: deine Position · Orange: Fahrtpartner*in',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
