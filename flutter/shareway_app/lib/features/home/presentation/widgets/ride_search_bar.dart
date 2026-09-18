import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ergebnis der Suchleisten-Eingabe, das an die Fahrtsuche übergeben wird.
class RideSearchQuery {
  final String origin;
  final String destination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final List<String> requirements;

  const RideSearchQuery({
    required this.origin,
    required this.destination,
    this.departureTime,
    this.arrivalTime,
    this.requirements = const [],
  });
}

const _availableRequirements = [
  'Nichtraucher',
  'Kein Gepäck',
  'Haustiere erlaubt',
  'Klimaanlage',
  'Nur Frauen',
];

/// Benutzerfreundliche Suchleiste auf dem Homescreen: Start, Ziel,
/// gewünschte Abfahrts-/Ankunftszeit und Voraussetzungen an die Fahrt.
class RideSearchBar extends StatefulWidget {
  const RideSearchBar({super.key, required this.onSearch});
  final ValueChanged<RideSearchQuery> onSearch;

  @override
  State<RideSearchBar> createState() => _RideSearchBarState();
}

class _RideSearchBarState extends State<RideSearchBar> {
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  DateTime? _departureTime;
  DateTime? _arrivalTime;
  final Set<String> _requirements = {};
  bool _expanded = false;

  final _timeFormat = DateFormat('EEE, dd.MM. HH:mm', 'de_DE');

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isDeparture) {
        _departureTime = result;
      } else {
        _arrivalTime = result;
      }
    });
  }

  void _submit() {
    widget.onSearch(RideSearchQuery(
      origin: _originCtrl.text.trim(),
      destination: _destinationCtrl.text.trim(),
      departureTime: _departureTime,
      arrivalTime: _arrivalTime,
      requirements: _requirements.toList(),
    ));
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _originCtrl,
              decoration: const InputDecoration(
                labelText: 'Von',
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                labelText: 'Nach',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 18),
                    onPressed: () => _pickDateTime(isDeparture: true),
                    label: Text(
                      _departureTime == null ? 'Abfahrt' : _timeFormat.format(_departureTime!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    onPressed: () => _pickDateTime(isDeparture: false),
                    label: Text(
                      _arrivalTime == null ? 'Ankunft' : _timeFormat.format(_arrivalTime!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableRequirements.map((req) {
                    final selected = _requirements.contains(req);
                    return FilterChip(
                      label: Text(req),
                      selected: selected,
                      onSelected: (v) => setState(
                        () => v ? _requirements.add(req) : _requirements.remove(req),
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.tune),
                  label: Text(_expanded ? 'Weniger' : 'Voraussetzungen'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.search),
                  label: const Text('Suchen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
