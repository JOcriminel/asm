import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import '../../../commands/domain/models/command.dart';

class PdfGenerationHelper {
  static String numberToFrenchWords(double amount) {
    final amountStr = amount.toStringAsFixed(3);
    final parts = amountStr.split('.');
    final dinars = int.parse(parts[0]);
    final millimesStr = parts[1];
    final millimes = int.parse(millimesStr);

    final dinarsWord = _convertIntegerToFrenchWords(dinars).toUpperCase();

    String result = '$dinarsWord Dinar (s) Tunisien';
    if (millimes > 0) {
      result += ' $millimesStr Millime(s)';
    }
    return result;
  }

  static String _convertIntegerToFrenchWords(int number) {
    if (number == 0) return 'zéro';
    if (number < 0) return 'moins ${_convertIntegerToFrenchWords(-number)}';

    final units = [
      '', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf',
      'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept',
      'dix-huit', 'dix-neuf'
    ];

    final tens = [
      '', 'dix', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante',
      'soixante-dix', 'quatre-vingt', 'quatre-vingt-dix'
    ];

    if (number < 20) return units[number];

    if (number < 100) {
      final t = number ~/ 10;
      final r = number % 10;
      if (number == 80) return 'quatre-vingts';
      if (r == 0) return tens[t];
      if (r == 1) {
        if (t == 7) return 'soixante et onze';
        if (t == 8) return 'quatre-vingt-un';
        if (t == 9) return 'quatre-vingt-onze';
        return '${tens[t]} et un';
      }
      if (t == 7) return 'soixante-${units[10 + r]}';
      if (t == 9) return 'quatre-vingt-${units[10 + r]}';
      return '${tens[t]}-${units[r]}';
    }

    if (number < 1000) {
      final c = number ~/ 100;
      final r = number % 100;
      final pluralCent = (c > 1 && r == 0) ? 'cents' : 'cent';
      final prefix = c == 1 ? 'cent' : '${units[c]} $pluralCent';
      if (r == 0) return prefix;
      return '$prefix ${_convertIntegerToFrenchWords(r)}';
    }

    if (number < 1000000) {
      final m = number ~/ 1000;
      final r = number % 1000;
      final millePart = m == 1 ? 'mille' : '${_convertIntegerToFrenchWords(m)} mille';
      if (r == 0) return millePart;
      return '$millePart ${_convertIntegerToFrenchWords(r)}';
    }

    if (number < 1000000000) {
      final mill = number ~/ 1000000;
      final r = number % 1000000;
      final millPart = mill == 1 ? 'un million' : '${_convertIntegerToFrenchWords(mill)} millions';
      final formattedMillPart = (mill > 1 && r == 0) ? millPart : (mill == 1 ? 'un million' : '${_convertIntegerToFrenchWords(mill)} million');
      if (r == 0) return formattedMillPart;
      return '$formattedMillPart ${_convertIntegerToFrenchWords(r)}';
    }

    return number.toString();
  }

  static Future<void> printCommand(Command command) async {
    final pdf = pw.Document();
    
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo not found
    }

    final paddedCode = command.documentCode.padLeft(12, '0');
    final formattedDate = "${command.date.day.toString().padLeft(2, '0')}/${command.date.month.toString().padLeft(2, '0')}/${command.date.year}";

    final netHT = command.totalHT;
    final tva = command.vat;
    final ttc = command.totalTTC;
    final stamp = double.parse((ttc - netHT - tva).toStringAsFixed(3)).clamp(0.0, double.infinity);

    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();

