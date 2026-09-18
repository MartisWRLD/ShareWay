import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/ride.dart';

class RideRequestCard extends StatelessWidget {
  const RideRequestCard({
    super.key,
    required this.request,
    required this.riderName,
    this.onAccept,
    this.onDecline,
    this.onOpenChat,
  });

  final RideRequest request;
  final String riderName;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(riderName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Abholung: ${request.pickup.address}'),
            Text('Ziel: ${request.dropoff.address}'),
            if (request.detourKm != null) ...[
              const SizedBox(height: 4),
              Text(
                'Umweg: ${request.detourKm!.toStringAsFixed(1)} km'
                '${request.estimatedFare != null ? ' · ca. ${request.estimatedFare!.toStringAsFixed(2)} €' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (request.status == RideRequestStatus.pending && onAccept != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(onPressed: onDecline, child: const Text('Ablehnen')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: onAccept, child: const Text('Annehmen')),
                ],
              ),
            ],
            if (request.status == RideRequestStatus.accepted && onOpenChat != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat öffnen'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final RideRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RideRequestStatus.pending => ('Offen', Colors.orange),
      RideRequestStatus.accepted => ('Angenommen', Colors.green),
      RideRequestStatus.declined => ('Abgelehnt', Colors.red),
      RideRequestStatus.cancelled => ('Storniert', Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
