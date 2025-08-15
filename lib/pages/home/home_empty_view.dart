// pages/home/home_empty_view.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class HomeEmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('lib/assets/images/findworkshop.png'),
          Text(
            "Explore",
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("Find nearby workshops from you"),
        ],
      ),
    );
  }
}
