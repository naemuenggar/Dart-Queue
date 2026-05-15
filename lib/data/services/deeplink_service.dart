import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../core/deeplink.dart';
import '../../presentation/screens/customer/queue_status_screen.dart';
import '../../presentation/screens/customer/take_ticket_screen.dart';

/// Listener untuk deeplink (QR meja & QR tiket) baik saat app cold-start
/// maupun saat app sudah jalan (resume).
class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Pasang ke `MaterialApp` lewat property `navigatorKey`.
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    // Cold-start link
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    // Stream link saat app running
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void dispose() => _sub?.cancel();

  void _handle(Uri uri) {
    final action = DeepLink.parse(uri.toString());
    if (action == null) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (action) {
      case TakeTicketAction(:final table):
        nav.push(MaterialPageRoute(
          builder: (_) => TakeTicketScreen(prefilledTable: table),
        ));
      case OpenTicketAction(:final ticketId):
        nav.push(MaterialPageRoute(
          builder: (_) => QueueStatusScreen(ticketId: ticketId),
        ));
    }
  }
}
