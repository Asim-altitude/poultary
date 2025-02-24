import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultary/model/custom_category.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'database/databse_helper.dart';
import 'model/custom_category_data.dart';
import 'model/flock.dart';

class CategoryChartScreen extends StatefulWidget {
  CustomCategory? customCategory;
  CategoryChartScreen({Key? key, required this.customCategory}) : super(key: key);

  @override
  _CategoryChartScreenState createState() => _CategoryChartScreenState();
}

class _CategoryChartScreenState extends State<CategoryChartScreen> {
  List<CustomCategoryData> records = [];
  double totalQuantity = 0.0;

  String sortSelected = "DESC";
  int? selectedFlock = -1;
  String? selectedType;

  double widthScreen = 0;
  double heightScreen = 0;

  int _reports_filter = 2;

  void getFilters() async {
    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }


  @override
  void initState() {
    super.initState();
    selectedType = widget.customCategory!.cat_type;
    getList();
    getFilters();
  }


  List<FlockQuantity> flockQuantityMap = [];
  Future<void> getCategoryDataList() async {
    List<CustomCategoryData> data = await DatabaseHelper.getCustomCategoriesData(selectedFlock, str_date, end_date, selectedType, sortSelected);

    flockQuantityMap = getFlockQuantities(data);
    Utils.flockQuantity = flockQuantityMap;
    Utils.categoryDataList = data;
    setState(() {
      records = data;
      totalQuantity = data.fold(0.0, (sum, item) => sum + item.quantity);
    });
  }

  Uint8List? imageData;
  String? _bgShape;
  bool direction = true;
  Uint8List imageFromBase64String(String base64String) {
    return base64Decode(base64String);
  }

  Future<void> exportCSV() async {
    List<List<dynamic>> csvData = [
      ["Date", "Category Name", "Quantity", "Unit"],
      ...records.map((data) => [data.date, data.cName, data.quantity, data.unit])
    ];
    String csv = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/category_report.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await Printing.sharePdf(bytes: utf8.encode(csv), filename: "category_report.csv");
  }


