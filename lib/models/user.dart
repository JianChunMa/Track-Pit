import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class User {
  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasCompletedVehicleSetup;

  User({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.updatedAt,
    this.hasCompletedVehicleSetup = false,
  });

  factory User.fromMap(String uid, Map<String, dynamic> m) => User(
    uid: uid,
    fullName: m['fullName'] ?? '',
    email: (m['email'] ?? '').toString(),
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    hasCompletedVehicleSetup: m['hasCompletedVehicleSetup'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'hasCompletedVehicleSetup': hasCompletedVehicleSetup,
  }..removeWhere((k, v) => v == null);
}
