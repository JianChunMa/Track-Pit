import 'package:flutter/material.dart';
import 'package:assignment/pages/home/home_empty_view.dart';
import 'package:assignment/pages/home/home_empty_view.dart';
import '../../../widgets/appbar.dart';
import '../../../widgets/bottom_navbar.dart';
import '../../../core/constants/colors.dart';
import 'package:assignment/widgets/vehicle_add_card.dart';
import 'package:assignment/widgets/vehicle_info_card.dart';

class HomePage extends StatelessWidget {
  final bool hasVehicle = true; // 👈 Set to false to test "Add a vehicle"

  @override
  Widget build(BuildContext context) {
    int i=0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom AppBar with conditional vehicle widget
          Stack(
            clipBehavior: Clip.none,
            children: [
              CustomAppBar(userName: "Mr. Lim Yuet Yang"),

              // Show based on vehicle status
              Positioned(
                bottom: -35,
                left: 16,
                right: 16,
                child: hasVehicle
                    ? VehicleInfoCard(
                  model: "Proton X50 1.5T",
                  plateNumber: "ABC 1234",
                  imagePath: 'lib/assets/images/x50.png',
                )
                    : VehicleAddCard(), // Your reusable widget
              ),
            ],
          ),

          SizedBox(height: 50),

          // Rest of body
          Expanded(
            child: Center(
              child: Text("Main content here..."),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0, onTap: (i) {
        if (i == 0) {
          Navigator.pushNamed(context, '/home');
        }
        else if(i==3){
          Navigator.pushNamed(context, '/more');
        }
      }),
    );
  }
}

