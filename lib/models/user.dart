import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int points;
  final bool hasCompletedVehicleSetup;
  final int vehicleCount;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.updatedAt,
    this.points = 0,
    this.hasCompletedVehicleSetup = false,
    this.vehicleCount = 0,
  });

  /// Create a model from Firestore document data
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: (data['email'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      points: (data['points'] ?? 0) as int,
      hasCompletedVehicleSetup: data['hasCompletedVehicleSetup'] ?? false,
      vehicleCount: (data['vehicleCount'] ?? 0) as int,
    );
  }

  /// Convert model into Firestore-savable map
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'points': points,
      'hasCompletedVehicleSetup': hasCompletedVehicleSetup,
      'vehicleCount': vehicleCount,
    }..removeWhere((k, v) => v == null);
  }

  /// For creating new users (auto-set timestamps server side)
  Map<String, dynamic> toCreateMap() {
    return {
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'points': points,
      'hasCompletedVehicleSetup': hasCompletedVehicleSetup,
      'vehicleCount': vehicleCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// CopyWith to update fields immutably
  UserModel copyWith({
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? points,
    bool? hasCompletedVehicleSetup,
    int? vehicleCount,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
      hasCompletedVehicleSetup:
      hasCompletedVehicleSetup ?? this.hasCompletedVehicleSetup,
      vehicleCount: vehicleCount ?? this.vehicleCount,
    );
  }
}
