import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzLib;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'providers/auth_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize timezone database and set device local timezone
  tz.initializeTimeZones();
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  tzLib.setLocalLocation(tzLib.getLocation(timezoneInfo.identifier));

  await NotificationService().initialize();
  runApp(const MediCinnectApp());
}

class MediCinnectApp extends StatelessWidget {
  const MediCinnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, MedicationProvider>(
          create: (_) => MedicationProvider(),
          update: (_, settings, medication) {
            medication!.updateSettings(settings);
            return medication;
          },
        ),
      ],
      child: MaterialApp(
        title: 'MediCinnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}