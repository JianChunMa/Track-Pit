import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/vehicle_list_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/user_services.dart';
import '../../core/constants/colors.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({Key? key}) : super(key: key);

  @override
  _MyVehiclesPageState createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  final _userService = UserService();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isDeleting = false;

  String _imageForModel(String model) {
    print('HomePage: Mapping image for model: $model');
    final m = model.toLowerCase();

    // Local asset matches
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('myvi')) return 'lib/assets/images/peroduamyvi.png';

    // Known online fallbacks (example hardcoded)
    if (m.contains('civic')) {
      return 'lib/assets/images/civic.png';
    }




    return 'lib/assets/images/car_icon.png';
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    final vehiclesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true);

    return WillPopScope(
      onWillPop: () async {
        print('WillPopScope triggered, isDeleting: $_isDeleting');
        return !_isDeleting;
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('My Vehicles'),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                print('AppBar back button pressed');
                if (!_isDeleting) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          floatingActionButton: SizedBox(
            width: 72,
            height: 72,
            child: FloatingActionButton(
              heroTag: 'addVehicleFab',
              backgroundColor: AppColors.primaryGreen,
              elevation: 5,
              shape: const CircleBorder(),
              onPressed: () {
                print('Navigating to /addvehicle');
                Navigator.pushNamed(context, '/addvehicle');
              },
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: vehiclesCol.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                print('No vehicles found in Firestore for MyVehiclesPage');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No vehicles yet.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          print('Navigating to /addvehicle from empty state');
                          Navigator.pushNamed(context, '/addvehicle');
                        },
                        child: const Text('Add Vehicle'),
                      ),
                    ],
                  ),
                );
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
                  final imagePath = _imageForModel(model);
                  print('Vehicle $i: id=$vehicleId, model=$model, plate=$plateNumber, img=$imagePath');

                  return VehicleListCard(
                    plateNumber: plateNumber,
                    model: model,
                    chassisNumber: chassis,
                    imagePath: imagePath,
                    selectMode: false,
                    onTap: () {
                      print('Tapped vehicle: $plateNumber');
                      // TODO: Navigate to details page if needed
                      // Example: Navigator.pushNamed(context, '/vehicle_details', arguments: {...});
                    },
                    onEdit: () {
                      print('Editing vehicle: $plateNumber');
                      // TODO: Navigate to edit page with vehicleId
                      // Example: Navigator.pushNamed(context, '/edit_vehicle', arguments: {...});
                    },
                    onDelete: () {
                      print('Initiating delete for vehicle: $plateNumber');
                      _confirmAndDelete(
                        uid: uid,
                        vehicleId: vehicleId,
                        plateNumber: plateNumber,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete({
    required String uid,
    required String vehicleId,
    required String plateNumber,
  }) async {
    if (_isDeleting) {
      print('Deletion already in progress');
      return;
    }
    print('Starting deletion for vehicle: $plateNumber');
    setState(() {
      _isDeleting = true;
    });

    try {
      final ok = await showDialog<bool>(
        context: _scaffoldMessengerKey.currentContext ?? context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => const ConfirmDialog(
          title: "Delete vehicle?",
          message: "This will remove the vehicle from your garage.",
          confirmText: "Delete",
          cancelText: "Cancel",
        ),
      );

      if (ok != true) {
        print('Deletion cancelled');
        return;
      }

      await _userService.removeVehicle(
        uid: uid,
        vehicleId: vehicleId,
        plateNumber: plateNumber,
      );

      if (_scaffoldMessengerKey.currentState != null) {
        print('Showing success SnackBar for: $plateNumber');
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(content: Text('Deleted $plateNumber')),
        );
      }
    } catch (e) {
      if (_scaffoldMessengerKey.currentState != null) {
        print('Showing error SnackBar: $e');
        _scaffoldMessengerKey.currentState!.showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) {
        print('Resetting deletion state');
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}