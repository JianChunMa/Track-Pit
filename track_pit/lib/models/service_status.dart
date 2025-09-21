import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceStatus {
  final String id;
  final String status;
  final DateTime? completedAt;

  ServiceStatus({required this.id, required this.status, this.completedAt});

  factory ServiceStatus.fromMap(String id, Map<String, dynamic> data) {
    return ServiceStatus(
      id: id,
      status: data['status'] ?? '',
      completedAt: _fromTs(data['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  static DateTime? _fromTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  String toString() {
    return 'ServiceStatus(id: $id, status: $status, completedAt: ${completedAt?.toIso8601String() ?? "null"})';
  }
}
