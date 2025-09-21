import 'package:flutter/material.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/pages/find_workshop.dart';

class HomeEmptyView extends StatelessWidget {
  const HomeEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FindWorkshopPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset('assets/images/find_workshop.png'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Explore",
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text("Find nearby workshops from you"),
            ],
          ),
        ),
      ),
    );
  }
}
