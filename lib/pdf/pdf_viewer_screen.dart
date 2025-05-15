import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/utils.dart';

class ProductionReportViewer extends StatelessWidget {
  final Uint8List pdfData;
  const ProductionReportViewer({super.key, required this.pdfData});

  Future<void> _saveAsFile(
      BuildContext context,
      LayoutCallback build,
      PdfPageFormat pageFormat,
      ) async {
    final bytes = await build(pageFormat);

    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocPath = appDocDir.path;
    final file = File('$appDocPath/document.pdf');
    print('Save as file ${file.path} ...');
    await file.writeAsBytes(bytes);
    // await OpenFile.open(file.path);
    // Share.shareFiles(['${file.path}'], text: 'Great picture');
    await Printing.layoutPdf(onLayout: (_) => bytes);

  }

  Future<void> _shareAsFile(
      BuildContext context,
      LayoutCallback build,
      PdfPageFormat pageFormat,
      ) async {
    final bytes = await build(pageFormat);

    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocPath = appDocDir.path;
    final file = File('$appDocPath/document.pdf');
    print('Save as file ${file.path} ...');
    await file.writeAsBytes(bytes);
    // await OpenFile.open(file.path);
    Share.shareXFiles([XFile(file.path)], text: 'Poultry Pdf');
    // await Printing.layoutPdf(onLayout: (_) => bytes);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Production Report", style: TextStyle(fontSize: 18), ),
          foregroundColor: Colors.white,
          backgroundColor: Utils.getThemeColorBlue(),
          actions: [

            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save PDF',
              onPressed: () async {
                _saveAsFile(context, (format) => pdfData, PdfPageFormat.a4);
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
              onPressed: () async {
                _shareAsFile(context, (format) => pdfData, PdfPageFormat.a4);

              },
            ),
          ]
    ),
      body:  Container(
        height: Utils.HEIGHT_SCREEN-100,
        child: PdfPreview(
          maxPageWidth: 700,
          build: (format) => pdfData,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canDebug: false,
          canChangePageFormat: false,
          onPrinted: _showPrintedToast,
          onShared: _showSharedToast,
          // actions: actions,
        ),),
    );
  }

  void _showPrintedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document printed successfully'),
      ),
    );
  }

  void _showSharedToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document shared successfully'),
      ),
    );
  }
}
