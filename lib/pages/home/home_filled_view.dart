import 'package:flutter/material.dart';
import '../../../widgets/vehicle_add_card.dart'; // If you want to reuse the add card
import '../../../widgets/vehicle_info_card.dart'; // For registered vehicle info (to create)
import '../../../core/constants/colors.dart';

class HomeFilledView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Example registered vehicle info
        VehicleInfoCard(
          model: "Honda Accord 2.4L",
          plateNumber: "ABC 1234",
          imagePath: 'lib/assets/images/x50.png',
        ),

        SizedBox(height: 30),



        // Add more widgets like upcoming services, history, etc.
        SizedBox(height: 100),
      ],
    );
  }
}
