import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/scheduling_models.dart';

class SchedulingService {
  SchedulingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int businessStartHour = 9;
  static const int businessEndHour = 18;
  static const int slotIntervalMinutes = 30;

  User? get currentUser => _auth.currentUser;

  String get projectId => Firebase.app().options.projectId;

  Future<User?> waitForAuthenticatedUser({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final current = _auth.currentUser;
    if (current != null) return current;

    try {
      return await _auth.authStateChanges().firstWhere(
        (user) => user != null,
      ).timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }
  List<StaffMember> get staff => StaffMember.defaults;

  List<TimeSlot> generateTimeSlots(DateTime selectedDate) {
    final slots = <TimeSlot>[];

    for (int hour = businessStartHour; hour < businessEndHour; hour++) {
      for (int minute = 0; minute < 60; minute += slotIntervalMinutes) {
        final dateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );

        slots.add(
          TimeSlot(
            time: TimeOfDay(hour: hour, minute: minute),
            dateTime: dateTime,
          ),
        );
      }
    }

    return slots;
  }

  bool _intervalsOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    final maxStart = start1.isAfter(start2) ? start1 : start2;
    final minEnd = end1.isBefore(end2) ? end1 : end2;
    return maxStart.isBefore(minEnd);
  }

  bool isSlotAvailable({
    required String staffId,
    required DateTime slotStart,
    required int durationMinutes,
    required List<Appointment> existingAppointments,
  }) {
    final slotEnd = slotStart.add(Duration(minutes: durationMinutes));

    final businessStart = DateTime(
      slotStart.year,
      slotStart.month,
      slotStart.day,
      businessStartHour,
    );
    final businessEnd = DateTime(
      slotStart.year,
      slotStart.month,
      slotStart.day,
      businessEndHour,
    );

    // Do not offer slots outside salon operating hours or slots that extend
    // beyond the closing time. On the current day, also hide past slots.
    if (slotStart.isBefore(businessStart) || slotEnd.isAfter(businessEnd)) {
      return false;
    }

    final now = DateTime.now();
    final isToday = slotStart.year == now.year &&
        slotStart.month == now.month &&
        slotStart.day == now.day;
    if (isToday && !slotStart.isAfter(now)) {
      return false;
    }

    for (final appointment in existingAppointments) {
      if (appointment.staffId != staffId ||
          appointment.status.toLowerCase() != 'confirmed') {
        continue;
      }

      if (_intervalsOverlap(
        slotStart,
        slotEnd,
        appointment.startTime,
        appointment.endTime,
      )) {
        return false;
      }
    }

    return true;
  }

  DateTime? findNextAvailableSlot({
    required String staffId,
    required DateTime fromTime,
    required int durationMinutes,
    required List<Appointment> existingAppointments,
  }) {
    final slots = generateTimeSlots(fromTime);

    for (final slot in slots) {
      if ((slot.dateTime.isAfter(fromTime) ||
              slot.dateTime.isAtSameMomentAs(fromTime)) &&
          isSlotAvailable(
            staffId: staffId,
            slotStart: slot.dateTime,
            durationMinutes: durationMinutes,
            existingAppointments: existingAppointments,
          )) {
        return slot.dateTime;
      }
    }

    return null;
  }

  Stream<List<Appointment>> getAppointmentsStream(DateTime date) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error(const _ScheduleAuthException());
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Query only by the indexed startTime field. Filter the end boundary in
    // Dart so the client does not depend on a composite Firestore index.
    return _firestore
        .collection('appointments')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Appointment.fromFirestore)
              .where((appointment) => appointment.startTime.isBefore(endOfDay))
              .toList(),
        );
  }

  Future<String?> bookAppointment({
    required String staffId,
    required DateTime startTime,
    required int durationMinutes,
    required String customerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'You must be signed in to book an appointment.';
      }

      final endTime = startTime.add(Duration(minutes: durationMinutes));
      final startOfDay = DateTime(startTime.year, startTime.month, startTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('startTime')
          .get();

      final existingAppointments = snapshot.docs
          .map(Appointment.fromFirestore)
          .where(
            (appointment) =>
                appointment.startTime.isBefore(endOfDay) &&
                appointment.staffId == staffId,
          )
          .toList();

      if (!isSlotAvailable(
        staffId: staffId,
        slotStart: startTime,
        durationMinutes: durationMinutes,
        existingAppointments: existingAppointments,
      )) {
        return 'This timeslot is no longer available. Please select another time.';
      }

      await _firestore.collection('appointments').add({
        'staffId': staffId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'customerName': customerName,
        'customerId': user.uid,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error, stackTrace) {
      debugPrint('Error booking appointment: $error');
      debugPrintStack(stackTrace: stackTrace);
      return userFacingError(error);
    }
  }

  Future<void> clearAllAppointments() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const _ScheduleAuthException();
    }

    final query = await _firestore.collection('appointments').get();
    final batch = _firestore.batch();

    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<ScheduleBlock>> getStaffSchedule(
    String staffId,
    DateTime date,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('startTime')
          .get();

      final existingAppointments = snapshot.docs
          .map(Appointment.fromFirestore)
          .where(
            (appointment) =>
                appointment.startTime.isBefore(endOfDay) &&
                appointment.staffId == staffId &&
                appointment.status.toLowerCase() == 'confirmed',
          )
          .toList();

      final timeSlots = generateTimeSlots(date);

      return [
        for (final slot in timeSlots)
          ScheduleBlock(
            startTime: slot.dateTime,
            endTime: slot.dateTime.add(
              const Duration(minutes: slotIntervalMinutes),
            ),
            isAvailable: isSlotAvailable(
              staffId: staffId,
              slotStart: slot.dateTime,
              durationMinutes: slotIntervalMinutes,
              existingAppointments: existingAppointments,
            ),
            isDuringBusinessHours:
                slot.time.hour >= businessStartHour &&
                    slot.time.hour < businessEndHour,
          ),
      ];
    } catch (error, stackTrace) {
      debugPrint('Error getting staff schedule: $error');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  String userFacingError(Object error) {
    if (error is _ScheduleAuthException) {
      return 'Your session is not authenticated. Please sign in again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'The schedule is currently unavailable because Firebase denied access. Please check your account or try again.';
        case 'failed-precondition':
          return 'The schedule database needs an index/configuration update. Please try again later.';
        case 'unavailable':
        case 'network-request-failed':
          return 'The connection to the schedule service was interrupted. Please check your internet connection and retry.';
      }
    }

    return 'We could not load the schedule right now. Please try again.';
  }
}

class _ScheduleAuthException implements Exception {
  const _ScheduleAuthException();
}
