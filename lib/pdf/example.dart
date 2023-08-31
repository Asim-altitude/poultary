import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../data.dart';
import 'birds_pdf.dart';


const examples = <Example>[
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
  Example('INVOICE', 'birds_pdf.dart', generateInvoice),
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
