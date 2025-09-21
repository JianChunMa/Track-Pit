import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class VehicleLoadingCard extends StatelessWidget {
  final double? top;
  const VehicleLoadingCard({super.key, this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: top == null ? Scale.cardTopOffset : null,
      left: Scale.cardMargin,
      right: Scale.cardMargin,
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
            // image skeleton
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 24),

            // text skeletons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // action button skeleton
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
