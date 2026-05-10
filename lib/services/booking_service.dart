import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _parseDuration(String duration) {
    final parts = duration.toUpperCase().split(' ');
    if (parts.length < 2) return 30;
    
    final value = double.tryParse(parts[0]) ?? 0.5;
    final unit = parts[1];
    
    if (unit.contains('HOUR')) {
      return (value * 60).toInt();
    }
    return value.toInt();
  }

  int _calculateTotalDuration(List<Map<String, String>> services) {
    int total = 0;
    for (var service in services) {
      total += _parseDuration(service['duration'] ?? '30 MINUTES');
    }
    return total;
  }

  // ✅ NEW: Create booking WITH schedule link
  Future<String?> createBookingWithSchedule({
    required List<Map<String, String>> services,
    required int totalAmount,
    required String paymentMethod,
    required String staffId,
    required DateTime scheduledStartTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'User not logged in';
      }

      final totalDuration = _calculateTotalDuration(services);
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // ✅ STEP 1: Create booking document
      final bookingRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim(),
        'userContact': userData?['contact'] ?? 'N/A',
        'services': services.map((service) => {
          'category': service['category'] ?? '',
          'name': service['name'] ?? '',
          'duration': service['duration'] ?? '',
          'price': service['price'] ?? '0',
        }).toList(),
        'totalAmount': totalAmount,
        'totalDuration': totalDuration,
        'paymentMethod': paymentMethod,
        'status': 'confirmed',
        'staffId': staffId,
        'scheduledStartTime': Timestamp.fromDate(scheduledStartTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ STEP 2: Create appointment WITH bookingId link
      final endTime = scheduledStartTime.add(Duration(minutes: totalDuration));
      await _firestore.collection('appointments').add({
        'bookingId': bookingRef.id,
        'staffId': staffId,
        'startTime': Timestamp.fromDate(scheduledStartTime),
        'endTime': Timestamp.fromDate(endTime),
        'customerName': '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim(),
        'customerId': user.uid,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      print('Error creating booking: $e');
      return 'Failed to create booking: ${e.toString()}';
    }
  }

  // Old method (without schedule)
  Future<String?> createBookingWithoutSchedule({
    required List<Map<String, String>> services,
    required int totalAmount,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'User not logged in';
      }

      final totalDuration = _calculateTotalDuration(services);
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      await _firestore.collection('bookings').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim(),
        'userContact': userData?['contact'] ?? 'N/A',
        'services': services.map((service) => {
          'category': service['category'] ?? '',
          'name': service['name'] ?? '',
          'duration': service['duration'] ?? '',
          'price': service['price'] ?? '0',
        }).toList(),
        'totalAmount': totalAmount,
        'totalDuration': totalDuration,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return 'Failed to create booking: ${e.toString()}';
    }
  }

  Stream<QuerySnapshot> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('bookings').where('userId', isEqualTo: user.uid).snapshots();
  }

  Future<String?> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to update: ${e.toString()}';
    }
  }

  Future<String?> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      return null;
    } catch (e) {
      return 'Failed to delete: ${e.toString()}';
    }
  }
}