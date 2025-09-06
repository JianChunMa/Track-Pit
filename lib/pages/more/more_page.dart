import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../home/home_page.dart'; // adjust to your paths
import '../../../widgets/appbar.dart';
import '../../../widgets/bottom_navbar.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Guest';
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ====== GREEN HEADER with overlapping profile card ======
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.primaryGreen, // 0xFF29A87A
                child: Stack(
                  children: [
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
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 120,
                child: _ProfileCard(name: name, email: email),
              ),
            ],
          ),
          const SizedBox(height: 70),

          // ====== MENU ======
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _MenuTile(
                  title: 'Profile',
                  onTap: () {
                    /* Navigator.pushNamed(context, '/profile'); */
                  },
                ),
                _divider(),
                _MenuTile(
                  title: 'Find Workshops',
                  onTap: () {
                    /* Navigator.pushNamed(context, '/workshops'); */
                  },
                ),
                _divider(),
                _MenuTile(
                  title: 'My Vehicles',
                  onTap: () {
                    Navigator.pushNamed(context, '/my_vehicles');
                  },
                ),
                _divider(),
                _MenuTile(
                  title: 'Payment Methods',
                  onTap: () {
                    /* Navigator.pushNamed(context, '/payments'); */
                  },
                ),
                _divider(),
                _MenuTile(
                  title: 'Feedback',
                  onTap: () {
                    /* Navigator.pushNamed(context, '/feedback'); */
                  },
                ),
                _divider(),
                _MenuTile(
                  title: 'FAQ',
                  onTap: () {
                    /* Navigator.pushNamed(context, '/faq'); */
                  },
                ),
                const SizedBox(height: 24),

                // ====== LOGOUT BUTTON ======
                SizedBox(
                  height: 52,
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
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/signin',
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),

      // ====== REUSABLE BOTTOM NAVBAR ======
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, // "More"
        onTap: (i) {
          if (i == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (i == 1) {
            Navigator.pushReplacementNamed(context, '/service_Page');
          } else if (i == 3) {
            Navigator.pushReplacementNamed(context, '/more');
          }
          // handle other indexes as you add pages
        },
      ),
    );
  }

  Widget _divider() => const Divider(height: 0);
  Widget _circle(double s, Color c) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

// ---------------- Reusable pieces ----------------

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileCard({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
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
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
      minLeadingWidth: 0,
    );
  }
}
