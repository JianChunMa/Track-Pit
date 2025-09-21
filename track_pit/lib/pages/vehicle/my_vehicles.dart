import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/services/car_model_service.dart';
import 'package:track_pit/widgets/vehicle/vehicle_list_card.dart';
import 'package:track_pit/core/constants/colors.dart';

class MyVehiclePage extends StatefulWidget {
  const MyVehiclePage({super.key});

  @override
  State<MyVehiclePage> createState() => _MyVehiclePageState();
}

class _MyVehiclePageState extends State<MyVehiclePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().startListening();
    });
  }

  @override
  void dispose() {
    context.read<VehicleProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProv = context.watch<VehicleProvider>();

    if (vehicleProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vehicleProv.vehicles.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("My Vehicles"),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("No vehicles yet."),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/add_vehicle'),
                child: const Text("Add Vehicle"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Vehicles"),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () => Navigator.pushNamed(context, '/add_vehicle'),
        shape: const CircleBorder(),
        child: const Icon(
          Symbols.add,
          color: Colors.white,
          weight: 900,
          size: 28,
        ),
      ),
      body: ListView.builder(
        itemCount: vehicleProv.vehicles.length,
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        itemBuilder: (context, i) {
          final v = vehicleProv.vehicles[i];

          return FutureBuilder<String>(
            future: CarModelService.getImagePathForModel(v.model),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final imagePath = snap.data ?? 'assets/images/car_icon.png';

              return VehicleListCard(
                id: v.id,
                plateNumber: v.plateNumber,
                model: v.model,
                chassisNumber: v.chassisNumber,
                imagePath: imagePath,
              );
            },
          );
        },
      ),
    );
  }
}
