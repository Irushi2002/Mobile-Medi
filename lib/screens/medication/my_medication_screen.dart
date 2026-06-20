import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/medication_card.dart';

class MyMedicationScreen extends StatefulWidget {
  const MyMedicationScreen({super.key});

  @override
  State<MyMedicationScreen> createState() => _MyMedicationScreenState();
}

class _MyMedicationScreenState extends State<MyMedicationScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<_ScheduledEntry> _getEntriesForDate(
      List<MedicationModel> meds, DateTime date) {
    final entries = <_ScheduledEntry>[];
    for (final med in meds) {
      if (!med.isScheduledForDate(date)) continue;
      for (final t in med.scheduledTimes) {
        final scheduled =
        DateTime(date.year, date.month, date.day, t.hour, t.minute);
        final timeKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        entries.add(_ScheduledEntry(
          medication: med,
          scheduledTime: scheduled,
          status: med.takenStatus[timeKey] ?? MedicationStatus.pending,
          timeKey: timeKey,
        ));
      }
    }
    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final entries = _getEntriesForDate(medProvider.medications, _selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () =>
                Navigator.pushNamed(context, '/profile'),
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
              lastDay: DateTime.utc(2026, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarFormat: CalendarFormat.week,
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
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle:
                TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  isToday
                      ? "Today's Medications"
                      : DateFormat('MMMM d, yyyy').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entries.length} medications',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),

          // Medication list
          Expanded(
            child: entries.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No medications for this date',
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final e = entries[i];
                return MedicationCard(
                  medication: e.medication,
                  scheduledTime: e.scheduledTime,
                  status: e.status,
                  onTakeMedication: isToday
                      ? () {
                    final uid = auth.user?.uid;
                    if (uid != null) {
                      medProvider.markTaken(
                          uid, e.medication.id, e.timeKey);
                    }
                  }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}

class _ScheduledEntry {
  final MedicationModel medication;
  final DateTime scheduledTime;
  final MedicationStatus status;
  final String timeKey;
  _ScheduledEntry(
      {required this.medication,
        required this.scheduledTime,
        required this.status,
        required this.timeKey});
}