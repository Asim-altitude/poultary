import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/egg_report_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'model/egg_item.dart';
import 'model/eggs_chart_data.dart';
import 'model/flock.dart';

class EggsReportsScreen extends StatefulWidget {
  const EggsReportsScreen({Key? key}) : super(key: key);

  @override
  _EggsReportsScreen createState() => _EggsReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _EggsReportsScreen extends State<EggsReportsScreen> with SingleTickerProviderStateMixin {

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
    try {
      //date_filter_name = Utils.applied_filter;
      _zoomPanBehavior = ZoomPanBehavior(
          enableDoubleTapZooming: true,
          enablePinching: true,
          // Enables the selection zooming
          enableSelectionZooming: true,
          selectionRectBorderColor: Colors.red,
          selectionRectBorderWidth: 1,
          selectionRectColor: Colors.grey
      );
      getFilters();
      getList();
    }
    catch (ex) {
      print(ex);
    }
    Utils.setupAds();
  }

  List<Eggs_Chart_Item> collectionList = [],
      reductionList = [];
  List<Eggs> eggs = [];
  List<String> flock_name = [];

  int egg_total = 0;


  int total_eggs_collected = 0;
  int total_eggs_reduced = 0;
  int total_eggs = 0;

  void clearValues() {
    total_eggs_collected = 0;
    total_eggs_reduced = 0;
    total_eggs = 0;
    eggs = [];
  }

  void getAllData() async {
    await DatabaseHelper.instance.database;

    clearValues();

    total_eggs_collected =
    await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);

