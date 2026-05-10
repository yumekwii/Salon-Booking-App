import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/scheduling_models.dart';

class SchedulingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ============================================================================
  // STAFF CONFIGURATION (3 staff members)
  // ============================================================================
  final List<StaffMember> staff = [
    StaffMember(id: 'staff_1', name: 'Alice'),
    StaffMember(id: 'staff_2', name: 'Bob'),
    StaffMember(id: 'staff_3', name: 'Charlie'),
  ];
  
  // ============================================================================
  // GENERATE TIMESLOTS (9:00 AM - 6:00 PM, 30-minute intervals)
  // ============================================================================
  List<TimeSlot> generateTimeSlots(DateTime selectedDate) {
    final slots = <TimeSlot>[];
    const startHour = 9;   // 9:00 AM
    const endHour = 18;    // 6:00 PM (last slot is 5:30 PM)
    
    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final dateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );
        
        slots.add(TimeSlot(
          time: TimeOfDay(hour: hour, minute: minute),
          dateTime: dateTime,
        ));
      }
    }
    
    return slots;
  }
  
  // ============================================================================
  // OVERLAP ALGORITHM - Half-open interval [start, end)
  // ============================================================================
  bool _intervalsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    final maxStart = start1.isAfter(start2) ? start1 : start2;
    final minEnd = end1.isBefore(end2) ? end1 : end2;
    return maxStart.isBefore(minEnd);
  }
  
  // ============================================================================
  // CHECK IF SPECIFIC TIMESLOT IS AVAILABLE FOR A STAFF
  // ============================================================================
  bool isSlotAvailable({
    required String staffId,
    required DateTime slotStart,
    required int durationMinutes,
    required List<Appointment> existingAppointments,
  }) {
    final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
    
    for (final appointment in existingAppointments) {
      if (appointment.staffId == staffId && 
          appointment.status == 'confirmed') {
        
        if (_intervalsOverlap(
          slotStart, 
          slotEnd, 
          appointment.startTime, 
          appointment.endTime
        )) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  // ============================================================================
  // FIND NEXT AVAILABLE SLOT FOR A STAFF MEMBER
  // ============================================================================
  DateTime? findNextAvailableSlot({
    required String staffId,
    required DateTime fromTime,
    required int durationMinutes,
    required List<Appointment> existingAppointments,
  }) {
    final slots = generateTimeSlots(fromTime);
    
    for (final slot in slots) {
      if (slot.dateTime.isAfter(fromTime) || 
          slot.dateTime.isAtSameMomentAs(fromTime)) {
        
        if (isSlotAvailable(
          staffId: staffId,
          slotStart: slot.dateTime,
          durationMinutes: durationMinutes,
          existingAppointments: existingAppointments,
        )) {
          return slot.dateTime;
        }
      }
    }
    
    return null;
  }
  
  // ============================================================================
  // ✅ FIXED: GET APPOINTMENTS STREAM (No composite index needed)
  // ============================================================================
  Stream<List<Appointment>> getAppointmentsStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
    
    // ✅ SIMPLE QUERY: Just get all appointments (or limit to recent ones)
    return _firestore
        .collection('appointments')
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          // ✅ Filter in memory for the selected date
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .where((apt) => 
                  apt.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                  apt.startTime.isBefore(endOfDay)
              )
              .toList();
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          return <Appointment>[]; // Return empty list on error
        });
  }
  
  // ============================================================================
  // ✅ FIXED: BOOK AN APPOINTMENT (No composite index needed)
  // ============================================================================
  Future<String?> bookAppointment({
    required String staffId,
    required DateTime startTime,
    required int durationMinutes,
    required String customerName,
  }) async {
    try {
      final endTime = startTime.add(Duration(minutes: durationMinutes));
      
      // Get start and end of the day for the selected date
      final startOfDay = DateTime(startTime.year, startTime.month, startTime.day, 0, 0);
      final endOfDay = DateTime(startTime.year, startTime.month, startTime.day, 23, 59);
      
      // ✅ FIXED: Only query by startTime >= startOfDay (single where clause)
      final snapshot = await _firestore
          .collection('appointments')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      // ✅ Filter by endTime and staffId in memory (not in query)
      final existingAppointments = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => 
              apt.startTime.isBefore(endOfDay) && 
              apt.staffId == staffId
          )
          .toList();
      
      // Final availability check
      if (!isSlotAvailable(
        staffId: staffId,
        slotStart: startTime,
        durationMinutes: durationMinutes,
        existingAppointments: existingAppointments,
      )) {
        return 'This timeslot is no longer available. Please select another time.';
      }
      
      // Create the appointment in Firestore
      await _firestore.collection('appointments').add({
        'staffId': staffId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'customerName': customerName,
        'customerId': _auth.currentUser?.uid ?? '',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return null; // ✅ Success
    } catch (e) {
      print('❌ Error booking appointment: $e');
      return 'Failed to book appointment: ${e.toString()}';
    }
  }
  
  // ============================================================================
  // CLEAR ALL APPOINTMENTS (For testing/admin reset)
  // ============================================================================
  Future<void> clearAllAppointments() async {
    final batch = _firestore.batch();
    final appointments = await _firestore.collection('appointments').get();
    
    for (final doc in appointments.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  Future<List<ScheduleBlock>> getStaffSchedule(String staffId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
      
      // Get all appointments for this staff on this date
      final snapshot = await _firestore
          .collection('appointments')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      
      final existingAppointments = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((apt) => 
              apt.startTime.isBefore(endOfDay) && 
              apt.staffId == staffId &&
              apt.status == 'confirmed'
          )
          .toList();
      
      // Generate all time slots for the day
      final timeSlots = generateTimeSlots(date);
      final scheduleBlocks = <ScheduleBlock>[];
      
      for (final slot in timeSlots) {
        final slotEnd = slot.dateTime.add(const Duration(minutes: 30));
        
        // Check if this is during business hours (9 AM - 6 PM)
        final isDuringBusinessHours = slot.time.hour >= 9 && slot.time.hour < 18;
        
        // Check if slot is available (no overlapping appointments)
        final isAvailable = isDuringBusinessHours && isSlotAvailable(
          staffId: staffId,
          slotStart: slot.dateTime,
          durationMinutes: 30,
          existingAppointments: existingAppointments,
        );
        
        scheduleBlocks.add(ScheduleBlock(
          startTime: slot.dateTime,
          endTime: slotEnd,
          isAvailable: isAvailable,
          isDuringBusinessHours: isDuringBusinessHours,
        ));
      }
      
      return scheduleBlocks;
    } catch (e) {
      print('❌ Error getting staff schedule: $e');
      return [];
    }
  }
}