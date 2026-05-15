import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/deeplink.dart';

/// Generator QR meja untuk admin/owner. Tampilkan grid QR yang siap di-screenshot
/// atau di-print sebagai sticker meja.
class TableQrScreen extends StatefulWidget {
  const TableQrScreen({super.key});

  @override
  State<TableQrScreen> createState() => _TableQrScreenState();
}

class _TableQrScreenState extends State<TableQrScreen> {
  final _countCtrl = TextEditingController(text: '10');
  int _tables = 10;

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final n = int.tryParse(_countCtrl.text) ?? 10;
    setState(() => _tables = n.clamp(1, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Meja')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Meja',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                    onPressed: _generate, child: const Text('Generate')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _tables,
              itemBuilder: (context, i) => _TableQrCard(tableNumber: '${i + 1}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableQrCard extends StatelessWidget {
  final String tableNumber;
  const _TableQrCard({required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    final url = DeepLink.tableUrl(tableNumber, useHttps: true);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Meja $tableNumber',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: QrImageView(
                  data: url,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan untuk antri',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
