import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultary/utils/utils.dart';
import '../../data.dart';
import '../financial_report_screen.dart';
import '../model/finance_report_item.dart';
import '../model/finance_summary_flock.dart';

Future<Uint8List> generateFinancialReport(
    PdfPageFormat pageFormat, CustomData data) async {
  final lorem = pw.LoremText();

  final products = Utils.finance_report_list;

  final invoice = Invoice(
    invoiceNumber: '982347',
    products: products,
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
    required this.customerName,
    required this.customerAddress,
    required this.invoiceNumber,
    required this.tax,
    required this.paymentInfo,
    required this.baseColor,
    required this.accentColor,
  });

  final List<Finance_Report_Item> products;
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

  double get _grandTotal => _total * (1 + tax);

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
      imageData = (image).buffer.asUint8List();
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
         // _contentHeader(context),
          _buildSummary(context),
          pw.SizedBox(height: 10),
          pw.Text(
            "By Flock".tr(),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),

          pw.SizedBox(height: 5),
          _contentTable(context,Utils.flockfinanceList!),
          pw.SizedBox(height: 20),

          _financialItemTable(context, Utils.incomeItems!, "Top Income Sources".tr()),
          pw.SizedBox(height: 10),
          _financialItemTable(context, Utils.expenseItems!, "Top Expenses".tr()),
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
          pw.SizedBox(height: 10),


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
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
          ),
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

            // REPORT TITLE
            pw.Text(
              'Financial Report'.tr(),
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
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
                  Utils.INVOICE_DATE,
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
  pw.Widget _buildSummary(pw.Context context) {
    return pw.Directionality(
      textDirection: direction ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      child: pw.Container(
        margin: pw.EdgeInsets.only(top: 15),
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Summary Title
            pw.Container(
              margin: pw.EdgeInsets.only(bottom: 10),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "SUMMARY".tr(),
                style: pw.TextStyle(
                  color: PdfColors.blue,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),

            pw.SizedBox(height: 5),

            // Financial Summary Box
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                children: [
                  _buildSummaryRow("GROSS_INCOME".tr(), Utils.currency + Utils.TOTAL_INCOME, PdfColors.green),
                  _buildSummaryRow("TOTAL_EXPENSE".tr(), Utils.currency + Utils.TOTAL_EXPENSE, PdfColors.red),
                  pw.Divider(color: PdfColors.grey, thickness: 0.8), // Divider line
                  _buildSummaryRow(
                    "NET_INCOME".tr(),
                    Utils.currency + Utils.NET_INCOME,
                    double.parse(Utils.NET_INCOME) < 0 ? PdfColors.red : PdfColors.black,
                    isBold: true,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper Function for Summary Rows
  pw.Widget _buildSummaryRow(String title, String value, PdfColor color, {bool isBold = false, double fontSize = 16}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title + ": ",
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
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
                'Total: ${_formatCurrency(_grandTotal)}',
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

  pw.Widget _contentTable(pw.Context context, List<FlockIncomeExpense> flockData) {
    const tableHeaders = [
      'Flock Name',
      'Income',
      'Expense',
      'NET_INCOME',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), // Light border for all cells
      columnWidths: {
        0: pw.FlexColumnWidth(3), // Flock Name
        1: pw.FlexColumnWidth(2), // Total Income
        2: pw.FlexColumnWidth(2), // Total Expense
        3: pw.FlexColumnWidth(2), // Net Profit
      },
      children: [
        // 🔹 Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue),
          children: tableHeaders.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

        // 🔹 Table Data Rows
        ...flockData.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final flock = entry.value;
          final rowColor = rowIndex.isEven ? PdfColors.white : PdfColors.grey100; // Alternating row colors

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _tableCell(flock.fName, align: pw.TextAlign.left),
              _tableCell('${flock.totalIncome.toStringAsFixed(2)}', align: pw.TextAlign.right),
              _tableCell('${flock.totalExpense.toStringAsFixed(2)}', align: pw.TextAlign.right),
              _tableCell('${(flock.totalIncome - flock.totalExpense).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

// 📌 Helper function for table cell styling
  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text.tr(),
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 11,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _financialItemTable(pw.Context context, List<FinancialItem> financialData, String title) {
    const tableHeaders = [
      'Item Name',
      'TOTAL',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 🔹 Table Title
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        ),
        pw.SizedBox(height: 6),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), // Light border for all cells
          columnWidths: {
            0: pw.FlexColumnWidth(3), // Item Name
            1: pw.FlexColumnWidth(2), // Amount
          },
          children: [
            // 🔹 Table Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue),
              children: tableHeaders.map((header) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

            // 🔹 Table Data Rows
            ...financialData.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final item = entry.value;
              final rowColor = rowIndex.isEven ? PdfColors.white : PdfColors.grey100; // Alternating row colors

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rowColor),
                children: [
                  _ftableCell(item.name, align: pw.TextAlign.left),
                  _ftableCell('${item.amount.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

// 📌 Helper function for table cell styling
  pw.Widget _ftableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text.tr(),
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 11,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

String _formatDate(DateTime date) {
  final format = DateFormat.yMMMd('en_US');
  return format.format(date);
}

class Product {
  const Product(
      this.sku,
      this.productName,
      this.price,
      this.quantity,
      );

  final String sku;
  final String productName;
  final double price;
  final int quantity;
  double get total => price * quantity;

  String getIndex(int index) {
    switch (index) {
      case 0:
        return sku;
      case 1:
        return productName;
      case 2:
        return _formatCurrency(price);
      case 3:
        return quantity.toString();
      case 4:
        return _formatCurrency(total);
    }
    return '';
  }
}