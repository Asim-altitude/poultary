
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/feed_report_item.dart';
import 'package:poultary/model/feed_summary_flock.dart';
import 'package:poultary/model/feedflock_report_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'model/feed_item.dart';
import 'model/feed_summary.dart';
import 'model/flock.dart';

class FeedReportsScreen extends StatefulWidget {
  const FeedReportsScreen({Key? key}) : super(key: key);

  @override
  _FeedReportsScreen createState() => _FeedReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FeedReportsScreen extends State<FeedReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }

  late ZoomPanBehavior _zoomPanBehavior;
  @override
  void initState() {
    super.initState();
     try
     {
       _zoomPanBehavior = ZoomPanBehavior(
           enableDoubleTapZooming: true,
           enablePinching: true,
           // Enables the selection zooming
           enableSelectionZooming: true,
           selectionRectBorderColor: Colors.red,
           selectionRectBorderWidth: 1,
           selectionRectColor: Colors.grey
       );
       date_filter_name = Utils.applied_filter;
       getFilters();
       getList();

     }
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  List<Feeding> list = [];

  List<FeedSummary> feedingSummary = [];
  List<FlockFeedSummary> flockFeedSummary = [];
  List<String> flock_name = [];


  num total_feed_consumption = 0;

  void clearValues(){

    total_feed_consumption =0;

  }

  void getAllData() async {

    await DatabaseHelper.instance.database;

    clearValues();

    feedingSummary = await DatabaseHelper.getMyMostUsedFeeds(f_id, str_date, end_date);
    flockFeedSummary = await DatabaseHelper.getMyMostUsedFeedsByFlock(f_id, str_date, end_date);

    total_feed_consumption = await DatabaseHelper.getTotalFeedConsumption(f_id, str_date, end_date);
    total_feed_consumption = num.parse(total_feed_consumption.toStringAsFixed(2));

    setState(() {

    });

  }


  Future<void> generateFeedReportExcel(
      List<Feed_Report_Item> feedReportList,
      List<FeedFlock_Report_Item> feedFlockReportList,
      ) async
  {
    var excel = Excel.createExcel();
    var sheet = excel['Feeding Report'.tr()];

    // ==== Define Styles ====
    var titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString("#1F4E78"), // dark blue
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var sectionTitleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#BDD7EE"), // light section
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#B7DEE8"), // header
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var numberStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
    );

    int row = 0;

    // ==== Report Title ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Feeding Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = titleStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

    row += 2;

    // ==== Section 1: By Feed Type ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("By Feed Type".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));

    row++;

    List<String> feedHeaders = [
      "Feed Name".tr(),
      "Consumption".tr() +"(${Utils.selected_unit.tr()})",
    ];

    for (int i = 0; i < feedHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(feedHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var item in feedReportList) {
      sheet.appendRow([
        TextCellValue(item.feed_name),
        DoubleCellValue(double.parse(item.consumption.toString()) ?? 0),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    row += 2;

    // ==== Section 2: By Flock ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("By Flock".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));

    row++;

    List<String> flockHeaders = [
      "Flock Name".tr(),
      "Consumption".tr()+"(${Utils.selected_unit.tr()})",
    ];

    for (int i = 0; i < flockHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(flockHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var flockItem in feedFlockReportList) {
      sheet.appendRow([
        TextCellValue(flockItem.f_name),
        DoubleCellValue(double.parse(flockItem.consumption.toString()) ?? 0),
      ]);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    // === Auto-adjust column widths ===
    for (var table in excel.tables.keys) {
      var sheet = excel[table];
      for (int col = 0; col < sheet.maxColumns; col++) {
        double maxLength = 0;
        for (int row = 0; row < sheet.maxRows; row++) {
          var cellValue = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value;
          if (cellValue != null) {
            var text = cellValue.toString();
            if (text.length > maxLength) {
              maxLength = text.length.toDouble();
            }
          }
        }
        sheet.setColumnWidth(col, (maxLength * 1.2).clamp(12, 35));
      }
    }

    saveAndShareExcel(excel);
  }


  Future<void> saveAndShareExcel(Excel excel) async {
    final downloadsDir = Directory("/storage/emulated/0/Download");
    String formattedDate = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
    String filePath = "${downloadsDir.path}/feed_report_$formattedDate.xlsx";

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved to Downloads: egg_report_$formattedDate.xlsx");

    // ✅ Share/Open the file safely
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Egg report exported successfully!",
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
      child:

    return SafeArea(child: Scaffold(
      body:SafeArea(
        top: false,

         child: Container(
          width: widthScreen,
          height: heightScreen,
             color: Colors.white,
            child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Utils.getDistanceBar(),

              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Utils.getThemeColorBlue(), //(x,y)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 50,
                        height: 50,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              "Feeding Report".tr(),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600),
                            )),
                      ),
                      if(!Platform.isIOS)

                        InkWell(
                        onTap: () {

                          Utils.setupInvoiceInitials("Feeding Report".tr(),pdf_formatted_date_filter);
                          prepareListData();
                          generateFeedReportExcel(Utils.feed_report_list, Utils.feed_flock_report_list);

                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: EdgeInsets.only(right: 10),
                          child: Image.asset('assets/excel_icon.png'),
                        ),
                      ),
                      InkWell(
                        onTap: (){
                          Utils.setupInvoiceInitials("Feeding Report".tr(),pdf_formatted_date_filter);
                          prepareListData();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 2)),
                          );
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: EdgeInsets.only(right: 10),
                          child: Image.asset('assets/pdf_icon.png'),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(left: 10),
                      margin: EdgeInsets.only(left: 10,right: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        /*border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),*/
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: getDropDownList(),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      openDatePicker();
                    },
                    borderRadius: BorderRadius.circular(8), // Adds ripple effect with rounded edges
                    child: Container(
                      height: 45,
                      margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        /*border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),*/
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


              Container(
                color: Colors.white,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white, //(x,y)
                      ),
                    ],
                  ),
                  child: Column(children: [

                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Column(
                        children: [
                          // Chart Title
                          Text(date_filter_name.tr(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 8),

                          // Chart Widget
                          SfCartesianChart(
                            primaryXAxis: CategoryAxis(
                              labelRotation: -45,  // Slanted labels for better readability
                              majorGridLines: MajorGridLines(width: 0.5),
                            ),
                            primaryYAxis: NumericAxis(
                              labelFormat: '{value}'+' '+ Utils.selected_unit.tr(),
                              majorGridLines: MajorGridLines(width: 0.3),
                            ),
                            zoomPanBehavior: _zoomPanBehavior,

                            // Enable Legend
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              textStyle: TextStyle(fontSize: 14),
                            ),

                            // Enable Tooltip
                            tooltipBehavior: TooltipBehavior(enable: true),

                            // Series
                            series: <CartesianSeries<FeedSummary, String>>[
                              ColumnSeries<FeedSummary, String>(
                                name: 'Feed'.tr(),
                                dataSource: feedingSummary,
                                xValueMapper: (FeedSummary feedItem, _) => feedItem.feedName.tr(),
                                yValueMapper: (FeedSummary feedItem, _) => feedItem.totalQuantity,
                                borderRadius: BorderRadius.all(Radius.circular(10)), // Smooth Rounded Bars
                                color: Colors.deepOrange,
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),


                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Title
                            Text(
                              "SUMMARY".tr(),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                            ),
                            SizedBox(height: 8),

                            // Section 1: By Feed Name
                            Text(
                              "By Feed Name".tr(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Divider(thickness: 1, color: Colors.black26),
                            Column(
                              children: feedingSummary.map((feed) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        feed.feedName.tr(),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                                      ),
                                      Text(
                                        "${Utils.roundTo2Decimal(feed.totalQuantity)}"+" "+Utils.selected_unit.tr(),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 10),

                            // Section 2: By Flock Name
                            Text(
                              "By Flock Name".tr(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Divider(thickness: 1, color: Colors.black26),
                            Column(
                              children: flockFeedSummary.map((flock) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        flock.f_name.tr(),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                                      ),
                                      Text(
                                        "${Utils.roundTo2Decimal(flock.totalQuantity)}" + " "+Utils.selected_unit.tr(),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            // Divider for Separation
                            Divider(thickness: 1, color: Colors.black26),
                            SizedBox(height: 6),

                            // Total Consumption Row
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL'.tr(),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                                  ),
                                  Text(
                                    "${total_feed_consumption}"+" "+Utils.selected_unit.tr(),
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )


                  ],),),
              ),


            ]
      ),),),),),);
  }

  Widget _buildChart() {
    return Container(
      height: 200,
      color: Colors.grey[300], // Placeholder for the chart
      alignment: Alignment.center,
      child: Text("Chart Placeholder"),
    );
  }



  //FILTER WORK
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

  int isCollection = 1;
  int selected = 1;
  int f_id = -1;


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
            getFlockID();
            getAllData();

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
      height: filterList.length * 55,
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

              Navigator.pop(bcontext);
              getData(date_filter_name);

            },
            child: ListTile(
              title: Text(filterList.elementAt(index).tr()),
            ),
          );
        },
      ),
    );
  }

  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date='',end_date='';
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

      getAllData();
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";
      getAllData();
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
      getAllData();
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'ALL_TIME';
      getAllData();
    }else if (filter == 'DATE_RANGE'){
      _pickDateRange();
    }


  }

  DateTimeRange? selectedDateRange;
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year - 5); // Allows past 5 years
    DateTime lastDate = DateTime(now.year + 5); // Allows future 5 years

    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: selectedDateRange ?? DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      var inputFormat = DateFormat('yyyy-MM-dd');
      selectedDateRange = pickedRange;

      str_date = inputFormat.format(pickedRange.start);
      end_date = inputFormat.format(pickedRange.end);
      date_filter_name = Utils.getFormattedDate(str_date) +" | "+Utils.getFormattedDate(end_date);
      print(str_date+" "+end_date);
      getAllData();

    }
  }

  int getFlockID() {


    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }

  void prepareListData() async {

   // Utils.feed_report_list = await DatabaseHelper.getAllFeedingsReport(str_date,end_date);
    //Utils.feed_flock_report_list = await DatabaseHelper.getAllFeedingsReportByFlock(str_date,end_date);

    Feed_Report_Item? feedItem = null;
    List<Feed_Report_Item> feedList = [];

    FeedFlock_Report_Item? feedFlock = null;
    List<FeedFlock_Report_Item> feedbyFlocck = [];
    for(int i=0;i<flockFeedSummary.length; i++)
    {
      feedFlock = new FeedFlock_Report_Item(f_name: flockFeedSummary.elementAt(i).f_name, consumption: flockFeedSummary.elementAt(i).totalQuantity);
      feedbyFlocck.add(feedFlock);
    }

    for(int i=0;i<feedingSummary.length; i++)
    {
      feedItem = new Feed_Report_Item(feed_name: feedingSummary.elementAt(i).feedName, consumption: feedingSummary.elementAt(i).totalQuantity);
      feedList.add(feedItem);
    }

    Utils.feed_flock_report_list = feedbyFlocck;
    Utils.feed_report_list = feedList;
  }

}

