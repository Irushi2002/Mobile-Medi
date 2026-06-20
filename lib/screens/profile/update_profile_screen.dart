import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _dobController =
        TextEditingController(text: user?.dateOfBirth ?? '');
    _phoneController =
        TextEditingController(text: user?.phoneNumber ?? '');
    _emergencyNameController =
        TextEditingController(text: user?.emergencyContactName ?? '');
    _emergencyPhoneController =
        TextEditingController(text: user?.emergencyContactNumber ?? '');
  }

  @override
  void dispose() {
    _dobController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AuthProvider>().updateProfile({
      'dateOfBirth': _dobController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'emergencyContactName': _emergencyNameController.text.trim(),
      'emergencyContactNumber': _emergencyPhoneController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppColors.stable,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Update Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Non-editable notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.upcoming.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.upcoming.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.upcoming, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some fields are pre-filled from the hospital system and cannot be edited.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.upcoming,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Non-Editable Fields ────────────────────────────────────────
            _sectionHeader('Hospital Information (Read-only)'),
            _readOnlyField('Full Name', user?.fullName ?? '—'),
            _readOnlyField('Hospital ID', user?.hospitalId ?? '—'),
            _readOnlyField('Gender', user?.gender ?? '—'),
            _readOnlyField('Blood Group', user?.bloodGroup ?? '—'),
            _readOnlyField('Primary Condition', user?.primaryCondition ?? '—'),
            _readOnlyField('Diagnosis', user?.diagnosis ?? '—'),
            _readOnlyField('Allergies', user?.allergies ?? '—'),

            const SizedBox(height: 20),

            // ─── Editable Fields ────────────────────────────────────────────
            _sectionHeader('Personal Details (Editable)'),

            _editableField(
              controller: _dobController,
              label: 'Date of Birth',
              hint: 'e.g. 15/04/1990',
              icon: Icons.cake_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your date of birth';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _editableField(
              controller: _phoneController,
              label: 'Mobile Number',
              hint: 'e.g. +94 77 123 4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your mobile number';
                return null;
              },
            ),

            const SizedBox(height: 20),
            _sectionHeader('Emergency Contact (Editable)'),

            _editableField(
              controller: _emergencyNameController,
              label: 'Emergency Contact Name',
              hint: 'Full name',
              icon: Icons.contact_emergency_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter contact name';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _editableField(
              controller: _emergencyPhoneController,
              label: 'Emergency Contact Number',
              hint: 'e.g. +94 77 987 6543',
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter contact number';
                return null;
              },
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Saving...'),
                ],
              )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
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
                        fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline,
              size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _editableField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}