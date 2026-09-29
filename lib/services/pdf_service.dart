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

    final formatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final prescriptionDate = DateTime.now();

    // Group medications by prescriber
    final groupedMeds = <String, List<MedicationModel>>{};
    for (var med in medications) {
      final docName = (med.prescribedBy != null && med.prescribedBy!.isNotEmpty)
          ? med.prescribedBy!
          : 'MediHub Doctor';
      groupedMeds.putIfAbsent(docName, () => []).add(med);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          final content = <pw.Widget>[
            _buildHeader(prescriptionDate, formatter),
            pw.SizedBox(height: 30),
          ];

          // Generate a table for each prescriber
          for (var entry in groupedMeds.entries) {
            final docName = entry.key;
            final docMeds = entry.value;

            content.addAll([
              pw.Text(
                'Prescriber: $docName',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildMedicationTable(docMeds, formatter, timeFormatter),
              pw.SizedBox(height: 25), // Space between doctors
            ]);
          }

          content.addAll([
            pw.SizedBox(height: 15),
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
          ]);

          return content;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(DateTime date, DateFormat formatter) {
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
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date Generated:',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
                pw.Text(formatter.format(date),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
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
        final drugName =
            med.dosage.isNotEmpty ? '${med.name}\n${med.dosage}' : med.name;

        final instList = <String>[];
        if (med.frequency.isNotEmpty) instList.add(med.frequency);
        if (med.instructions != null && med.instructions!.isNotEmpty)
          instList.add(med.instructions!);
        final instructions = instList.isEmpty ? '-' : instList.join('\n');

        final start = DateTime(
            med.startDate.year, med.startDate.month, med.startDate.day);
        String durationStr = '';
        if (med.endDate != null) {
          final end =
              DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
          final days = end.difference(start).inDays + 1;
          durationStr =
              '$days day${days == 1 ? '' : 's'}\n${formatter.format(start)} - ${formatter.format(end)}';
        } else {
          durationStr = 'Ongoing\nFrom ${formatter.format(start)}';
        }

        final times = med.scheduledTimes.isNotEmpty
            ? med.scheduledTimes.map((t) => timeFormatter.format(t)).join('\n')
            : '-';

        return [drugName, instructions, durationStr, times];
      }).toList(),
    );
  }
}
