import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';

class QueueTicket {
  final String id;
  final String prefix;
  final int number;
  final QueueStatus status;
  final String? customerName;
  final String? tableNumber;
  final String? fcmToken;
  final String? counterId;
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? servedAt;
  final DateTime? doneAt;

  QueueTicket({
    required this.id,
    required this.prefix,
    required this.number,
    required this.status,
    this.customerName,
    this.tableNumber,
    this.fcmToken,
    this.counterId,
    required this.createdAt,
    this.calledAt,
    this.servedAt,
    this.doneAt,
  });

  String get displayNumber => '$prefix${number.toString().padLeft(3, '0')}';

  factory QueueTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueTicket(
      id: doc.id,
      prefix: data['prefix'] ?? AppConstants.defaultPrefix,
      number: data['number'] ?? 0,
      status: QueueStatusX.fromString(data['status']),
      customerName: data['customerName'],
      tableNumber: data['tableNumber'],
      fcmToken: data['fcmToken'],
      counterId: data['counterId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      servedAt: (data['servedAt'] as Timestamp?)?.toDate(),
      doneAt: (data['doneAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prefix': prefix,
      'number': number,
      'status': status.name,
      'customerName': customerName,
      'tableNumber': tableNumber,
      'fcmToken': fcmToken,
      'counterId': counterId,
      'createdAt': Timestamp.fromDate(createdAt),
      'calledAt': calledAt != null ? Timestamp.fromDate(calledAt!) : null,
      'servedAt': servedAt != null ? Timestamp.fromDate(servedAt!) : null,
      'doneAt': doneAt != null ? Timestamp.fromDate(doneAt!) : null,
    };
  }
}
