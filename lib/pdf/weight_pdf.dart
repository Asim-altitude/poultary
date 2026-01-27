import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:poultary/model/weight_record.dart';
import 'package:poultary/utils/utils.dart';

import '../../data.dart';
import '../model/custom_category_data.dart';
import '../model/egg_report_item.dart';
import '../model/feed_report_item.dart';
import '../model/feedflock_report_item.dart';

Future<Uint8List> generateWeightReport(
    PdfPageFormat pageFormat, CustomData data) async
{
  final lorem = pw.LoremText();

  final products = Utils.weight_list;
  final feedbyflock = Utils.feed_flock_report_list;

  final invoice = Invoice(
    invoiceNumber: '982347',
    products: products,
    flockFeedList: feedbyflock,
    customerName: 'Abraham Swearegin',
    customerAddress: '54 rue de Rivoli\n75001 Paris, France',
    paymentInfo:
    '4509 Wiseman Street\nKnoxville, Tennessee(TN), 37929\n865-372-0425',
    tax: .15,
    baseColor: PdfColors.teal,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat);
}

class Invoice {
  Invoice({
    required this.products,
    required this.flockFeedList,
    required this.customerName,
    required this.customerAddress,
    required this.invoiceNumber,
    required this.tax,
    required this.paymentInfo,
    required this.baseColor,
    required this.accentColor,
  });

  final List<WeightRecord> products;
  final List<FeedFlock_Report_Item> flockFeedList;
  final String customerName;
  final String customerAddress;
  final String invoiceNumber;
  final double tax;
  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;

  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;

  PdfColor get _accentTextColor => baseColor.isLight ? _lightColor : _darkColor;

  double get _total =>
      products.map<double>((p) => 0).reduce((a, b) => a + b);

  int get _feedTotal => products.map<int>((e) => 0).reduce((a, b) => a + b);
  int get _flockTotal => flockFeedList.map<int>((e) => 0).reduce((a, b) => a + b);

  double get _grandTotal => _total * (1 + tax);

  num getFLockTotal() {
    num total = 0;
    for (int i=0;i<flockFeedList.length;i++){
      total = total + flockFeedList.elementAt(i).consumption!;
    }

    total = num.parse(total.toStringAsFixed(2));
    return total;
  }

  num getFeedTotal() {
    num total = 0;
    for (int i=0;i<products.length;i++){
      total = total + products.elementAt(i).averageWeight;
    }

    total = num.parse(total.toStringAsFixed(2));
    return total;
  }

  Uint8List? _logo;
  Uint8List? imageData;
  String? _bgShape;
  bool direction = true;
  Uint8List imageFromBase64String(String base64String) {
    return base64Decode(base64String);
  }
  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();

    // final ByteData imageLogo = await rootBundle.load('assets/logo.svg');
    // _logo = (imageLogo).buffer.asUint8List();
    ByteData? image = null;

    if(Utils.INVOICE_LOGO_STR =="assets/farm_icon.png" || Utils.INVOICE_LOGO_STR =="assets/farm.jpg"){
      image = await rootBundle.load('assets/farm_icon.png');
      imageData = (image)?.buffer.asUint8List();
    }
    else{
      imageData = imageFromBase64String(Utils.INVOICE_LOGO_STR);

    }

    direction = await Utils.getDirection();
    String regular = await Utils.getPdfregularFont();
    String bold = await Utils.getPdfBoldFont();
    _bgShape = await rootBundle.loadString('assets/invoice.svg');
    final font = await rootBundle.load(regular);
    final ttfFLight = pw.Font.ttf(font);
    final font1 = await rootBundle.load(bold);
    final ttfFBold = pw.Font.ttf(font1);

    // Add page to the PDF
    doc.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(
          pageFormat,
          direction? ttfFLight:ttfFBold,
          ttfFBold,ttfFLight,
        ),
        header: _buildHeader,
        build: (context) => [

          /*buildWeightSummary(),
          buildWeightTable(),*/
          pw.SizedBox(height: 10),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Flock Weight Report'.tr(),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                ' ${Utils.selectedWeightFlock!.f_name}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
              ),

              pw.SizedBox(height: 14),
              buildWeightSummary(),

