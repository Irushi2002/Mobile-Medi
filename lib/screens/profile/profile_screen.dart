import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.critical),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person,
                      color: Colors.white, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Patient',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      if (user?.hospitalId != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${user!.hospitalId}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Personal Information
          _SectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Full Name',
                  value: user?.fullName ?? '—'),
              _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: user?.phoneNumber ?? '—'),
              _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: user?.email ?? '—'),
              _InfoTile(
                  icon: Icons.home_outlined,
                  label: 'Home Address',
                  value: user?.address ?? '—'),
              _InfoTile(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: user?.dateOfBirth ?? '—'),
            ],
          ),

          const SizedBox(height: 12),

          // Medical Information
          _SectionCard(
            title: 'Medical Information',
            icon: Icons.medical_information_outlined,
            children: [
              _InfoTile(
                  icon: Icons.bloodtype_outlined,
                  label: 'Blood Group',
                  value: user?.bloodGroup ?? '—'),
              _InfoTile(
                  icon: Icons.person_pin_outlined,
                  label: 'Gender',
                  value: user?.gender ?? '—'),
              _InfoTile(
                  icon: Icons.coronavirus_outlined,
                  label: 'Primary Condition',
                  value: user?.primaryCondition ?? '—'),
              _InfoTile(
                  icon: Icons.assignment_outlined,
                  label: 'Diagnosis',
                  value: user?.diagnosis ?? '—'),
              _InfoTile(
                  icon: Icons.warning_amber_outlined,
                  label: 'Allergies',
                  value: user?.allergies ?? '—'),
            ],
          ),

          const SizedBox(height: 12),

          // Emergency Contact
          _SectionCard(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            children: [
              _InfoTile(
                  icon: Icons.contact_emergency_outlined,
                  label: 'Contact Name',
                  value: user?.emergencyContactName ?? '—'),
              _InfoTile(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Contact Number',
                  value: user?.emergencyContactNumber ?? '—'),
            ],
          ),

          const SizedBox(height: 16),

          // Settings / Navigation
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.edit_outlined,
              label: 'Update Profile',
              color: AppColors.primary,
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.updateProfile),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notification Settings',
              color: AppColors.primaryLight,
              onTap: () => Navigator.pushNamed(
                  context, AppRouter.notificationSettings),
            ),
            _SettingsTile(
              icon: Icons.history_rounded,
              label: 'Medication History',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(
                  context, AppRouter.medicationHistory),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy & Support',
              color: AppColors.upcoming,
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.privacySupport),
            ),
            _SettingsTile(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.critical,
              onTap: () => _confirmLogout(context),
            ),
          ]),

          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}