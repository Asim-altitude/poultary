import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../data.dart';
import 'birds_pdf.dart';
import 'eggs_pdf.dart';
import 'feed_pdf.dart';
import 'finance_pdf.dart';


const financeexamples = <Example>[
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
  Example('FINANCE_REPORT', 'finance_pdf.dart', generateFinancialReport),
];

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, CustomData data);

class Example {
  const Example(this.name, this.file, this.builder, [this.needsData = false]);

  final String name;

  final String file;

  final LayoutCallbackWithData builder;

  final bool needsData;
}
