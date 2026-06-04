import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
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

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppointmentModel> _apptForDay(
      List<AppointmentModel> appts, DateTime day) {
    return appts.where((a) =>
    a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day).toList();
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
      body: Column(
        children: [
          // Calendar
          Container(
            color: AppColors.surface,
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: (day) => _apptForDay(medProvider.appointments, day),
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
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
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
                      final color = a.status == AppointmentStatus.upcoming
                          ? AppColors.upcoming
                          : a.status == AppointmentStatus.completed
                          ? AppColors.completed
                          : AppColors.missed;
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // Appointments for selected date
          if (_apptForDay(medProvider.appointments, _selectedDay).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On selected date:',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ..._apptForDay(medProvider.appointments, _selectedDay)
                      .map((a) => AppointmentCard(appointment: a)),
                ],
              ),
            ),

          // Tab bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upcoming_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                          'Upcoming (${medProvider.upcomingAppointments.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Missed (${medProvider.missedAppointments.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                medProvider.upcomingAppointments.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('No upcoming appointments',
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: medProvider.upcomingAppointments
                      .map((a) => AppointmentCard(appointment: a))
                      .toList(),
                ),

                // Missed
                medProvider.missedAppointments.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppColors.stable),
                      SizedBox(height: 12),
                      Text('No missed appointments!',
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: medProvider.missedAppointments
                      .map((a) => AppointmentCard(appointment: a))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}