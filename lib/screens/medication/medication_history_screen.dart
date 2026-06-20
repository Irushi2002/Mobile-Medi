import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class MedicationHistoryScreen extends StatefulWidget {
  const MedicationHistoryScreen({super.key});

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<_HistoryEntry> _getHistoryForDate(
      List<MedicationModel> meds, DateTime date) {
    final entries = <_HistoryEntry>[];
    for (final med in meds) {
      if (!med.isScheduledForDate(date)) continue;
      for (final t in med.scheduledTimes) {
        final scheduled =
        DateTime(date.year, date.month, date.day, t.hour, t.minute);
        final timeKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final status = med.takenStatus[timeKey] ?? MedicationStatus.pending;
        entries.add(_HistoryEntry(
            medication: med,
            scheduledTime: scheduled,
            status: status));
      }
    }
    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return entries;
  }

  // Return events (missed count) for calendar markers
  List<int> _eventsForDay(List<MedicationModel> meds, DateTime day) {
    final entries = _getHistoryForDate(meds, day);
    return entries
        .where((e) => e.status == MedicationStatus.overdue)
        .map((e) => 1)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final entries =
    _getHistoryForDate(medProvider.medications, _selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medication History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar with missed markers
          Container(
            color: AppColors.surface,
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2026, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: (day) =>
                  _eventsForDay(medProvider.medications, day),
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
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.overdue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Summary counts
                _StatusBadge(
                    label: 'Taken',
                    count: entries
                        .where((e) => e.status == MedicationStatus.taken)
                        .length,
                    color: AppColors.stable),
                const SizedBox(width: 6),
                _StatusBadge(
                    label: 'Missed',
                    count: entries
                        .where((e) => e.status == MedicationStatus.overdue)
                        .length,
                    color: AppColors.overdue),
              ],
            ),
          ),

          Expanded(
            child: entries.isEmpty
                ? const Center(
              child: Text('No medication data for this date',
                  style: TextStyle(color: AppColors.textHint)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final e = entries[i];
                return _buildHistoryTile(e);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHistoryTile(_HistoryEntry e) {
    final isMissed = e.status == MedicationStatus.overdue;
    final isTaken = e.status == MedicationStatus.taken;
    final color = isMissed
        ? AppColors.overdue
        : isTaken
        ? AppColors.stable
        : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMissed
              ? AppColors.overdue.withValues(alpha: 0.35)
              : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken
                  ? Icons.check_circle_outline
                  : isMissed
                  ? Icons.cancel_outlined
                  : Icons.circle_outlined,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.medication.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                    isMissed ? AppColors.overdue : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${e.medication.dosage}  •  ${_fmtTime(e.scheduledTime)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isTaken
                  ? 'Taken'
                  : isMissed
                  ? 'Missed'
                  : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }
}

class _HistoryEntry {
  final MedicationModel medication;
  final DateTime scheduledTime;
  final MedicationStatus status;
  _HistoryEntry(
      {required this.medication,
        required this.scheduledTime,
        required this.status});
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}