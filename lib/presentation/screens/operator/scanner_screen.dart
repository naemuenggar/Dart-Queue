import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/deeplink.dart';
import '../../../data/models/queue_ticket.dart';
import '../../../data/repositories/queue_repository.dart';

/// Scanner QR untuk operator. Bisa scan QR di tiket customer untuk
/// langsung tahu detail tiket & tindakannya.
class OperatorScannerScreen extends StatefulWidget {
  const OperatorScannerScreen({super.key});

  @override
  State<OperatorScannerScreen> createState() => _OperatorScannerScreenState();
}

class _OperatorScannerScreenState extends State<OperatorScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final action = DeepLink.parse(raw);
    if (action is! OpenTicketAction) {
      _showSnack('QR tidak dikenali.');
      return;
    }

    _handling = true;
    await _controller.stop();

    if (!mounted) return;
    final repo = context.read<QueueRepository>();
    final ticket = await repo.getTicketOnce(action.ticketId);
    if (!mounted) return;

    if (ticket == null) {
      _showSnack('Tiket tidak ditemukan.');
      _handling = false;
      await _controller.start();
      return;
    }

    final result = await _showActionSheet(ticket);
    if (!mounted) return;

    switch (result) {
      case 'serve':
        await repo.markServing(ticket.id);
        if (mounted) _showSnack('Mulai melayani ${ticket.displayNumber}');
        break;
      case 'done':
        await repo.markDone(ticket.id);
        if (mounted) _showSnack('${ticket.displayNumber} selesai dilayani');
        break;
    }
    _handling = false;
    await _controller.start();
  }

  Future<String?> _showActionSheet(QueueTicket ticket) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => _TicketActionSheet(
        title: ticket.displayNumber,
        subtitle:
            '${ticket.customerName ?? "Tamu"} • Meja ${ticket.tableNumber ?? "-"}',
        status: ticket.status.label,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Overlay viewfinder
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketActionSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  const _TicketActionSheet({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Status: $status',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, 'serve'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Layani'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'done'),
              icon: const Icon(Icons.check),
              label: const Text('Tandai Selesai'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
