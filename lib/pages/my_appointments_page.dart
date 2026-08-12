import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/scheduling_models.dart';
import '../theme/app_theme.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStaffName(String staffId) {
    for (final staff in StaffMember.defaults) {
      if (staff.id == staffId) return staff.name;
    }
    return 'Staff';
  }

  String _formatDuration(String duration) {
    return duration.replaceAll('MINUTES', 'min').replaceAll('HOURS', 'hrs');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return const Color(0xFFFFA726);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My Appointments'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Done'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList('all'),
          _buildAppointmentsList('upcoming'),
          _buildAppointmentsList('completed'),
          _buildAppointmentsList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String type) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view appointments'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, bookingsSnapshot) {
        if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (bookingsSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 15),
                Text(
                  'Error loading appointments',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }

        if (!bookingsSnapshot.hasData || bookingsSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('customerId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, appointmentsSnapshot) {
            final bookings = bookingsSnapshot.data!.docs.toList()
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });
            
            final appointments = appointmentsSnapshot.hasData
                ? appointmentsSnapshot.data!.docs
                : <QueryDocumentSnapshot>[];

            final filteredBookings = bookings.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString().toLowerCase() ?? 'pending';
              
              if (type == 'all') return true;
              
              final bookingId = doc.id;
              DateTime? appointmentDate;
              
              if (appointments.isNotEmpty) {
                try {
                  final matchingAppointment = appointments.firstWhere(
                    (apt) {
                      final aptData = apt.data() as Map<String, dynamic>;
                      return aptData['bookingId'] == bookingId;
                    },
                  );
                  
                  final aptData = matchingAppointment.data() as Map<String, dynamic>;
                  final startTime = aptData['startTime'] as Timestamp?;
                  appointmentDate = startTime?.toDate();
                } catch (e) {
                  appointmentDate = null;
                }
              }

              final now = DateTime.now();
              final isPast = appointmentDate != null && appointmentDate.isBefore(now);

              switch (type) {
                case 'upcoming':
                  return (status == 'confirmed' || status == 'pending') && !isPast;
                case 'completed':
                  return status == 'completed' || (status == 'confirmed' && isPast);
                case 'cancelled':
                  return status == 'cancelled';
                default:
                  return false;
              }
            }).toList();

            if (filteredBookings.isEmpty) {
              return _buildEmptyState(type);
            }

            int totalBookings = filteredBookings.length;
            int totalSpent = 0;
            for (var doc in filteredBookings) {
              final data = doc.data() as Map<String, dynamic>;
              totalSpent += (data['totalAmount'] as int?) ?? 0;
            }

            return Column(
              children: [
                if (type == 'all') _buildStatisticsCard(totalBookings, totalSpent),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final bookingDoc = filteredBookings[index];
                      final bookingData = bookingDoc.data() as Map<String, dynamic>;
                      
                      Map<String, dynamic>? appointmentData;
                      
                      if (appointments.isNotEmpty) {
                        try {
                          final matchingAppointment = appointments.firstWhere(
                            (apt) {
                              final aptData = apt.data() as Map<String, dynamic>;
                              return aptData['bookingId'] == bookingDoc.id;
                            },
                          );
                          appointmentData = matchingAppointment.data() as Map<String, dynamic>;
                        } catch (e) {
                          appointmentData = null;
                        }
                      }

                      return _buildAppointmentCard(
                        bookingDoc.id,
                        bookingData,
                        appointmentData,
                        type,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard(int totalBookings, int totalSpent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D3346), Color(0xFF8B5A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(child: _statTile(Icons.event_available_rounded, '$totalBookings', 'Bookings')),
          Container(width: 1, height: 54, color: Colors.white24),
          Expanded(child: _statTile(Icons.account_balance_wallet_rounded, '₱$totalSpent', 'Total spent')),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 19),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'Nothing scheduled yet';
        subtitle = 'Your next salon appointment will appear here.';
        icon = Icons.calendar_today_rounded;
        break;
      case 'completed':
        message = 'No completed visits yet';
        subtitle = 'Your salon history will build up here.';
        icon = Icons.auto_awesome_rounded;
        break;
      case 'cancelled':
        message = 'No cancelled bookings';
        subtitle = 'Cancelled appointments will appear here.';
        icon = Icons.event_busy_rounded;
        break;
      default:
        message = 'No bookings yet';
        subtitle = 'Book a service and it will show up here.';
        icon = Icons.calendar_month_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.selectedBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    String bookingId,
    Map<String, dynamic> bookingData,
    Map<String, dynamic>? appointmentData,
    String type,
  ) {
    final services = (bookingData['services'] as List?)
        ?.map((s) => s as Map<String, dynamic>)
        .toList() ?? [];
    final totalAmount = bookingData['totalAmount'] ?? 0;
    final status = bookingData['status']?.toString() ?? 'pending';
    final paymentMethod = bookingData['paymentMethod'] ?? 'N/A';
    final createdAt = (bookingData['createdAt'] as Timestamp?)?.toDate();

    DateTime? appointmentDate;
    String? staffName;
    
    if (appointmentData != null) {
      final startTime = appointmentData['startTime'] as Timestamp?;
      appointmentDate = startTime?.toDate();
      staffName = _getStaffName(appointmentData['staffId'] ?? '');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
                if (createdAt != null)
                  Text(
                    'Booked: ${DateFormat('MMM d, yyyy').format(createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointmentDate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8F2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(appointmentDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                  const SizedBox(width: 5),
                                  Text(
                                    DateFormat('h:mm a').format(appointmentDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  if (staffName != null) ...[
                                    const SizedBox(width: 15),
                                    const Icon(Icons.person, size: 14, color: Colors.black54),
                                    const SizedBox(width: 5),
                                    Text(
                                      staffName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ] else if (status == 'pending') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Awaiting schedule confirmation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                const Row(
                  children: [
                    Icon(Icons.spa, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 35,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'] ?? 'Service',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  service['category'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(service['duration'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${service['price']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )),

                const Divider(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              paymentMethod == 'Cash' ? Icons.money : Icons.phone_android,
                              size: 16,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              paymentMethod,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₱$totalAmount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if ((type == 'upcoming' || type == 'all') && 
                    status != 'cancelled' && 
                    status != 'completed' &&
                    (appointmentDate == null || appointmentDate.isAfter(DateTime.now()))) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAppointmentDetails(bookingId, bookingData, appointmentData),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmCancellation(bookingId),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAppointmentDetails(bookingId, bookingData, appointmentData),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(
    String bookingId,
    Map<String, dynamic> bookingData,
    Map<String, dynamic>? appointmentData,
  ) {
    final status = bookingData['status']?.toString().toUpperCase() ?? 'N/A';
    final total = bookingData['totalAmount']?.toString() ?? '0';
    final duration = bookingData['totalDuration']?.toString() ?? '0';
    final payment = bookingData['paymentMethod']?.toString() ?? 'N/A';
    final shortId = bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId;
    final start = appointmentData?['startTime'] is Timestamp
        ? (appointmentData!['startTime'] as Timestamp).toDate()
        : null;
    final staff = appointmentData == null
        ? '—'
        : _getStaffName(appointmentData['staffId']?.toString() ?? '');
    final services = bookingData['services'] is List
        ? List<Map<String, dynamic>>.from(
            (bookingData['services'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Appointment details',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, _) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 35,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking invoice', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 2),
                                  Text('Appointment details', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _invoiceStatus(status),
                                  Text(
                                    '#$shortId',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    _invoiceMiniInfo(Icons.calendar_month_rounded, start == null ? 'Date' : DateFormat('EEE, MMM d').format(start)),
                                    const SizedBox(width: 10),
                                    _invoiceMiniInfo(Icons.schedule_rounded, start == null ? 'Time' : DateFormat('h:mm a').format(start)),
                                    const SizedBox(width: 10),
                                    _invoiceMiniInfo(Icons.person_rounded, staff),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text('Services', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              if (services.isEmpty)
                                const Text('No service details recorded.', style: TextStyle(color: AppColors.textSecondary))
                              else
                                ...services.map((service) {
                                  final name = service['name']?.toString() ?? 'Service';
                                  final cat = service['category']?.toString() ?? '';
                                  final price = service['price']?.toString() ?? '0';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.selectedBackground,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                                              if (cat.isNotEmpty)
                                                Text(cat, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        Text('₱$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    _invoiceTotalRow('Duration', '$duration minutes', false),
                                    const SizedBox(height: 8),
                                    _invoiceTotalRow('Payment', payment, false),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(color: Colors.white24, height: 1),
                                    ),
                                    _invoiceTotalRow('Total paid', '₱$total', true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.done_rounded),
                            label: const Text('Done'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curved), child: child),
        );
      },
    );
  }

  Widget _invoiceStatus(String status) {
    final isCancelled = status == 'CANCELLED';
    final color = isCancelled ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _invoiceMiniInfo(IconData icon, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 17),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _invoiceTotalRow(String label, String value, bool prominent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: prominent ? Colors.white : Colors.white70, fontSize: prominent ? 14 : 11, fontWeight: prominent ? FontWeight.w900 : FontWeight.w700)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: prominent ? 22 : 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _confirmCancellation(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Cancel Appointment?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'No, Keep It',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelAppointment(bookingId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
