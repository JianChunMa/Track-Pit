import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_pit/models/invoice.dart';

class InvoiceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<Invoice> _invoices = [];
  bool _loading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> startListening() async {
    stopListening(notify: false);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _loading = true;
    notifyListeners();

    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('invoices')
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _invoices =
                snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

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

  void stopListening({bool notify = true}) {
    _sub?.cancel();
    _sub = null;
    _invoices = [];
    _loading = false;
    _error = null;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
