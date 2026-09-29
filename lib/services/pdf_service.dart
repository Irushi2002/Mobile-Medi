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
    final doctorName = prescribers.isNotEmpty ? prescribers.first! : 'MediHub Doctor';
    
    final formatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final prescriptionDate = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(doctorName, prescriptionDate, formatter),
            pw.SizedBox(height: 30),
            _buildMedicationTable(medications, formatter, timeFormatter),
            pw.SizedBox(height: 40),
            pw.Divider(color: PdfColors.grey300),
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

  static pw.Widget _buildHeader(String doctorName, DateTime date, DateFormat formatter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'MediHub',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'PRESCRIPTION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Prescriber:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text(doctorName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date Generated:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text(formatter.format(date), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMedicationTable(
    List<MedicationModel> meds,
    DateFormat formatter,
    DateFormat timeFormatter,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      headers: ['Medication & Dose', 'Instructions', 'Duration', 'Schedule'],
      data: meds.map((med) {
        // 1. Medication & Dose
        final drugName = med.dosage.isNotEmpty ? '${med.name}\n${med.dosage}' : med.name;
        
        // 2. Instructions
        final instList = <String>[];
        if (med.frequency.isNotEmpty) instList.add(med.frequency);
        if (med.instructions != null && med.instructions!.isNotEmpty) instList.add(med.instructions!);
        final instructions = instList.isEmpty ? '-' : instList.join('\n');
        
        // 3. Duration
        final start = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
        String durationStr = '';
        if (med.endDate != null) {
          final end = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
          final days = end.difference(start).inDays + 1;
          durationStr = '$days day${days == 1 ? '' : 's'}\n${formatter.format(start)} - ${formatter.format(end)}';
        } else {
          durationStr = 'Ongoing\nFrom ${formatter.format(start)}';
        }
        
        // 4. Schedule
        final times = med.scheduledTimes.isNotEmpty 
            ? med.scheduledTimes.map((t) => timeFormatter.format(t)).join('\n')
            : '-';
            
        return [drugName, instructions, durationStr, times];
      }).toList(),
    );
  }
}
