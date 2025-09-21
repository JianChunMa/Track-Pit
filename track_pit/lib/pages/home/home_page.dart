import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_pit/pages/vehicle/swap_vehicle.dart';
import 'package:track_pit/services/car_model_service.dart';
import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/layout/bottom_navbar.dart';
import 'package:track_pit/widgets/vehicle/vehicle_add_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_loading_card.dart';
import 'package:track_pit/widgets/vehicle/vehicle_info_card.dart';
import 'package:track_pit/pages/home/home_empty_view.dart';
import 'package:track_pit/pages/home/service_empty_view.dart';
import 'package:track_pit/provider/user_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final vehicleProv = context.watch<VehicleProvider>();
    final name = userProvider.fullName;
    var selected = vehicleProv.selectedVehicle;
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CustomAppBar(fullName: name),
              if (vehicleProv.isLoading)
                const VehicleLoadingCard()
              else if (selected != null)
                FutureBuilder<String>(
                  future: CarModelService.getImagePathForModel(selected.model),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const VehicleLoadingCard();
                    }

                    final imagePath =
                        snapshot.data ?? 'assets/images/car_icon.png';

                    return VehicleInfoCard(
                      model: selected.model,
                      plateNumber: selected.plateNumber,
                      imagePath: imagePath,
                      onSwap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SwapVehiclePage(),
                          ),
                        );
                      },
                    );
                  },
                )
              else
                const VehicleAddCard(),
            ],
          ),
          const SizedBox(height: 50),
          Expanded(
            child: uid == null
                ? const HomeEmptyView()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('services')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hasServices = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                final hasVehicles = vehicleProv.vehicles.isNotEmpty || selected != null;

                if (hasVehicles && !hasServices) {
                  return const ServiceEmptyView();
                }

                return const HomeEmptyView();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}