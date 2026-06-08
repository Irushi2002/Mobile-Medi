import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final bool isOverdue;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    this.isOverdue = false,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.targetTime.difference(DateTime.now());
    if (diff.isNegative) {
      setState(() => _remaining = Duration.zero);
      if (!widget.isOverdue) {
        _timer.cancel();
        widget.onExpired?.call();
      }
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  String _overdueLabel() {
    final diff = DateTime.now().difference(widget.targetTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return 'Overdue by ${hours}h ${minutes}m';
    }
    return 'Overdue by ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.overdue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.overdue.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded,
                size: 16, color: AppColors.overdue),
            const SizedBox(width: 6),
            Text(
              _overdueLabel(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.overdue,
              ),
            ),
          ],
        ),
      );
    }

    final totalMinutes = widget.targetTime.difference(DateTime.now()).inMinutes;
    final isUrgent = totalMinutes <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isUrgent ? AppColors.warning : AppColors.primary)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isUrgent ? AppColors.warning : AppColors.primary)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isUrgent ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_remaining),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isUrgent ? AppColors.warning : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}