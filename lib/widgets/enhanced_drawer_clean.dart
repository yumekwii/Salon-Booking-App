import '../theme/app_theme.dart';
// ============================================================================
// FILE: lib/widgets/enhanced_drawer_clean.dart
// Copy-paste this ENTIRE file into your project
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // For HomePage
import '../pages/my_appointments_page.dart';

// ============================================================================
// 1. ENHANCED DRAWER CLEAN
// ============================================================================
class EnhancedDrawerClean extends StatelessWidget {
  final String userName;
  final String userEmail;

  const EnhancedDrawerClean({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        color: AppColors.surfaceAlt,
        child: Column(
          children: [
            // User Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // My Appointments
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      title: const Text(
                        'My Appointments & History',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAppointmentsPage(),
                          ),
                        );
                      },
                    ),

                    // Profile Settings
                    ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      title: const Text(
                        'Profile Settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSettingsPage(),
                          ),
                        );
                      },
                    ),

                    // View Staff Schedule
                    ListTile(
                      leading: const Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      title: const Text(
                        'View Staff Schedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffSchedulesViewPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 20, thickness: 1),
                  ],
                ),
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Log Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. STAFF SCHEDULE VIEWER PAGE (Different name to avoid conflict!)
// ============================================================================
