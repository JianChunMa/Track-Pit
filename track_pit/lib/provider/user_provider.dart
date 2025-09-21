import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  String? _uid;

  Map<String, dynamic>? get userData => _userData;

  StreamSubscription<DocumentSnapshot>? _sub;

  void startListening(String uid) {
    stopListening();
    _uid = uid;
    _sub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      _userData = snap.data();
      notifyListeners();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _userData = null;
    _uid = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  String get uid => _uid ?? '';
  String get email => _userData?['email'] ?? '';
  String get fullName => _userData?['fullName'] ?? 'Guest';
  int get points => (_userData?['points'] ?? 0) as int;

  DateTime? get createdAt {
    final ts = _userData?['createdAt'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return null;
  }

  DateTime? get updatedAt {
    final ts = _userData?['updatedAt'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return null;
  }

  bool get isLoaded => _userData != null;

  Future<void> updateFullName(String name) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'fullName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEmail(String email) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementPoints(int delta) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'points': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