              pw.SizedBox(height: 14),
              buildWeightTable(),
            ],
          ),

          pw.Container(
              margin: pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.topLeft,
                      child: pw.Directionality(
                        textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,
                        child: pw.Text(
                          'Report Generated On: '.tr(),
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 10,
                          ),
                        ),),

                    ),pw.Container(
                      margin: pw.EdgeInsets.only(left: 10),
                      alignment: pw.Alignment.topLeft,
                      child: pw.Text(
                        DateTime.now().toString(),
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ]
              )
          ),
          //_contentFooter(context),
          // pw.SizedBox(height: 20),
          // _termsAndConditions(context),
        ],
      ),
    );

    // Return the PDF file content
    return doc.save();
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Directionality(
      textDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // LOGO
            pw.Container(
              height: 70,
              alignment: pw.Alignment.center,
              child: imageData != null
                  ? pw.Image(pw.MemoryImage(imageData!))
                  : pw.PdfLogo(),
            ),
            pw.SizedBox(height: 10),

            // HEADER TITLE
            pw.Text(
              Utils.INVOICE_HEADING.tr(),
              style: pw.TextStyle(
                color: PdfColors.blue700,
                fontWeight: pw.FontWeight.bold,
                fontSize: 22,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "Weight Report".tr(),
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.normal,
                fontSize: 18,
              ),
            ),

            pw.SizedBox(height: 6),

            // DATE
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: pw.Text(
                  Utils.INVOICE_DATE.tr(),
                  style: pw.TextStyle(
                    color: PdfColors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (context.pageNumber > 1) pw.SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
  pw.Widget buildWeightSummary() {

    final initialWeight = Utils.initialWeight;
    final currentWeight = Utils.currentWeight;
    final change = Utils.changeWeight;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryTile(
            'Initial',
            '${initialWeight.toStringAsFixed(2)} ',
          ),
          _summaryTile(
            'Now',
            '${currentWeight.toStringAsFixed(2)} ',
          ),
          _summaryTile(
            'Total Change',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} ',
             valueColor: change >= 0 ? PdfColors.green : PdfColors.red,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryTile(
      String title,
      String value, {
      PdfColor? valueColor,
      }) {
    return pw.Directionality(
        textDirection:
        direction? pw.TextDirection.ltr : pw.TextDirection.rtl,
        child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.tr(),
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value + Utils.selected_unit.tr(),
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    ));
  }


  pw.Widget buildWeightTable() {
    final list = Utils.weight_list;

    return pw.Directionality(
        textDirection:
        direction? pw.TextDirection.ltr : pw.TextDirection.rtl,
        child:  pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(2), // Weight
        2: const pw.FlexColumnWidth(2), // Change
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('Date', bold: true),
            _cell('Weight', bold: true),
            _cell('Change', bold: true),
          ],
        ),

        for (int i = 0; i < list.length; i++)
          _weightRow(
            list[i],
            i == 0 ? null : list[i - 1],
          ),
      ],
    ));
  }

  pw.TableRow _weightRow(item, previousItem) {
    final current = item.averageWeight;
    final previous = previousItem?.averageWeight ?? current;
    final change = previousItem == null ? 0 : current - previous;

    return pw.TableRow(
      children: [
        _cell(Utils.getFormattedDate(item.date)),
        _cell(
          current.toStringAsFixed(2) + Utils.selected_unit.tr(),
        ),
        _cell(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}${Utils.selected_unit.tr()}',
          color:PdfColors.black
        ),
      ],
    );
  }

  pw.Widget _cell(
      String text, {
        bool bold = false,
        PdfColor? color,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text.tr(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  pw.TableRow _weightHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('Date', bold: true),
        _cell('Avg (kg)', bold: true),
      ],
    );
  }

  pw.TableRow _weightDataRow(item) {
    return pw.TableRow(
      children: [
        _cell(Utils.getFormattedDate(item.date)),
        _cell(item.averageWeight.toStringAsFixed(2)),
      ],
    );
  }



  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          height: 20,
          width: 100,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.pdf417(),
            data: 'Invoice# $invoiceNumber',
            drawText: false,
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  pw.PageTheme _buildTheme(
      PdfPageFormat pageFormat, pw.Font base, pw.Font bold, pw.Font italic) {
    return pw.PageTheme(
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

  pw.Widget _contentHeader(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            height: 70,
            child: pw.FittedBox(
              child: pw.Text(
                'TOTAL'.tr()+': ${_formatCurrency(_grandTotal)}',
                style: pw.TextStyle(
                  color: baseColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(left: 10, right: 10),
                height: 70,
                child: pw.Text(
                  'Invoice to:',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 70,
                  child: pw.RichText(
                      text: pw.TextSpan(
                          text: '$customerName\n',
                          style: pw.TextStyle(
                            color: _darkColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            const pw.TextSpan(
                              text: '\n',
                              style: pw.TextStyle(
                                fontSize: 5,
                              ),
                            ),
                            pw.TextSpan(
                              text: customerAddress,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          ])),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _contentTable2(pw.Context context, List<CustomCategoryData> categoryDataList) {
    const tableHeaders = [
      'Category Name',
      'Quantity',
      'Unit',
      'Date',
      'Item Type',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Category Name
        1: const pw.FlexColumnWidth(1), // Quantity
        2: const pw.FlexColumnWidth(1), // Unit
        3: const pw.FlexColumnWidth(2), // Date
        4: const pw.FlexColumnWidth(2), // Item Type
      },
      children: [
        // Table Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue600,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          children: tableHeaders.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header.tr(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // Data Rows with alternating colors
        for (int i = 0; i < categoryDataList.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColors.grey100, // Alternate row colors
            ),
            children: [
              _tableCell(categoryDataList[i].cName.tr(), align: pw.TextAlign.left),
              _tableCell(categoryDataList[i].quantity.toStringAsFixed(2).tr(), align: pw.TextAlign.right),
              _tableCell(categoryDataList[i].unit.tr(), align: pw.TextAlign.center),
              _tableCell(Utils.getFormattedDate(categoryDataList[i].date).tr(), align: pw.TextAlign.center),
              _tableCell(categoryDataList[i].itemType.tr(), align: pw.TextAlign.center),
            ],
          ),
      ],
    );
  }

// Helper function to format table cells
  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 11,
        ),
        textAlign: align,
      ),
    );
  }


  pw.Widget _contentFooter(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Thank you for your business',
                style: pw.TextStyle(
                  color: _darkColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
                child: pw.Text(
                  'Payment Info:',
                  style: pw.TextStyle(
                    color: baseColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                paymentInfo,
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 5,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: const pw.TextStyle(
              fontSize: 10,
              color: _darkColor,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sub Total:'),
                    pw.Text(_formatCurrency(_total)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:'),
                    pw.Text('${(tax * 100).toStringAsFixed(1)}%'),
                  ],
                ),
                pw.Divider(color: accentColor),
                pw.DefaultTextStyle(
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total:'),
                      pw.Text(_formatCurrency(_grandTotal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _termsAndConditions(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: accentColor)),
                ),
                padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                child: pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: baseColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                pw.LoremText().paragraph(40),
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(
                  fontSize: 6,
                  lineSpacing: 2,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.SizedBox(),
        ),
      ],
    );
  }

  pw.Widget _contentTable(pw.Context context) {
    const tableHeaders = [
      'Feed Name',
      'Consumption Quantity (Kg)',
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      headerHeight: 30,
      cellHeight: 35,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,  // Feed Name
        1: pw.Alignment.centerRight, // Quantity
      },
      headerDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      tableDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      headerStyle: pw.TextStyle(
        color: _baseTextColor,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        color: _darkColor,
        fontSize: 10,
      ),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: accentColor,
            width: 0.5,
          ),
        ),
      ),
      headers: tableHeaders.map((header) => header.tr()).toList(),
      data: products.map((feed) => [
        feed.averageWeight,
        "${feed.averageWeight.toString()}".tr(), // Formatting quantity
      ]).toList(),
    );
  }

  pw.Widget _contentTable1(pw.Context context) {
    const tableHeaders = [
      'Flock Name',
      'Consumption Quantity (Kg)',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Flock Name
        1: const pw.FlexColumnWidth(1), // Quantity
      },
      children: [
        // Table Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.blue600,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          children: tableHeaders.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header.tr(),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // Data Rows with alternating colors
        for (int i = 0; i < Utils.flockQuantity!.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColors.grey100, // Alternate row colors
            ),
            children: [
              _tableCell2(Utils.flockQuantity![i].flockName.tr(), align: pw.TextAlign.left),
              _tableCell2(Utils.flockQuantity![i].totalQuantity.toString(), align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

// Helper function to format table cells
  pw.Widget _tableCell2(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 11,
        ),
        textAlign: align,
      ),
    );
  }

}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}
