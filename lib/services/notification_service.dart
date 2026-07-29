import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_model.dart';
import '../models/appointment_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ───────────────────────────────────────────────────────────────────────────
  //  Initialise
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Runtime permission request (Android 13+ / iOS)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Deterministic ID helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Produces a stable, collision-resistant int from a string key.
  /// Kept within the positive 31-bit safe range for Android notification IDs.
  int _stableId(String key) {
    int hash = 0;
    for (final codeUnit in key.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }

  int _medicationNotificationId(
          String medicationId, int timeIndex, int dayOffset) =>
      _stableId('med_${medicationId}_t${timeIndex}_d$dayOffset');

  int _appointmentNotificationId(String appointmentId,
          {required String suffix}) =>
      _stableId('appt_${appointmentId}_$suffix');

  // ───────────────────────────────────────────────────────────────────────────
  //  Notification channel details (with and without sound)
  // ───────────────────────────────────────────────────────────────────────────

  static const _medicationChannelSound = AndroidNotificationDetails(
    'medication_channel',
    'Medication Reminders',
    channelDescription: 'Reminders to take your medications on time',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
  );

  static const _medicationChannelSilent = AndroidNotificationDetails(
    'medication_channel_silent',
    'Medication Reminders (Silent)',
    channelDescription: 'Silent reminders to take your medications on time',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: false,
    enableVibration: true,
  );

  static const _appointmentChannelSound = AndroidNotificationDetails(
    'appointment_channel',
    'Follow-up Reminders',
    channelDescription: 'Reminders for upcoming doctor follow-up appointments',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
  );

  static const _appointmentChannelSilent = AndroidNotificationDetails(
    'appointment_channel_silent',
    'Follow-up Reminders (Silent)',
    channelDescription:
        'Silent reminders for upcoming doctor follow-up appointments',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: false,
    enableVibration: true,
  );

  NotificationDetails _medicationDetails({required bool soundEnabled}) =>
      NotificationDetails(
        android:
            soundEnabled ? _medicationChannelSound : _medicationChannelSilent,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        ),
      );

  NotificationDetails _appointmentDetails({required bool soundEnabled}) =>
      NotificationDetails(
        android: soundEnabled
            ? _appointmentChannelSound
            : _appointmentChannelSilent,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        ),
      );

  // ───────────────────────────────────────────────────────────────────────────
  //  Medication notifications
  // ───────────────────────────────────────────────────────────────────────────

  /// Schedule a single medication dose notification.
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    bool soundEnabled = true,
  }) async {
    final tzTime = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id,
        '\u{1F48A} Time for your medication',
        'Take $medicationName \u2014 $dosage',
        tzTime,
        _medicationDetails(soundEnabled: soundEnabled),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Scheduled medication reminder: $medicationName at $tzTime');
    } catch (e) {
      print('Failed to schedule medication reminder: $e');
    }
  }

  /// Cancel all scheduled notifications for a specific medication
  /// across the full 7-day scheduling window.
  Future<void> cancelMedicationNotifications(
      String medicationId, int timeCount) async {
    for (int t = 0; t < timeCount; t++) {
      for (int d = 0; d < 7; d++) {
        await _plugin.cancel(_medicationNotificationId(medicationId, t, d));
      }
    }
  }

  /// Cancel and reschedule notifications for all medications
  /// over a rolling 7-day window starting today.
  Future<void> scheduleAllMedicationNotifications(
    List<MedicationModel> medications, {
    bool notificationsEnabled = true,
    bool soundEnabled = true,
  }) async {
    final now = DateTime.now();

    for (final med in medications) {
      // Cancel any stale notifications for this medication first
      await cancelMedicationNotifications(med.id, med.scheduledTimes.length);

      // Don't schedule if notifications are disabled globally
      if (!notificationsEnabled) continue;

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));

        if (!med.isScheduledForDate(targetDate)) continue;

        for (int timeIndex = 0;
            timeIndex < med.scheduledTimes.length;
            timeIndex++) {
          final t = med.scheduledTimes[timeIndex];
          final scheduledTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            t.hour,
            t.minute,
          );

          if (scheduledTime.isAfter(now)) {
            await scheduleMedicationReminder(
              id: _medicationNotificationId(med.id, timeIndex, dayOffset),
              medicationName: med.name,
              dosage: med.dosage,
              scheduledTime: scheduledTime,
              soundEnabled: soundEnabled,
            );
          }
        }
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Appointment notifications
  // ───────────────────────────────────────────────────────────────────────────

  /// Schedule a 24-hour, a 1-day (calendar day), and a 1-hour reminder
  /// for a single appointment.
  Future<void> scheduleFollowUpReminder(
    AppointmentModel appointment, {
    bool notificationsEnabled = true,
    bool soundEnabled = true,
  }) async {
    if (!notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final apptTime = tz.TZDateTime(
      tz.local,
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
      appointment.dateTime.hour,
      appointment.dateTime.minute,
    );

    // Only schedule for upcoming appointments within the next 30 days
    final cutoff = now.add(const Duration(days: 30));
    if (apptTime.isBefore(now) ||
        apptTime.isAfter(cutoff) ||
        appointment.status != AppointmentStatus.upcoming) {
      return;
    }

    final timeStr =
        '${appointment.dateTime.hour.toString().padLeft(2, '0')}:'
        '${appointment.dateTime.minute.toString().padLeft(2, '0')}';

    final details = _appointmentDetails(soundEnabled: soundEnabled);

    // 1-day reminder (fires at 9 AM the day before the appointment)
    final dayBefore = tz.TZDateTime(
      tz.local,
      apptTime.year,
      apptTime.month,
      apptTime.day - 1,
      9,
      0,
    );
    if (dayBefore.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          _appointmentNotificationId(appointment.id, suffix: '1d'),
          '\u{1F4C5} Appointment Tomorrow',
          'Reminder: your appointment with ${appointment.doctorName} at '
              '${appointment.clinic} is tomorrow at $timeStr',
          dayBefore,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('Scheduled 1d appointment reminder for $timeStr at $dayBefore');
      } catch (e) {
        print('Failed to schedule 1d appointment reminder: $e');
      }
    }

    // 24-hour reminder (exactly 24 h before appointment time)
    final reminder24h = apptTime.subtract(const Duration(hours: 24));
    if (reminder24h.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          _appointmentNotificationId(appointment.id, suffix: '24h'),
          '\u{1F4C5} Upcoming Follow-up Tomorrow',
          'Your appointment with ${appointment.doctorName} at '
              '${appointment.clinic} is tomorrow at $timeStr',
          reminder24h,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('Scheduled 24h appointment reminder for $timeStr at $reminder24h');
      } catch (e) {
        print('Failed to schedule 24h appointment reminder: $e');
      }
    }

    // 1-hour reminder
    final reminder1h = apptTime.subtract(const Duration(hours: 1));
    if (reminder1h.isAfter(now)) {
      try {
        await _plugin.zonedSchedule(
          _appointmentNotificationId(appointment.id, suffix: '1h'),
          '\u{23F0} Follow-up in 1 Hour',
          'Your appointment with ${appointment.doctorName} at '
              '${appointment.clinic} starts in 1 hour',
          reminder1h,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('Scheduled 1h appointment reminder for $timeStr at $reminder1h');
      } catch (e) {
        print('Failed to schedule 1h appointment reminder: $e');
      }
    }
  }

  /// Cancel all reminder notifications for a specific appointment.
  Future<void> cancelAppointmentNotifications(String appointmentId) async {
    await _plugin
        .cancel(_appointmentNotificationId(appointmentId, suffix: '1d'));
    await _plugin
        .cancel(_appointmentNotificationId(appointmentId, suffix: '24h'));
    await _plugin
        .cancel(_appointmentNotificationId(appointmentId, suffix: '1h'));
  }

  /// Cancel and reschedule reminder notifications for all appointments.
  Future<void> scheduleAllAppointmentNotifications(
    List<AppointmentModel> appointments, {
    bool notificationsEnabled = true,
    bool soundEnabled = true,
  }) async {
    for (final appt in appointments) {
      await cancelAppointmentNotifications(appt.id);
      await scheduleFollowUpReminder(
        appt,
        notificationsEnabled: notificationsEnabled,
        soundEnabled: soundEnabled,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Legacy — daily check-in reminder
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> scheduleDailyCheckInReminder() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      999,
      'Daily Check-In',
      "Don't forget to complete your daily health check-in!",
      tz.TZDateTime(tz.local, scheduledTime.year, scheduledTime.month, scheduledTime.day, scheduledTime.hour, scheduledTime.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_channel',
          'Daily Check-In Reminders',
          channelDescription: 'Reminders for daily health check-ins',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Cancel helpers
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}