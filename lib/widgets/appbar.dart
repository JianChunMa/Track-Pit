import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import 'package:assignment/widgets/vehicle_add_card.dart';
class CustomAppBar extends StatelessWidget {
  final String userName;
  const CustomAppBar({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          color: AppColors.primaryGreen,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative background circles
              Positioned(
                top: 40,
                left: -60,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                right: -40,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    color:  AppColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Greeting text
              Positioned(
                top: 60,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification icon
              Positioned(
                top: 60,
                right: 17,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    color: Color(0xFF29A87A),
                  ),
                ),
              ),
            ],
          ),
        ),



      ],
    );
  }
}
