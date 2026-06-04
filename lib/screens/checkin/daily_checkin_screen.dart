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
  bool _alreadySubmitted = false;
  bool _isChecking = true;

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
      _alreadySubmitted = existing != null;
      _isChecking = false;
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

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _alreadySubmitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in submitted to your doctor'),
        backgroundColor: AppColors.stable,
      ),
    );
  }

  Color get _statusColor {
    switch (_healthStatus) {
      case HealthStatus.stable:
        return AppColors.stable;
      case HealthStatus.warning:
        return AppColors.warning;
      case HealthStatus.critical:
        return AppColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      body: _alreadySubmitted ? _buildSubmittedView() : _buildFormView(),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSubmittedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.stable.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.stable, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              "Today's Check-In Complete",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your health status has been submitted to your doctor. Come back tomorrow for your next check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(isSelected ? 1 : 0.3),
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon,
                                  color: isSelected ? Colors.white : color,
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
                          color: AppColors.primary.withOpacity(0.1),
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
                // Custom symptom input
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