import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/privacy_policy_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/medication/my_medication_screen.dart';
import '../screens/medication/medication_history_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/update_profile_screen.dart';
import '../screens/checkin/daily_checkin_screen.dart';
import '../screens/support/privacy_support_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String privacyPolicy = '/privacy-policy';
  static const String dashboard = '/dashboard';
  static const String myMedication = '/my-medication';
  static const String medicationHistory = '/medication-history';
  static const String appointments = '/appointments';
  static const String profile = '/profile';
  static const String updateProfile = '/update-profile';
  static const String dailyCheckIn = '/daily-check-in';
  static const String privacySupport = '/privacy-support';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _route(const SplashScreen());
      case login:
        return _route(const LoginScreen());
      case privacyPolicy:
        return _route(const PrivacyPolicyScreen());
      case dashboard:
        return _route(const DashboardScreen());
      case myMedication:
        return _route(const MyMedicationScreen());
      case medicationHistory:
        return _route(const MedicationHistoryScreen());
      case appointments:
        return _route(const AppointmentsScreen());
      case profile:
        return _route(const ProfileScreen());
      case updateProfile:
        return _route(const UpdateProfileScreen());
      case dailyCheckIn:
        return _route(const DailyCheckInScreen());
      case privacySupport:
        return _route(const PrivacySupportScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute _route(Widget widget) {
    return MaterialPageRoute(builder: (_) => widget);
  }
}