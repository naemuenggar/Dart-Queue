import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/services/mock_seeder.dart';

/// Halaman dev-only untuk seed/reset mock data.
/// Hanya muncul saat `kDebugMode == true`.
class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  late final MockSeeder _seeder;
  bool _busy = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _seeder = MockSeeder(FirebaseFirestore.instance);
  }

  Future<void> _run(String label, Future<String> Function() task) async {
    setState(() {
      _busy = true;
      _log = '⏳ $label...';
    });
    try {
      final result = await task();
      if (!mounted) return;
      setState(() => _log = '✅ $result');
    } catch (e) {
      if (!mounted) return;
      setState(() => _log = '❌ Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Dev tools hanya tersedia di debug mode.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tools ini menulis langsung ke Firestore. '
                        'Pastikan kamu di project dev/staging, bukan production.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                        'Seeding 12 mock tickets',
                        () async {
                          final n = await _seeder.seedMockTickets();
                          return 'Seeded $n tickets + counters + settings.';
                        },
                      ),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Seed Mock Tickets (12)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                        'Resetting & re-seeding',
                        () async {
                          final deleted = await _seeder.resetQueues();
                          final n = await _seeder.seedMockTickets();
                          return 'Deleted $deleted, seeded $n tickets.';
                        },
                      ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset & Re-Seed'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _busy
                  ? null
                  : () => _run(
                        'Deleting all tickets',
                        () async {
                          final n = await _seeder.resetQueues();
                          return 'Deleted $n tickets.';
                        },
                      ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete All Tickets'),
            ),
            const SizedBox(height: 24),
            if (_log.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_log),
                ),
              ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
