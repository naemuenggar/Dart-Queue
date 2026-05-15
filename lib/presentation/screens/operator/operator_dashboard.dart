import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../data/models/counter.dart';
import '../../../data/models/queue_ticket.dart';
import '../../../data/repositories/queue_repository.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  String? _selectedCounterId;

  @override
  void initState() {
    super.initState();
    // Pastikan loket default ada
    context.read<QueueRepository>().ensureDefaultCounters();
  }

  Future<void> _callNext(QueueRepository repo) async {
    if (_selectedCounterId == null) return;
    final ticket = await repo.callNext(counterId: _selectedCounterId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ticket == null
            ? 'Tidak ada antrian menunggu.'
            : 'Memanggil ${ticket.displayNumber}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QueueRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Operator'),
        actions: [
          IconButton(
            tooltip: 'Scan QR Tiket',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () =>
                Navigator.of(context).pushNamed('/operator/scan'),
          ),
          IconButton(
            tooltip: 'QR Meja',
            icon: const Icon(Icons.table_restaurant_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/admin/qr'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Counter selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<Counter>>(
              stream: repo.watchCounters(),
              builder: (context, snap) {
                final counters = snap.data ?? const [];
                _selectedCounterId ??=
                    counters.where((c) => c.isActive).map((c) => c.id).firstOrNull ??
                        counters.map((c) => c.id).firstOrNull;
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCounterId,
                        decoration: const InputDecoration(
                          labelText: 'Loket Aktif',
                          border: OutlineInputBorder(),
                        ),
                        items: counters
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                      '${c.name}${c.isActive ? "" : " (off)"}'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCounterId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _selectedCounterId == null
                          ? null
                          : () => _callNext(repo),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Panggil'),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Active queue list
          Expanded(
            child: StreamBuilder<List<QueueTicket>>(
              stream: repo.watchActiveQueues(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = snap.data!;
                if (tickets.isEmpty) {
                  return const Center(child: Text('Belum ada antrian.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _TicketTile(ticket: tickets[i], repo: repo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final QueueTicket ticket;
  final QueueRepository repo;
  const _TicketTile({required this.ticket, required this.repo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            ticket.displayNumber,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(ticket.customerName ?? 'Tamu'),
        subtitle: Text(ticket.status.label),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'serve':
                await repo.markServing(ticket.id);
                break;
              case 'done':
                await repo.markDone(ticket.id);
                break;
              case 'skip':
                await repo.skipTicket(ticket.id);
                break;
            }
          },
          itemBuilder: (_) => [
            if (ticket.status == QueueStatus.called)
              const PopupMenuItem(value: 'serve', child: Text('Mulai Layani')),
            if (ticket.status == QueueStatus.serving ||
                ticket.status == QueueStatus.called)
              const PopupMenuItem(value: 'done', child: Text('Tandai Selesai')),
            const PopupMenuItem(value: 'skip', child: Text('Lewati')),
          ],
        ),
      ),
    );
  }
}
