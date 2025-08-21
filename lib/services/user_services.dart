import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';
import '../models/vehicle.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Create/merge the user profile using server timestamps.
  /// Pass a UserModel with uid/fullName/email; other fields have defaults.
  Future<void> createUserDoc(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(
      user.toCreateMap(), // uses serverTimestamp() for createdAt/updatedAt
      SetOptions(merge: true),
    );
  }

  /// Optional: ensure a user doc exists (useful after Google sign-in).
  Future<void> ensureUserDoc({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final model = UserModel(
        uid: uid,
        fullName: fullName,
        email: email,
        createdAt: DateTime.now(), // not used by toCreateMap(), but fine
      );
      await createUserDoc(model);
    }
  }

  /// Get a typed stream of UserModel (for your HomePage header, etc).
  Stream<UserModel> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return UserModel.fromMap(doc.id, data);
    });
  }

  /// One-shot fetch of the user model.
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  String _canonPlate(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Add a vehicle and update counters/flags in a single transaction.
  Future<void> addVehicleForUser({
    required String uid,
    required Vehicle vehicle,
  }) async {
    final plate = _canonPlate(vehicle.plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(); // auto id
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      // Guard: plate must be unique globally
      final plateSnap = await tx.get(plateRef);
      if (plateSnap.exists) {
        throw Exception('Plate already registered');
      }

      final vehData = vehicle.toMap()
        ..putIfAbsent('createdAt', () => FieldValue.serverTimestamp())
        ..['updatedAt'] = FieldValue.serverTimestamp()
        ..['plateNumber'] = plate;

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

  /// Remove a vehicle and update counters/flags accordingly.
  Future<void> removeVehicle({
    required String uid,
    required String vehicleId,
    required String plateNumber,
  }) async {
    final plate = _canonPlate(plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(vehicleId);
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      tx.delete(vehRef);
      tx.delete(plateRef);

      // recompute hasCompletedVehicleSetup based on new count
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

  /// Stream vehicles (raw maps) for UI lists., raw-map version
  Stream<List<Map<String, dynamic>>> vehiclesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Vehicle>> vehiclesTypedStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Vehicle.fromMap(d.id, d.data()))
        .toList());
  }

  /// Increment/decrement user points (positive to add, negative to redeem).
  Future<void> updateUserPoints(String uid, int delta) async {
    final userRef = _db.collection('users').doc(uid);
    await userRef.update({
      'points': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Live points only (useful for a small badge in the app bar).
  Stream<int> userPointsStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (snap) => (snap.data()?['points'] ?? 0) as int,
    );
  }
}
