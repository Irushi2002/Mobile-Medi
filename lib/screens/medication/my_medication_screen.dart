import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class MyMedicationScreen extends StatefulWidget {
  const MyMedicationScreen({super.key});

  @override
  State<MyMedicationScreen> createState() => _MyMedicationScreenState();
}

class _MyMedicationScreenState extends State<MyMedicationScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final medications = medProvider.medications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescription Chart'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: medications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text(
                    'No active prescriptions found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Please contact your physician to sync data.',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Prescription Rx Header ────────────────────────
                  Row(
                    children: [
                      const Text(
                        '℞', // Rx symbol
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ACTIVE Rx PRESCRIPTIONS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${medications.length} items',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Medication List (Prescription Table) ──────────
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medications.length,
                    itemBuilder: (ctx, i) {
                      return _buildPrescriptionCard(medications[i]);
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildPrescriptionCard(MedicationModel med) {
    final startStr = DateFormat('dd MMM yyyy').format(med.startDate);
    final endStr = med.endDate != null
        ? DateFormat('dd MMM yyyy').format(med.endDate!)
        : 'Ongoing Intake';

    final timesStr = med.scheduledTimes
        .map((t) => DateFormat('hh:mm a').format(
            DateTime(2026, 1, 1, t.hour, t.minute)))
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Line
              Container(
                width: 6,
                color: AppColors.primaryLight,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drug name & dosage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            med.dosage,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Sig Directions
                      _buildRowDetail(Icons.repeat_rounded, 'Sig / Frequency', med.frequency),
                      const SizedBox(height: 6),
                      if (med.instructions != null && med.instructions!.isNotEmpty) ...[
                        _buildRowDetail(Icons.info_outline_rounded, 'Directions', med.instructions!),
                        const SizedBox(height: 6),
                      ],
                      _buildRowDetail(Icons.calendar_today_outlined, 'Duration', '$startStr — $endStr'),
                      const SizedBox(height: 6),
                      _buildRowDetail(Icons.access_time_rounded, 'Dosing Times', timesStr),

                      const Divider(height: 20, color: AppColors.border),

                      // Prescribed by doctor name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prescriber: ${med.prescribedBy ?? 'Hospital Medical Team'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.stable, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE Rx',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.stable,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}