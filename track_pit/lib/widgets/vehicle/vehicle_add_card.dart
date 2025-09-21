import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class VehicleAddCard extends StatelessWidget {
  final double? top;
  const VehicleAddCard({super.key, this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: top == null ? Scale.cardTopOffset : null,
      left: Scale.cardMargin,
      right: Scale.cardMargin,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/add_vehicle');
        },
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
              Image.asset('assets/images/car_icon.png', width: 60, height: 60),
              const SizedBox(width: 24),
              const Expanded(
                child: Text(
                  "Add a vehicle",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Symbols.add,
                  color: Colors.white,
                  size: 28,
                  weight: 900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
