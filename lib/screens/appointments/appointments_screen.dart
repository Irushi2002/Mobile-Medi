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

  void _showRescheduleDialog(
      BuildContext context, AppointmentModel appointment) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Reschedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment: ${appointment.clinic}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(appointment.dateTime)}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for rescheduling:',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                'Please explain why you need to reschedule...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a reason')),
                );
                return;
              }
              final uid = context.read<AuthProvider>().user?.uid;
              if (uid != null) {
                await context
                    .read<MedicationProvider>()
                    .requestReschedule(
                    uid, appointment.id, noteController.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Reschedule request sent to your doctor'),
                    backgroundColor: AppColors.stable,
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
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
                          _showRescheduleDialog(context, a),
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
                        _showRescheduleDialog(context, a),
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
                        _showRescheduleDialog(context, a),
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