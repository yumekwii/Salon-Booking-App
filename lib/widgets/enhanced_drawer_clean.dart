// ============================================================================
// FILE: lib/widgets/enhanced_drawer_clean.dart
// Copy-paste this ENTIRE file into your project
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/scheduling_provider.dart';
import '../models/scheduling_models.dart';
import '../main.dart'; // For HomePage

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
        color: const Color(0xFFD3CBBB),
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
                color: Color(0xFF8B0000),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                        color: Color(0xFF8B0000),
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
                        // TODO: Navigate to appointments page
                      },
                    ),

                    // Profile Settings
                    ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF8B0000),
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
                        // TODO: Navigate to profile page
                      },
                    ),

                    // View Staff Schedule
                    ListTile(
                      leading: const Icon(
                        Icons.schedule,
                        color: Color(0xFF8B0000),
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
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => SchedulingProvider(),
                              child: const StaffScheduleViewerPage(),
                            ),
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
class StaffScheduleViewerPage extends StatefulWidget {
  const StaffScheduleViewerPage({super.key});

  @override
  State<StaffScheduleViewerPage> createState() => _StaffScheduleViewerPageState();
}

class _StaffScheduleViewerPageState extends State<StaffScheduleViewerPage> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B0000),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBEB5A8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Staff Schedule',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<SchedulingProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Appointment>>(
            stream: provider.service.getAppointmentsStream(_selectedDate),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                provider.updateAppointments(snapshot.data!);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B0000),
                    strokeWidth: 3,
                  ),
                );
              }

              final slots =
                  provider.service.generateTimeSlots(_selectedDate);

              return Column(
                children: [
                  // Date Selector
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Change Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scheduling Grid
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    _buildHeaderCell('Staff',
                                        isCorner: true),
                                    ...slots.map((slot) =>
                                        _buildHeaderCell(slot.displayTime)),
                                  ],
                                ),

                                // Staff Rows
                                ...provider.service.staff.map((staff) {
                                  return Row(
                                    children: [
                                      _buildStaffNameCell(staff.name),
                                      ...slots.map((slot) {
                                        final isAvailable = provider
                                            .isSlotAvailable(staff.id, slot);
                                        return _buildSlotCell(isAvailable);
                                      }),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isCorner = false}) {
    return Container(
      width: isCorner ? 100 : 75,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStaffNameCell(String name) {
    return Container(
      width: 100,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE8DCC8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSlotCell(bool isAvailable) {
    return Container(
      width: 75,
      height: 56,
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFCDD2),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable
                ? const Color(0xFF4CAF50)
                : const Color(0xFFD32F2F),
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            isAvailable ? 'Free' : 'Booked',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}