  Future<void> exportPDF(BuildContext context) async {
    Utils.setupInvoiceInitials(widget.customCategory!.name.tr()+" "+"Report".tr(), pdf_formatted_date_filter);
    Utils.INVOICE_SUB_HEADING = widget.customCategory!.name.tr()+" "+"Report".tr();
    Utils.TOTAL_CONSUMPTION = totalQuantity.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  PDFScreen(item: 5,)),
    );

  }
  
  
  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      height: 175,
      child: pw.Column(
        children: [
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(bottom: 8, left: 30),
                  height: 50,
                  child: imageData != null ? pw.Image(pw.MemoryImage(imageData!), ) : pw.PdfLogo(),
                ),
                // pw.Container(
                //   color: baseColor,
                //   padding: pw.EdgeInsets.only(top: 3),
                // ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Container(
                  height: 30,
                  padding: const pw.EdgeInsets.only(left: 20),
                  alignment: pw.Alignment.center,
                  child: pw.Directionality(
                    textDirection: direction? pw.TextDirection.ltr : pw.TextDirection.rtl,
                    child: pw.Text(
                      Utils.INVOICE_HEADING.tr(),
                      style: pw.TextStyle(
                        color: PdfColors.blue,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),),
                ),

                pw.Container(
                  height: 30,
                  padding: const pw.EdgeInsets.only(left: 20,top: 10),
                  alignment: pw.Alignment.center,

                  child: pw.Directionality(
                    textDirection: direction? pw.TextDirection.ltr:pw.TextDirection.rtl,
                    child: pw.Text(
                      widget.customCategory!.name.tr()+" Report",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),),

                ),

                pw.Container(
                  height: 20,

                  padding: const pw.EdgeInsets.only(left: 20, top: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    Utils.INVOICE_DATE,
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),

              ],
            ),
          ),
          if (context.pageNumber > 1) pw.SizedBox(height: 20)
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customCategory!.name.tr() + " " + "REPORT".tr()),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Export as PDF",
            onPressed: () => exportPDF(context),
          ),
         /* IconButton(
            icon: Icon(Icons.insert_drive_file, color: Colors.white),
            tooltip: "Export as CSV",
            onPressed: exportCSV,
          ),*/
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              /*Expanded(
                child: Container(
                  height: 45,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(left: 10),
                  margin: EdgeInsets.only(top: 10,left: 10,right: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(5.0)),
                    border: Border.all(
                      color:  Utils.getThemeColorBlue(),
                      width: 1.0,
                    ),
                  ),
                  child: getDropDownList(),
                ),
              ),*/
              InkWell(
                onTap: () {
                  openDatePicker();
                },
                borderRadius: BorderRadius.circular(8), // Adds ripple effect with rounded edges
                child: Container(
                  height: 45,
                  width: widthScreen - 20,
                  margin: EdgeInsets.only(right: 10,left: 10, top: 15, bottom: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Utils.getThemeColorBlue(),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: Utils.getThemeColorBlue(), size: 18),
                      SizedBox(width: 8),
                      Text(
                        date_filter_name.tr(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(), size: 20),
                    ],
                  ),
                ),
              )
            ],
          ),


          records.isEmpty
              ? Center(child: Text("No Data Available".tr(), style: TextStyle(fontSize: 18, color: Colors.grey)))
              : Padding( padding: EdgeInsets.all(12),
                            child: SfCartesianChart(
                              primaryXAxis: CategoryAxis(),
                              primaryYAxis: NumericAxis(),
                              title: ChartTitle(text: widget.customCategory!.name.tr()+" "+"Quantity".tr(), textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue())),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              series: <CartesianSeries<dynamic, dynamic>>[
                                ColumnSeries<CustomCategoryData, String>(
                                  dataSource: records,
                                  xValueMapper: (CustomCategoryData data, _) => data.date.substring(5),
                                  yValueMapper: (CustomCategoryData data, _) => data.quantity,
                                  name: "Quantity".tr(),
                                  dataLabelSettings: DataLabelSettings(isVisible: true, color: Colors.white),
                                  color: Colors.blueAccent,
                                )
                              ],
                            ),
              ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Summary Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                         "Summary & Analytics".tr(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                        ),

                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "TOTAL".tr()+" "+"Quantity".tr()+": ${totalQuantity.toStringAsFixed(2)} ${widget.customCategory!.unit.tr()}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Divider(thickness: 1, height: 20),

                    // 📌 Flock Quantity List
                    Column(
                      children: flockQuantityMap.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.home, color: Colors.blue),
                            ),
                            title: Text(entry.flockName, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Quantity".tr()+": ${entry.totalQuantity.toStringAsFixed(2)} ${widget.customCategory!.unit.toString()}"),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          )

        ],
      ),
    );
  }

  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    _purposeselectedValue = _purposeList[0];

    setState(() {

    });

  }


  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _purposeselectedValue = newValue!;
            selectedFlock = getFlockID();
            getCategoryDataList();
          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,widthScreen - 40, widthScreen),
          );
        });
  }


  Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

    return Container(
      height: height, // Change as per your requirement
      width: width, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filterList.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {

              setState(() {
                date_filter_name = filterList.elementAt(index);
              });

              getData(date_filter_name);
              Navigator.pop(bcontext);
            },
            child: ListTile(
              title: Text(filterList.elementAt(index).tr()),
            ),
          );
        },
      ),
    );
  }


  // Function to Convert List to FlockQuantity Class
  List<FlockQuantity> getFlockQuantities(List<CustomCategoryData> dataList) {
    Map<String, double> flockQuantityMap = {};

    for (var data in dataList) {
      if (flockQuantityMap.containsKey(data.fName)) {
        flockQuantityMap[data.fName] = flockQuantityMap[data.fName]! + data.quantity;
      } else {
        flockQuantityMap[data.fName] = data.quantity;
      }
    }

    // Convert Map to List<FlockQuantity>
    return flockQuantityMap.entries.map((entry) => FlockQuantity(
      flockName: entry.key,
      totalQuantity: entry.value,
    )).toList();
  }



  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'TODAY'.tr()+" ("+Utils.getFormattedDate(str_date)+")";

    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'THIS_MONTH'.tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'ALL_TIME'.tr();
    }
    getCategoryDataList();

  }

  int f_id = -1;
  int getFlockID() {


    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }


}

// Sample data class
class Record {
  String date;
  String cName;
  double quantity;
  String unit;

  Record({required this.date, required this.cName, required this.quantity, required this.unit});
}


class CustomPdfViewerScreen extends StatelessWidget {
  final String filePath;

  CustomPdfViewerScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Report')),
      body: PDFView(
        filePath: filePath, // Pass the filePath here
        onPageChanged: (int? currentPage, int? totalPages) {
          print("Page changed: $currentPage/$totalPages");
        },
        onError: (error) {
          print("Error loading PDF: $error");
        },
      ),
    );
  }
}

// 🆕 Class to Store Total Quantity by Flock
class FlockQuantity {
  String flockName;
  double totalQuantity;

  FlockQuantity({required this.flockName, required this.totalQuantity});
}
