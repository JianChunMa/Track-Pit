import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/user_services.dart';
import '../../widgets/vehicle_list_card.dart';
import '../../models/vehicle.dart';

class MyVehiclesPage extends StatelessWidget {
  const MyVehiclesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      // Not signed in — bounce back or show message
      Future.microtask(() => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    final service = UserService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Vehicles'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                heroTag: 'addVehicleFab',
                backgroundColor: AppColors.primaryGreen,
                elevation: 0,
                shape: const CircleBorder(),
                onPressed: () => Navigator.pushNamed(context, '/addVehicle'),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: service.vehiclesTypedStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final vehicles = snap.data ?? const <Vehicle>[];
          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No vehicles yet'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/addVehicle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Vehicle'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 6, bottom: 24),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final v = vehicles[i];

              // If you store an imagePath in Firestore, use it directly.
              // Otherwise map model -> asset here as a fallback:
              final imagePath = _imageForModel(v.model);

              return VehicleListCard(
                plateNumber: v.plateNumber,
                model: v.model,
                chassisNumber: v.chassisNumber,
                imagePath: imagePath,
                onTap: () {
                  // TODO: push details page with vehicle id v.id
                  // Navigator.pushNamed(context, '/vehicleDetails', arguments: v.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Simple local mapping for image
  String _imageForModel(String model) {
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('sedan') || m.contains('accord')) {
      return 'lib/assets/images/sedan_silver.png';
    }
    return 'lib/assets/images/car_icon.png'; // fallback
  }
}
