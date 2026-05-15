import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/queue_repository.dart';
import '../../../data/services/notification_service.dart';
import 'queue_status_screen.dart';

/// Halaman target deeplink dari QR meja: `restoqueue://take?meja=5`.
/// Nomor meja sudah auto-terisi, tinggal konfirmasi.
class TakeTicketScreen extends StatefulWidget {
  final String? prefilledTable;
  const TakeTicketScreen({super.key, this.prefilledTable});

  @override
  State<TakeTicketScreen> createState() => _TakeTicketScreenState();
}

class _TakeTicketScreenState extends State<TakeTicketScreen> {
  final _nameCtrl = TextEditingController();
  late final TextEditingController _tableCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tableCtrl = TextEditingController(text: widget.prefilledTable ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tableCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final table = _tableCtrl.text.trim();
    if (table.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor meja wajib diisi.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = context.read<QueueRepository>();
      final token = await NotificationService.instance.getToken();
      final ticket = await repo.takeTicket(
        customerName: _nameCtrl.text.trim().isEmpty
            ? null
            : _nameCtrl.text.trim(),
        tableNumber: table,
        fcmToken: token,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QueueStatusScreen(ticketId: ticket.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil antrian: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrefill = widget.prefilledTable != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPrefill)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda di Meja ${widget.prefilledTable}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableCtrl,
              enabled: !hasPrefill,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.table_restaurant_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.confirmation_number_outlined),
              label: const Text('Ambil Antrian'),
            ),
          ],
        ),
      ),
    );
  }
}
