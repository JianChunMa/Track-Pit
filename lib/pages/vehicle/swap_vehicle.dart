import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/vehicle_list_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/user_services.dart';
import '../../core/constants/colors.dart';

class SwapVehiclePage extends StatefulWidget {
  const SwapVehiclePage({Key? key}) : super(key: key);

  @override
  _SwapVehiclePageState createState() => _SwapVehiclePageState();
}

class _SwapVehiclePageState extends State<SwapVehiclePage> {
  bool _isSelecting = false;

  String _imageForModel(String model) {
    print('HomePage: Mapping image for model: $model');
    final m = model.toLowerCase();
    if (m.contains('x50')) return 'lib/assets/images/x50.png';
    if (m.contains('myvi')) return 'lib/assets/images/peroduamyvi.png';

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
        print('WillPopScope triggered, isSelecting: $_isSelecting');
        return !_isSelecting;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Select Vehicle to Swap'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              print('AppBar back button pressed');
              if (!_isSelecting) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: vehiclesCol.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              print('No vehicles found in Firestore for swapping');
              return const Center(child: Text('No vehicles found.'));
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
                  selectMode: true,
                  onTap: () {
                    if (_isSelecting) {
                      print('Selection already in progress');
                      return;
                    }
                    print('Selecting vehicle: $plateNumber');
                    setState(() {
                      _isSelecting = true;
                    });
                    Future.microtask(() {
                      if (mounted) {
                        print('Navigating back with vehicle: $plateNumber, img=$imagePath');
                        Navigator.pop(context, {
                          'id': vehicleId,
                          'plate': plateNumber,
                          'model': model,
                          'img': imagePath,
                        });
                        setState(() {
                          _isSelecting = false;
                        });
                      } else {
                        print('Widget not mounted, skipping navigation');
                      }
                    });
                  },
                  onEdit: null,
                  onDelete: null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}