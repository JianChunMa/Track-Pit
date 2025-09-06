import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../widgets/appbar.dart';                 // CustomAppBar(title/subtitle/showBack)
import '../../widgets/vehicle_info_card.dart';      // header card with onSwap()
import '../../widgets/bottom_navbar.dart';
import '../home/home_empty_view.dart';
import '../../widgets/service_record_card.dart';    // your reusable list item

class ServicesPage extends StatefulWidget {
  const ServicesPage({Key? key}) : super(key: key);

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage>
    with SingleTickerProviderStateMixin {
  // vehicle selection (latest by default; can be swapped)
  String? _selVehicleId;
  String? _selModel;
  String? _selPlate;
  String? _selImg;

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== Header with title/subtitle + overlapping vehicle card =====
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CustomAppBar(
                title: 'Services',
                subtitle: 'Your service records',
                showBack: false,
              ),
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

                    final docs = vehSnap.data?.docs ?? [];
                    if (docs.isEmpty && _selModel == null) {
                      // No vehicles yet
                      return Container(
                        height: 80,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.primaryAccent),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car,
                                size: 32, color: Colors.black38),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No vehicle available. Add a vehicle first.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/addvehicle'),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Base (latest) from Firestore
                    String baseId = '';
                    String baseModel = '';
                    String basePlate = '';
                    String baseImg = 'lib/assets/images/car_icon.png';

                    if (docs.isNotEmpty) {
                      final first = docs.first;
                      final v = first.data();
                      baseId = first.id;
                      baseModel = (v['model'] ?? '') as String;
                      basePlate = (v['plateNumber'] ?? '') as String;
                      baseImg = _imageForModel(baseModel);
                    }

                    final vehicleId = _selVehicleId ?? baseId;
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
                          arguments: {'selectMode': true},
                        );
                        if (!mounted) return;
                        if (picked is Map) {
                          final m = (picked['model'] ?? '').toString();
                          setState(() {
                            _selVehicleId = (picked['id'] ?? '').toString();
                            _selModel = m;
                            _selPlate = (picked['plate'] ?? '').toString();
                            _selImg = _imageForModel(m);
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

          // ===== Tab Bar =====
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              indicatorColor: AppColors.primaryGreen,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),
          ),

          // ===== Tab Views =====
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildListDummy(status: 'upcoming'),
                _buildListDummy(status: 'ongoing'),
                _buildListDummy(status: 'completed'),
              ],
            ),
          ),
        ],
      ),

      // FAB → Book Service
      floatingActionButton: FloatingActionButton(
        heroTag: 'bookFab',
        backgroundColor: AppColors.primaryGreen,
        onPressed: () => Navigator.pushNamed(context, '/bookService'),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Services tab
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/home');
          if (i == 1) {/* already here */}
          if (i == 2) Navigator.pushReplacementNamed(context, '/billing');
          if (i == 3) Navigator.pushReplacementNamed(context, '/more');
        },
      ),
    );
  }

  // --- demo list; replace with Firestore query later ---
  Widget _buildListDummy({required String status}) {
    // MOCK DATA — replace with your query results
    final items = switch (status) {
      'upcoming' => [
        (
        date: DateTime(2025, 8, 19, 14, 0),
        title: 'Air Conditional Repair',
        workshop: 'Kuala Lumpur, MH Prestige Auto Sdn Bhd',
        price: 500.0
        ),
        (
        date: DateTime(2025, 8, 29, 14, 0),
        title: 'Brake Repair',
        workshop: 'Kuala Lumpur, MH Prestige Auto Sdn Bhd',
        price: 500.0
        )
      ],
      'ongoing' => [
        (
        date: DateTime.now(),
        title: 'Major Service',
        workshop: 'Speedy Autos (PJ)',
        price: 750.0
        )
      ],
      _ => [
        (
        date: DateTime(2025, 5, 12, 10, 0),
        title: 'Regular Service',
        workshop: 'Green Motors (Setapak)',
        price: 300.0
        )
      ],
    };

    if (items.isEmpty) {
      return Center(child: HomeEmptyView());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final it = items[i];
        return ServiceRecordCard(
          dateTime: it.date,
          title: it.title,
          workshop: it.workshop,
          price: it.price,
          onDetails: () {
            // TODO: push to service details
            // Navigator.pushNamed(context, '/service_details', arguments: {...});
          },
        );
      },
    );
  }

  // small skeleton that matches your header vehicle card
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
