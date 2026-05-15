import 'package:cloud_firestore/cloud_firestore.dart';

class Counter {
  final String id;
  final String name;
  final bool isActive;
  final int currentNumber;
  final String? servingTicketId;

  Counter({
    required this.id,
    required this.name,
    required this.isActive,
    required this.currentNumber,
    this.servingTicketId,
  });

  factory Counter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Counter(
      id: doc.id,
      name: data['name'] ?? 'Loket',
      isActive: data['isActive'] ?? false,
      currentNumber: data['currentNumber'] ?? 0,
      servingTicketId: data['servingTicketId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isActive': isActive,
      'currentNumber': currentNumber,
      'servingTicketId': servingTicketId,
    };
  }
}
