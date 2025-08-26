import 'package:cloud_firestore/cloud_firestore.dart';

//Represents a future or ongoing appointment made by the user
// historical data
class Booking {
  final String id;
  final String uid;
  final String vehicleId;

  final String serviceType;      // e.g. Regular Service, Repair, Inspection
  final String workshopName;
  final String workshopLocation;

  final DateTime date;           // selected calendar day
  final String time;             // "HH:mm"
  final DateTime startAt;        // date + time combined for sorting

  final String? notes;
  final String status;           // pending | confirmed | cancelled | completed

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.uid,
    required this.vehicleId,
    required this.serviceType,
    required this.workshopName,
    required this.workshopLocation,
    required this.date,
    required this.time,
    required this.startAt,
    this.notes,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
    id: id,
    uid: (m['uid'] ?? '') as String,
    vehicleId: (m['vehicleId'] ?? '') as String,
    serviceType: (m['serviceType'] ?? '') as String,
    workshopName: (m['workshopName'] ?? '') as String,
    workshopLocation: (m['workshopLocation'] ?? '') as String,
    date: (m['date'] as Timestamp).toDate(),
    time: (m['time'] ?? '') as String,
    startAt: (m['startAt'] as Timestamp).toDate(),
    notes: m['notes'] as String?,
    status: (m['status'] ?? 'pending') as String,
    createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'vehicleId': vehicleId,
    'serviceType': serviceType,
    'workshopName': workshopName,
    'workshopLocation': workshopLocation,
    'date': Timestamp.fromDate(date),
    'time': time,
    'startAt': Timestamp.fromDate(startAt),
    'notes': notes,
    'status': status,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  }..removeWhere((k, v) => v == null);
}
