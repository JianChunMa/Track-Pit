import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/pages/vehicle/edit_vehicle.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/widgets/vehicle/confirm_dialog.dart';
import 'package:track_pit/services/car_model_service.dart';

class VehicleDetailsPage extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailsPage({super.key, required this.vehicleId});

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProv = context.watch<VehicleProvider>();
    final vehicle = vehicleProv.vehicles.firstWhereOrNull(
      (v) => v.id == vehicleId,
    );

    if (vehicle == null) {
      return const Scaffold(
        body: Center(child: Text("This vehicle no longer exists.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Vehicle Details"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => const ConfirmDialog(
                      title: "Remove Vehicle",
                      message: "Are you sure you want to remove this vehicle?",
                      confirmText: "Delete",
                      cancelText: "Cancel",
                    ),
              );

              if (confirm == true) {
                if (context.mounted) Navigator.pop(context);
                await vehicleProv.deleteVehicle(
                  vehicle.id,
                  vehicle.plateNumber,
                );
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditVehiclePage(vehicle: vehicle),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: SizedBox(
              width: 240,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<String>(
                  future: CarModelService.getImagePathForModel(vehicle.model),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final imagePath =
                        snapshot.data ?? 'assets/images/car_icon.png';

                    return Image.asset(imagePath, fit: BoxFit.contain);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            vehicle.plateNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Text(
            vehicle.model,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
          const SizedBox(height: 20),
          const Divider(),

          _buildDetail("Chassis No.", vehicle.chassisNumber),
          _buildDetail("Year", vehicle.year.toString()),
          _buildDetail("Mileage", "${vehicle.mileage} km"),
          _buildDetail("Transmission", vehicle.transmission.name.toUpperCase()),
          _buildDetail("Created At", _formatDate(vehicle.createdAt)),
          if (vehicle.updatedAt != null)
            _buildDetail("Last Updated", _formatDate(vehicle.updatedAt!)),
        ],
      ),
    );
  }
}
