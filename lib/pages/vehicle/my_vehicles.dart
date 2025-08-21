import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/vehicle_list_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/user_services.dart';

import '../../core/constants/colors.dart';

class MyVehiclesPage extends StatelessWidget {
  MyVehiclesPage({Key? key}) : super(key: key);

  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Not signed in – redirect or show empty state
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    final vehiclesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Vehicles'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton:SizedBox(
        width: 72,   // default is ~56
        height: 72,  // make it larger
        child: FloatingActionButton(
          heroTag: 'addVehicleFab',
          backgroundColor: AppColors.primaryGreen,
          elevation: 5,
          shape: const CircleBorder(),
          onPressed: () => Navigator.pushNamed(context, '/addvehicle'),
          child: const Icon(Icons.add, color: Colors.white, size: 32), // bigger icon too
      ),
    ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,   // default bottom-right


      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: vehiclesCol.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No vehicles yet.'));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 6, bottom: 24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final v = d.data();
              final vehicleId = d.id;
              final plateNumber = (v['plateNumber'] ?? '') as String;
              final model = (v['model'] ?? '') as String;
              final chassis = (v['chassisNumber'] ?? '') as String;
              final imagePath =
                  'lib/assets/images/x50.png'; // or from v['imagePath']

              return VehicleListCard(
                plateNumber: plateNumber,
                model: model,
                chassisNumber: chassis,
                imagePath: imagePath,
                onTap: () {
                  // open details if you have one
                },
                onEdit: () {
                  // navigate to edit page if you have one
                },
                onDelete: () => _confirmAndDelete(
                  context: context,
                  uid: uid,
                  vehicleId: vehicleId,
                  plateNumber: plateNumber,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDelete({
    required BuildContext context,
    required String uid,
    required String vehicleId,
    required String plateNumber,
  }) async {
    // Use a local context tied to ScaffoldMessenger
    final scaffoldCtx = context;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ConfirmDialog(
        title: "Delete vehicle?",
        message: "This will remove the vehicle from your garage.",
        confirmText: "Delete",
        cancelText: "Cancel",
      ),
    );

    if (ok != true) return;

    try {
      await _userService.removeVehicle(
        uid: uid,
        vehicleId: vehicleId,
        plateNumber: plateNumber,
      );

      // In newer Flutter versions you can also check: if (!scaffoldCtx.mounted) return;
      ScaffoldMessenger.of(
        scaffoldCtx,
      ).showSnackBar(SnackBar(content: Text('Deleted $plateNumber')));
    } catch (e) {
      ScaffoldMessenger.of(
        scaffoldCtx,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }
}
