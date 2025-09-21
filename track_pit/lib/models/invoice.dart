import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String vehicleId;
  final String serviceId;
  final int workshopId;
  final double price;
  final bool paid;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.vehicleId,
    required this.serviceId,
    required this.workshopId,
    required this.price,
    required this.paid,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Invoice(
      id: doc.id,
      vehicleId: data['vehicleId'] as String,
      serviceId: data['serviceId'] as String,
      workshopId: data['workshopId'] as int,
      price: (data['price'] as num).toDouble(),
      paid: data['paid'] as bool,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'serviceId': serviceId,
      'workshopId': workshopId,
      'price': price,
      'paid': paid,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
