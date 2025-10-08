// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data.dart';
import '../production_report.dart';
import '../utils/utils.dart';

bool direction = true;
Uint8List? _logo;
Uint8List? imageData;
String? _bgShape;

Future<Uint8List> generateProductionReportPdf({
  required String flockName,
  required int totalBirdsAdded,
  required int totalBirdsReduced,
  required int mortality,
  required int culling,
  required int totalEggsCollected,
  required int totalEggsReduced,
  required num grossIncome,
  required num totalExpense,
  required num profit,
  required num totalFeedUsed,
  required Map<String, Map<String, dynamic>> dailyBreakdown,
  required List<MonthlyBreakdownData> monthlyBreakdown,
}) async
{

  final pdf = pw.Document();

  direction = await Utils.getDirection();
  String regular = await Utils.getPdfregularFont();
  String bold = await Utils.getPdfBoldFont();
  final font = await rootBundle.load(regular);
  final ttfLight = pw.Font.ttf(font);
  final fontBold = await rootBundle.load(bold);
  final ttfBold = pw.Font.ttf(fontBold);

  if (Utils.INVOICE_LOGO_STR == "assets/farm_icon.png" || Utils.INVOICE_LOGO_STR == "assets/farm.jpg") {
    final image = await rootBundle.load('assets/farm_icon.png');
    imageData = image.buffer.asUint8List();
  } else {
    imageData = base64Decode(Utils.INVOICE_LOGO_STR);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => [

        _buildHeader(context,ttfBold),
         pw.SizedBox(height: 20),

        _buildSectionTitle('HEADING_DASHBOARD', ttfBold),
        _buildKeyValueTable({
          'Income'.tr(): Utils.currency +'$grossIncome',
          'Expense': Utils.currency +'$totalExpense',
          'NET_PROFIT': Utils.currency +'$profit',
        }, ttfBold, direction),

        pw.SizedBox(height: 12),
        _buildSectionTitle('BIRDS_SUMMARY', ttfBold),
        _buildKeyValueTable({
          'Birds Added': '$totalBirdsAdded',
          'Birds Reduced': '$totalBirdsReduced',
          'MORTALITY': '$mortality',
          'CULLING': '$culling',
        }, ttfBold,direction),

        pw.SizedBox(height: 12),
        _buildSectionTitle('EGGS_SUMMARY', ttfBold),
        _buildKeyValueTable({
          'eggs collected': '$totalEggsCollected',
          'TOTAL_USED': '$totalEggsReduced',
        }, ttfBold,direction),

        pw.SizedBox(height: 12),
        _buildSectionTitle('FEED'.tr()+" "+"SUMMARY".tr(), ttfBold),
        _buildKeyValueTable({
          'Total Consumption: ': '$totalFeedUsed '+Utils.selected_unit.tr(),
        }, ttfBold,direction),

        pw.SizedBox(height: 20),
        _buildSectionTitle('Daily Breakdown', ttfBold),
        _buildDailyBreakdownTable(dailyBreakdown, ttfBold),

        pw.SizedBox(height: 20),
        _buildSectionTitle('Monthly Breakdown', ttfBold),
        _buildMonthlyBreakdownTable(monthlyBreakdown, ttfBold),
      ],
    ),
  );
  return pdf.save();
 // await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

pw.Widget _buildHeader(pw.Context context, pw.Font font) {
  return pw.Center(
    child: pw.Directionality(
      textDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (imageData != null)
              pw.Image(pw.MemoryImage(imageData!), height: 60)
            else
              pw.PdfLogo(),

            pw.SizedBox(height: 10),

            pw.Text(
              Utils.INVOICE_HEADING.tr(),
              style: pw.TextStyle(
                color: PdfColors.blue800,
                fontSize: 22,
                font: font
              ),
            ),
            pw.SizedBox(height: 4),

            pw.Text(
              'Production Report'.tr(),
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                font: font,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text(
                Utils.INVOICE_DATE,
                style: pw.TextStyle(fontSize: 14, color: PdfColors.black),
              ),
            ),
          ],
        ),
      ),
    )
  );
}

