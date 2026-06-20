import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
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

  // Find next upcoming (non-overdue) medication
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

  // Find current overdue medications (before next dose)
  List<_ScheduledMedEntry> _getOverdueMeds(
      List<_ScheduledMedEntry> entries) {
    final now = DateTime.now();
    final overdue = <_ScheduledMedEntry>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.status == MedicationStatus.overdue) {
        // Show until next dose time
        DateTime? nextDoseTime;
        for (int j = i + 1; j < entries.length; j++) {
          if (entries[j].medication.id == e.medication.id) {
            nextDoseTime = entries[j].scheduledTime;
            break;
          }
        }
        // If no next dose today, show until end of day
        final showUntil =
            nextDoseTime ?? DateTime(now.year, now.month, now.day, 23, 59);
        if (now.isBefore(showUntil)) {
          overdue.add(e);
        }
      }
    }
    return overdue;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final user = auth.user;
    final entries = _getTodayEntries(medProvider.medications);
    final nextMed = _getNextMedication(entries);
    final overdueMeds = _getOverdueMeds(entries);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
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
                        AppColors.primaryLight.withValues(alpha: 0.15),
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

            // ── Overdue Banner (shown in RED until next dose) ────────
            if (overdueMeds.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: overdueMeds.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.overdue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.overdue.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.overdue.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medication_rounded,
                                  color: AppColors.overdue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.medication.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.overdue,
                                    ),
                                  ),
                                  Text(
                                    '${e.medication.dosage} — missed at ${_fmtTime(e.scheduledTime)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.overdue),
                                  ),
                                ],
                              ),
                            ),
                            CountdownTimer(
                              targetTime: e.scheduledTime,
                              isOverdue: true,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // ── Today's Medication Banner ────────────────────────────
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                          style: TextStyle(color: AppColors.primary)),
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
                            medProvider.markTaken(
                                uid, entry.medication.id, entry.timeKey);
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

  String _fmtTime(DateTime dt) {
    final hour =
    dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }
}

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
                  color: color.withValues(alpha: 0.1),
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