import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/medication_model.dart';

class PdfService {
  static Future<Uint8List> generatePrescriptionPdf({
    required List<MedicationModel> medications,
  }) async {
    final pdf = pw.Document();

    // Get unique prescribers or default
    final prescribers = medications
        .map((m) => m.prescribedBy)
        .where((p) => p != null && p.isNotEmpty)
        .toSet();
    final doctorName =
        prescribers.isNotEmpty ? prescribers.first! : 'MediHub Doctor';

    final formatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final prescriptionDate = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(doctorName, prescriptionDate, formatter),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'MEDICATIONS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            ...medications
                .map((med) =>
                    _buildMedicationSection(med, formatter, timeFormatter))
                .toList(),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Generated through MediHub',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      String doctorName, DateTime date, DateFormat formatter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'MediHub',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'PRESCRIPTION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Text('Prescriber: $doctorName',
            style: const pw.TextStyle(fontSize: 12)),
        pw.Text('Date Generated: ${formatter.format(date)}',
            style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildMedicationSection(
    MedicationModel med,
    DateFormat formatter,
    DateFormat timeFormatter,
  ) {
    final start =
        DateTime(med.startDate.year, med.startDate.month, med.startDate.day);

    String durationText = 'Not specified';
    String periodText = 'Not specified';

    if (med.endDate != null) {
      final end =
          DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
      final days = end.difference(start).inDays + 1;

      durationText = '$days day${days == 1 ? '' : 's'}';
      periodText = '${formatter.format(start)} - ${formatter.format(end)}';
    } else {
      periodText = 'From ${formatter.format(start)}';
      durationText = 'Ongoing';
    }

    final timesText = med.scheduledTimes.isNotEmpty
        ? med.scheduledTimes.map((t) => timeFormatter.format(t)).join(', ')
        : 'Not specified';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            med.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          _buildDetailRow('Strength/Dose:',
              med.dosage.isNotEmpty ? med.dosage : 'Not specified'),
          _buildDetailRow('Frequency:',
              med.frequency.isNotEmpty ? med.frequency : 'Not specified'),
          _buildDetailRow(
              'Directions:',
              (med.instructions != null && med.instructions!.isNotEmpty)
                  ? med.instructions!
                  : 'Not specified'),
          _buildDetailRow('Duration:', durationText),
          _buildDetailRow('Treatment Period:', periodText),
          _buildDetailRow('Dosing Times:', timesText),
          _buildDetailRow(
              'Status:', med.isActive ? 'Active' : 'Stopped/Completed'),
          if (med.prescribedBy != null && med.prescribedBy!.isNotEmpty)
            _buildDetailRow('Prescriber:', med.prescribedBy!),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
