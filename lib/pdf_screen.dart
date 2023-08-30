import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultary/utils/utils.dart';

import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

import 'data.dart';
import 'example.dart';


class PDFScreen extends StatefulWidget {
  const PDFScreen({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  State<PDFScreen> createState() => _PDFScreen();
}

class _PDFScreen extends State<PDFScreen> {
  int _counter = 0;
  int _tab = 0;
  var _data = const CustomData();





  @override
  void initState() {
    super.initState();
  }


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

  @override
  Widget build(BuildContext context) {

    final actions = <PdfPreviewAction>[
      PdfPreviewAction(
        icon: const Icon(Icons.search),
        onPressed: _saveAsFile,
      )
    ];
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(131, 57,126, 1),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('PDF',
          style: new TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body:
      Center(
        child:Container(
          width: Utils.WIDTH_SCREEN,
          height: Utils.HEIGHT_SCREEN,
          color: Color.fromRGBO(199, 199,204, 1),
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child:
          SingleChildScrollView(
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[



                Container(
                  height: Utils.HEIGHT_SCREEN-100,
                child:PdfPreview(
                  maxPageWidth: 700,
                  build: (format) => examples[_tab].builder(format, _data),
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  canChangePageFormat: false,
                  onPrinted: _showPrintedToast,
                  onShared: _showSharedToast,
                  // actions: actions,
                ),),
              ],
            ),
          ),),),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
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
  void _showToast6Digits(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter 6 digit code"),
      ),
    );
  }
  void _showToastCorrectCode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter a correct code."),
      ),
    );
  }

}
