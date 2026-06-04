import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class PrivacySupportScreen extends StatelessWidget {
  const PrivacySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Help & Support
          _SupportSection(
            title: 'Help & Support',
            icon: Icons.support_agent_outlined,
            color: AppColors.primary,
            children: [
              _ContactTile(
                icon: Icons.phone_outlined,
                title: 'Support Hotline',
                subtitle: AppConstants.supportPhone,
                color: AppColors.stable,
              ),
              _ContactTile(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: AppConstants.supportEmail,
                color: AppColors.upcoming,
              ),
              _ContactTile(
                icon: Icons.local_hospital_outlined,
                title: 'Emergency',
                subtitle: AppConstants.emergencyPhone,
                color: AppColors.critical,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Terms & Privacy
          _SupportSection(
            title: 'Legal',
            icon: Icons.gavel_outlined,
            color: AppColors.accent,
            children: [
              _NavigationTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => _showLegalPage(context, 'Terms & Conditions',
                    _termsContent),
              ),
              _NavigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () =>
                    _showLegalPage(context, 'Privacy Policy', _privacyContent),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.medical_services_rounded,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 10),
                const Text('MediCinnect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                const Text('Version 1.0.0',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                const Text('© 2024 MediCinnect. All rights reserved.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLegalPage(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const String _termsContent = '''
TERMS AND CONDITIONS

Last Updated: January 2024

1. ACCEPTANCE OF TERMS
By accessing and using MediCinnect, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the application.

2. USE OF THE APPLICATION
MediCinnect is designed to assist patients in managing their medication schedules and health records. The application is not a substitute for professional medical advice, diagnosis, or treatment.

3. USER RESPONSIBILITIES
Users are responsible for maintaining the accuracy of their health information, taking medications as prescribed by their healthcare providers, and reporting any technical issues to our support team.

4. MEDICAL DISCLAIMER
MediCinnect does not provide medical advice. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.

5. DATA ACCURACY
While we strive to ensure data accuracy, MediCinnect is not responsible for medication schedules entered incorrectly or discrepancies between the app and your actual prescription.

6. LIMITATION OF LIABILITY
MediCinnect and its affiliates shall not be liable for any indirect, incidental, special, or consequential damages resulting from the use of this application.

7. MODIFICATIONS
We reserve the right to modify these Terms at any time. Continued use of the application after changes constitutes acceptance of the modified terms.

8. CONTACT
For questions about these Terms, contact us at support@medicinnect.lk
''';

  static const String _privacyContent = '''
PRIVACY POLICY

Last Updated: January 2024

1. INFORMATION WE COLLECT
MediCinnect collects personal health information including your name, email address, medication schedules, appointment records, and daily health check-in data.

2. HOW WE USE YOUR INFORMATION
Your health data is used to display personalized medication reminders, track appointment schedules, and share daily check-in reports with your assigned medical team.

3. DATA SHARING
Health data including daily check-ins and symptom reports is shared with your registered medical team through the MediCinnect hospital portal.

4. DATA SECURITY
All data is encrypted in transit and at rest using industry-standard AES-256 encryption.

5. YOUR RIGHTS
You have the right to access, correct, or request deletion of your personal data.

6. NOTIFICATIONS
MediCinnect sends push notifications for medication reminders and daily check-in prompts.

7. CONTACT US
For privacy-related questions, contact us at support@medicinnect.lk or call +94 11 234 5678.
''';
}

class _SupportSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _SupportSection(
      {required this.title,
        required this.icon,
        required this.color,
        required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _ContactTile(
      {required this.icon,
        required this.title,
        required this.subtitle,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavigationTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}