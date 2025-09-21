import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/constants/scale.dart';

class CustomAppBar extends StatelessWidget {
  final String? fullName;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final bool isEmpty;
  final bool showNotifications;
  final double height;

  const CustomAppBar({
    super.key,
    this.fullName,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.isEmpty = false,
    this.showNotifications = true,
    this.height = Scale.defaultAppbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: Container(
            height: height,
            width: double.infinity,
            color: AppColors.primaryGreen,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 40,
                  left: -60,
                  child: Container(
                    width: 135,
                    height: 135,
                    decoration: const BoxDecoration(
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
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                if (!isEmpty)
                  Positioned(
                    top: 60,
                    left: showBack ? 0 : Scale.cardMargin + 2,
                    right: Scale.cardMargin,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showBack)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 68,
                              minHeight: 68,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null) ...[
                                Text(
                                  title!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 240, 240, 240),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                              ] else if (fullName != null) ...[
                                const Text(
                                  "Welcome back,",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  fullName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (showNotifications)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Symbols.notifications,
                              color: AppColors.primaryGreen,
                              weight: 900,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
