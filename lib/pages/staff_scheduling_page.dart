import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/scheduling_models.dart';
import '../providers/scheduling_provider.dart';
import '../theme/app_theme.dart';

enum _SlotState { selected, available, occupied, closed }

class StaffSchedulingPage extends StatefulWidget {
  final int totalDurationMinutes;
  final void Function(String staffId, DateTime startTime) onScheduleConfirmed;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSchedule();
    });
  }

  Future<void> _initializeSchedule() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final provider = context.read<SchedulingProvider>();
    provider.setServiceDuration(widget.totalDurationMinutes);
    await provider.loadAppointments(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 90));
    var draftDate = _selectedDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 650),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.selectedBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choose appointment date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEE, MMM d, yyyy').format(draftDate),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _quickDateChip(
                          label: 'Today',
                          date: firstDate,
                          current: draftDate,
                          onTap: () => setSheetState(() => draftDate = firstDate),
                        ),
                        const SizedBox(width: 8),
                        _quickDateChip(
                          label: 'Tomorrow',
                          date: firstDate.add(const Duration(days: 1)),
                          current: draftDate,
                          onTap: () => setSheetState(
                            () => draftDate = firstDate.add(const Duration(days: 1)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: CalendarDatePicker(
                        initialDate: draftDate.isBefore(firstDate)
                            ? firstDate
                            : draftDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        currentDate: now,
                        onDateChanged: (date) =>
                            setSheetState(() => draftDate = date),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, draftDate),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Use this date'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;
    if (picked.year == _selectedDate.year &&
        picked.month == _selectedDate.month &&
        picked.day == _selectedDate.day) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _selectedStaffId = null;
      _selectedSlot = null;
    });

    final provider = context.read<SchedulingProvider>();
    await provider.loadAppointments(_selectedDate);
    if (!mounted) return;
  }

  Widget _quickDateChip({
    required String label,
    required DateTime date,
    required DateTime current,
    required VoidCallback onTap,
  }) {
    final selected = date.year == current.year &&
        date.month == current.month &&
        date.day == current.day;

    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSlot(String staffId, TimeSlot slot) {
    final provider = context.read<SchedulingProvider>();
    if (provider.isLoading || provider.hasError) return;
    if (!_fitsBusinessHours(slot)) return;
    if (!provider.isSlotAvailable(staffId, slot)) return;

    setState(() {
      _selectedStaffId = staffId;
      _selectedSlot = slot;
    });
  }

  bool _fitsBusinessHours(TimeSlot slot) {
    final end = slot.dateTime.add(
      Duration(minutes: widget.totalDurationMinutes),
    );
    final closing = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      18,
    );
    return !end.isAfter(closing);
  }

  void _retry() {
    setState(() {
      _selectedStaffId = null;
      _selectedSlot = null;
    });
    context.read<SchedulingProvider>().loadAppointments(_selectedDate);
  }

  Color _getStaffColor(int index) {
    const colors = [
      Color(0xFF6D3346),
      Color(0xFF8B5A6A),
      Color(0xFF9B7A58),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Schedule'),
      ),
      body: Consumer<SchedulingProvider>(
        builder: (context, provider, _) {
          final slots = provider.service.generateTimeSlots(_selectedDate);
          final staff = provider.service.staff;

          return Column(
            children: [
              _buildTopSection(context, provider),
              if (provider.hasError) _buildErrorBanner(provider.errorMessage),
              _buildStatusLegend(),
              Expanded(
                child: _buildScheduleArea(
                  context,
                  provider,
                  staff,
                  slots,
                ),
              ),
              _buildBottomBar(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    SchedulingProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Appointment date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 17),
                    label: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat(
                  compact ? 'EEE, MMM d, yyyy' : 'EEEE, MMM d, yyyy',
                ).format(_selectedDate),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${widget.totalDurationMinutes} minutes • 9:00 AM – 6:00 PM',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildStatusLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _statusLegendItem(const Color(0xFFE8F7EE), AppColors.success, 'AVAILABLE'),
          const SizedBox(width: 8),
          _statusLegendItem(const Color(0xFFFCE8EC), AppColors.danger, 'OCCUPIED'),
          const SizedBox(width: 8),
          _statusLegendItem(const Color(0xFFF1EEEC), AppColors.textSecondary, 'CLOSED'),
        ],
      ),
    );
  }

  Widget _statusLegendItem(Color background, Color foreground, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String? message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'We could not load current appointments.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleArea(
    BuildContext context,
    SchedulingProvider provider,
    List<StaffMember> staff,
    List<TimeSlot> slots,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1000;
    final timeCellWidth = isDesktop ? 88.0 : width < 420 ? 76.0 : 82.0;
    final staffCellWidth = isDesktop ? 128.0 : width < 420 ? 104.0 : 116.0;
    final rowHeight = width < 420 ? 76.0 : 82.0;

    return Scrollbar(
      thumbVisibility: isDesktop,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildHeaderCell('STAFF', staffCellWidth, rowHeight),
                    for (final slot in slots)
                      _buildHeaderCell(slot.displayTime, timeCellWidth, rowHeight),
                  ],
                ),
                for (var staffIndex = 0; staffIndex < staff.length; staffIndex++)
                  _buildStaffRow(
                    provider,
                    staff[staffIndex],
                    staffIndex,
                    slots,
                    staffCellWidth,
                    timeCellWidth,
                    rowHeight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRow(
    SchedulingProvider provider,
    StaffMember staff,
    int index,
    List<TimeSlot> slots,
    double staffCellWidth,
    double timeCellWidth,
    double rowHeight,
  ) {
    final staffColor = _getStaffColor(index);

    return Row(
      children: [
        Container(
          width: staffCellWidth,
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: staffColor.withValues(alpha: 0.08),
            border: Border(
              right: const BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: staffColor,
                child: Text(
                  staff.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  staff.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final slot in slots)
          _buildSlot(
            provider,
            staff,
            slot,
            staffColor,
            timeCellWidth,
            rowHeight,
          ),
      ],
    );
  }

  Widget _buildSlot(
    SchedulingProvider provider,
    StaffMember staff,
    TimeSlot slot,
    Color staffColor,
    double width,
    double height,
  ) {
    final withinHours = _fitsBusinessHours(slot);
    final available = withinHours &&
        !provider.isLoading &&
        !provider.hasError &&
        provider.isSlotAvailable(staff.id, slot);

    final isSelected = _selectedStaffId == staff.id &&
        _selectedSlot?.dateTime == slot.dateTime;

    final state = isSelected
        ? _SlotState.selected
        : available
            ? _SlotState.available
            : withinHours
                ? _SlotState.occupied
                : _SlotState.closed;

    final palette = switch (state) {
      _SlotState.selected => (
          background: AppColors.primary,
          foreground: Colors.white,
          border: AppColors.primary,
        ),
      _SlotState.available => (
          background: const Color(0xFFF0FAF4),
          foreground: AppColors.success,
          border: const Color(0xFFB9DEC8),
        ),
      _SlotState.occupied => (
          background: const Color(0xFFFFEFF1),
          foreground: AppColors.danger,
          border: const Color(0xFFF2C3C9),
        ),
      _SlotState.closed => (
          background: const Color(0xFFF2EFED),
          foreground: AppColors.textSecondary,
          border: AppColors.border,
        ),
    };

    final label = switch (state) {
      _SlotState.selected => 'Selected',
      _SlotState.available => 'Available',
      _SlotState.occupied => 'Occupied',
      _SlotState.closed => 'Closed',
    };

    final icon = switch (state) {
      _SlotState.selected => Icons.check_circle_rounded,
      _SlotState.available => Icons.add_circle_outline_rounded,
      _SlotState.occupied => Icons.event_busy_rounded,
      _SlotState.closed => Icons.lock_outline_rounded,
    };

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: available ? () => _selectSlot(staff.id, slot) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border, width: isSelected ? 1.6 : 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.displayTime,
                      style: TextStyle(
                        color: palette.foreground,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: palette.foreground, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          label,
                          style: TextStyle(
                            color: palette.foreground,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          right: BorderSide(color: Colors.white24),
          bottom: BorderSide(color: Colors.white24),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBottomBar(SchedulingProvider provider) {
    final canConfirm = !provider.isLoading &&
        !provider.hasError &&
        _selectedStaffId != null &&
        _selectedSlot != null &&
        provider.isSlotAvailable(_selectedStaffId!, _selectedSlot!);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedStaffId == null
                        ? 'No time selected'
                        : 'Selected time',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedSlot == null
                        ? 'Choose a staff member and time'
                        : '${provider.service.staff.firstWhere((s) => s.id == _selectedStaffId).name} • ${_selectedSlot!.displayTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 155,
              height: 50,
              child: ElevatedButton(
                onPressed: canConfirm
                    ? () => widget.onScheduleConfirmed(
                          _selectedStaffId!,
                          _selectedSlot!.dateTime,
                        )
                    : null,
                child: const Text('Confirm Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
