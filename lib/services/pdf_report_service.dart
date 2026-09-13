/// PDF Rapor Servisi — doktor viziti için 3 aylık INR & doz özeti.
/// pubspec:
///   pdf: ^3.11.0
///   printing: ^5.13.0   (paylaşma/yazdırma için, opsiyonel)
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../repositories/repositories.dart';

class PdfReportService {
  final InrRepository _inrRepo;

  PdfReportService(this._inrRepo);

  String _status(Loc loc, InrEntry e, PatientProfile p) => inrZoneLabel(
        loc,
        e.zoneWith(criticalLow: p.criticalLow, criticalHigh: p.criticalHigh),
      );

  /// Son [months] ayın raporunu [loc] dilinde üretir. Dönen byte'lar
  /// `Printing.sharePdf(bytes: ...)` ile tek tuşla paylaşılabilir.
  ///
  /// Rapor doktora gidiyor: tarih ve sayı biçimleri de hastanın bölgesine
  /// göre yazılır, aksi hâlde "05.03" hangi ay olduğu belirsiz kalırdı.
  Future<Uint8List> buildReport(
    Loc loc,
    PatientProfile profile, {
    int months = 3,
  }) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - months, now.day);
    final entries = await _inrRepo.getEntries(from: from, to: now);

    final inRange =
        entries.where((e) => profile.targetRange.contains(e.inrValue)).length;
    final pct =
        entries.isEmpty ? 0 : (100 * inRange / entries.length).round();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(loc.l10n.pdfTitle,
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                loc.l10n.pdfHeaderLine(
                  profile.name,
                  loc.formats.inr(profile.targetRange.lower),
                  loc.formats.inr(profile.targetRange.upper),
                  loc.formats.date(from),
                  loc.formats.date(now),
                ),
                style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Sayfa ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (ctx) => [
          pw.Paragraph(
            text: loc.l10n.pdfSummaryLine(entries.length, '$pct'),
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              loc.l10n.pdfColumnDate,
              loc.l10n.pdfColumnInr,
              loc.l10n.pdfColumnDose,
              loc.l10n.pdfColumnStatus,
              loc.l10n.pdfColumnNote,
            ],
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            // Kritik satırları görsel olarak vurgula
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey100),
            data: [
              for (final e in entries.reversed)
                [
                  loc.formats.date(e.date),
                  loc.formats.inr(e.inrValue),
                  loc.formats.decimal(e.doseMg, maxFractionDigits: 1),
                  _status(loc, e, profile),
                  e.note ?? '',
                ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            loc.l10n.pdfDisclaimer,
            style: pw.TextStyle(
                fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    return doc.save();
  }
}

// Kullanım (tek tuş):
//   final bytes = await pdfReportService.buildReport(profile);
//   await Printing.sharePdf(bytes: bytes, filename: 'inr_raporu.pdf');
