/// Helper untuk encode/decode deeplink QR.
///
/// Format yang dipakai:
///   restoqueue://take?meja=5            → QR statik di meja
///   restoqueue://ticket?id=<ticketId>   → QR dinamis di tiket
///
/// Fallback https (kalau scan dari kamera bawaan HP yang gak kenal scheme):
///   https://restoqueue.app/take?meja=5
///   https://restoqueue.app/ticket?id=<ticketId>
class DeepLink {
  static const scheme = 'restoqueue';
  static const httpsHost = 'restoqueue.app';

  /// Build URL untuk QR statik di meja.
  static String tableUrl(String tableNumber, {bool useHttps = false}) {
    return useHttps
        ? 'https://$httpsHost/take?meja=$tableNumber'
        : '$scheme://take?meja=$tableNumber';
  }

  /// Build URL untuk QR di tiket customer.
  static String ticketUrl(String ticketId, {bool useHttps = false}) {
    return useHttps
        ? 'https://$httpsHost/ticket?id=$ticketId'
        : '$scheme://ticket?id=$ticketId';
  }

  /// Parse URL yang masuk. Return action+payload, atau null kalau bukan format kita.
  static DeepLinkAction? parse(String raw) {
    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return null;
    }
    final isOurs = uri.scheme == scheme || uri.host == httpsHost;
    if (!isOurs) return null;

    // Normalize: untuk custom scheme, host = "take" / "ticket"
    // untuk https, path = "/take" / "/ticket"
    final action = uri.scheme == scheme
        ? uri.host
        : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');

    switch (action) {
      case 'take':
        return DeepLinkAction.takeTicket(table: uri.queryParameters['meja']);
      case 'ticket':
        final id = uri.queryParameters['id'];
        if (id == null || id.isEmpty) return null;
        return DeepLinkAction.openTicket(ticketId: id);
    }
    return null;
  }
}

sealed class DeepLinkAction {
  const DeepLinkAction();
  factory DeepLinkAction.takeTicket({String? table}) = TakeTicketAction;
  factory DeepLinkAction.openTicket({required String ticketId}) =
      OpenTicketAction;
}

class TakeTicketAction extends DeepLinkAction {
  final String? table;
  const TakeTicketAction({this.table});
}

class OpenTicketAction extends DeepLinkAction {
  final String ticketId;
  const OpenTicketAction({required this.ticketId});
}
