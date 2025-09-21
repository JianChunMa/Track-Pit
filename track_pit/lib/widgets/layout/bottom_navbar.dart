import 'package:flutter/material.dart';
import '/core/constants/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, this.currentIndex = 0});

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/service_page');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/billing');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 220, 220, 220), width: 1),
        ),
      ),
      child: SizedBox(
        height: 64,
        child: BottomNavigationBar(
          backgroundColor: AppColors.white,
          currentIndex: currentIndex,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => _handleTap(context, i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: "Services"),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: "Billing",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
          ],
        ),
      ),
    );
  }
}