    final tableWidths = {
      0: const pw.FixedColumnWidth(70),
      1: const pw.FixedColumnWidth(0.8),
      2: const pw.FlexColumnWidth(),
      3: const pw.FixedColumnWidth(0.8),
      4: const pw.FixedColumnWidth(30),
      5: const pw.FixedColumnWidth(0.8),
      6: const pw.FixedColumnWidth(55),
      7: const pw.FixedColumnWidth(0.8),
      8: const pw.FixedColumnWidth(55),
      9: const pw.FixedColumnWidth(0.8),
      10: const pw.FixedColumnWidth(60),
      11: const pw.FixedColumnWidth(0.8),
      12: const pw.FixedColumnWidth(40),
    };

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: roboto,
          bold: robotoBold,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            height: 45,
                            child: pw.Image(logoImage),
                          )
                        else
                          pw.Text(
                            'AW-Dux',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        pw.SizedBox(height: 15),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              barcode: Barcode.code128(),
                              data: paddedCode,
                              width: 120,
                              height: 35,
                              drawText: true,
                              textStyle: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.SizedBox(width: 30),
                            pw.BarcodeWidget(
                              barcode: Barcode.qrCode(),
                              data: paddedCode,
                              width: 40,
                              height: 40,
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 15),
                        pw.Text(
                          'Bon de Commande Client N° ${command.documentCode}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'SFAX le $formattedDate',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Affaire suivie par: / +216',
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: robotoItalic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                            children: [
                              pw.TextSpan(
                                text: "A l'attention de ",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(text: command.preparedBy ?? 'client'),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                            children: [
                              pw.TextSpan(
                                text: "Client ",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(text: command.tier),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          command.clientRaisonSociale ?? command.customerName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                        ),
                        pw.Text(
                          command.clientAddress ?? command.deliveryAddress,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 5),
                        pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                            children: [
                              pw.TextSpan(
                                text: "ID Fiscale : ",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(text: command.clientTaxNumber ?? 'N/A'),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                            children: [
                              pw.TextSpan(
                                text: "Téléphone : ",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(text: command.clientPhone ?? (command.phone.isNotEmpty ? command.phone : 'N/A')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),
              // Table Container (with rounded corners and vertical divider lines)
              pw.Container(
                height: 320,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Stack(
                  children: [
                    // Underlay: Vertical lines extending all the way down
                    pw.Positioned.fill(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Container(width: 70),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Expanded(child: pw.Container()),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Container(width: 30),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Container(width: 55),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Container(width: 55),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Container(width: 60),
                          pw.Container(width: 0.8, color: PdfColors.black),
                          pw.Container(width: 40),
                        ],
                      ),
                    ),
                    // Foreground: The actual table contents
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        // Headers row
                        pw.Table(
                          columnWidths: tableWidths,
                          children: [
                            pw.TableRow(
                              children: [
                                _buildHeaderCell('REF', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('DESIGNATION', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('QTE', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('PU HT', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('PU Net HT', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('Mnt Net HT', font: robotoBold),
                                pw.Container(),
                                _buildHeaderCell('TVA(%)', font: robotoBold),
                              ],
                            ),
                          ],
                        ),
                        pw.Container(height: 0.8, color: PdfColors.black),
                        // Table content
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Table(
                            columnWidths: tableWidths,
                            children: command.articles.map((item) {
                              final puNet = (item.netHT != null && item.quantity > 0) ? (item.netHT! / item.quantity) : item.unitPrice;
                              return pw.TableRow(
                                children: [
                                  _buildTableCell(item.code, font: roboto, align: pw.Alignment.centerLeft),
                                  pw.Container(),
                                  _buildTableCell(item.name, font: roboto, align: pw.Alignment.centerLeft),
                                  pw.Container(),
                                  _buildTableCell('${item.quantity}', font: roboto, align: pw.Alignment.center),
                                  pw.Container(),
                                  _buildTableCell(item.unitPrice.toStringAsFixed(3), font: roboto, align: pw.Alignment.centerRight),
                                  pw.Container(),
                                  _buildTableCell(puNet.toStringAsFixed(3), font: roboto, align: pw.Alignment.centerRight),
                                  pw.Container(),
                                  _buildTableCell((item.netHT ?? item.total).toStringAsFixed(3), font: roboto, align: pw.Alignment.centerRight),
                                  pw.Container(),
                                  _buildTableCell((item.tvaPercent ?? 19.0).toStringAsFixed(2), font: roboto, align: pw.Alignment.centerRight),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Bottom Section: Capsule on the left, Totals Table on the right
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left Column: Capsule & Cachet et Signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
                        ),
                        child: pw.Text(
                          numberToFrenchWords(ttc),
                          style: pw.TextStyle(font: robotoBold, fontSize: 8),
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Cachet et Signature',
                        style: pw.TextStyle(font: robotoBold, fontSize: 8),
                      ),
                    ],
                  ),
                  // Right Column: Totals Table & Signature Client
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 170,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Table(
                          columnWidths: {
                            0: const pw.FixedColumnWidth(95),
                            1: const pw.FixedColumnWidth(75),
                          },
                          border: const pw.TableBorder(
                            horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                            verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                          ),
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text('TOTAL NET HT', style: pw.TextStyle(font: robotoBold, fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text(netHT.toStringAsFixed(3), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: roboto, fontSize: 8)),
                                ),
                              ],
                            ),
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text('TOTAL TVA', style: pw.TextStyle(font: robotoBold, fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text(tva.toStringAsFixed(3), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: roboto, fontSize: 8)),
                                ),
                              ],
                            ),
                            if (stamp > 0)
                              pw.TableRow(
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: pw.Text('TT', style: pw.TextStyle(font: robotoBold, fontSize: 8)),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: pw.Text(stamp.toStringAsFixed(3), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: roboto, fontSize: 8)),
                                  ),
                                ],
                              ),
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text('TOTAL TTC', style: pw.TextStyle(font: robotoBold, fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: pw.Text(ttc.toStringAsFixed(3), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: robotoBold, fontSize: 8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Signature Client',
                        style: pw.TextStyle(font: robotoBold, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'AW-Dux Portal - Généré automatiquement',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'bon_de_commande_${command.documentCode}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text, {required pw.Font font}) {
    return pw.Container(
      height: 20,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {required pw.Font font, pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }
}
