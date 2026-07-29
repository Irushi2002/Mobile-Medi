import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../utils/app_colors.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onRequestReschedule;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onRequestReschedule,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return AppColors.upcoming;
      case AppointmentStatus.completed:
        return AppColors.completed;
      case AppointmentStatus.missed:
        return AppColors.missed;
    }
  }

  String get _statusLabel {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.missed:
        return 'Missed';
    }
  }

  // ── Helper: humanise a time string like "09:00" → "09:00 AM" ─────────────
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return timeStr ?? '';
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  // ── Helper: humanise a date string "2026-08-05" → "Aug 05, 2026" ─────────
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return dateStr ?? '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = appointment.rescheduleStatus;

    final canReschedule =
        (appointment.status == AppointmentStatus.upcoming ||
            appointment.status == AppointmentStatus.missed) &&
            rs == RescheduleStatus.none;

    final isRequested = rs == RescheduleStatus.requested;
    final isApproved  = rs == RescheduleStatus.approved || rs == RescheduleStatus.accepted;
    final isRejected  = rs == RescheduleStatus.rejected;
    final isAlternative = rs == RescheduleStatus.alternativeSuggested;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: date block + details ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date block
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMM')
                            .format(appointment.dateTime)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Clinic, doctor, time, details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.clinic,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('hh:mm a').format(appointment.dateTime),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                      if (appointment.requestDetails.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          appointment.requestDetails,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ── Status banners ─────────────────────────────────────

            // Approved
            if (isApproved) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                color: AppColors.stable,
                icon: Icons.check_circle,
                child: Text(
                  appointment.staffMessage ??
                      (appointment.newDateTime != null
                          ? 'Rescheduled to ${DateFormat('MMM dd, yyyy – hh:mm a').format(appointment.newDateTime!)}'
                          : 'Your reschedule request has been approved.'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.stable,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ]

            // Pending / Requested
            else if (isRequested) ...[
              const SizedBox(height: 10),
              const _StatusBanner(
                color: AppColors.warning,
                icon: Icons.schedule,
                child: Text(
                  'Reschedule request submitted — awaiting staff response',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ]

            // Rejected
            else if (isRejected) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                color: AppColors.missed,
                icon: Icons.cancel,
                child: Text(
                  appointment.staffMessage ?? 'Your rescheduling request has been rejected.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.missed,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ]

            // Alternative time suggested
            else if (isAlternative) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                color: const Color(0xFFFF9800),
                icon: Icons.event_available,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appointment.staffMessage != null)
                      Text(
                        appointment.staffMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      )
                    else ...[
                      const Text(
                        'Staff suggested an alternative time:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (appointment.suggestedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(appointment.suggestedDate)} at ${_formatTime(appointment.suggestedTime)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ]

            // Request Reschedule button
            else if (canReschedule && onRequestReschedule != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRequestReschedule,
                  icon: const Icon(Icons.event_repeat, size: 16),
                  label: const Text('Request Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reusable status banner widget ─────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Widget child;

  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}