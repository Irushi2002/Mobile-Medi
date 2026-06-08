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

  @override
  Widget build(BuildContext context) {
    final canReschedule =
        (appointment.status == AppointmentStatus.upcoming ||
            appointment.status == AppointmentStatus.missed) &&
            appointment.rescheduleStatus == RescheduleStatus.none;

    final isRequested =
        appointment.rescheduleStatus == RescheduleStatus.requested;
    final isAccepted =
        appointment.rescheduleStatus == RescheduleStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      // Clip everything inside the rounded border
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

            // ── Reschedule accepted ────────────────────────────────
            if (isAccepted && appointment.newDateTime != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.stable.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.stable.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.stable, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rescheduled to ${DateFormat('MMM dd, yyyy – hh:mm a').format(appointment.newDateTime!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.stable,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]

            // ── Reschedule requested (pending) ────────────────────
            else if (isRequested) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reschedule request sent — awaiting doctor approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]

            // ── Request reschedule button ─────────────────────────
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