import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/counter.dart';
import '../models/queue_ticket.dart';

/// Repository untuk operasi antrian.
///
/// Logika nomor antrian:
/// - Counter (nomor terakhir) disimpan di `settings/{prefix}` dengan field
///   `lastNumber` dan `date` (yyyy-MM-dd) untuk auto-reset harian.
/// - Saat ambil tiket, transaksi atomik increment `lastNumber`.
class QueueRepository {
  QueueRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _queues =>
      _db.collection(AppConstants.queuesCollection);
  CollectionReference<Map<String, dynamic>> get _counters =>
      _db.collection(AppConstants.countersCollection);

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Ambil tiket antrian baru. Return tiket yang baru dibuat.
  Future<QueueTicket> takeTicket({
    String prefix = AppConstants.defaultPrefix,
    String? customerName,
    String? tableNumber,
    String? fcmToken,
  }) async {
    final settingsRef =
        _db.collection(AppConstants.settingsCollection).doc(prefix);
    final today = _todayKey();

    final ticket = await _db.runTransaction<QueueTicket>((tx) async {
      final snap = await tx.get(settingsRef);
      int lastNumber = 0;
      String? lastDate;
      if (snap.exists) {
        final data = snap.data()!;
        lastNumber = (data['lastNumber'] ?? 0) as int;
        lastDate = data['date'] as String?;
      }

      // Auto reset jika hari berubah
      if (lastDate != today) lastNumber = 0;
      final next = lastNumber + 1;

      tx.set(settingsRef, {
        'prefix': prefix,
        'lastNumber': next,
        'date': today,
      });

      final newTicketRef = _queues.doc();
      final ticket = QueueTicket(
        id: newTicketRef.id,
        prefix: prefix,
        number: next,
        status: QueueStatus.waiting,
        customerName: customerName,
        tableNumber: tableNumber,
        fcmToken: fcmToken,
        createdAt: DateTime.now(),
      );
      tx.set(newTicketRef, ticket.toFirestore());
      return ticket;
    });

    return ticket;
  }

  /// Stream tiket spesifik (untuk customer melihat status ticket-nya).
  Stream<QueueTicket?> watchTicket(String ticketId) {
    return _queues.doc(ticketId).snapshots().map(
          (doc) => doc.exists ? QueueTicket.fromFirestore(doc) : null,
        );
  }

  /// Stream daftar antrian aktif (untuk operator dashboard).
  Stream<List<QueueTicket>> watchActiveQueues() {
    return _queues
        .where('status', whereIn: [
          QueueStatus.waiting.name,
          QueueStatus.called.name,
          QueueStatus.serving.name,
        ])
        .orderBy('number')
        .snapshots()
        .map((s) => s.docs.map(QueueTicket.fromFirestore).toList());
  }

  /// Hitung berapa orang di depan tiket ini (status waiting & nomor lebih kecil).
  Stream<int> watchAheadCount(QueueTicket ticket) {
    return _queues
        .where('prefix', isEqualTo: ticket.prefix)
        .where('status', isEqualTo: QueueStatus.waiting.name)
        .where('number', isLessThan: ticket.number)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Operator: panggil tiket berikutnya yang waiting (FIFO by number).
  Future<QueueTicket?> callNext({required String counterId}) async {
    final query = await _queues
        .where('status', isEqualTo: QueueStatus.waiting.name)
        .orderBy('number')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;

    await doc.reference.update({
      'status': QueueStatus.called.name,
      'counterId': counterId,
      'calledAt': Timestamp.now(),
    });

    await _counters.doc(counterId).set({
      'servingTicketId': doc.id,
      'currentNumber': (doc.data()['number'] ?? 0),
    }, SetOptions(merge: true));

    final updated = await doc.reference.get();
    return QueueTicket.fromFirestore(updated);
  }

  Future<void> markServing(String ticketId) =>
      _queues.doc(ticketId).update({
        'status': QueueStatus.serving.name,
        'servedAt': Timestamp.now(),
      });

  Future<void> markDone(String ticketId) =>
      _queues.doc(ticketId).update({
        'status': QueueStatus.done.name,
        'doneAt': Timestamp.now(),
      });

  Future<void> skipTicket(String ticketId) =>
      _queues.doc(ticketId).update({'status': QueueStatus.skipped.name});

  /// Ambil tiket sekali (buat handler scanner di operator).
  Future<QueueTicket?> getTicketOnce(String ticketId) async {
    final doc = await _queues.doc(ticketId).get();
    return doc.exists ? QueueTicket.fromFirestore(doc) : null;
  }

  // ----- Counter management -----

  Stream<List<Counter>> watchCounters() {
    return _counters.orderBy('name').snapshots().map(
          (s) => s.docs.map(Counter.fromFirestore).toList(),
        );
  }

  Future<void> ensureDefaultCounters() async {
    final snap = await _counters.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    // Restoran biasanya 1-2 loket, kita seed 2.
    await _counters.doc('counter-1').set({
      'name': 'Loket 1',
      'isActive': true,
      'currentNumber': 0,
      'servingTicketId': null,
    });
    await _counters.doc('counter-2').set({
      'name': 'Loket 2',
      'isActive': false,
      'currentNumber': 0,
      'servingTicketId': null,
    });
  }

  Future<void> setCounterActive(String counterId, bool active) {
    return _counters.doc(counterId).update({'isActive': active});
  }
}
