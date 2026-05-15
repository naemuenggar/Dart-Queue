import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk handle notifikasi (FCM + local).
///
/// Catatan:
/// - FCM butuh konfigurasi server-side (Cloud Functions) untuk kirim push
///   ke ticket tertentu saat dipanggil. Setup template ada di README.
/// - Local notification dipakai saat app foreground supaya user tetap tahu
///   walau push masuk diam-diam.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'queue_calls';
  static const _channelName = 'Panggilan Antrian';

  Future<void> init() async {
    // Request permission (iOS / Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi saat antrian dipanggil',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground messages → tampilkan local notif
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<String?> getToken() => _fcm.getToken();

  void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Untuk peringatan dini lokal (mis. "3 nomor lagi giliranmu")
  Future<void> showLocal({required String title, required String body}) {
    return _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
