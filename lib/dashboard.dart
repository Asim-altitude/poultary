import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/language_picker_dropdown.dart';
import 'package:language_picker/languages.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/daily_feed.dart';
import 'package:poultary/eggs_report_screen.dart';
import 'package:poultary/feed_report_screen.dart';
import 'package:poultary/health_report_screen.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/medication_vaccination.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'CAS_Ads.dart';
import 'add_flocks.dart';
import 'all_events.dart';
import 'all_reports_screen.dart';
import 'auto_add_feed_screen.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'financial_report_screen.dart';
import 'model/flock.dart';
import 'model/med_vac_item.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreen createState() => _DashboardScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _DashboardScreen extends State<DashboardScreen> {

  final supportedLanguages = [
    Languages.english,
    Languages.arabic,
    Languages.russian,
    Languages.persian,
    Languages.german,
    Languages.japanese,
    Languages.korean,
    Languages.portuguese,
    Languages.turkish,
    Languages.french,
    Languages.indonesian,
    Languages.hindi,
    Languages.spanish,
    Languages.chineseSimplified,
    Languages.ukrainian,
    Languages.polish,
    Languages.bengali,
    Languages.telugu,
    Languages.tamil,
    Languages.greek

  ];
  double widthScreen = 0;
  double heightScreen = 0;
  late Language _selectedCupertinoLanguage;
  bool isGetLanguage = false;
  getLanguage() async {
    _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
    setState(() {
      isGetLanguage = true;

    });

  }

  Widget _buildDropdownItem(Language language) {
    return Container(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 8.0,
          ),
          if(language.isoCode !="pt" && language.isoCode !="zh_Hans")
            Text("${language.name} (${language.isoCode})",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
          if(language.isoCode =="pt")
            Text("${'Portuguese'} (${language.isoCode})",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
          if(language.isoCode =="zh_Hans")
            Text("${'Chinese'} (zh)",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();

  }

  Map<String, double> dataMap = {"Income".tr(): 0,
    "Expense".tr(): 0};

  @override
  void initState() {
    super.initState();

    getFilters();
    getList();
    getLanguage();
    Utils.setupAds();

    // Utils.showInterstitial();
  }
  void addEggColorColumn() async{
    DatabaseHelper.instance.database;
    await DatabaseHelper.addEggColorColumn();
    print("DONE");
  }
  int _dashboard_filter = 2;
  void getFilters() async {

    _dashboard_filter = (await SessionManager.getDashboardFilter())!;
    date_filter_name = filterList.elementAt(_dashboard_filter);
    addEggColorColumn();

  }


  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,Utils.WIDTH_SCREEN - 40, widthScreen),
          );
        });
  }
  Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

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
              getFilteredData(date_filter_name);

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
  void getFilteredData(String filter){
    int index = 0;


    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
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
      getFilteredTransactions(str_date, end_date);

    }
  }


  void getFilteredTransactions(String st,String end) async {
    print("DATE"+st+end);

    await DatabaseHelper.instance.database;
    getFinanceData();
    total_eggs_collected = await DatabaseHelper.getEggCalculations(-1, 1, str_date, end_date);
    total_feed_consumption = await DatabaseHelper.getTotalFeedConsumption(-1, str_date, end_date);
    int vac_count = await DatabaseHelper.getHealthTotal(-1, "Vaccination", str_date, end_date);
    int med_count = await DatabaseHelper.getHealthTotal(-1, "Medication", str_date, end_date);
    treatmentCount = vac_count + med_count;
    total_feed_consumption = num.parse(total_feed_consumption.toStringAsFixed(2));

    _piData = [
      PieData("Income".tr(), gross_income, Colors.green),
      PieData("Expense".tr(), total_expense, Colors.red),
    ];

    setState(() {

    });

  }

  void getFinanceData() async{

    await DatabaseHelper.instance.database;

/*
    DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);
    DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

    var inputFormat = DateFormat('yyyy-MM-dd');
    str_date = inputFormat.format(firstDayCurrentMonth);
    end_date = inputFormat.format(lastDayCurrentMonth);*/

    gross_income = await DatabaseHelper.getTransactionsTotal(-1, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(-1, "Expense", str_date, end_date);

    net_income = gross_income - total_expense;


    gross_income = num.parse(gross_income.toStringAsFixed(2));
    total_expense = num.parse(total_expense.toStringAsFixed(2));
    net_income = num.parse(net_income.toStringAsFixed(2));

    dataMap = { "Income".tr(): gross_income.toDouble(),
      "Expense".tr(): total_expense.toDouble(),};

    setState(() {

    });
  }

  bool no_flock = true;
  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getFlocks();

    if(flocks.length == 0)
    {
      no_flock = true;
      print("NO_FLOCKS".tr());
      Utils.showToast("Please add new flock to continue.".tr());

    }else{
      bool isShow = await SessionManager.isShowWhatsNewDialog();
      if(isShow)
        _showFeatureDialog();
    }

    flock_total = flocks.length;

    getFilteredData(date_filter_name);

    setState(() {

    });



  }

  List<PieData> _piData =[];

  int flock_total = 0;


  num gross_income = 0;
  num total_expense = 0;
  num net_income = 0;
  int total_eggs_collected = 0;
  num total_feed_consumption = 0;
  int treatmentCount =0;

  @override
  Widget build(BuildContext context) {
    double widthScreen = MediaQuery.of(context).size.width;
    Color backgroundColor = Color(0xFFF0F0F3);
    Color shadowColor = Utils.getThemeColorBlue();
    Color lightShadowColor = Colors.white;
    Color primaryTextColor = Colors.black87;

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

    return SafeArea(child: Scaffold(

      body:  SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
            child:SingleChildScrollView(
            child: Column(
            children:  [
              // Utils.getDistanceBar(),
            ClipRRect(
            child: Container(
              width: widthScreen,
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Utils.getThemeColorBlue(),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🌍 Language Picker (Left Side)
                  if (isGetLanguage)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Frosted Glass Effect
                          child: Container(
                            height: 45,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white, // Semi-transparent background
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.language, size: 20, color: Colors.black.withOpacity(0.8)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    width: 200,
                                    child: LanguagePickerDropdown(
                                      initialValue: _selectedCupertinoLanguage,
                                      itemBuilder: (Language language) => _buildDropdownItem(language),
                                      languages: supportedLanguages,
                                      onValuePicked: (Language language) {
                                        _selectedCupertinoLanguage = language;
                                        Utils.setSelectedLanguage(_selectedCupertinoLanguage, context);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(width: 12),

                  // 📅 Date Picker (Right Side)
                  Expanded(
                    child: GestureDetector(
                      onTap: openDatePicker,
                      child: Container(
                        height: 45,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Colors.black.withOpacity(0.8)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                date_filter_name.tr(),
                                style: TextStyle(fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'PTSans'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: 24, color: Colors.black.withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),




          /*InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const FinanceReportsScreen()),
                  );
                },
              child:Container(
                *//*padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),*//*
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  color: Utils.getThemeColorBlue().withAlpha(70),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],

                ),

                child: Column(children: [
                  Visibility(
                    visible: false,
                    child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("HEADING_DASHBOARD".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Utils.getThemeColorBlue()),),

                          ],
                        )),
                  ),
                  Visibility(visible: false,child: Text("("+"THIS_MONTH".tr()+")",style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black),)),


                  Visibility(
                    visible: false,
                    child: PieChart(
                      dataMap: dataMap,
                      animationDuration: Duration(milliseconds: 800),
                      chartLegendSpacing: 32,
                      chartRadius: MediaQuery.of(context).size.width / 3.2,
                      colorList: [Colors.green,Colors.red],
                      initialAngleInDegree: 0,
                      chartType: ChartType.disc,
                      ringStrokeWidth: 32,
                      legendOptions: LegendOptions(
                        showLegendsInRow: false,
                        showLegends: true,
                        legendShape: BoxShape.circle,
                        legendTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      chartValuesOptions: ChartValuesOptions(
                        showChartValueBackground: true,
                        showChartValues: true,
                        showChartValuesInPercentage: false,
                        showChartValuesOutside: false,
                        decimalPlaces: 1,
                      ),
                      // gradientList: ---To add gradient colors---
                      // emptyColorGradient: ---Empty Color gradient---
                    ),
                  ),

                  Visibility(
                    visible: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          width:140,
                          child:Align(
                            alignment: Alignment.centerLeft,
                            child:Text("GROSS_INCOME".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),

                          ),),

                        Container(
                          width:140,
                          child:Align(
                            alignment: Alignment.centerRight,
                          child:Text('$gross_income'+ Utils.currency,style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                        ),),
                      ],),
                  ),
                  Visibility(
                    visible: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width:140,
                          child:Align(
                            alignment: Alignment.centerLeft,
                            child:Text("GROSS_EXPENSE".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),

                          ),),

                        Container(
                          width:140,
                          child:Align(
                            alignment: Alignment.centerRight,
                            child:Text('-$total_expense'+ Utils.currency,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),),

                          ),),


                      ],),
                  ),



                ],),),),
*/
              Stack(
                children: [
                  /*Container(
                    padding: EdgeInsets.only(bottom: 30, top:10,right: 10,left: 10),
                    decoration: BoxDecoration(
                     // borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      color: Utils.getThemeColorBlue2(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 2,
                          offset: Offset(0, 1), // changes position of shadow
                        ),
                      ],

                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            openDatePicker();
                          },
                          child: Container(
                            width: widthScreen,
                            margin: EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                              Icon(Icons.keyboard_arrow_left, color: Colors.white70,),
                              Container(
                                  margin: EdgeInsets.only(left: 5, right: 5),
                                  child:Text(date_filter_name.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),)),
                              Icon(Icons.keyboard_arrow_right, color: Colors.white70,),
                            ],),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const FinanceReportsScreen()),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(net_income>=0?Utils.currency+'$net_income' : "-"+Utils.currency+"${-net_income}",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: net_income>=0? Colors.white : Colors.red),),
                              Text("NET_INCOME".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),

                            ],),
                        ),
                        InkWell(
                          onTap: (){
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const FinanceReportsScreen()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: getDashboardDataBox(Colors.white12, "Income".tr(), '$gross_income', Icons.arrow_upward,Colors.green)),
                                Expanded(child: getDashboardDataBox(Colors.white12, "Expense".tr(), '$total_expense', Icons.arrow_downward, Colors.pink)),
                              ],),
                          ),
                        ),
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           Expanded(child: InkWell(onTap : () async{
                             await Navigator.push(
                               context,
                               CupertinoPageRoute(
                                   builder: (context) => const EggCollectionScreen()),
                             );
                             getFilteredData(date_filter_name);
                           },child: getCustomDataBox(Colors.white12, "EGG_COLLECTION".tr(), '$total_eggs_collected', '',''))),
                           Expanded(child: InkWell(onTap : () async{
                             await Navigator.push(
                               context,
                               CupertinoPageRoute(
                                   builder: (context) => const DailyFeedScreen()),
                             );
                             getFilteredData(date_filter_name);
                           },child: getCustomDataBox(Colors.white12, "FEEDING".tr(), '$total_feed_consumption', '',' '+'KG'.tr()))),
                           Expanded(child: InkWell(onTap: () async{
                            await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const MedicationVaccinationScreen()),
                            );

                            getFilteredData(date_filter_name);
                          },child: getCustomDataBox(Colors.white12, "TREATMENT".tr(), '$treatmentCount', '',''))),

                        ],),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Expanded(child: getCustomDataBox(Utils.getThemeColorBlue(), "Vaccination".tr(), '3', '')),
                            // Expanded(child: getCustomDataBox(Utils.getThemeColorBlue(), "Medication".tr(), '2', '')),
                          ],),],
                    ),
                  ),*/
                  Container(
                    padding: EdgeInsets.only(bottom: 40),
                    color: Utils.getThemeColorBlue(),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // Financial Overview (Pie Chart + Info)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Pie Chart (Left Side)
                              InkWell(
                                onTap: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FinanceReportsScreen()),
                                  );
                                },
                                child: Container(
                                  width: widthScreen / 2,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue, Utils.getThemeColorBlue()], // Lighter gradient
                                      begin: Alignment.topLeft,
                                      end: Alignment.centerRight,
                                    ),
                                     borderRadius: BorderRadius.circular(15), // Optional rounded corners
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2), // Shadow color
                                        blurRadius: 10, // Blur effect
                                        spreadRadius: 3, // Spread radius
                                        offset: Offset(3, 5), // Shadow position
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(1.0), // Padding to prevent chart overflow
                                    child: SfCircularChart(
                                      legend: Legend(isVisible: true, textStyle: TextStyle(fontSize: 11, color: Colors.white), padding: 2),
                                      series: <CircularSeries>[
                                        PieSeries<PieData, String>(
                                          dataSource: _piData,
                                          xValueMapper: (PieData data, _) => data.label,
                                          yValueMapper: (PieData data, _) => data.value,
                                          dataLabelSettings: DataLabelSettings(
                                            isVisible: true,
                                            textStyle: TextStyle(
                                              fontSize: 12,  // Change font size
                                              fontWeight: FontWeight.bold,  // Make it bold
                                              color: Colors.white,  // Adjust color if needed
                                            ),
                                          ),
                                          pointColorMapper: (PieData data, _) => data.color,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),


                              // Financial Summary (Right Side)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    getFinanceCard(Icons.arrow_upward, "Income", "${Utils.currency} $gross_income", Colors.green, FinanceReportsScreen(), context),
                                    getFinanceCard(Icons.arrow_downward, "Expense", "${Utils.currency} $total_expense", Colors.red, FinanceReportsScreen(), context),
                                    getFinanceCard(Icons.monetization_on, "NET_PROFIT", net_income >= 0 ? "${Utils.currency} $net_income" : "-${Utils.currency} ${-net_income}", net_income >= 0 ? Colors.white : Colors.white, FinanceReportsScreen(), context),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10,),
                          // Egg Collection, Feed Consumption, Treatment Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [

                              Expanded(child: getSummaryCard(Icons.egg, "Eggs", "$total_eggs_collected", Colors.white, EggsReportsScreen(), context)),
                              Expanded(child: getSummaryCard(Icons.food_bank, "Feed", "$total_feed_consumption"+ "KG".tr(), Colors.white, FeedReportsScreen(), context)),
                              Expanded(child: getSummaryCard(Icons.medical_information, "Health", "$treatmentCount", Colors.white, HealthReportScreen(), context)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
               Container(
          margin: EdgeInsets.only(top: 340),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            color: backgroundColor,
          ),
          child: Column(
            children: [
              // Title Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ALL_FLOCKS".tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "(${flocks.length})",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating Action Button
                    flocks.isNotEmpty
                        ? Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton(
                        backgroundColor: backgroundColor,
                        elevation: 4,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => const ADDFlockScreen()),
                          );
                          getList();
                          getFilteredData(date_filter_name);
                        },
                        child: Icon(Icons.add, color: primaryTextColor, size: 28),
                      ),
                    )
                        : SizedBox(),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Flock List with Neumorphic Effect
              flocks.isNotEmpty
                  ? ListView.builder(
                itemCount: flocks.length,
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      Utils.selected_flock = flocks[index];
                      await Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const SingleFlockScreen()),
                      );
                      getList();
                      getFilteredData(date_filter_name);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: backgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(4, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: lightShadowColor,
                            offset: Offset(-4, -4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Flock Icon
                          Container(
                            margin: EdgeInsets.all(5),
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              flocks[index].icon,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),

                          // Flock Info (Expanded to take available space)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flocks[index].f_name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  flocks[index].acqusition_type.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  Utils.getFormattedDate(flocks[index].acqusition_date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bird Count + Arrow in a Column
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadowColor,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: lightShadowColor,
                                      offset: Offset(-2, -2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  flocks[index].active_bird_count.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "BIRDS".tr(),
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),


                        ],
                      ),
                    )

                  );
                },
              )
                  : // Empty State UI
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "NO_FLOCKS".tr(),
                    style: TextStyle(fontSize: 16, color: primaryTextColor),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const ADDFlockScreen()),
                      );
                      getList();
                      getFilteredData(date_filter_name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      shadowColor: shadowColor,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    icon: Icon(Icons.add, color: primaryTextColor),
                    label: Text(
                      "NEW_FLOCK".tr(),
                      style: TextStyle(fontSize: 16, color: primaryTextColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
                ],
              ),


              /*Center(
                    child: SfCircularChart(
                        title: ChartTitle(text: 'Income/Expense'),
                        legend: Legend(isVisible: true),
                        series: <PieSeries<_PieData, String>>[
                          PieSeries<_PieData, String>(
                              explode: false,
                              explodeIndex: 0,
                              dataSource: _piData,
                              xValueMapper: (_PieData data, _) => data.xData,
                              yValueMapper: (_PieData data, _) => data.yData,
                              dataLabelMapper: (_PieData data, _) => data.text,
                              dataLabelSettings: DataLabelSettings(isVisible: true)),
                        ]
                    )
                ),*//*


                   *//* Text(
              "Main Menu",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  color: Utils.getThemeColorBlue(),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold
              ),
            ),
                    SizedBox(width: widthScreen, height: 50,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 4),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: const BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 30),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/image.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Inventory",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Inventory()),
                          );
                        }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Profit/Loss",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiRepeatScreen()),
                    );*//**//*
                  }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Medication",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiScreen()),
                    );*//**//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Feeding",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//**//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Form Setup",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//**//*
                  }),*//*
                  ]
      ),),
        ),),),),);*/
    ]))))));
  }

  Widget buildDateFilterWidget(String selectedFilter, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Opens the dialog on click
      child: Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 22),
              SizedBox(width: 8),
              Text(
                selectedFilter,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_drop_down, color: Colors.blue.shade600, size: 24), // Dropdown Indicator
            ],
          ),
        ),
      ),
    );
  }


  // Finance Info Card (Income, Expense, Net Profit)
  Widget getFinanceCard(IconData icon, String title, String amount, Color color, Widget nextScreen, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      },
      borderRadius: BorderRadius.circular(16), // To match the container radius
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Utils.getThemeColorBlue(), Colors.blue.shade700], // Lighter gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
          ],
        ),
        margin: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.tr(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(height: 3),
                  Text(amount,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Summary Card (Eggs, Feed, Treatments)
  Widget getSummaryCard(IconData icon, String title, String value, Color color,Widget nextScreen, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      },
      child: Container(

        margin: EdgeInsets.only(left: 3,right: 3),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Utils.getThemeColorBlue(), Colors.blue.shade700], // Lighter gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color),
                SizedBox(height: 8),
                Text(title.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),

              ],
            ),
              SizedBox(height: 5),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }


  Widget getDashboardDataBox(Color color, String title, String data, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: color,

      ),
       padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
         
            Icon(icon, color: iconColor,),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white70),)
          ],),

          Container(
              margin: EdgeInsets.only(top: 5),
              child: Text(Utils.currency+data, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),))
        ],
      ),
    );
  }


  Widget getCustomDataBox(Color color, String title, String data, String imageSource,String ext) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: color,
      ),
      padding: EdgeInsets.only(top: 12,bottom: 12,left: 5,right: 5),
      margin: EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,


            children: [

            imageSource == ''? SizedBox(width: 0,height: 0,) :  Image.asset(imageSource, width: 40, height: 40,),

            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),)
          ],),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(data, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),)),
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(ext, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),)),
            ],
          )
        ],
      ),
    );
  }


  void showWhatsNewDialog() {

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              controller: ModalScrollController.of(context),
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's New".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Utils.getThemeColorBlue(),
                      ),
                    ),
                    SizedBox(height: 5,),

                    Text(
                      'Some key changes made in this update'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    SizedBox(height: 20,),
                    Text(
                      'Birds'.tr()+' '+'ADITION_RDCTIN'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5,),
                    Text(
                      'graph1'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      'Income'.tr()+'/'+'Expense'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'graph2'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    InkWell(
                      onTap: (){
                        SessionManager.setWhatsNewDialog(false);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: widthScreen,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Utils.getThemeColorBlue(),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(10.0)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        margin: EdgeInsets.all( 20),
                        child: Text(
                          "DONE".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFeatureDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                'New Feature: Automatic Feed Management!'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
               Text(
                'feature_msg'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Utils.getThemeColorBlue(), // Button color for "Activate Now"
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // Padding for a better look
                    ),
                    onPressed: () {
                      // Navigate to the settings screen or activate the feature
                      SessionManager.setWhatsNewDialog(false);
                      Navigator.pop(context); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  SettingsScreen()),
                      ); // Example route
                    },
                    child:  Text('Activate Now'.tr(), style: TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Button color for "Not Now"
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // Padding for a better look
                    ),
                    onPressed: () {
                      // Close the dialog and save the preference
                      SessionManager.setWhatsNewDialog(false);
                      Navigator.pop(context);
                    },
                    child:  Text('Not Now'.tr(), style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

}



class PieData {
  final String label;
final num value;
final Color color;

PieData(this.label, this.value, this.color);
}

class FinanceData {
  final String month;
  final num income;
  final num expense;

  FinanceData(this.month, this.income, this.expense);
}

