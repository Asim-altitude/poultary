import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/language_picker_dropdown.dart';
import 'package:language_picker/languages.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/daily_feed.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/medication_vaccination.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'CAS_Ads.dart';
import 'add_flocks.dart';
import 'all_reports_screen.dart';
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
    // Languages.urdu

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
    return Row(
      children: <Widget>[
        SizedBox(
          width: 8.0,
        ),
        if(language.isoCode !="pt" && language.isoCode !="zh_Hans")
          Text("${language.name} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="pt")
          Text("${'Portuguese'} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="zh_Hans")
          Text("${'Chinese'} (zh)",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
      ],
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
    getList();
    getLanguage();
    Utils.setupAds();


    // Utils.showInterstitial();
  }
  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String filter_name = "All";
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

              getFilteredData(date_filter_name);
              Navigator.pop(bcontext);
            },
            child: ListTile(
              title: Text(filterList.elementAt(index)),
            ),
          );
        },
      ),
    );
  }

  void getFilteredData(String filter){

    if(flocks.length==0){
      Utils.showToast("Please add new flock to continue.");
      return;
    }

    int index = 0;

    if (filter == 'TODAY'.tr()){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'YESTERDAY'.tr()){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'THIS_MONTH'.tr()){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_MONTH'.tr()){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'LAST3_MONTHS'.tr()){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST6_MONTHS'.tr()){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'THIS_YEAR'.tr()){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_YEAR'.tr()){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'ALL_TIME'.tr()){
      index = 8;
      str_date ="";
      end_date ="";
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }
    getFilteredTransactions(str_date, end_date);

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
    setState(() {

    });

  }

  String str_date='',end_date='';
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
    }

    flock_total = flocks.length;

    getFilteredData("THIS_MONTH".tr());

    setState(() {

    });

  }

  List<_PieData> _piData =[];

  int flock_total = 0;


  int gross_income = 0;
  int total_expense = 0;
  int net_income = 0;
  int total_eggs_collected = 0;
  int total_feed_consumption = 0;
  int treatmentCount =0;

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

      body:  SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
            child:SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              // Utils.getDistanceBar(),

              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                child: Container(
                  color: Utils.getThemeColorBlue(),
                  width: widthScreen,
                  height: 60,
                  /*decoration: BoxDecoration(
                    color: Utils.getThemeColorBlue(),
                   *//* boxShadow: [
                      BoxShadow(
                        color: Utils.getThemeColorBlue()
                      ),
                    ],*//*
                  ),*/
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 52,
                        height: 52,
                        child: Container(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.home, color: Colors.white,),

                        )
                      ),
                      Container(

                          child: Expanded(
                            child: Text(
                              "TITLE_DASHBOARD".tr(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),),
                      if(isGetLanguage)
                      Container(
                        width: Utils.getWidthResized(150),height:60,color: Colors.white,
                        child: LanguagePickerDropdown(

                          initialValue: _selectedCupertinoLanguage,
                          itemBuilder: _buildDropdownItem,
                          languages: supportedLanguages,
                          onValuePicked: (Language language) {
                            _selectedCupertinoLanguage = language;
                            // Utils.showToast(language.isoCode);
                            Utils.setSelectedLanguage(_selectedCupertinoLanguage,context);

                          },
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FinanceReportsScreen()),
                  );
                },
              child:Container(
                /*padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),*/
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

                child:

                Column(children: [
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

              Stack(
                children: [
                  Container(
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
                                  child:Text(date_filter_name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),)),
                              Icon(Icons.keyboard_arrow_right, color: Colors.white70,),
                            ],),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
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
                              MaterialPageRoute(
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
                               MaterialPageRoute(
                                   builder: (context) => const EggCollectionScreen()),
                             );
                             getFilteredData(date_filter_name);
                           },child: getCustomDataBox(Colors.white12, "EGG_COLLECTION".tr(), '$total_eggs_collected', '',''))),
                           Expanded(child: InkWell(onTap : () async{
                             await Navigator.push(
                               context,
                               MaterialPageRoute(
                                   builder: (context) => const DailyFeedScreen()),
                             );
                             getFilteredData(date_filter_name);
                           },child: getCustomDataBox(Colors.white12, "FEEDING".tr(), '$total_feed_consumption', '',' kg'))),
                           Expanded(child: InkWell(onTap: () async{
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
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
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 295),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      color: Utils.getScreenBackground(),

                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                          child: Stack(
                            children: [
                              Container(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("ALL_FLOCKS".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                                    Text("(" + flocks.length.toString() + ")",style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),

                                  ],
                                ),
                              ),
                             flocks.length > 0 ? InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const ADDFlockScreen()),
                                  );

                                  getList();
                                  getFilteredData(date_filter_name);

                                },
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 2,
                                              offset: Offset(0, 1), // changes position of shadow
                                            ),
                                          ],
                                          color: Utils.getThemeColorBlue(),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(30.0)),
                                          border: Border.all(
                                            color:  Utils.getThemeColorBlue(),
                                            width: 2.0,
                                          ),
                                        ),child: Text("+", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white),))),
                              ) : SizedBox(width: 0,),

                            ],
                          ),
                        ),
                        // Container(width: widthScreen,height: 60,
                        // ),
                        SizedBox(height: 8,),
                        flocks.length > 0 ? Container(
                          height: flocks.length * 140,
                          width: widthScreen - 10,
                          child: ListView.builder(
                              itemCount: flocks.length,
                              scrollDirection: Axis.vertical,
                              physics: const NeverScrollableScrollPhysics(),

                              itemBuilder: (BuildContext context, int index) {
                                return  InkWell(
                                    onTap: () async{
                                      Utils.selected_flock = flocks.elementAt(index);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const SingleFlockScreen()),
                                      );
                                      getList();
                                      getFilteredData(date_filter_name);();

                                    },
                                    child:Container(
                                      margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(3)),
                                        color: Colors.white12,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 2,
                                            offset: Offset(0, 1), // changes position of shadow
                                          ),
                                        ],

                                      ),
                                      child: Container(
                                        height: 120,
                                        width: widthScreen,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        child: Row( children: [
                                          Expanded(
                                            child: Container(

                                              margin: EdgeInsets.all(5),
                                              padding: EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container( child: Text(flocks.elementAt(index).f_name, style: TextStyle( fontWeight: FontWeight.w600, fontSize: 17, color: Utils.getThemeColorBlue()),)),
                                                  Container( child: Text(flocks.elementAt(index).acqusition_type, style: TextStyle( fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black,    decoration: TextDecoration.underline,
                                                  ),)),
                                                  Container( child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black54),)),

                                                ],),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.all(5),
                                                height: 80, width: 80,
                                                child: Image.asset(flocks.elementAt(index).icon, fit: BoxFit.contain,),),
                                              Container(
                                                margin: EdgeInsets.only(right: 10),
                                                child: Row(
                                                  children: [
                                                    Container( margin: EdgeInsets.only(right: 5), child: Text(flocks.elementAt(index).active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 17, color: Utils.getThemeColorBlue()),)),
                                                    Text("BIRDS".tr(), style: TextStyle(color: Colors.black, fontSize: 14),)
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                        ]),
                                      ),
                                    )
                                );

                              }),
                        ) : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                alignment:  Alignment.center,
                                margin: EdgeInsets.only(top: 30),
                                child: Text("NO_FLOCKS".tr(),style: TextStyle( fontSize: 14,color: Colors.black),)),
                            InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ADDFlockScreen()),
                                );

                                getList();
                                getFilteredData(date_filter_name);();

                              },
                              child: Align(

                                  child: Container(
                                      width: 150,
                                      margin: EdgeInsets.only(top: 10),
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 2,
                                            offset: Offset(0, 1), // changes position of shadow
                                          ),
                                        ],
                                        color: Utils.getThemeColorBlue(),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(30.0)),
                                        border: Border.all(
                                          color:  Utils.getThemeColorBlue(),
                                          width: 2.0,
                                        ),
                                      ),child: Text("+ " +"NEW_FLOCK".tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 16, color: Colors.white),))),
                            )
                          ],
                        )
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


}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);
  final String xData;
  final num yData;
  final String? text;
}

