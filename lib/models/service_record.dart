import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRecord {
  final String id;            // Firestore doc id
  final String uid;           // owner
  final String vehicleId;     // parent vehicle
  final DateTime date;        // service date
  final int odometer;         // km at service
  final String type;          // e.g., "Regular Service", "Repair"
  final double cost;          // total cost
  final String workshopName;  // optional
  final String? notes;
  final int? nextDueOdo;      // e.g., 10000 km later
  final DateTime? nextDueDate;
  final List<String> items;   // ["Engine Oil", "Oil Filter", ...]

  ServiceRecord({
    required this.id,
    required this.uid,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.type,
    required this.cost,
    required this.workshopName,
    this.notes,
    this.nextDueOdo,
    this.nextDueDate,
    this.items = const [],
  });

  factory ServiceRecord.fromMap(String id, Map<String, dynamic> m) {
    return ServiceRecord(
      id: id,
      uid: (m['uid'] ?? '') as String,
      vehicleId: (m['vehicleId'] ?? '') as String,
      date: (m['date'] as Timestamp).toDate(),
      odometer: (m['odometer'] ?? 0) as int,
      type: (m['type'] ?? '') as String,
      cost: (m['cost'] ?? 0).toDouble(),
      workshopName: (m['workshopName'] ?? '') as String,
      notes: m['notes'] as String?,
      nextDueOdo: m['nextDueOdo'] as int?,
      nextDueDate: (m['nextDueDate'] as Timestamp?)?.toDate(),
      items: (m['items'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'vehicleId': vehicleId,
    'date': Timestamp.fromDate(date),
    'odometer': odometer,
    'type': type,
    'cost': cost,
    'workshopName': workshopName,
    'notes': notes,
    'nextDueOdo': nextDueOdo,
    'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
    'items': items,
  }..removeWhere((k, v) => v == null);
}
