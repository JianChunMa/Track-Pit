import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/appbar.dart';
import '../../../widgets/bottom_navbar.dart';
import '../../../core/constants/colors.dart';
import 'package:assignment/widgets/vehicle_add_card.dart';
import 'package:assignment/widgets/vehicle_info_card.dart';
import 'package:assignment/pages/home/home_empty_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/signin'));
      return const SizedBox.shrink();
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final latestVehicleQ = userDoc
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .limit(1);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = userSnap.data!.data() ?? {};
        final fullName = (data['fullName'] as String?) ?? (user.displayName ?? 'User');
        final hasVehicle = ((data['vehicleCount'] ?? 0) as int) > 0;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Header + overlapping card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomAppBar(userName: fullName),

                  // Overlapping: show latest vehicle if any, else "Add Vehicle"
                  Positioned(
                    bottom: -35,
                    left: 16,
                    right: 16,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: latestVehicleQ.snapshots(),
                      builder: (context, vehSnap) {
                        if (vehSnap.connectionState == ConnectionState.waiting) {
                          // placeholder skeleton while loading
                          return _loadingVehicleCardSkeleton();
                        }
                        if (vehSnap.hasError) {
                          // fallback to Add card when error
                          return VehicleAddCard(
                            onTap: () => Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        final docs = vehSnap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return VehicleAddCard(
                            onTap: () => Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        final v = docs.first.data();
                        return VehicleInfoCard(
                          model: (v['model'] ?? '') as String,
                          plateNumber: (v['plateNumber'] ?? '') as String,
                          imagePath: _imageForModel((v['model'] ?? '').toString()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Main content switches here
              Expanded(
                child: hasVehicle
                    ? const Center(
                  child: Text(
                    "Main content here...",
                    style: TextStyle(fontSize: 16),
                  ),
                )
                    : HomeEmptyView(),
              ),
            ],
          ),

          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (i) {
              if (i == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (i == 3) {
                Navigator.pushReplacementNamed(context, '/more');
              }
            },
          ),
        );
      },
    );
  }

  // Small skeleton loader matching your card dimensions
  Widget _loadingVehicleCardSkeleton() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryAccent),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(width: 80, height: 56, color: Colors.black12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 140, color: Colors.black12),
                const SizedBox(height: 8),
                Container(height: 14, width: 100, color: Colors.black12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 32, height: 32, decoration: BoxDecoration(
            color: Colors.black12, borderRadius: BorderRadius.circular(8),
          )),
        ],
      ),
    );
  }

  /// Local asset mapping if you don't store an imagePath in Firestore.
  String _imageForModel(String model) {
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('accord')) return 'lib/assets/images/sedan_silver.png';
    return 'lib/assets/images/car_icon.png';
  }
}
