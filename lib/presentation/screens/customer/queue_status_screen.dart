import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../data/models/queue_ticket.dart';
import '../../../data/repositories/queue_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/queue_ticket_card.dart';

class QueueStatusScreen extends StatefulWidget {
  final String ticketId;
  const QueueStatusScreen({super.key, required this.ticketId});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  int? _lastNotifiedAhead;
  QueueStatus? _lastStatus;

  void _checkProactiveNotif(QueueTicket ticket, int ahead) {
    // Notif lokal saat semakin dekat (mis. 3 nomor lagi)
    if (ahead == AppConstants.notifyBeforeNumbers &&
        _lastNotifiedAhead != ahead) {
      _lastNotifiedAhead = ahead;
      NotificationService.instance.showLocal(
        title: 'Sebentar lagi giliran Anda',
        body:
            'Tinggal $ahead antrian sebelum nomor ${ticket.displayNumber} dipanggil.',
      );
    }

    // Notif lokal saat status berubah ke called (fallback kalau FCM telat)
    if (ticket.status == QueueStatus.called && _lastStatus != QueueStatus.called) {
      NotificationService.instance.showLocal(
        title: 'Giliran Anda!',
        body:
            'Nomor ${ticket.displayNumber} dipanggil. Silakan menuju ${ticket.counterId ?? "loket"}.',
      );
    }
    _lastStatus = ticket.status;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QueueRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Status Antrian')),
      body: StreamBuilder<QueueTicket?>(
        stream: repo.watchTicket(widget.ticketId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ticket = snap.data;
          if (ticket == null) {
            return const Center(child: Text('Tiket tidak ditemukan.'));
          }

          return StreamBuilder<int>(
            stream: repo.watchAheadCount(ticket),
            builder: (context, aheadSnap) {
              final ahead = aheadSnap.data ?? 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkProactiveNotif(ticket, ahead);
              });

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    QueueTicketCard(ticket: ticket, aheadCount: ahead),
                    const SizedBox(height: 16),
                    if (ticket.status == QueueStatus.done ||
                        ticket.status == QueueStatus.skipped)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Selesai'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
