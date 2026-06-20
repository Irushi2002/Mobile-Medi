import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../utils/app_colors.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final DateTime scheduledTime;
  final MedicationStatus status;
  final VoidCallback? onTakeMedication;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.scheduledTime,
    required this.status,
    this.onTakeMedication,
  });

  Color get _statusColor {
    switch (status) {
      case MedicationStatus.taken:
        return AppColors.stable;
      case MedicationStatus.overdue:
        return AppColors.overdue;
      case MedicationStatus.pending:
        return AppColors.primary;
      case MedicationStatus.skipped:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case MedicationStatus.taken:
        return 'Taken';
      case MedicationStatus.overdue:
        return 'Overdue';
      case MedicationStatus.pending:
        return 'Pending';
      case MedicationStatus.skipped:
        return 'Skipped';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.overdue:
        return Icons.warning_rounded;
      case MedicationStatus.pending:
        return Icons.circle_outlined;
      case MedicationStatus.skipped:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = status == MedicationStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.overdue.withValues(alpha: 0.4)
              : AppColors.border,
          width: isOverdue ? 1.5 : 0.8,
        ),
        boxShadow: isOverdue
            ? [BoxShadow(color: AppColors.overdue.withValues(alpha: 0.1), blurRadius: 8)]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Pill icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_rounded,
                  color: _statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Medication info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppColors.overdue
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${medication.dosage}  •  ${_formatTime(scheduledTime)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (medication.instructions != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      medication.instructions!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status / Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == MedicationStatus.pending ||
                    status == MedicationStatus.overdue) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onTakeMedication,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Mark Taken',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }
}