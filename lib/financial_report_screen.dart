import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/finance_report_item.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';

import 'model/egg_item.dart';
import 'model/feed_item.dart';
import 'model/finance_chart_data.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';

class FinanceReportsScreen extends StatefulWidget {
  const FinanceReportsScreen({Key? key}) : super(key: key);

  @override
  _FinanceReportsScreen createState() => _FinanceReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FinanceReportsScreen extends State<FinanceReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  List<_SalesData> data = [];

  List<_SalesData> data1 = [];

  late ZoomPanBehavior _zoomPanBehavior;

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }

  @override
  void initState() {
    super.initState();
     try
     {
       date_filter_name = "THIS_MONTH".tr();
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
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  List<TransactionItem> list = [];
  List<Finance_Chart_Item> incomeChartData = [];
  List<Finance_Chart_Item> expenseChartData = [];
  List<String> flock_name = [];

  num gross_income = 0;
  num total_expense = 0;
  num net_income = 0;

  void clearValues(){

     gross_income = 0;
     total_expense = 0;
     net_income = 0;
     list = [];

  }

  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    gross_income = await DatabaseHelper.getTransactionsTotal(f_id, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(f_id, "Expense", str_date, end_date);


    print(gross_income);
    print(total_expense);
    print(net_income);

    net_income = gross_income - total_expense;

    gross_income = num.parse(gross_income.toStringAsFixed(2));
    total_expense = num.parse(total_expense.toStringAsFixed(2));
    net_income = num.parse(net_income.toStringAsFixed(2));

    getFilteredEggsCollections(str_date, end_date);

    setState(() {

    });

  }

  void getFilteredEggsCollections(String st,String end) async {

    await DatabaseHelper.instance.database;

    List<String> dates = [];
    List<Intl> amount = [];
    double tamount = 0;
    int added = -1;

    list = await DatabaseHelper.getReportFilteredTransactions(f_id,"All",st,end);
    incomeChartData = await DatabaseHelper.getFinanceChartData(st, end,"Income");
    expenseChartData = await DatabaseHelper.getFinanceChartData(st, end,"Expense");

    for(int j=0;j<expenseChartData.length;j++){
      expenseChartData.elementAt(j).date = Utils.getFormattedDate(expenseChartData.elementAt(j).date).substring(0,Utils.getFormattedDate(expenseChartData.elementAt(j).date).length-4);
    }

    for(int i=0;i<incomeChartData.length;i++){
      incomeChartData.elementAt(i).date = Utils.getFormattedDate(incomeChartData.elementAt(i).date).substring(0,Utils.getFormattedDate(incomeChartData.elementAt(i).date).length-4);
    }

/*

    for(int i=0;i<list.length;i++){

      if(list.elementAt(i).type == "Income"){

        added = isDateAdded(data, getShortDate(list.elementAt(i).date));
        if(added == -1){
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), double.parse(list.elementAt(i).amount)));

        }else{
          double amt =  data.elementAt(added).sales;
          amt = amt + double.parse(list.elementAt(i).amount);
          data.removeAt(added);
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), amt));

        }
      }
     */
/* else{
        data1.add(new _SalesData(getShortDate(list.elementAt(i).date), double.parse(list.elementAt(i).amount)));
        data.add(new _SalesData(getShortDate(list.elementAt(i).date), 0));
       *//*
*/
/* if(isDateAdded(data, getShortDate(list.elementAt(i).date)) == -1){
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), 0));
        }*//*
*/
/*
      }*//*


    }


    for(int j =0;j<data.length;j++){
      print("INCOME $j "+data.elementAt(j).sales.toString());
      //print("EXPENSE "+data1.elementAt(j).year);
    }
*/

   /* setState(() {

    });*/

    setState(() {

    });

  }

  String getShortDate(String tdate){
    
    print(tdate);
    int l = tdate.characters.length;
    String sdate = Utils.getFormattedDate(tdate).substring(0,l-4);

     print(sdate);
     return sdate;
  }

  int isDateAdded(List<_SalesData> dlist, String tdate){
    int t = -1;
    for(int i=0;i<dlist.length;i++){
      if(dlist.elementAt(i).year == tdate){
        t = i;
        break;
      }
    }

    return t;
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

         child:Container(
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
                              "Financial Report".tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      InkWell(
                        onTap: () {
                          Utils.setupInvoiceInitials("Financial Report".tr(),pdf_formatted_date_filter);
                          prepareListData();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 3,)),
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
                  Expanded(
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
                  ),
                  InkWell(
                      onTap: () {
                        openDatePicker();
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(5.0)),
                            border: Border.all(
                              color:  Utils.getThemeColorBlue(),
                              width: 1.0,
                            ),
                          ),
                          margin: EdgeInsets.only(right: 10,top: 15,bottom: 5),
                          padding: EdgeInsets.only(left: 5,right: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(date_filter_name.tr(), style: TextStyle(fontSize: 14),),
                              Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(),),
                            ],
                          ),
                        ),
                      )),
                ],
              ),

              Container(
                color: Colors.white,
                child: Container(
                  padding: EdgeInsets.all(10),
                  /*decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                   *//* boxShadow: [
                      BoxShadow(
                        color: Colors.white, //(x,y)
                      ),
                    ],*//*
                  ),*/
                  child: Column(children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('INCOME_EXPENSE'.tr(),style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
                          ],
                        )),

                    Container(
                      width: widthScreen,
                      child: Column(children: [
                     //Initialize the chart widget
                     SfCartesianChart(
                         primaryXAxis: CategoryAxis(),

                         zoomPanBehavior: _zoomPanBehavior,
                         // Chart title
                         title: ChartTitle(text: date_filter_name),
                         // Enable legend
                         legend: Legend(isVisible: true, position: LegendPosition.bottom),

                         // Enable tooltip
                         tooltipBehavior: TooltipBehavior(enable: true),
                         series: <CartesianSeries<Finance_Chart_Item, String>>[

                           ColumnSeries(borderRadius: BorderRadius.all(Radius.circular(10)),color:Colors.green,name: 'Income'.tr(),dataSource: incomeChartData, xValueMapper: (Finance_Chart_Item incomeItem, _) => incomeItem.date, yValueMapper: (Finance_Chart_Item incomeItem, _)=> incomeItem.amount,),
                           ColumnSeries(borderRadius: BorderRadius.all(Radius.circular(10)),color: Colors.red,name:'Expense'.tr(),dataSource: expenseChartData, xValueMapper: (Finance_Chart_Item expenseItem, _) => expenseItem.date, yValueMapper: (Finance_Chart_Item expenseItem, _) => expenseItem.amount,)

                         ]),
                     /*Expanded(
                       child: Padding(
                         padding: const EdgeInsets.all(8.0),
                         //Initialize the spark charts widget
                         child: SfSparkLineChart.custom(
                           //Enable the trackball
                           trackball: SparkChartTrackball(
                               activationMode: SparkChartActivationMode.tap),
                           //Enable marker
                           marker: SparkChartMarker(
                               displayMode: SparkChartMarkerDisplayMode.all),
                           //Enable data label
                           labelDisplayMode: SparkChartLabelDisplayMode.all,
                           xValueMapper: (int index) => data[index].year,
                           yValueMapper: (int index) => data[index].sales,
                           dataCount: data.length,
                         ),
                       ),
                     )*/
                   ]),) ,

                    SizedBox(height: 20,width: widthScreen,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GROSS_INCOME'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text(Utils.currency+'$gross_income',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL_EXPENSE'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text("-"+Utils.currency+"$total_expense",style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NET_INCOME'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text(Utils.currency+'$net_income',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),),

                      ],)
                  ],),),
              ),

              Container(
                padding: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  color: Utils.getScreenBackground(),
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
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                          margin: EdgeInsets.all(10),
                          child: Text('transactions'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),)),
                    ),
                    list.length > 0 ? Container(
                      margin: EdgeInsets.only(top: 0,bottom: 20),
                      width: widthScreen,
                      height: list.length * 90,
                      child: ListView.builder(
                          itemCount: list.length,
                          scrollDirection: Axis.vertical,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              onTap: ()
                              {

                              },
                              child: Container(
                                margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(3)),
                                    color: Colors.white,
                                ),

                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(3)),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 2,
                                        offset: Offset(0, 1), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(child: Text(style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black), list.elementAt(index).type == 'Income'? list.elementAt(index).sale_item.tr() : list.elementAt(index).expense_item.tr()),),
                                          Container(child: Text(style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black), " ("+list.elementAt(index).f_name.tr()+")"),),
                                          Icon(list.elementAt(index).type == 'Income'? Icons.arrow_upward:Icons.arrow_downward, color: list.elementAt(index).type == 'Income'? Colors.green:Colors.red,)
                                        ],
                                      ),
                                      Row( children: [
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.only(top: 10),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [

                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_month, size: 25,),
                                                    Container(margin: EdgeInsets.only(left: 5),child: Text(Utils.getFormattedDate(list.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                                  ],
                                                ),
                                                // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                              ],),
                                          ),
                                        ),

                                        Container(
                                          margin: EdgeInsets.only(right: 5),
                                          child: Row(
                                            children: [
                                              Text(Utils.currency, style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 14),),
                                              Container(  child: Text(list.elementAt(index).amount.toString(), style: TextStyle( fontWeight: FontWeight.w700, fontSize: 16, color: list.elementAt(index).type == 'Income'? Utils.getThemeColorBlue():Colors.red),)),
                                            ],
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ) ,
                                ),
                              ),
                            );

                          }),
                    ) : Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Container(
                          height: heightScreen - 200,
                          width: widthScreen,
                          child: Column(
                            children: [
                              Text('No Income/Expense added in current period'.tr(), style: TextStyle(fontSize: 15, color: Colors.black54),),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100,),
                  ],
                ),
              )


            ]
      ),),),),),);
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
              title: Text(filterList.elementAt(index)),
            ),
          );
        },
      ),
    );
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
    getAllData();

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

  void prepareListData() {

    Utils.TOTAL_INCOME = gross_income.toString();
    Utils.TOTAL_EXPENSE = total_expense.toString();
    Utils.NET_INCOME = net_income.toString();

    Utils.finance_report_list.clear();
    for(int i=0;i<list.length;i++){

      TransactionItem transactionItem = list.elementAt(i);
      Utils.finance_report_list.add(Finance_Report_Item(f_name: transactionItem.f_name, date: Utils.getFormattedDate(transactionItem.date), salePurchaseItem: transactionItem.type == 'Income'? transactionItem.sale_item : transactionItem.expense_item, income:  transactionItem.type == 'Income'? transactionItem.amount : '0', expense:  transactionItem.type == 'Income'? '0' : transactionItem.amount));

    }

  }

}

class _SalesData {
  _SalesData(this.year, this.sales);

   String year;
   double sales;
}

