import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================================
// STAFF MEMBER MODEL
// ============================================================================
class StaffMember {
  final String id;
  final String name;
  
  StaffMember({required this.id, required this.name});
  
  // In production, you can add fromFirestore if staff are stored in database
  factory StaffMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffMember(
      id: doc.id,
      name: data['name'] ?? 'Staff',
    );
  }
}

// ============================================================================
// TIME SLOT MODEL
// ============================================================================
class TimeSlot {
  final TimeOfDay time;
  final DateTime dateTime;
  
  TimeSlot({required this.time, required this.dateTime});
  
  // Display format: "09:00", "09:30", etc.
  String get displayTime => 
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

// ============================================================================
// APPOINTMENT MODEL
// ============================================================================
class Appointment {
  final String id;
  final String staffId;
  final DateTime startTime;
  final DateTime endTime;
  final String customerName;
  final String customerId;
  final String status; // 'confirmed', 'pending', 'cancelled'
  
  Appointment({
    required this.id,
    required this.staffId,
    required this.startTime,
    required this.endTime,
    required this.customerName,
    required this.customerId,
    required this.status,
  });
  
  // Convert Firestore document to Appointment object
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      staffId: data['staffId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      customerName: data['customerName'] ?? 'Unknown',
      customerId: data['customerId'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }
  
  // Convert Appointment to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'staffId': staffId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'customerName': customerName,
      'customerId': customerId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ScheduleBlock {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final bool isDuringBusinessHours;
  
  ScheduleBlock({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isDuringBusinessHours,
  });
}