import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/queue_repository.dart';
import '../../../data/services/notification_service.dart';
import 'queue_status_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _takeTicket() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<QueueRepository>();
      final token = await NotificationService.instance.getToken();
      final ticket = await repo.takeTicket(
        customerName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        fcmToken: token,
      );
      if (!mounted) return;
      Navigator.of(context).push(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Selamat Datang')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.restaurant_menu,
                size: 96, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Ambil Nomor Antrian',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol di bawah untuk dapat nomor.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
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
              onPressed: _loading ? null : _takeTicket,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.confirmation_number_outlined),
              label: const Text('Ambil Antrian'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/operator');
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Mode Operator'),
            ),
            if (kDebugMode)
              TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/dev'),
                icon: const Icon(Icons.developer_mode),
                label: const Text('Dev Tools'),
              ),
          ],
        ),
      ),
    );
  }
}
