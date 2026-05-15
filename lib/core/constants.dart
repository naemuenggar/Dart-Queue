class AppConstants {
  static const String appName = 'Resto Queue';

  // Firestore collections
  static const String queuesCollection = 'queues';
  static const String countersCollection = 'counters';
  static const String settingsCollection = 'settings';

  // Default settings
  static const int notifyBeforeNumbers = 3; // Notif "kamu nomor ke-N lagi"
  static const String defaultPrefix = 'A';
  static const int avgServiceMinutes = 5;
}

enum QueueStatus { waiting, called, serving, done, skipped }

extension QueueStatusX on QueueStatus {
  String get label {
    switch (this) {
      case QueueStatus.waiting:
        return 'Menunggu';
      case QueueStatus.called:
        return 'Dipanggil';
      case QueueStatus.serving:
        return 'Dilayani';
      case QueueStatus.done:
        return 'Selesai';
      case QueueStatus.skipped:
        return 'Dilewati';
    }
  }

  static QueueStatus fromString(String? value) {
    return QueueStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QueueStatus.waiting,
    );
  }
}
