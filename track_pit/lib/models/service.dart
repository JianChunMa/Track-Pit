import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_pit/models/service_status.dart';

enum ServiceOverallStatus { upcoming, ongoing, completed }

class Service {
  final String id;
  final int serviceTypeId;
  final int workshopId;
  final String vehicleId;
  final DateTime bookedDateTime;
  final String notes;
  final List<ServiceStatus> _timeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.serviceTypeId,
    required this.workshopId,
    required this.vehicleId,
    required this.bookedDateTime,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    List<ServiceStatus> timeline = const [],
  }) : _timeline = timeline;

  factory Service.fromMap(String id, Map<String, dynamic> data) {
    return Service(
      id: id,
      serviceTypeId: (data['serviceTypeId'] as num?)?.toInt() ?? 0,
      workshopId: (data['workshopId'] as num?)?.toInt() ?? 0,
      vehicleId: data['vehicleId'] ?? '',
      bookedDateTime: _fromTs(data['bookedDateTime']),
      notes: data['notes'] ?? '',
      createdAt: _fromTs(data['createdAt']),
      updatedAt: _fromTs(data['updatedAt']),
      timeline: const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceTypeId': serviceTypeId,
      'workshopId': workshopId,
      'vehicleId': vehicleId,
      'bookedDateTime': Timestamp.fromDate(bookedDateTime),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Service copyWithTimeline(List<ServiceStatus> timeline) {
    return Service(
      id: id,
      serviceTypeId: serviceTypeId,
      workshopId: workshopId,
      vehicleId: vehicleId,
      bookedDateTime: bookedDateTime,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timeline: timeline,
    );
  }

  static DateTime _fromTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  ServiceOverallStatus get overallStatus {
    if (_timeline.isEmpty) {
      return DateTime.now().isAfter(bookedDateTime)
          ? ServiceOverallStatus.ongoing
          : ServiceOverallStatus.upcoming;
    }

    final completedCount = _timeline.where((s) => s.completedAt != null).length;

    if (completedCount == 0) {
      return DateTime.now().isAfter(bookedDateTime)
          ? ServiceOverallStatus.ongoing
          : ServiceOverallStatus.upcoming;
    } else if (completedCount == _timeline.length) {
      return ServiceOverallStatus.completed;
    } else {
      return ServiceOverallStatus.ongoing;
    }
  }

  List<ServiceStatus>? get timeline =>
      overallStatus == ServiceOverallStatus.upcoming ? null : _timeline;

  @override
  String toString() {
    final timelineStr =
        _timeline.isNotEmpty
            ? _timeline.map((e) => e.toString()).join('\n')
            : 'No timeline';

    return '''
Service(
  id: $id,
  serviceTypeId: $serviceTypeId,
  workshopId: $workshopId,
  vehicleId: $vehicleId,
  bookedDateTime: $bookedDateTime,
  notes: $notes,
  createdAt: $createdAt,
  updatedAt: $updatedAt,
  timeline:
$timelineStr
)''';
  }
}
