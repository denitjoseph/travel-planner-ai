import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPrint(
    Map<String, dynamic> tripData,
    String destination,
  ) async {
    final pdf = pw.Document();

    // Extract Data
    List itinerary = tripData['itinerary'] ?? [];
    String summary = tripData['summary'] ?? "No summary available.";
    Map budget = tripData['budget_breakdown'] ?? {};
    List hotels = tripData['hotel_suggestions'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TravelAI Premium Plan",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    destination,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // --- SUMMARY SECTION ---
            pw.Text(
              "Trip Summary",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              summary,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            ),
            pw.SizedBox(height: 30),

            // --- BUDGET SECTION ---
            if (budget.isNotEmpty) ...[
              pw.Text(
                "Estimated Budget",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                headers: ['Category', 'Estimated Amount'],
                data: [
                  ['Flights', budget['flights'] ?? 'N/A'],
                  ['Hotels', budget['hotels'] ?? 'N/A'],
                  ['Food', budget['food'] ?? 'N/A'],
                  ['Activities', budget['activities'] ?? 'N/A'],
                  ['Total Estimated', budget['total_estimated'] ?? 'N/A'],
                ],
              ),
              pw.SizedBox(height: 30),
            ],

            // --- HOTELS SECTION ---
            if (hotels.isNotEmpty) ...[
              pw.Text(
                "Recommended Stays",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 10),
              ...hotels
                  .map(
                    (h) => pw.Bullet(
                      text:
                          "${h['name']} (${h['price_per_night']}/night): ${h['description']}",
                      style: const pw.TextStyle(fontSize: 11),
                      margin: const pw.EdgeInsets.only(bottom: 5),
                    ),
                  )
                  .toList(),
              pw.SizedBox(height: 30),
            ],

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),
            pw.Text(
              "Daily Adventure Itinerary",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 15),

            ...itinerary.map((day) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            "Day ${day['day']}",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          day['title'] ?? "",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      day['description'] ?? "",
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                    if (day['food_recommendation'] != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Text(
                          "🍴 Must Try: ${day['food_recommendation']}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.green800,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Divider(
                      color: PdfColors.grey100,
                      borderStyle: pw.BorderStyle.dashed,
                    ),
                  ],
                ),
              );
            }).toList(),

            // --- FOOTER ---
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Generated by TravelAI - Your Personal Journey Companion",
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
