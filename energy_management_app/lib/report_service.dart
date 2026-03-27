import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> generatePDFReport({
  required String company,
  required double consumption,
  required double generation,
  required double balance,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Energy Management Report",
                style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text("Company: $company"),
            pw.Text("Consumption: $consumption"),
            pw.Text("Generation: $generation"),
            pw.Text("Balance: $balance"),
          ],
        );
      },
    ),
  );

  final directory = await getApplicationDocumentsDirectory();

  final file = File("${directory.path}/energy_report.pdf");

  await file.writeAsBytes(await pdf.save());
}
