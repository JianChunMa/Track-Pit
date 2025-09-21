import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final List<String> invoiceIds;
  final double subtotal;
  final double discount;
  final double netTotal;
  final DateTime paidAt;

  Payment({
    required this.id,
    required this.invoiceIds,
    required this.subtotal,
    required this.discount,
    required this.netTotal,
    required this.paidAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      invoiceIds: List<String>.from(data['invoiceIds'] ?? []),
      subtotal: (data['subtotal'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      netTotal: (data['netTotal'] as num).toDouble(),
      paidAt: (data['paidAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceIds': invoiceIds,
      'subtotal': subtotal,
      'discount': discount,
      'netTotal': netTotal,
      'paidAt': Timestamp.fromDate(paidAt),
    };
  }
}
