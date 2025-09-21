import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_pit/models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _prefKeySelectedVehicle = 'selected_vehicle_id';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<Vehicle> _vehicles = [];
  bool _loading = false;
  String? _error;

  String? _selectedVehicleId;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _loading;
  String? get error => _error;

  Vehicle? get selectedVehicle {
    if (_selectedVehicleId == null) return null;
    try {
      return _vehicles.firstWhere((v) => v.id == _selectedVehicleId);
    } catch (_) {
      return null;
    }
  }

  String? get selectedVehicleId => _selectedVehicleId;

  Future<void> _loadSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedVehicleId = prefs.getString(_prefKeySelectedVehicle);
  }

  Future<void> _saveSelectedVehicleId(String? vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (vehicleId == null) {
      await prefs.remove(_prefKeySelectedVehicle);
    } else {
      await prefs.setString(_prefKeySelectedVehicle, vehicleId);
    }
  }

  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _saveSelectedVehicleId(vehicleId);
    notifyListeners();
  }

  void clearSelectedVehicle() {
    _selectedVehicleId = null;
    _saveSelectedVehicleId(null);
    notifyListeners();
  }

  void _ensureValidSelection() {
    if (_vehicles.isEmpty) {
      _selectedVehicleId = null;
      _saveSelectedVehicleId(null);
      return;
    }

    final stillExists = _vehicles.any((v) => v.id == _selectedVehicleId);

    if (!stillExists) {
      _selectedVehicleId = _vehicles.first.id;
      _saveSelectedVehicleId(_selectedVehicleId);
    }
  }

  Future<void> startListening() async {
    stopListening(notify: false);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _loading = true;
    notifyListeners();

    await _loadSelectedVehicleId();

    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _vehicles =
                snapshot.docs
                    .map((d) => Vehicle.fromMap(d.id, d.data()))
                    .toList();

            _loading = false;
            _ensureValidSelection();
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  void stopListening({bool notify = true}) {
    _sub?.cancel();
    _sub = null;
    _vehicles = [];
    _loading = false;
    _error = null;
    _selectedVehicleId = null;
    if (notify) notifyListeners();
  }

  String _canonPlate(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> addVehicle(Vehicle vehicle) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not signed in");

    final plate = _canonPlate(vehicle.plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc();
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      final plateSnap = await tx.get(plateRef);
      if (plateSnap.exists) {
        throw Exception('Plate already registered');
      }

      final vehData =
          vehicle.toMap()
            ..putIfAbsent('createdAt', () => FieldValue.serverTimestamp())
            ..['updatedAt'] = FieldValue.serverTimestamp()
            ..['plateNumber'] = plate;

      tx.set(vehRef, vehData);

      tx.set(plateRef, {
        'uid': uid,
        'vehicleId': vehRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {'updatedAt': FieldValue.serverTimestamp()});
    });

    setSelectedVehicle(vehRef.id);
  }

  Future<void> updateVehicle(
    String vehicleId,
    Vehicle vehicle,
    String oldPlate,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not signed in");

    final newPlate = _canonPlate(vehicle.plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(vehicleId);
    final oldPlateRef = _db.collection('plates').doc(_canonPlate(oldPlate));
    final newPlateRef = _db.collection('plates').doc(newPlate);

    await _db.runTransaction((tx) async {
      final vehSnap = await tx.get(vehRef);
      if (!vehSnap.exists) throw Exception("Vehicle not found");
      if (newPlate != _canonPlate(oldPlate)) {
        final newPlateSnap = await tx.get(newPlateRef);
        if (newPlateSnap.exists) {
          throw Exception("New plate already registered");
        }

        tx.delete(oldPlateRef);
        tx.set(newPlateRef, {
          'uid': uid,
          'vehicleId': vehicleId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      final vehData =
          vehicle.toMap()
            ..['plateNumber'] = newPlate
            ..['updatedAt'] = FieldValue.serverTimestamp();

      tx.update(vehRef, vehData);
      tx.update(userRef, {'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> deleteVehicle(String vehicleId, String plateNumber) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not signed in");

    final plate = _canonPlate(plateNumber);
    final userRef = _db.collection('users').doc(uid);
    final vehRef = userRef.collection('vehicles').doc(vehicleId);
    final plateRef = _db.collection('plates').doc(plate);

    await _db.runTransaction((tx) async {
      final vehSnap = await tx.get(vehRef);
      if (!vehSnap.exists) {
        throw Exception("Vehicle not found");
      }

      tx.delete(vehRef);
      tx.delete(plateRef);
      tx.update(userRef, {'updatedAt': FieldValue.serverTimestamp()});
    });

    if (_selectedVehicleId == vehicleId) {
      _selectedVehicleId = null;
      _saveSelectedVehicleId(null);
      _ensureValidSelection();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
