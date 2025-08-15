import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class VehicleAddCard extends StatelessWidget {
  final VoidCallback? onTap;

  const VehicleAddCard({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // optional tap handler
      child: Container(
        height: 80,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppColors.primaryAccent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.grey.shade300,
            )
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset('lib/assets/images/car_icon.png'),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Add a vehicle",
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
