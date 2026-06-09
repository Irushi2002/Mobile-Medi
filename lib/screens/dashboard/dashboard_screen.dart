import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../models/appointment_model.dart';
import '../../routes/app_router.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/medication_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<MedicationProvider>().initialize(user.uid);
      }
    });
  }

  List<_ScheduledMedEntry> _getTodayEntries(
      List<MedicationModel> medications) {
    final now = DateTime.now();
    final entries = <_ScheduledMedEntry>[];
    for (final med in medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final t in med.scheduledTimes) {
        final todayTime =
        DateTime(now.year, now.month, now.day, t.hour, t.minute);
        final timeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final status =
            med.takenStatus[timeKey] ?? MedicationStatus.pending;
        entries.add(_ScheduledMedEntry(
            medication: med,
            scheduledTime: todayTime,
            status: status,
            timeKey: timeKey));
      }
    }
    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return entries;
  }

  _ScheduledMedEntry? _getNextMedication(
      List<_ScheduledMedEntry> entries) {
    final now = DateTime.now();
    for (final e in entries) {
      if (e.status == MedicationStatus.pending &&
          e.scheduledTime.isAfter(now)) {
        return e;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final user = auth.user;
    final entries = _getTodayEntries(medProvider.medications);
    final nextMed = _getNextMedication(entries);
    final nextAppointment = medProvider.upcomingAppointments.isNotEmpty
        ? medProvider.upcomingAppointments.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.fullName.split(' ').first ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy')
                                .format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.profile),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor:
                        AppColors.primaryLight.withOpacity(0.15),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? const Icon(Icons.person,
                            color: AppColors.primary, size: 24)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Today's Medication Banner ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Medication",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMed?.medication.name ?? 'All caught up!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (nextMed != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                nextMed.medication.dosage,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (nextMed != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Next dose in',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            CountdownTimer(
                              targetTime: nextMed.scheduledTime,
                              isOverdue: false,
                            ),
                          ],
                        )
                      else
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 36),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Next Appointment Card ──────────────────────────────
            if (nextAppointment != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NextAppointmentCard(
                      appointment: nextAppointment),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Quick Actions ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _QuickActionCard(
                      icon: Icons.history_rounded,
                      label: 'Medication\nHistory',
                      color: AppColors.accent,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.medicationHistory),
                    ),
                    const SizedBox(width: 10),
                    _QuickActionCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Appointments',
                      color: AppColors.upcoming,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.appointments),
                    ),
                    const SizedBox(width: 10),
                    _QuickActionCard(
                      icon: Icons.favorite_rounded,
                      label: 'Daily\nCheck-In',
                      color: AppColors.critical,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.dailyCheckIn),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Today's Schedule ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRouter.myMedication),
                      child: const Text('View All',
                          style:
                          TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),

            if (entries.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No medications scheduled for today',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      final entry = entries[i];
                      return MedicationCard(
                        medication: entry.medication,
                        scheduledTime: entry.scheduledTime,
                        status: entry.status,
                        onTakeMedication: () {
                          final uid = auth.user?.uid;
                          if (uid != null) {
                            medProvider.markTaken(uid,
                                entry.medication.id, entry.timeKey);
                          }
                        },
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Next Appointment Card ─────────────────────────────────────────────────────

class _NextAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _NextAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final daysUntil =
        appointment.dateTime.difference(DateTime.now()).inDays;
    final daysLabel = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
        ? 'Tomorrow'
        : 'In $daysUntil days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined,
                  color: AppColors.upcoming, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Next Appointment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.upcoming.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.upcoming,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.border),
          _DetailRow(
            icon: Icons.local_hospital_outlined,
            label: 'Clinic',
            value: appointment.clinic,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Doctor',
            value: appointment.doctorName,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormat('EEEE, MMMM d, yyyy')
                .format(appointment.dateTime),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: DateFormat('hh:mm a').format(appointment.dateTime),
          ),

          // ── Investigations ─────────────────────────────────────
          if (appointment.hasInvestigations) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.4),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.assignment_outlined,
                          color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '⚠ Reports to Bring',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...appointment.investigations.map(
                        (inv) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_box_outline_blank,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inv,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (appointment.investigationNotes != null &&
                      appointment.investigationNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appointment.investigationNotes!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon,
        required this.label,
        required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ScheduledMedEntry {
  final MedicationModel medication;
  final DateTime scheduledTime;
  final MedicationStatus status;
  final String timeKey;
  _ScheduledMedEntry({
    required this.medication,
    required this.scheduledTime,
    required this.status,
    required this.timeKey,
  });
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}