pw.Widget _buildSectionTitle(String title, pw.Font font) => pw.Padding(
  padding:  pw.EdgeInsets.symmetric(vertical: 4),
  child: pw.Directionality(
    textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,
    child: pw.Text(
    title.tr(),
    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: font, color: PdfColors.blue),
  ),),
);
pw.PageTheme _buildTheme(
    PdfPageFormat pageFormat, pw.Font base, pw.Font bold, pw.Font italic) {
  return pw.PageTheme(
    textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,
    pageFormat: pageFormat,
    theme: pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: italic,
    ),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.SvgImage(svg: _bgShape!),
    ),
  );
}
pw.Widget _buildKeyValueTable(Map<String, String> data, pw.Font font, bool direction) {
  return pw.Directionality(
    textDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
    child: pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: data.entries.map((e) {
          return pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Directionality(
                      textDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
                      child: pw.Text(
                        tr(e.key),
                        style: pw.TextStyle(font: font),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Text(
                      e.value,
                      style: pw.TextStyle(font: font),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );

}

pw.Widget _buildDailyBreakdownTable(Map<String, Map<String, dynamic>> data, pw.Font font) {
  final headers = [
    'DATE'.tr(), 'Birds Added'.tr(), 'Birds Reduced'.tr(), 'MORTALITY'.tr(), 'CULLING'.tr(), 'Eggs'.tr(), 'Feed'.tr()+" "+Utils.selected_unit.tr(), 'Income'.tr(), 'Expense'.tr()
  ];

  final rows = data.entries.map((e) {
    final d = e.value;
    return [
      e.key,
      d['birdsAdded'].toString(),
      d['birdsReduced'].toString(),
      d['mortality'].toString(),
      d['culling'].toString(),
      d['eggs'].toString(),
      d['feed'].toStringAsFixed(2),
      Utils.currency+'${(d['income'] as num).toStringAsFixed(2)}',
      Utils.currency+'${(d['expense'] as num).toStringAsFixed(2)}'
    ];
  }).toList();

  return pw.Directionality(
    textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,

    child: pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
        cellStyle: pw.TextStyle(font: font, fontSize: 9),
        cellAlignment: pw.Alignment.center,
        border: pw.TableBorder.symmetric(inside: pw.BorderSide.none, outside: pw.BorderSide.none),
        rowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
        oddRowDecoration: pw.BoxDecoration(color: PdfColors.white),
      ),
    ),
  );
}

pw.Widget _buildMonthlyBreakdownTable(List<MonthlyBreakdownData> list, pw.Font font) {
  final headers = [
    'Month'.tr(), 'Birds Added'.tr(), 'Birds Reduced'.tr(), 'MORTALITY'.tr(), 'CULLING'.tr(), 'Eggs'.tr(), 'Feed'.tr(), 'Income'.tr(), 'Expense'.tr()
  ];

  final rows = list.map((e) => [
    e.month,
    e.birdsAdded.toString(),
    e.birdsReduced.toString(),
    e.mortality.toString(),
    e.culling.toString(),
    e.totalEggs.toString(),
    e.totalFeedKg.toStringAsFixed(2),
    Utils.currency+'${e.income.toStringAsFixed(2)}',
    Utils.currency+'${e.expense.toStringAsFixed(2)}',
  ]).toList();

  return pw.Directionality(
    textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,

    child: pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
        cellStyle: pw.TextStyle(font: font, fontSize: 9),
        cellAlignment: pw.Alignment.center,
        border: pw.TableBorder.symmetric(inside: pw.BorderSide.none, outside: pw.BorderSide.none),
        rowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
        oddRowDecoration: pw.BoxDecoration(color: PdfColors.white),
      ),
    ),
  );

}
