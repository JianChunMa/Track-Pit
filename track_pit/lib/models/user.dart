import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int points;

  const User({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.updatedAt,
    this.points = 0,
  });

  factory User.fromMap(String uid, Map<String, dynamic> data) {
    return User(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: (data['email'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      points: (data['points'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'points': points,
    }..removeWhere((k, v) => v == null);
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  User copyWith({
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? points,
  }) {
    return User(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
    );
  }
}
