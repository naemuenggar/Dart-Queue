import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants.dart';
import '../../core/deeplink.dart';
import '../../data/models/queue_ticket.dart';

class QueueTicketCard extends StatelessWidget {
  final QueueTicket ticket;
  final int? aheadCount;
  const QueueTicketCard({super.key, required this.ticket, this.aheadCount});

  Color _statusColor(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    switch (ticket.status) {
      case QueueStatus.waiting:
        return c.secondaryContainer;
      case QueueStatus.called:
        return c.primary;
      case QueueStatus.serving:
        return c.tertiary;
      case QueueStatus.done:
        return Colors.green.shade400;
      case QueueStatus.skipped:
        return c.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final est = aheadCount != null
        ? aheadCount! * AppConstants.avgServiceMinutes
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Nomor Antrian Anda',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              ticket.displayNumber,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(context).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ticket.status.label,
                style: TextStyle(
                  color: _statusColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (ticket.status == QueueStatus.waiting) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    label: 'Di depan Anda',
                    value: aheadCount?.toString() ?? '-',
                  ),
                  _Stat(
                    label: 'Estimasi',
                    value: est != null ? '$est mnt' : '-',
                  ),
                ],
              ),
            ],
            if (ticket.status == QueueStatus.called) ...[
              const SizedBox(height: 16),
              Text(
                'Silakan menuju ${ticket.counterId ?? "loket"}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            // QR tiket — operator bisa scan untuk validasi cepat
            if (ticket.status == QueueStatus.waiting ||
                ticket.status == QueueStatus.called) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Tunjukkan QR ini ke operator',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SizedBox(
                width: 140,
                height: 140,
                child: QrImageView(
                  data: DeepLink.ticketUrl(ticket.id, useHttps: true),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
