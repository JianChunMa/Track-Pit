import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
enum Transmission { manual, automatic, cvt, dct }

class Vehicle {
  final String id; // Firestore doc id
  final String plateNumber;     // canonicalized (ABC1234)
  final String model;
  final String chassisNumber;
  final int year;
  final int mileage;
  final Transmission transmission;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.chassisNumber,
    required this.year,
    required this.mileage,
    required this.transmission,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> m) => Vehicle(
    id: id,
    plateNumber: m['plateNumber'] ?? '',
    model: m['model'] ?? '',
    chassisNumber: m['chassisNumber'] ?? '',
    year: (m['year'] ?? 0) as int,
    mileage: (m['mileage'] ?? 0) as int,
    transmission: _txFromString(m['transmission']),
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'plateNumber': plateNumber,
    'model': model,
    'chassisNumber': chassisNumber,
    'year': year,
    'mileage': mileage,
    'transmission': transmission.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  }..removeWhere((k, v) => v == null);

  static Transmission _txFromString(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    return Transmission.values.firstWhere(
          (e) => e.name == s,
      orElse: () => Transmission.automatic,
    );
  }
}
