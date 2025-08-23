// lib/widgets/vehicle_info_card.dart
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class VehicleInfoCard extends StatelessWidget {
  final String model;
  final String plateNumber;
  final String imagePath;
  final VoidCallback? onSwap;

  const VehicleInfoCard({
    Key? key,
    required this.model,
    required this.plateNumber,
    required this.imagePath,
    this.onSwap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      width: double.infinity,
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
          Image.asset(imagePath, width: 80),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(plateNumber,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              ],
            ),
          ),
          // 🔁 Swap button
          InkWell(
            onTap: onSwap, // 👈 call back to parent
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
