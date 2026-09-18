import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/ride.dart';

/// Fahrer legt eine neue Fahrt an: Start, Ziel und den gewünschten
/// Ankunftszeitpunkt (siehe Ablaufbeschreibung: der Fahrer nennt seinen
/// gewünschten Ankunftszeitpunkt, nicht primär die Abfahrtszeit).
class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '3');
  DateTime? _departureTime;
  DateTime? _desiredArrivalTime;
  final Set<String> _requirements = {};
  bool _saving = false;

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context, initialDate: now, firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isDeparture ? _departureTime = result : _desiredArrivalTime = result);
  }

  Future<void> _submit() async {
    if (_originCtrl.text.trim().isEmpty ||
        _destinationCtrl.text.trim().isEmpty ||
        _desiredArrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Start, Ziel und Ankunftszeit angeben.')),
      );
      return;
    }
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _saving = true);

    // Hinweis: In einer echten Implementierung würden Start/Ziel per
    // TomTomService.searchAddress() in echte Koordinaten aufgelöst
    // (Autovervollständigung). Hier als einfacher Platzhalter mit lat/lng 0.
    final ride = Ride(
      id: '',
      driverId: profile.uid,
      origin: GeoPoint2(lat: 0, lng: 0, address: _originCtrl.text.trim()),
      destination: GeoPoint2(lat: 0, lng: 0, address: _destinationCtrl.text.trim()),
      departureTime: _departureTime ?? _desiredArrivalTime!.subtract(const Duration(hours: 1)),
      desiredArrivalTime: _desiredArrivalTime!,
      availableSeats: int.tryParse(_seatsCtrl.text) ?? 1,
      requirements: _requirements.toList(),
      createdAt: DateTime.now(),
    );

    final rideId = await ref.read(rideRepositoryProvider).createRide(ride);
    if (mounted) context.pushReplacement(AppRoutes.rideDetailsPath(rideId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fahrt anbieten')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _originCtrl,
            decoration: const InputDecoration(labelText: 'Abfahrtsort', prefixIcon: Icon(Icons.trip_origin)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(labelText: 'Zielort', prefixIcon: Icon(Icons.place_outlined)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                onPressed: () => _pickDateTime(isDeparture: true),
                label: Text(_departureTime?.toString() ?? 'Abfahrtszeit (optional)'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.flag),
                onPressed: () => _pickDateTime(isDeparture: false),
                label: Text(_desiredArrivalTime?.toString() ?? 'Gewünschte Ankunftszeit *'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _seatsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Freie Plätze'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: const ['Nichtraucher', 'Kein Gepäck', 'Haustiere erlaubt', 'Klimaanlage']
                .map((r) {
              final selected = _requirements.contains(r);
              return FilterChip(
                label: Text(r),
                selected: selected,
                onSelected: (v) => setState(() => v ? _requirements.add(r) : _requirements.remove(r)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Fahrt veröffentlichen'),
          ),
        ],
      ),
    );
  }
}