    total_eggs_reduced =
    await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);

    total_eggs = total_eggs_collected - total_eggs_reduced;

    collectionList =
    await DatabaseHelper.getEggsReportData(str_date, end_date, 1);

    reductionList =
    await DatabaseHelper.getEggsReportData(str_date, end_date, 0);

    for (int i = 0; i < reductionList.length; i++) {
      reductionList
          .elementAt(i)
          .date = Utils.getFormattedDate(reductionList
          .elementAt(i)
          .date).substring(0, Utils
          .getFormattedDate(reductionList
          .elementAt(i)
          .date)
          .length - 4);
    }

    for (int j = 0; j < collectionList.length; j++) {
      collectionList
          .elementAt(j)
          .date = Utils.getFormattedDate(collectionList
          .elementAt(j)
          .date).substring(0, Utils
          .getFormattedDate(collectionList
          .elementAt(j)
          .date)
          .length - 4);
    }


    getFilteredEggsCollections(str_date, end_date);

    setState(() {

    });
  }

  List<FlockEggSummary> flockEggSummary = [];
  List<EggReductionSummary> eggReductionSummary = [];

  int good_eggs = 0,
      bad_eggs = 0;

  void getFilteredEggsCollections(String st, String end) async {
    await DatabaseHelper.instance.database;

    eggs = await DatabaseHelper.getFilteredEggs(f_id, "All", st, end);

    good_eggs = eggs
        .where((item) => item.isCollection == 1)
        .fold(0, (sum, item) => sum + item.good_eggs);

    bad_eggs = eggs
        .where((item) => item.isCollection == 1)
        .fold(0, (sum, item) => sum + item.bad_eggs);

    flockEggSummary = getFlockWiseEggSummary(eggs, str_date, end_date);
    eggReductionSummary = getEggReductionSummary(eggs, str_date, end_date);

    Utils.eggReductionSummary = eggReductionSummary;

    setState(() {

    });
  }


  @override
  Widget build(BuildContext context) {
    double safeAreaHeight = MediaQuery
        .of(context)
        .padding
        .top;
    double safeAreaHeightBottom = MediaQuery
        .of(context)
        .padding
        .bottom;
    widthScreen =
        MediaQuery
            .of(context)
            .size
            .width; // because of default padding
    heightScreen = MediaQuery
        .of(context)
        .size
        .height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery
        .of(context)
        .size
        .height - (safeAreaHeight + safeAreaHeightBottom);

    return SafeArea(child: Scaffold(
      body: SafeArea(
        top: false,

        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
          child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Utils.getDistanceBar(),

                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0)),
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
                                  "EGGS_REPORT".tr(),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )),
                          ),
                          InkWell(
                            onTap: () {
                              Utils.setupInvoiceInitials("EGGS_REPORT".tr(),
                                  pdf_formatted_date_filter);
                              prepareListData();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PDFScreen(item: 1,)),
                              );
                            },
                            child: Container(
                              width: 30,
                              height: 30,
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

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Chart Section
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(10),
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            zoomPanBehavior: _zoomPanBehavior,
                            title: ChartTitle(text: date_filter_name.tr()),
                            legend: Legend(isVisible: true,
                                position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries<Eggs_Chart_Item, String>>[
                              ColumnSeries(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                color: Colors.green,
                                name: 'Collections'.tr(),
                                dataSource: collectionList,
                                xValueMapper: (Eggs_Chart_Item item, _) =>
                                item.date,
                                yValueMapper: (Eggs_Chart_Item item, _) =>
                                item.total,
                              ),
                              ColumnSeries(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                color: Colors.red,
                                name: 'Reductions'.tr(),
                                dataSource: reductionList,
                                xValueMapper: (Eggs_Chart_Item item, _) =>
                                item.date,
                                yValueMapper: (Eggs_Chart_Item item, _) =>
                                item.total,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 📌 Summary Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      "Summary & Analytics".tr(),
                                      style: TextStyle(fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                SizedBox(height: 8),

                                // 🥚 Statistics Section
                                Column(
                                  children: [
                                    SummaryRow(
                                      title: 'Total Collected'.tr(),
                                      value: '$total_eggs_collected',
                                      icon: Icons.egg,
                                      color: Colors.green,
                                    ),
                                    SummaryRow(
                                      title: 'Good Eggs'.tr(),
                                      value: '$good_eggs',
                                      icon: Icons.check_circle,
                                      color: Colors.blue,
                                    ),
                                    SummaryRow(
                                      title: 'Bad Eggs'.tr(),
                                      value: '$bad_eggs',
                                      icon: Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                    ),
                                    Divider(),
                                    SummaryRow(
                                      title: 'Total Used'.tr(),
                                      value: '-$total_eggs_reduced',
                                      icon: Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    SummaryRow(
                                      title: 'Remaining Eggs'.tr(),
                                      value: '${total_eggs_collected -
                                          total_eggs_reduced}',
                                      icon: Icons.egg_alt,
                                      color: (total_eggs_collected -
                                          total_eggs_reduced) >= 0 ? Colors
                                          .black : Colors.red,
                                      isBold: true,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Divider(),

                                // 🐔 Flock-wise Summary Section
                                Text(
                                  "By Flock".tr(),
                                  style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),

                                // 🏷️ Flock List
                                Column(
                                  children: flockEggSummary.map((flock) =>
                                      _buildFlockRow(flock)).toList(),
                                ),
                                SizedBox(height: 8),
                                buildEggReductionList(eggReductionSummary)
                              ],
                            ),
                          ),
                        )

                      ],
                    ),
                  )


                ]
            ),),),),),);
  }


  Widget buildEggReductionList(List<EggReductionSummary> reductionList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Egg Usage (Reductions)".tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...reductionList.map((reduction) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(Icons.remove_circle, color: Colors.red),
            title: Text(
              reduction.reason.tr(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "-${reduction.totalReduced}",
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        )),
      ],
    );
  }


  Widget _buildFlockRow(FlockEggSummary flock) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // 🟡 Flock Icon
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade200,
              child: Icon(Icons.egg, color: Colors.white, size: 28),
            ),
            SizedBox(width: 12),

            // 📋 Flock Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flock.fName,
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _buildEggInfo("Good", flock.goodEggs, Colors.green),
                      SizedBox(width: 10),
                      _buildEggInfo("Bad", flock.badEggs, Colors.orange),
                      SizedBox(width: 10),
                      _buildEggInfo("Total", flock.totalEggs, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// 🎨 Helper for Colored Egg Info
  Widget _buildEggInfo(String label, int count, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        SizedBox(width: 4),
        Text(
          "$label: $count",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }


  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

  void getList() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0, Flock(f_id: -1,
        f_name: 'Farm Wide'.tr(),
        bird_count: 0,
        purpose: '',
        acqusition_date: '',
        acqusition_type: '',
        notes: '',
        icon: '',
        active_bird_count: 0,
        active: 1,
        flock_new: 1));

    for (int i = 0; i < flocks.length; i++) {
      _purposeList.add(flocks
          .elementAt(i)
          .f_name);
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
              value,
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
            content: setupAlertDialoadContainer(
                bcontext, widthScreen - 40, widthScreen),
          );
        });
  }


  Widget setupAlertDialoadContainer(BuildContext bcontext, double width,
      double height) {
    return Container(
      height: filterList.length * 55, // Change as per your requirement
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
    for (int i = 0; i < flocks.length; i++) {
      if (_purposeselectedValue == flocks
          .elementAt(i)
          .f_name) {
        f_id = flocks
            .elementAt(i)
            .f_id;
        break;
      }
    }

    return f_id;
  }

  void prepareListData() async {
    int collected = 0,
        reduced = 0,
        reserve = 0,
        t_good_eggs,
        t_bad_eggs;

    Utils.egg_report_list.clear();
    Utils.TOTAL_EGG_COLLECTED = total_eggs_collected.toString();
    Utils.TOTAL_EGG_REDUCED = total_eggs_reduced.toString();
    Utils.EGG_RESERVE = total_eggs.toString();
    Utils.GOOD_EGGS = good_eggs.toString();
    Utils.BAD_EGGS = bad_eggs.toString();


    if (f_id == -1) {
      for (int i = 0; i < flocks.length; i++) {
        collected = await DatabaseHelper.getUniqueEggCalculations(flocks
            .elementAt(i)
            .f_id, 1, str_date, end_date);
        reduced = await DatabaseHelper.getUniqueEggCalculations(flocks
            .elementAt(i)
            .f_id, 0, str_date, end_date);

        t_good_eggs =
        await DatabaseHelper.getUniqueEggCalculationsGoodBad(flocks
            .elementAt(i)
            .f_id, 1, str_date, end_date);
        t_bad_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(flocks
            .elementAt(i)
            .f_id, 0, str_date, end_date);

        reserve = collected - reduced;

        Egg_Report_Item item = Egg_Report_Item(f_name: flocks
            .elementAt(i)
            .f_name,
            collected: collected,
            reduced: reduced,
            reserve: reserve);
        item.good_eggs = t_good_eggs;
        item.bad_eggs = t_bad_eggs;
        Utils.egg_report_list.add(item);
      }
    } else {
      collected =
      await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);
      reduced =
      await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);
      t_good_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(
          f_id, 1, str_date, end_date);
      t_bad_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(
          f_id, 0, str_date, end_date);
      reserve = collected - reduced;

      Flock? flock = await getSelectedFlock();

      Egg_Report_Item item = Egg_Report_Item(f_name: flock!.f_name,
          collected: collected,
          reduced: reduced,
          reserve: reserve);
      item.good_eggs = t_good_eggs;
      item.bad_eggs = t_bad_eggs;
      Utils.egg_report_list.add(item);
    }
  }

  Future<Flock?> getSelectedFlock() async {
    Flock? flock = null;

    for (int i = 0; i < flocks.length; i++) {
      if (f_id == flocks
          .elementAt(i)
          .f_id) {
        flock = flocks.elementAt(i);
        break;
      }
    }

    return flock;
  }

  List<FlockEggSummary> getFlockWiseEggSummary(List<Eggs> eggsList,
      String startDate, String endDate) {
    Map<String, FlockEggSummary> summaryMap = {};

    for (var egg in eggsList) {
      if (egg.date != null &&
          egg.isCollection == 1) { // ✅ Filter by type "Addition"
        DateTime eggDate = DateTime.parse(egg.date!);
        DateTime start = DateTime.parse(startDate);
        DateTime end = DateTime.parse(endDate);

        if (eggDate.isAfter(start.subtract(Duration(days: 1))) &&
            eggDate.isBefore(end.add(Duration(days: 1)))) {
          if (!summaryMap.containsKey(egg.f_name)) {
            summaryMap[egg.f_name!] = FlockEggSummary(
                fName: egg.f_name!, goodEggs: 0, badEggs: 0, totalEggs: 0);
          }
          summaryMap[egg.f_name]!.goodEggs += egg.good_eggs;
          summaryMap[egg.f_name]!.badEggs += egg.bad_eggs;
          summaryMap[egg.f_name]!.totalEggs += egg.total_eggs;
        }
      }
    }

    return summaryMap.values.toList();
  }

  List<EggReductionSummary> getEggReductionSummary(List<Eggs> eggsList,
      String str, String endDate) {
    Map<String, int> reductionMap = {};

    for (var egg in eggsList) {
      if (egg.isCollection == 0) {
        DateTime eggDate = DateTime.parse(egg.date!);
        DateTime start = DateTime.parse(str);
        DateTime end = DateTime.parse(endDate);

        if (eggDate.isAfter(start.subtract(Duration(days: 1))) &&
            eggDate.isBefore(end.add(Duration(days: 1)))) {
          String reason = egg.reduction_reason ?? "Unknown";
          reductionMap[reason] = (reductionMap[reason] ?? 0) + egg.total_eggs;
        }
      }
    }

      return reductionMap.entries
          .map((entry) =>
          EggReductionSummary(reason: entry.key, totalReduced: entry.value))
          .toList();
  }

}

// 📌 Model for Flock-wise summary
class FlockEggSummary {
   String fName;
   int goodEggs;
   int badEggs;
   int totalEggs;

  FlockEggSummary({required this.fName, required this.goodEggs, required this.badEggs, required this.totalEggs});
}

// 📌 Summary Row Widget
class SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isBold;

  SummaryRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class EggReductionSummary {
  String reason;
  int totalReduced;

  EggReductionSummary({required this.reason, required this.totalReduced});
}

