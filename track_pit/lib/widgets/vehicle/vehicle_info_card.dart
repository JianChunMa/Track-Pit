import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class VehicleInfoCard extends StatelessWidget {
  final String model;
  final String plateNumber;
  final String imagePath;
  final VoidCallback? onSwap;
  final double? top;

  const VehicleInfoCard({
    super.key,
    required this.model,
    required this.plateNumber,
    required this.imagePath,
    this.onSwap,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: top == null ? Scale.cardTopOffset : null,
      left: Scale.cardMargin,
      right: Scale.cardMargin,
      child: GestureDetector(
        onTap: onSwap,
        child: Container(
          height: Scale.cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primaryAccent, width: 2),
            borderRadius: BorderRadius.circular(Scale.cardBorderRadius),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 6,
                offset: Offset(0, 2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 24),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plateNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (onSwap != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Symbols.swap_horiz,
                    color: Colors.white,
                    size: 26,
                    weight: 800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
