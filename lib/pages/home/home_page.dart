import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../widgets/appbar.dart';
import '../../../widgets/bottom_navbar.dart';
import '../../../core/constants/colors.dart';
import '../../../widgets/vehicle_add_card.dart';
import '../../../widgets/vehicle_info_card.dart';
import '../home/home_empty_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selVehicleId;
  String? _selModel;
  String? _selPlate;
  String? _selImg;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/signin'),
      );
      return const SizedBox.shrink();
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final latestVehicleQ = userDoc
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .limit(1);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = userSnap.data!.data() ?? {};
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
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: latestVehicleQ.snapshots(),
                      builder: (context, vehSnap) {
                        if (vehSnap.connectionState ==
                            ConnectionState.waiting) {
                          return _loadingVehicleCardSkeleton();
                        }
                        if (vehSnap.hasError) {
                          return VehicleAddCard(
                            onTap: () =>
                                Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        final docs = vehSnap.data?.docs ?? [];
                        if (docs.isEmpty && _selModel == null) {
                          return VehicleAddCard(
                            onTap: () =>
                                Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        // Firestore “base” (latest) vehicle
                        String baseVehicleId = '';
                        String baseModel = '';
                        String basePlate = '';
                        String baseImg = 'lib/assets/images/car_icon.png';

                        if (docs.isNotEmpty) {
                          final first = docs.first;
                          final v = first.data();
                          baseVehicleId = first.id;
                          baseModel = (v['model'] ?? '') as String;
                          basePlate = (v['plateNumber'] ?? '') as String;
                          baseImg = _imageForModel(baseModel);
                        }

                        // Use selection if present, else base
                        final vehicleId = _selVehicleId ?? baseVehicleId;
                        final model = _selModel ?? baseModel;
                        final plate = _selPlate ?? basePlate;
                        final img = _selImg ?? baseImg;

                        return VehicleInfoCard(
                          model: model,
                          plateNumber: plate,
                          imagePath: img,
                          onSwap: () async {
                            final picked = await Navigator.pushNamed(
                              context,
                              '/swap_vehicle',
                            );
                            if (picked is Map) {
                              final selectedModel = (picked['model'] ?? '')
                                  .toString();
                              setState(() {
                                _selVehicleId = (picked['id'] ?? '').toString();
                                _selModel = selectedModel;
                                _selPlate = (picked['plate'] ?? '').toString();
                                _selImg = _imageForModel(selectedModel);
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // ===== Main content: if hasVehicle, check service records of active vehicle =====
              Expanded(
                child: hasVehicle
                    ? _ActiveVehicleServiceGate(
                        uid: user.uid,
                        // if user picked a vehicle use it, else look up latest one again here
                        selectedVehicleId: _selVehicleId,
                      )
                    : HomeEmptyView(),
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (i) {
              if (i == 0) {
                //
              } else if (i == 1) {
                Navigator.pushNamed(context, '/service_Page');

              } else if (i == 3) {
                Navigator.pushNamed(context, '/more');
              }
            },
          ),
        );
      },
    );
  }

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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  String _imageForModel(String model) {
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('myvi')) return 'lib/assets/images/peroduamyvi.png';
    if (m.contains('civic')) return 'lib/assets/images/civic.png';
    if (m.contains('accord')) return 'lib/assets/images/accord.jpg';
    return 'lib/assets/images/car_icon.png';
  }
}

/// Decides what to show based on whether the **active vehicle** has service records.
/// - If `selectedVehicleId` is provided, we use that.
/// - Else we fetch the latest vehicle and check its services.
class _ActiveVehicleServiceGate extends StatelessWidget {
  const _ActiveVehicleServiceGate({required this.uid, this.selectedVehicleId});

  final String uid;
  final String? selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    // If we already know which vehicle is active, just check its services.
    if (selectedVehicleId != null && selectedVehicleId!.isNotEmpty) {
      final servicesQ = userDoc
          .collection('vehicles')
          .doc(selectedVehicleId)
          .collection('services')
          .limit(1);
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: servicesQ.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasAny = (snap.data?.docs.isNotEmpty ?? false);
          return hasAny
              ? const Center(child: Text("Main content here..."))
              : const ServiceEmptyView();
        },
      );
    }

    // Otherwise, find the latest vehicle, then check its services
    final latestVehicleQ = userDoc
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: latestVehicleQ.snapshots(),
      builder: (context, vehSnap) {
        if (vehSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final vDocs = vehSnap.data?.docs ?? [];
        if (vDocs.isEmpty) {
          // No vehicle at all – should not happen since parent already checked
          return HomeEmptyView();
        }
        final vehicleId = vDocs.first.id;

        final servicesQ = userDoc
            .collection('vehicles')
            .doc(vehicleId)
            .collection('services')
            .limit(1);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: servicesQ.snapshots(),
          builder: (context, sSnap) {
            if (sSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final hasAny = (sSnap.data?.docs.isNotEmpty ?? false);
            return hasAny
                ? const Center(child: Text("Main content here..."))
                : const ServiceEmptyView();
          },
        );
      },
    );
  }
}

/// Simple empty state for “no service records yet”
class ServiceEmptyView extends StatelessWidget {
  const ServiceEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Swap to your own artwork
            Image.asset(
              'lib/assets/images/setup_complete.png',
              width: 300,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/Service');
              },
              child: Text(
                "Book Service",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryGreen,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
