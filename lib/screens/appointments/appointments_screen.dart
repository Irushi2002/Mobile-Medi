import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../models/appointment_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<AppointmentModel> _apptForDay(
      List<AppointmentModel> appts, DateTime day) {
    return appts
        .where((a) =>
    a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day)
        .toList();
  }

  // ── Slot-Picker Reschedule Flow ──────────────────────────────────────────

  /// Step 1 — Fetch available slots, then show the date+slot picker sheet.
  Future<void> _startRescheduleFlow(
      BuildContext context, AppointmentModel appointment) async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    // We need the doctorId — it's stored in Firestore as part of the appointment doc
    // The appointment ID is used to exclude the patient's own current slot.
    // doctorId is fetched from the backend via the available-slots endpoint which
    // takes doctorId as a query param.
    // But we don't store doctorId directly in AppointmentModel.
    // Strategy: show a loading modal while fetching, then show the picker.

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading available slots…',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );

    // Fetch slots — doctorId is the appointment's doctor.
    // We infer doctorId from the backend call using appointment ID.
    // The backend will look up the doctorId from the appointment record itself.
    List<Map<String, String>> slots = [];
    final provider = context.read<MedicationProvider>();
    final navigator = Navigator.of(context);
    try {
      slots = await provider.fetchAvailableSlots(
          appointment.doctorName, appointment.id);
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    }

    if (!mounted) return;
    navigator.pop(); // dismiss loader

    // Show the slot-picker bottom sheet
    if (mounted) {
      _showSlotPickerSheet(context, appointment, uid, slots);
    }
  }

  /// Step 2 — Show a bottom sheet: pick a date → pick a time slot → enter reason.
  void _showSlotPickerSheet(
      BuildContext context,
      AppointmentModel appointment,
      String uid,
      List<Map<String, String>> slots) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RescheduleSheet(
        appointment: appointment,
        uid: uid,
        slots: slots,
        onSubmit: (requestedDate, requestedTime, reason) async {
          final provider = context.read<MedicationProvider>();
          final messenger = ScaffoldMessenger.of(context);
          final success = await provider.requestRescheduleWithSlot(
            uid,
            appointment.id,
            requestedDate,
            requestedTime,
            reason,
          );
          if (!mounted) return;
          if (success) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Reschedule request submitted successfully'),
                backgroundColor: AppColors.stable,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                    'Request submitted, but could not reach the server. '
                        'Please check your connection.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Calendar ──────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2027, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                eventLoader: (day) =>
                    _apptForDay(medProvider.appointments, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(
                    color: AppColors.upcoming,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (ctx, day, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    final appts = events.cast<AppointmentModel>();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: appts.take(3).map((a) {
                        final color =
                        a.status == AppointmentStatus.upcoming
                            ? AppColors.upcoming
                            : a.status == AppointmentStatus.completed
                            ? AppColors.completed
                            : AppColors.missed;
                        return Container(
                          width: 5,
                          height: 5,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),

            // ── Selected date appointments ─────────────────────────
            if (_apptForDay(medProvider.appointments, _selectedDay)
                .isNotEmpty) ...[
              Container(
                color: AppColors.surfaceVariant,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._apptForDay(medProvider.appointments, _selectedDay)
                        .map((a) => AppointmentCard(
                      appointment: a,
                      onRequestReschedule: () =>
                          _startRescheduleFlow(context, a),
                    )),
                  ],
                ),
              ),
            ],

            // ── Upcoming Appointments ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.upcoming_outlined,
                      color: AppColors.upcoming, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming (${medProvider.upcomingAppointments.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            if (medProvider.upcomingAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: Text('No upcoming appointments',
                      style: TextStyle(color: AppColors.textHint)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: medProvider.upcomingAppointments
                      .map((a) => AppointmentCard(
                    appointment: a,
                    onRequestReschedule: () =>
                        _startRescheduleFlow(context, a),
                  ))
                      .toList(),
                ),
              ),

            // ── Missed Appointments ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: AppColors.missed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Missed (${medProvider.missedAppointments.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            if (medProvider.missedAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 36, color: AppColors.stable),
                      SizedBox(height: 8),
                      Text('No missed appointments!',
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: medProvider.missedAppointments
                      .map((a) => AppointmentCard(
                    appointment: a,
                    onRequestReschedule: () =>
                        _startRescheduleFlow(context, a),
                  ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reschedule Sheet — three-step flow: pick date → pick slot → enter reason
// ─────────────────────────────────────────────────────────────────────────────
class _RescheduleSheet extends StatefulWidget {
  final AppointmentModel appointment;
  final String uid;
  final List<Map<String, String>> slots;
  final Future<void> Function(
      String date, String time, String reason) onSubmit;

  const _RescheduleSheet({
    required this.appointment,
    required this.uid,
    required this.slots,
    required this.onSubmit,
  });

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  // Step: 0 = date/slot selection, 1 = reason entry
  int _step = 0;

  String? _selectedDate;
  String? _selectedTime;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Group slots by date
  Map<String, List<String>> get _slotsByDate {
    final map = <String, List<String>>{};
    for (final s in widget.slots) {
      map.putIfAbsent(s['date']!, () => []).add(s['time']!);
    }
    return map;
  }

  // Distinct sorted dates that have available slots
  List<String> get _availableDates =>
      _slotsByDate.keys.toList()..sort();

  // Time slots for the currently selected date
  List<String> get _timesForSelectedDate =>
      _selectedDate != null ? (_slotsByDate[_selectedDate] ?? []) : [];

  String _formatDate(String dateStr) {
    try {
      return DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for rescheduling')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_selectedDate!, _selectedTime!, reason);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Request Reschedule',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Current appointment info
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current: ${widget.appointment.clinic} — '
                          '${DateFormat('MMM d, yyyy').format(widget.appointment.dateTime)} '
                          'at ${DateFormat('hh:mm a').format(widget.appointment.dateTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Step content
            Expanded(
              child: _step == 0
                  ? _buildSlotPickerStep(scrollController)
                  : _buildReasonStep(),
            ),

            // Footer buttons
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Date + time slot picker ─────────────────────────────────────
  Widget _buildSlotPickerStep(ScrollController scrollController) {
    if (widget.slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy,
                  size: 48, color: AppColors.textHint.withOpacity(0.6)),
              const SizedBox(height: 16),
              const Text(
                'No available slots found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The doctor has no free upcoming time slots at the moment. '
                    'Please contact the clinic directly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      children: [
        // Section label
        const Text(
          'SELECT A NEW DATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Date chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableDates.map((date) {
            final isSelected = date == _selectedDate;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDate = date;
                _selectedTime = null; // reset time when date changes
              }),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Time slots for selected date
        if (_selectedDate != null) ...[
          const SizedBox(height: 20),
          const Text(
            'SELECT A TIME SLOT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (_timesForSelectedDate.isEmpty)
            const Text(
              'No slots available for this date.',
              style:
              TextStyle(fontSize: 13, color: AppColors.textHint),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timesForSelectedDate.map((time) {
                final isSelected = time == _selectedTime;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 1: Reason entry ─────────────────────────────────────────────────
  Widget _buildReasonStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected slot summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requested slot',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_formatDate(_selectedDate!)}  ·  ${_formatTime(_selectedTime!)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Change',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'REASON FOR RESCHEDULING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _reasonController,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText:
              'Please explain why you need to reschedule this appointment…',
              hintStyle: const TextStyle(
                  color: AppColors.textHint, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your request will be reviewed by staff. The appointment will '
                'only be changed after approval.',
            style: TextStyle(
                fontSize: 11, color: AppColors.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Footer: navigation buttons ────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          if (_step == 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_step == 1) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : _step == 0
                  ? (_selectedDate != null && _selectedTime != null
                  ? () => setState(() => _step = 1)
                  : null)
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: _submitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text(_step == 0 ? 'Next: Add Reason' : 'Submit Request'),
            ),
          ),
        ],
      ),
    );
  }
}