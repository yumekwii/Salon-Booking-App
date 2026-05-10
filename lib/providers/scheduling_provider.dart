import 'package:flutter/material.dart';
import '../models/scheduling_models.dart';
import '../services/scheduling_service.dart';

class SchedulingProvider extends ChangeNotifier {
  final SchedulingService _service = SchedulingService();
  
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  String? _selectedStaffId;
  TimeSlot? _selectedSlot;
  int _serviceDurationMinutes = 60; // Default 1 hour
  
  // ============================================================================
  // GETTERS (Para ma-access sa UI)
  // ============================================================================
  DateTime get selectedDate => _selectedDate;
  List<Appointment> get appointments => _appointments;
  String? get selectedStaffId => _selectedStaffId;
  TimeSlot? get selectedSlot => _selectedSlot;
  int get serviceDurationMinutes => _serviceDurationMinutes;
  SchedulingService get service => _service;
  
  // ============================================================================
  // SET SELECTED DATE
  // ============================================================================
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    // Clear selection when date changes
    _selectedStaffId = null;
    _selectedSlot = null;
    notifyListeners(); // Notify UI to rebuild
  }
  
  // ============================================================================
  // SET SERVICE DURATION (from checkout total duration)
  // ============================================================================
  void setServiceDuration(int minutes) {
    _serviceDurationMinutes = minutes;
    notifyListeners();
  }
  
  // ============================================================================
  // UPDATE APPOINTMENTS (from Firestore stream)
  // ============================================================================
  void updateAppointments(List<Appointment> appointments) {
    _appointments = appointments;
    notifyListeners();
  }
  
  // ============================================================================
  // SELECT A TIMESLOT
  // ============================================================================
  void selectSlot(String staffId, TimeSlot slot) {
    _selectedStaffId = staffId;
    _selectedSlot = slot;
    notifyListeners();
  }
  
  // ============================================================================
  // CLEAR SELECTION
  // ============================================================================
  void clearSelection() {
    _selectedStaffId = null;
    _selectedSlot = null;
    notifyListeners();
  }

  void loadAppointments(DateTime date) {
  service.getAppointmentsStream(date).listen((appointments) {
    updateAppointments(appointments);
  });
}
  
  // ============================================================================
  // CHECK IF SLOT IS AVAILABLE (wrapper for service method)
  // ============================================================================
  bool isSlotAvailable(String staffId, TimeSlot slot) {
    return _service.isSlotAvailable(
      staffId: staffId,
      slotStart: slot.dateTime,
      durationMinutes: _serviceDurationMinutes,
      existingAppointments: _appointments,
    );
  }
  
  // ============================================================================
  // FIND NEXT AVAILABLE SLOT (wrapper for service method)
  // ============================================================================
  DateTime? findNextAvailable(String staffId) {
    return _service.findNextAvailableSlot(
      staffId: staffId,
      fromTime: DateTime.now(),
      durationMinutes: _serviceDurationMinutes,
      existingAppointments: _appointments,
    );
  }
  
  // ============================================================================
  // GET STAFF NAME BY ID
  // ============================================================================
  String getStaffName(String staffId) {
    try {
      return _service.staff.firstWhere((s) => s.id == staffId).name;
    } catch (e) {
      return 'Unknown Staff';
    }
  }

}