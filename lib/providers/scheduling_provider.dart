import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/scheduling_models.dart';
import '../services/scheduling_service.dart';

class SchedulingProvider extends ChangeNotifier {
  SchedulingProvider({SchedulingService? service})
      : _service = service ?? SchedulingService();

  final SchedulingService _service;

  List<Appointment> _appointments = [];
  int _serviceDurationMinutes = 60;
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;

  bool _disposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  int get serviceDurationMinutes => _serviceDurationMinutes;
  SchedulingService get service => _service;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  void setServiceDuration(int minutes) {
    if (_disposed || minutes <= 0 || minutes == _serviceDurationMinutes) {
      return;
    }

    _serviceDurationMinutes = minutes;
    notifyListeners();
  }

  Future<void> loadAppointments(DateTime date) async {
    if (_disposed) return;

    await _appointmentsSubscription?.cancel();
    if (_disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _service.waitForAuthenticatedUser();
      if (user == null) {
        _isLoading = false;
        _errorMessage = 'You must be signed in to load the schedule.';
        notifyListeners();
        return;
      }

      _appointmentsSubscription = _service
          .getAppointmentsStream(date)
          .listen(
            (appointments) {
              if (_disposed) return;

              _appointments = List<Appointment>.from(appointments);
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (_disposed) return;

              debugPrint('SchedulingProvider stream error: $error');
              debugPrint('Firebase project: ${_service.projectId}');
              debugPrintStack(stackTrace: stackTrace);

              _isLoading = false;
              _errorMessage = _service.userFacingError(error);
              notifyListeners();
            },
          );
    } catch (error, stackTrace) {
      if (_disposed) return;

      debugPrint('SchedulingProvider load error: $error');
      debugPrint('Firebase project: ${_service.projectId}');
      debugPrintStack(stackTrace: stackTrace);

      _isLoading = false;
      _errorMessage = _service.userFacingError(error);
      notifyListeners();
    }
  }

  void clearError() {
    if (_disposed || _errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  bool isSlotAvailable(String staffId, TimeSlot slot) {
    if (_disposed || _isLoading || hasError) return false;

    return _service.isSlotAvailable(
      staffId: staffId,
      slotStart: slot.dateTime,
      durationMinutes: _serviceDurationMinutes,
      existingAppointments: _appointments,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    final subscription = _appointmentsSubscription;
    _appointmentsSubscription = null;
    subscription?.cancel();
    super.dispose();
  }
}
