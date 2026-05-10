// ============================================================================
// FILE: lib/pages/staff_scheduling_page.dart
// FIXED: Time slot selection now works properly
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/scheduling_provider.dart';
import '../models/scheduling_models.dart';

class StaffSchedulingPage extends StatefulWidget {
  final int totalDurationMinutes;
  final Function(String staffId, DateTime startTime) onScheduleConfirmed;

  const StaffSchedulingPage({
    super.key,
    required this.totalDurationMinutes,
    required this.onScheduleConfirmed,
  });

  @override
  State<StaffSchedulingPage> createState() => _StaffSchedulingPageState();
}

class _StaffSchedulingPageState extends State<StaffSchedulingPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStaffId;
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    // Load initial appointments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SchedulingProvider>();
      provider.loadAppointments(_selectedDate);
    });
  }

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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedStaffId = null;
        _selectedSlot = null;
      });
      
      // Load appointments for new date
      if (mounted) {
        final provider = context.read<SchedulingProvider>();
        provider.loadAppointments(_selectedDate);
      }
    }
  }

  Color _getStaffColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  void _selectSlot(String staffId, TimeSlot slot) {
    setState(() {
      _selectedStaffId = staffId;
      _selectedSlot = slot;
    });
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
          'Select Schedule',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<SchedulingProvider>(
        builder: (context, provider, child) {
          final slots = provider.service.generateTimeSlots(_selectedDate);
          final staff = provider.service.staff;

          return Column(
            children: [
              // Date Selector Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Service Duration Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Service Duration: ${widget.totalDurationMinutes} minutes',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Schedule Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                _buildHeaderCell('Staff', isCorner: true),
                                ...slots
                                    .map((slot) =>
                                        _buildHeaderCell(slot.displayTime))
                                    .toList(),
                              ],
                            ),

                            // Staff Rows
                            ...staff.asMap().entries.map((entry) {
                              final staffIndex = entry.key;
                              final staffMember = entry.value;
                              final staffColor = _getStaffColor(staffIndex);

                              return Row(
                                children: [
                                  _buildStaffNameCell(
                                    staffMember.name,
                                    staffColor,
                                  ),
                                  ...slots.map((slot) {
                                    final isAvailable =
                                        provider.isSlotAvailable(
                                      staffMember.id,
                                      slot,
                                    );
                                    final isSelected =
                                        _selectedStaffId == staffMember.id &&
                                            _selectedSlot?.dateTime == slot.dateTime;

                                    return GestureDetector(
                                      onTap: isAvailable
                                          ? () =>
                                              _selectSlot(staffMember.id, slot)
                                          : null,
                                      child: _buildSlotCell(
                                        isAvailable,
                                        isSelected,
                                        staffColor,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Legend
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.green, 'Available'),
                    _buildLegendItem(Colors.red, 'Booked'),
                    _buildLegendItem(const Color(0xFF8B0000), 'Selected'),
                  ],
                ),
              ),

              // Confirm Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedStaffId != null && _selectedSlot != null
                        ? () {
                            widget.onScheduleConfirmed(
                              _selectedStaffId!,
                              _selectedSlot!.dateTime,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Confirm Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isCorner = false}) {
    return Container(
      width: isCorner ? 110 : 80,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStaffNameCell(String name, Color staffColor) {
    return Container(
      width: 110,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [staffColor.withOpacity(0.15), staffColor.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [staffColor, staffColor.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.split(' ')[0],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCell(
    bool isAvailable,
    bool isSelected,
    Color staffColor,
  ) {
    return Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFF8B0000),
                  Color(0xFFB22222),
                ],
              )
            : isAvailable
                ? LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
        border: Border(
          top: isSelected
              ? const BorderSide(
                  color: Color(0xFF8B0000),
                  width: 3,
                )
              : BorderSide(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
          left: isSelected
              ? const BorderSide(
                  color: Color(0xFF8B0000),
                  width: 3,
                )
              : BorderSide(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : isAvailable
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_rounded,
            color: isSelected
                ? Colors.white
                : isAvailable
                    ? Colors.green
                    : Colors.red,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            isSelected
                ? 'Selected'
                : isAvailable
                    ? 'Free'
                    : 'Booked',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : isAvailable
                      ? Colors.green
                      : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}