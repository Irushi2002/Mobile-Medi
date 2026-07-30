class AppConstants {
  // ── Collections (Firestore) ──────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String medicationsCollection = 'medications';
  static const String appointmentsCollection = 'appointments';
  static const String checkInsCollection = 'checkIns';

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const String privacyAcceptedKey = 'privacy_policy_accepted';
  static const String userIdKey = 'user_id';

  // ── Web Backend URL ──────────────────────────────────────────────────────
  // Change this to your actual deployed backend URL
  //For local development: 'http://10.0.2.2:5000'  (Android emulator)
  // For real device on same WiFi: 'http://192.168.x.x:5000'
  // For deployed backend: 'https://your-backend.railway.app'
  //static const String webBackendUrl = 'http://10.0.2.2:5000';
  static const String webBackendUrl = 'http://10.253.140.4:5000';

  // ── API Secret Key (must match CLOUD_FUNCTION_SECRET in server .env) ─────
  static const String apiSecretKey = '5cc8745ab3c18fbf501a27dd04b7b981';

  // ── Support Contact ──────────────────────────────────────────────────────
  static const String supportPhone = '+94 11 234 5678';
  static const String supportEmail = 'support@medihub.lk';
  static const String emergencyPhone = '+94 11 987 6543';

  // ── Predefined Symptoms ──────────────────────────────────────────────────
  static const List<String> predefinedSymptoms = [
    'Headache',
    'Fever',
    'Nausea',
    'Fatigue',
    'Chest Pain',
    'Shortness of Breath',
    'Dizziness',
    'Stomach Pain',
    'Back Pain',
    'Cough',
    'Sore Throat',
    'Joint Pain',
    'Muscle Weakness',
    'Swelling',
    'Rash',
    'Loss of Appetite',
    'Insomnia',
    'Anxiety',
  ];
}