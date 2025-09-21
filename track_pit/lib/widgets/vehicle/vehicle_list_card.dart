import 'package:flutter/material.dart';
import 'package:track_pit/pages/vehicle/vehicle_details.dart';
import '/core/constants/colors.dart';

class VehicleListCard extends StatelessWidget {
  final String id;
  final String plateNumber;
  final String model;
  final String chassisNumber;
  final String imagePath;
  final EdgeInsets margin;

  final bool selectMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleListCard({
    super.key,
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.chassisNumber,
    required this.imagePath,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.selectMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (selectMode) {
            onTap?.call();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailsPage(vehicleId: id),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ), // taller padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.secondaryGreen, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.14),
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plateNumber,
                      style: const TextStyle(
                        fontSize: 28, // bigger plate
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      model,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chassis No.',
                      style: TextStyle(
                        height: 1.2,
                        fontSize: 15,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      chassisNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                height: 86, // increased height for better balance
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      imagePath.startsWith('http')
                          ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/car_icon.png',
                                fit: BoxFit.contain,
                              );
                            },
                          )
                          : Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),

              if (!selectMode && (onEdit != null || onDelete != null)) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
