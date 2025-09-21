import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  static final _col = FirebaseFirestore.instance.collection('feedback');

  static Future<bool> hasFeedback(String serviceId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final query =
          await _col
              .where('serviceId', isEqualTo: serviceId)
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
