import 'package:flutter/material.dart';
import '/core/constants/colors.dart';

class VehicleListCard extends StatelessWidget {
  final String plateNumber;
  final String model;
  final String chassisNumber;
  final String imagePath; // asset or network
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool selectMode;

  const VehicleListCard({
    Key? key,
    required this.plateNumber,
    required this.model,
    required this.chassisNumber,
    required this.imagePath,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.onEdit,
    this.onDelete,
    this.selectMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFF29A87A); // primary

    return Container(
      margin: margin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Left block: text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plateNumber,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Chassis No.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          chassisNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right: car image
                  SizedBox(
                    width: 128,
                    height: 74,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imagePath.startsWith('http')
                          ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/assets/images/car_icon.png',
                            fit: BoxFit.contain,
                          );
                        },
                      )
                          : Image.asset(imagePath, fit: BoxFit.contain),

                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu icon in top-right corner (only shown if not in selectMode)
          if (!selectMode)
            Positioned(
              top: 5,
              right: 3,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  print('PopupMenuButton selected: $value, selectMode: $selectMode');
                  if (value == 'edit' && onEdit != null) {
                    Future.microtask(onEdit!);
                  }
                  if (value == 'delete' && onDelete != null) {
                    Future.microtask(onDelete!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}