import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/core/utils/snackbar.dart';
import 'package:track_pit/pages/find_workshop.dart';
import 'package:track_pit/pages/more/faq_page.dart';
import 'package:track_pit/pages/more/feedback_page.dart';
import 'package:track_pit/pages/more/profile_page.dart';
import 'package:track_pit/pages/vehicle/my_vehicles.dart';
import 'package:track_pit/provider/auth_provider.dart';
import 'package:track_pit/provider/user_provider.dart';
import 'package:track_pit/widgets/layout/appbar.dart';
import 'package:track_pit/widgets/layout/bottom_navbar.dart';
import 'package:track_pit/widgets/more/profile_card.dart';
import 'package:track_pit/widgets/vehicle/confirm_dialog.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    if (!auth.isLoggedIn) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      });
      return const SizedBox.shrink();
    }

    if (!userProvider.isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    final name = userProvider.fullName;
    final email = userProvider.email;

    final menuItems = [
      {'title': 'Profile', 'page': const ProfilePage()},
      {'title': 'Find Workshop', 'page': const FindWorkshopPage()},
      {'title': 'My Vehicles', 'page': const MyVehiclePage()},
      {'title': 'Feedback', 'page': const FeedbackPage()},
      {'title': 'FAQ', 'page': const FaqPage()},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CustomAppBar(isEmpty: true, height: 180),
              ProfileCard(name: name, email: email),
            ],
          ),
          const SizedBox(height: 70),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _MenuTile(
                  title: item['title'] as String,
                  onTap: () {
                    final page = item['page'];
                    if (page != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => page as Widget),
                      );
                    } else {
                      showClosableSnackBar(
                        context,
                        '${item['title']} coming soon',
                      );
                    }
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => const ConfirmDialog(
                          title: "Logout",
                          message: "Are you sure you want to log out?",
                          confirmText: "Logout",
                          cancelText: "Cancel",
                        ),
                  );

                  if (confirmed == true) {
                    // ignore: use_build_context_synchronously
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  }
                },

                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _MenuTile({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
