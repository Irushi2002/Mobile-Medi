const fs = require('fs');
let content = fs.readFileSync('lib/screens/medication/my_medication_screen.dart', 'utf-8');

// 1. Add imports
content = content.replace(
  "import '../../widgets/bottom_nav_bar.dart';",
  "import '../../widgets/bottom_nav_bar.dart';\nimport 'package:printing/printing.dart';\nimport '../../services/pdf_service.dart';"
);

// 2. Add loading state
content = content.replace(
  "class _MyMedicationScreenState extends State<MyMedicationScreen> {",
  "class _MyMedicationScreenState extends State<MyMedicationScreen> {\n  bool _isGeneratingPdf = false;"
);

// 3. Add PDF button
const actionRegex = /actions: \[\s*IconButton\(\s*icon: const Icon\(Icons\.person_outline\),/;
const newAction = `actions: [
          _isGeneratingPdf 
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : IconButton(
                tooltip: 'Save or share prescription',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () async {
                  if (medications.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No active medications to export.')),
                    );
                    return;
                  }
                  setState(() => _isGeneratingPdf = true);
                  try {
                    final bytes = await PdfService.generatePrescriptionPdf(
                      medications: medications,
                    );
                    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'MediHub_Prescription_$dateStr.pdf',
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to generate the prescription PDF. Please try again.')),
                    );
                  } finally {
                    setState(() => _isGeneratingPdf = false);
                  }
                },
              ),
          IconButton(
            icon: const Icon(Icons.person_outline),`;

content = content.replace(actionRegex, newAction);

fs.writeFileSync('lib/screens/medication/my_medication_screen.dart', content, 'utf-8');
console.log("Updated my_medication_screen.dart");
