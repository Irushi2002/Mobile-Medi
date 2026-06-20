import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _accepted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _acceptAndContinue() async {
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the Privacy Policy to continue')),
      );
      return;
    }
    await context.read<AuthProvider>().acceptPrivacyPolicy();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please read our Privacy Policy carefully before using MediHub.',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildPolicySections(),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.stable.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.stable.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'You have read the full Privacy Policy. You may now accept to continue.',
                      style: TextStyle(
                          color: AppColors.stable,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (val) =>
                      setState(() => _accepted = val ?? false),
                  title: const Text(
                    'I have read and agree to the Privacy Policy and Terms of Service',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _accepted ? _acceptAndContinue : null,
                  child: const Text('Accept & Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPolicySections() {
    final sections = [
      {
        'title': '1. Information We Collect',
        'content':
        'MediHub collects personal health information including your name, email address, medication schedules, appointment records, and daily health check-in data. This information is collected solely for the purpose of providing healthcare management services.'
      },
      {
        'title': '2. How We Use Your Information',
        'content':
        'Your health data is used to display personalized medication reminders, track appointment schedules, and share daily check-in reports with your assigned medical team. We do not sell or share your data with third parties outside your healthcare providers.'
      },
      {
        'title': '3. Data Security',
        'content':
        'All data is encrypted in transit and at rest using industry-standard AES-256 encryption. We use Firebase Security Rules to ensure only authorized users can access their own health records.'
      },
      {
        'title': '4. Data Sharing',
        'content':
        'Health data including daily check-ins and symptom reports is shared with your registered medical team through the MediHub hospital portal. You consent to this sharing by using this application.'
      },
      {
        'title': '5. Notifications',
        'content':
        'MediHub sends push notifications for medication reminders and daily check-in prompts. You can manage notification preferences in your device settings.'
      },
      {
        'title': '6. Your Rights',
        'content':
        'You have the right to access, correct, or request deletion of your personal data. Contact our support team at support@medihub.lk for any data-related requests.'
      },
      {
        'title': '7. Contact Us',
        'content':
        'If you have questions about this Privacy Policy, contact us at support@medihub.lk or call +94 11 234 5678.'
      },
    ];
    return sections.map((s) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s['title']!,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(s['content']!,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6)),
          ],
        ),
      );
    }).toList();
  }
}