import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    final staffMap = {
      'staff_1': 'Alice',
      'staff_2': 'Bob',
      'staff_3': 'Charlie',
    };
    return staffMap[staffId] ?? 'Staff';
  }

  String _formatDuration(String duration) {
    return duration.replaceAll('MINUTES', 'min').replaceAll('HOURS', 'hrs');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
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
      backgroundColor: const Color(0xFFFFF8DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBEB5A8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Appointments & History',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B0000),
          labelColor: const Color(0xFF8B0000),
          unselectedLabelColor: Colors.black54,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
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
              color: Color(0xFF8B0000),
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
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.event_note, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  '$totalBookings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Bookings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white30,
          ),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.payments, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  '₱$totalSpent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'all':
        message = 'No bookings yet';
        icon = Icons.event_note;
        break;
      case 'upcoming':
        message = 'No upcoming appointments';
        icon = Icons.event_available;
        break;
      case 'completed':
        message = 'No completed appointments';
        icon = Icons.history;
        break;
      case 'cancelled':
        message = 'No cancelled appointments';
        icon = Icons.event_busy;
        break;
      default:
        message = 'No appointments found';
        icon = Icons.event_note;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            type == 'upcoming' || type == 'all' ? 'Book a service to get started!' : '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4CAF50),
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
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                    Icon(Icons.spa, color: Color(0xFF8B0000), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B0000),
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
                          color: const Color(0xFF8B0000),
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
                          color: Color(0xFF8B0000),
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
                            color: Color(0xFF8B0000),
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
                            foregroundColor: const Color(0xFF8B0000),
                            side: const BorderSide(color: Color(0xFF8B0000)),
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
                        foregroundColor: const Color(0xFF8B0000),
                        side: const BorderSide(color: Color(0xFF8B0000)),
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

  void _showAppointmentDetails(String bookingId, Map<String, dynamic> bookingData, Map<String, dynamic>? appointmentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD3CBBB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Appointment Details',
            style: TextStyle(
              color: Color(0xFF8B0000),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Booking ID', '#${bookingId.substring(0, 8)}'),
                _buildDetailRow('Status', bookingData['status']?.toString().toUpperCase() ?? 'N/A'),
                const Divider(height: 20),
                if (appointmentData != null) ...[
                  _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format((appointmentData['startTime'] as Timestamp).toDate())),
                  _buildDetailRow('Time', DateFormat('h:mm a').format((appointmentData['startTime'] as Timestamp).toDate())),
                  _buildDetailRow('Staff', _getStaffName(appointmentData['staffId'] ?? '')),
                  const Divider(height: 20),
                ],
                _buildDetailRow('Total Duration', '${bookingData['totalDuration']} minutes'),
                _buildDetailRow('Payment', bookingData['paymentMethod'] ?? 'N/A'),
                _buildDetailRow('Amount', '₱${bookingData['totalAmount']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancellation(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD3CBBB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Cancel Appointment?',
            style: TextStyle(
              color: Color(0xFF8B0000),
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