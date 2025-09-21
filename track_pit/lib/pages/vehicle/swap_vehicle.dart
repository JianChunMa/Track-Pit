import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/widgets/vehicle/vehicle_list_card.dart';
import 'package:track_pit/services/car_model_service.dart';

class SwapVehiclePage extends StatefulWidget {
  const SwapVehiclePage({super.key});

  @override
  State<SwapVehiclePage> createState() => _SwapVehiclePageState();
}

class _SwapVehiclePageState extends State<SwapVehiclePage> {
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VehicleProvider>().startListening();
      }
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

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isSelecting) {
          Navigator.pop(context);
        }
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
              if (!_isSelecting) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Builder(
          builder: (context) {
            if (vehicleProv.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vehicleProv.error != null) {
              return Center(child: Text('Error: ${vehicleProv.error}'));
            }
            if (vehicleProv.vehicles.isEmpty) {
              return const Center(child: Text('No vehicles found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              itemCount: vehicleProv.vehicles.length,
              itemBuilder: (context, i) {
                final v = vehicleProv.vehicles[i];

                return FutureBuilder<String>(
                  future: CarModelService.getImagePathForModel(v.model),
                  builder: (context, snap) {
                    final imagePath = snap.data ?? 'assets/images/car_icon.png';

                    return VehicleListCard(
                      id: v.id,
                      plateNumber: v.plateNumber,
                      model: v.model,
                      chassisNumber: v.chassisNumber,
                      imagePath: imagePath,
                      selectMode: true,
                      onTap: () {
                        if (_isSelecting) return;
                        setState(() {
                          _isSelecting = true;
                        });
                        final vehicleProvider = context.read<VehicleProvider>();
                        vehicleProvider.setSelectedVehicle(v.id);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                        if (mounted) {
                          setState(() {
                            _isSelecting = false;
                          });
                        }
                      },

                      onEdit: null,
                      onDelete: null,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
