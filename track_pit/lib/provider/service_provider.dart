import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_pit/models/service.dart';
import 'package:track_pit/models/service_status.dart';

List<ServiceStatus> defaultTimeline = [
  ServiceStatus(id: "1", status: "inspection", completedAt: null),
  ServiceStatus(id: "2", status: "parts_awaiting", completedAt: null),
  ServiceStatus(id: "3", status: "in_repair", completedAt: null),
  ServiceStatus(id: "4", status: "completed", completedAt: null),
];

class ServiceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Map<String, StreamSubscription> _timelineSubs = {};

  List<Service> _services = [];
  bool _loading = false;
  String? _error;

  List<Service> get services => _services;
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
        .collection('services')
        .orderBy('bookedDateTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            // cancel old timeline listeners
            for (final sub in _timelineSubs.values) {
              sub.cancel();
            }
            _timelineSubs.clear();

            _services =
                snapshot.docs
                    .map((doc) => Service.fromMap(doc.id, doc.data()))
                    .toList();

            for (final doc in snapshot.docs) {
              final serviceId = doc.id;
              final service = Service.fromMap(serviceId, doc.data());

              _timelineSubs[serviceId] = doc.reference
                  .collection('statusTimeline')
                  .snapshots()
                  .listen((tlSnap) {
                    final timeline =
                        tlSnap.docs
                            .map((d) => ServiceStatus.fromMap(d.id, d.data()))
                            .toList()
                          ..sort(
                            (a, b) =>
                                int.parse(a.id).compareTo(int.parse(b.id)),
                          );

                    final updated = service.copyWithTimeline(timeline);

                    // replace in _services
                    final index = _services.indexWhere(
                      (s) => s.id == serviceId,
                    );
                    if (index != -1) {
                      _services[index] = updated;
                      notifyListeners();
                    }
                  });
            }

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
    _services = [];
    _loading = false;
    _error = null;
    if (notify) notifyListeners();
  }

  Future<String> addService(Service service) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not signed in");

    final serviceRef =
        _db.collection('users').doc(uid).collection('services').doc();
    final serviceId = serviceRef.id;
    final data =
        service.toMap()
          ..['createdAt'] = FieldValue.serverTimestamp()
          ..['updatedAt'] = FieldValue.serverTimestamp();

    await serviceRef.set(data);
    final timelineBatch = _db.batch();
    for (final s in defaultTimeline) {
      final statusRef = serviceRef.collection('statusTimeline').doc(s.id);
      timelineBatch.set(statusRef, s.toMap());
    }
    await timelineBatch.commit();
    return serviceId;
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final sub in _timelineSubs.values) {
      sub.cancel();
    }
    _timelineSubs.clear();
    super.dispose();
  }
}
