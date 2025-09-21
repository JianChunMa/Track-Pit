import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:track_pit/models/user.dart' as usermodel;

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserDoc(usermodel.User user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toCreateMap(), SetOptions(merge: true));
  }

  Future<void> ensureUserDoc(fb.User fbUser) async {
    final docRef = _db.collection('users').doc(fbUser.uid);
    final snap = await docRef.get();

    if (!snap.exists) {
      final newUser = usermodel.User(
        uid: fbUser.uid,
        fullName: fbUser.displayName ?? 'Guest',
        email: fbUser.email ?? '',
        points: 0,
        createdAt: DateTime.now(),
      );

      await docRef.set(newUser.toCreateMap(), SetOptions(merge: true));
    }
  }
}
