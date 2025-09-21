
import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';

class ServiceEmptyView extends StatelessWidget {
  const ServiceEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/setup_complete.png',
              width: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/book_service');
              },
              child: Text(
                "Book Service",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryGreen,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}