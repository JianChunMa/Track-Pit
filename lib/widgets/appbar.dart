import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class CustomAppBar extends StatelessWidget {
  final String? userName;
  final String? title;
  final bool showBack;

  const CustomAppBar({
    Key? key,
    this.userName,
    this.title,
    this.showBack = false, // default false
  }) : super(key: key);

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
              // Decorative circles
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
                    color: AppColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Title or greeting
              Positioned(
                top: 60,
                left: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ] else if (userName != null) ...[
                      const Text(
                        "Welcome back,",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Back button (optional)
              if (showBack)
                Positioned(
                  top: 50,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

              // Notification icon (only show if not in "back" mode)
              if (!showBack)
                Positioned(
                  top: 60,
                  right: 17,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: AppColors.primaryGreen,
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
