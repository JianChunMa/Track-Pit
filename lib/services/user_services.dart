
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserDoc({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'hasCompletedVehicleSetup': false,
      'vehicleCount': 0,
    }, SetOptions(merge: true));
  }

  String _canonPlate(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Add a vehicle later (when user taps "Add Vehicle")
  /// - Reserves plate globally in /plates/{PLATE}
  /// - Creates /users/{uid}/vehicles/{autoId}
  /// - Increments vehicleCount and sets hasCompletedVehicleSetup
  Future<void> addVehicleForUser({
    required String uid,
    required Vehicle vehicle,
  }) async {
    final plate = _canonPlate(vehicle.plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(); // auto id
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      // ensure plate uniqueness
      final plateSnap = await tx.get(plateRef);
      if (plateSnap.exists) {
        throw Exception('Plate already registered');
      }

      // vehicle data (ensure timestamps if your model doesn't)
      final vehData = vehicle.toMap()
        ..putIfAbsent('createdAt', () => FieldValue.serverTimestamp())
        ..['updatedAt'] = FieldValue.serverTimestamp()
        ..['plateNumber'] = plate; // store canonicalized

      tx.set(vehRef, vehData);

      tx.set(plateRef, {
        'uid': uid,
        'vehicleId': vehRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'vehicleCount': FieldValue.increment(1),
        'hasCompletedVehicleSetup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Optional: remove a vehicle and update counters/flags accordingly.
  Future<void> removeVehicle({
    required String uid,
    required String vehicleId,
    required String plateNumber, // raw; we'll canonicalize
  }) async {
    final plate = _canonPlate(plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(vehicleId);
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      // delete docs
      tx.delete(vehRef);
      tx.delete(plateRef);

      // decrement and set flag
      final userSnap = await tx.get(userRef);
      final current = (userSnap.data()?['vehicleCount'] ?? 1) as int;
      final newCount = (current - 1).clamp(0, 1 << 31);
      tx.update(userRef, {
        'vehicleCount': FieldValue.increment(-1),
        'hasCompletedVehicleSetup': newCount > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Stream vehicles for UI
  Stream<List<Map<String, dynamic>>> vehiclesStream(String uid) {
    return _db.collection('users').doc(uid).collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
