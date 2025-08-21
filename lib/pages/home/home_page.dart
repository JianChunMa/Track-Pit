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

    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() ?? {};
        final fullName =
            (data['fullName'] as String?) ?? (user.displayName ?? 'User');
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
                  Positioned(
                    bottom: -35,
                    left: 16,
                    right: 16,
                    child: hasVehicle
                        ? VehicleInfoCard(
                      model: "Proton X50 1.5T",
                      plateNumber: "ABC 1234",
                      imagePath: 'lib/assets/images/x50.png',

                    )
                        :  VehicleAddCard(onTap: () => Navigator.pushNamed(context, '/addvehicle'),),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // ===== Main content switches here =====
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
}
