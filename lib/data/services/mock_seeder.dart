import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';

/// Mock seeder yang bisa dipanggil dari dalam app.
///
/// Berguna untuk testing UI tanpa harus jalanin script Node.js.
/// HANYA untuk dev/staging — jangan expose di build release.
class MockSeeder {
  MockSeeder(this._db);
  final FirebaseFirestore _db;

  static const _prefix = 'A';
  static const _names = [
    'Budi Santoso',
    'Siti Aminah',
    'Andi Wijaya',
    'Dewi Lestari',
    'Rudi Hartono',
    'Maya Sari',
    'Agus Setiawan',
    'Linda Putri',
    'Bambang',
    'Rina',
    null,
    null,
  ];

  static const _tickets = [
    _MockSpec(1, QueueStatus.done, 45, null),
    _MockSpec(2, QueueStatus.done, 30, null),
    _MockSpec(3, QueueStatus.skipped, 25, null),
    _MockSpec(4, QueueStatus.serving, 5, 'counter-1'),
    _MockSpec(5, QueueStatus.called, 3, 'counter-1'),
    _MockSpec(6, QueueStatus.waiting, 12, null),
    _MockSpec(7, QueueStatus.waiting, 10, null),
    _MockSpec(8, QueueStatus.waiting, 9, null),
    _MockSpec(9, QueueStatus.waiting, 8, null),
    _MockSpec(10, QueueStatus.waiting, 6, null),
    _MockSpec(11, QueueStatus.waiting, 4, null),
    _MockSpec(12, QueueStatus.waiting, 2, null),
  ];

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Timestamp _ts(int minutesAgo) {
    return Timestamp.fromDate(
      DateTime.now().subtract(Duration(minutes: minutesAgo)),
    );
  }

  /// Hapus semua tiket existing.
  Future<int> resetQueues() async {
    final snap = await _db.collection(AppConstants.queuesCollection).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snap.size;
  }

  /// Tambah 12 tiket dummy + sync settings & counter.
  /// Return jumlah tiket yang berhasil di-seed.
  Future<int> seedMockTickets() async {
    final batch = _db.batch();
    final today = _todayKey();
    String? servingTicketId;

    for (var i = 0; i < _tickets.length; i++) {
      final spec = _tickets[i];
      final ref = _db.collection(AppConstants.queuesCollection).doc();
      final created = _ts(spec.minutesAgo);

      Timestamp? calledAt;
      Timestamp? servedAt;
      Timestamp? doneAt;
      if (spec.status == QueueStatus.called ||
          spec.status == QueueStatus.serving ||
          spec.status == QueueStatus.done ||
          spec.status == QueueStatus.skipped) {
        calledAt = _ts((spec.minutesAgo - 1).clamp(0, 999));
      }
      if (spec.status == QueueStatus.serving ||
          spec.status == QueueStatus.done) {
        servedAt = _ts((spec.minutesAgo - 2).clamp(0, 999));
      }
      if (spec.status == QueueStatus.done) {
        doneAt = _ts((spec.minutesAgo - 3).clamp(0, 999));
      }

      batch.set(ref, {
        'prefix': _prefix,
        'number': spec.number,
        'status': spec.status.name,
        'customerName': _names[i % _names.length],
        'tableNumber': '${(i % 10) + 1}',
        'fcmToken': null,
        'counterId': spec.counterId,
        'createdAt': created,
        'calledAt': calledAt,
        'servedAt': servedAt,
        'doneAt': doneAt,
      });

      if (spec.status == QueueStatus.serving) {
        servingTicketId = ref.id;
      }
    }

    final lastNumber = _tickets.last.number;
    batch.set(
      _db.collection(AppConstants.settingsCollection).doc(_prefix),
      {'prefix': _prefix, 'lastNumber': lastNumber, 'date': today},
    );

    batch.set(
      _db.collection(AppConstants.countersCollection).doc('counter-1'),
      {
        'name': 'Loket 1',
        'isActive': true,
        'currentNumber': 4,
        'servingTicketId': servingTicketId,
      },
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection(AppConstants.countersCollection).doc('counter-2'),
      {
        'name': 'Loket 2',
        'isActive': false,
        'currentNumber': 0,
        'servingTicketId': null,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return _tickets.length;
  }
}

class _MockSpec {
  final int number;
  final QueueStatus status;
  final int minutesAgo;
  final String? counterId;
  const _MockSpec(this.number, this.status, this.minutesAgo, this.counterId);
}
