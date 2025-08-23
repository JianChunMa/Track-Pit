import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('bookings');

  Future<String> create(Booking b) async {
    final doc = _col(b.uid).doc();
    await doc.set(b.toMap()
      ..addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }));
    return doc.id;
  }

  Future<void> update(Booking b) async {
    await _col(b.uid).doc(b.id).update(b.toMap()
      ..addAll({'updatedAt': FieldValue.serverTimestamp()}));
  }

  Future<void> cancel({
    required String uid,
    required String bookingId,
  }) async {
    await _col(uid).doc(bookingId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Booking>> upcoming(String uid) {
    return _col(uid)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('startAt')
        .snapshots()
        .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Booking>> forVehicle(String uid, String vehicleId) {
    return _col(uid)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }
}
