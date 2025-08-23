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
  String? _selModel;
  String? _selPlate;
  String? _selImg;

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
        final fullName =
            (data['fullName'] as String?) ?? (user.displayName ?? 'User');
        final hasVehicle = ((data['vehicleCount'] ?? 0) as int) > 0;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
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
                        if (vehSnap.connectionState == ConnectionState.waiting) {
                          return _loadingVehicleCardSkeleton();
                        }
                        if (vehSnap.hasError) {
                          print('Error loading vehicle: ${vehSnap.error}');
                          return VehicleAddCard(
                            onTap: () => Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        final docs = vehSnap.data?.docs ?? [];
                        if (docs.isEmpty && _selModel == null) {
                          print('No vehicles found in Firestore');
                          return VehicleAddCard(
                            onTap: () => Navigator.pushNamed(context, '/addvehicle'),
                          );
                        }

                        String baseModel = '';
                        String basePlate = '';
                        String baseImg = 'lib/assets/images/car_icon.png';

                        if (docs.isNotEmpty) {
                          final v = docs.first.data();
                          baseModel = (v['model'] ?? '') as String;
                          basePlate = (v['plateNumber'] ?? '') as String;
                          baseImg = _imageForModel(baseModel);
                          print('Firestore vehicle: model=$baseModel, plate=$basePlate, img=$baseImg');
                        } else {
                          print('Using default values: model=$baseModel, plate=$basePlate, img=$baseImg');
                        }

                        final model = _selModel ?? baseModel;
                        final plate = _selPlate ?? basePlate;
                        final img = _selImg ?? baseImg;

                        print('Rendering VehicleInfoCard: model=$model, plate=$plate, img=$img');

                        return VehicleInfoCard(
                          model: model,
                          plateNumber: plate,
                          imagePath: img,
                          onSwap: () async {
                            print('Navigating to /swap_vehicle');
                            final picked = await Navigator.pushNamed(
                              context,
                              '/swap_vehicle',
                            );
                            if (picked is Map) {
                              final selectedModel = (picked['model'] ?? '').toString();
                              setState(() {
                                _selModel = selectedModel;
                                _selPlate = (picked['plate'] ?? '').toString();
                                _selImg = _imageForModel(selectedModel);
                              });
                              print('Selected vehicle: model=$_selModel, plate=$_selPlate, img=$_selImg');
                            } else {
                              print('No vehicle selected');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

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
              } else if (i == 1) {
                Navigator.pushReplacementNamed(context, '/bookService');
              } else if (i == 3) {
                Navigator.pushReplacementNamed(context, '/more');
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
    print('HomePage: Mapping image for model: $model');
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('myvi')) return 'lib/assets/images/peroduamyvi.png';

    return 'lib/assets/images/car_icon.png';
  }
}