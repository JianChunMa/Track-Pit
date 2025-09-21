import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_pit/models/payment.dart';

class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<Payment> _payments = [];
  bool _loading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Start listening to payment changes
  Future<void> startListening() async {
    stopListening(notify: false);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _loading = true;
    notifyListeners();

    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('payments')
        .orderBy('paidAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _payments =
                snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  /// Stop listening
  void stopListening({bool notify = true}) {
    _sub?.cancel();
    _sub = null;
    _payments = [];
    _loading = false;
    _error = null;
    if (notify) notifyListeners();
  }

  /// Create a new payment
  Future<String> createPayment(Payment payment) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not signed in");

    final ref = _db.collection('users').doc(uid).collection('payments').doc();
    final paymentId = ref.id;

    final data =
        payment.toMap()
          ..['createdAt'] = FieldValue.serverTimestamp()
          ..['updatedAt'] = FieldValue.serverTimestamp();

    await ref.set(data);
    return paymentId;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
