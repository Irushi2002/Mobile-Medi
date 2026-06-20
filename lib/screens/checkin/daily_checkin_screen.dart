import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/checkin_model.dart';
import '../../services/medication_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final MedicationService _service = MedicationService();
  final TextEditingController _customSymptomController =
  TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Set<String> _selectedSymptoms = {};
  HealthStatus _healthStatus = HealthStatus.stable;
  bool _isLoading = false;
  bool _isChecking = true;

  // Edit mode support
  CheckInModel? _existingCheckIn;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _checkTodayCheckIn();
  }

  Future<void> _checkTodayCheckIn() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final existing = await _service.getTodayCheckIn(uid);
    setState(() {
      _existingCheckIn = existing;
      _isChecking = false;
      if (existing != null) {
        // Pre-fill the form with existing data for editing
        _selectedSymptoms.addAll(existing.symptoms);
        _healthStatus = existing.healthStatus;
        _notesController.text = existing.additionalNotes ?? '';
      }
    });
  }

  void _enterEditMode() {
    setState(() => _isEditMode = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      // Reset to existing values
      _selectedSymptoms.clear();
      if (_existingCheckIn != null) {
        _selectedSymptoms.addAll(_existingCheckIn!.symptoms);
        _healthStatus = _existingCheckIn!.healthStatus;
        _notesController.text = _existingCheckIn!.additionalNotes ?? '';
      }
    });
  }

  @override
  void dispose() {
    _customSymptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCustomSymptom() {
    final text = _customSymptomController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _selectedSymptoms.add(text);
      _customSymptomController.clear();
    });
  }

  Future<void> _submit() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);

    if (_isEditMode && _existingCheckIn != null) {
      // Update existing check-in
      final updated = CheckInModel(
        id: _existingCheckIn!.id,
        userId: uid,
        date: _existingCheckIn!.date,
        symptoms: _selectedSymptoms.toList(),
        healthStatus: _healthStatus,
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        submittedToDoctor: true,
      );
      await _service.updateCheckIn(uid, _existingCheckIn!.id, updated);
      setState(() {
        _existingCheckIn = updated;
        _isEditMode = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in updated successfully'),
            backgroundColor: AppColors.stable,
          ),
        );
      }
    } else {
      // New submission
      final checkIn = CheckInModel(
        id: '',
        userId: uid,
        date: DateTime.now(),
        symptoms: _selectedSymptoms.toList(),
        healthStatus: _healthStatus,
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        submittedToDoctor: true,
      );
      await _service.submitCheckIn(checkIn);
      final saved = await _service.getTodayCheckIn(uid);
      setState(() {
        _existingCheckIn = saved;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in submitted to your doctor'),
            backgroundColor: AppColors.stable,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show submitted view if submitted and not in edit mode
    final showSubmitted =
        _existingCheckIn != null && !_isEditMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Check-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: showSubmitted
          ? _buildSubmittedView()
          : _buildFormView(),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSubmittedView() {
    final checkIn = _existingCheckIn!;
    final statusColor = checkIn.healthStatus == HealthStatus.stable
        ? AppColors.stable
        : checkIn.healthStatus == HealthStatus.warning
        ? AppColors.warning
        : AppColors.critical;
    final statusLabel = checkIn.healthStatus == HealthStatus.stable
        ? 'Stable'
        : checkIn.healthStatus == HealthStatus.warning
        ? 'Warning'
        : 'Critical';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.stable.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border:
              Border.all(color: AppColors.stable.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.stable, size: 44),
                SizedBox(height: 12),
                Text(
                  "Today's Check-In Submitted",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your health status has been sent to your doctor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary of submitted data
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Submitted Summary',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                // Health status
                Row(
                  children: [
                    const Icon(Icons.favorite_outline,
                        size: 16, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    const Text('Health Status: ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (checkIn.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Symptoms:',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: checkIn.symptoms
                        .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary)),
                    ))
                        .toList(),
                  ),
                ],
                if (checkIn.additionalNotes != null &&
                    checkIn.additionalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Notes:',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    checkIn.additionalNotes!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Edit button
          OutlinedButton.icon(
            onPressed: _enterEditMode,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Update Check-In'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'You can update your check-in if your condition has changed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    final isEditing = _isEditMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit mode notice
          if (isEditing) ...[
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
                  Icon(Icons.edit_outlined,
                      color: AppColors.upcoming, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are updating your daily check-in. Changes will be sent to your doctor.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.upcoming,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Health status selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How are you feeling today?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: HealthStatus.values.map((status) {
                    final isSelected = _healthStatus == status;
                    final color = status == HealthStatus.stable
                        ? AppColors.stable
                        : status == HealthStatus.warning
                        ? AppColors.warning
                        : AppColors.critical;
                    final label = status == HealthStatus.stable
                        ? 'Stable'
                        : status == HealthStatus.warning
                        ? 'Warning'
                        : 'Critical';
                    final icon = status == HealthStatus.stable
                        ? Icons.sentiment_satisfied_alt
                        : status == HealthStatus.warning
                        ? Icons.sentiment_neutral
                        : Icons.sentiment_very_dissatisfied;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _healthStatus = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color
                                  .withValues(alpha: isSelected ? 1 : 0.3),
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon,
                                  color:
                                  isSelected ? Colors.white : color,
                                  size: 26),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Symptoms
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Symptoms',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(width: 8),
                    if (_selectedSymptoms.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedSymptoms.length} selected',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Select all that apply',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.predefinedSymptoms.map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isSelected
                              ? _selectedSymptoms.remove(symptom)
                              : _selectedSymptoms.add(symptom);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          symptom,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customSymptomController,
                        decoration: const InputDecoration(
                          hintText: 'Add other symptom...',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onFieldSubmitted: (_) => _addCustomSymptom(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addCustomSymptom,
                      icon: const Icon(Icons.add_circle,
                          color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Additional notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Additional Notes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                    'Describe any additional symptoms or concerns...',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit / Cancel buttons
          if (isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side:
                      const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.update_rounded),
                    label: Text(
                        _isLoading ? 'Updating...' : 'Update Check-In'),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'Submitting...' : 'Submit Check-In'),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'Your check-in will be sent directly to your medical team',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}