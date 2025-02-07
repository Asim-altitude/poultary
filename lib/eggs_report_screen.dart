import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'model/feed_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';

class EggsReportsScreen extends StatefulWidget {
  const EggsReportsScreen({Key? key}) : super(key: key);

  @override
  _EggsReportsScreen createState() => _EggsReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _EggsReportsScreen extends State<EggsReportsScreen> with SingleTickerProviderStateMixin{

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
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  List<Eggs_Chart_Item> collectionList = [], reductionList = [];
  List<Eggs> eggs = [];
  List<String> flock_name = [];

  int egg_total = 0;


  int total_eggs_collected = 0;
  int total_eggs_reduced = 0;
  int total_eggs = 0;

  void clearValues(){

     total_eggs_collected = 0;
     total_eggs_reduced = 0;
     total_eggs = 0;
     eggs = [];

  }

  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    total_eggs_collected = await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);

    total_eggs_reduced = await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);

    total_eggs = total_eggs_collected - total_eggs_reduced;

    collectionList = await DatabaseHelper.getEggsReportData(str_date, end_date, 1);

    reductionList = await DatabaseHelper.getEggsReportData(str_date, end_date, 0);

    for(int i=0;i<reductionList.length;i++){
      reductionList.elementAt(i).date = Utils.getFormattedDate(reductionList.elementAt(i).date).substring(0,Utils.getFormattedDate(reductionList.elementAt(i).date).length-4);
    }

    for(int j=0;j<collectionList.length;j++){
      collectionList.elementAt(j).date = Utils.getFormattedDate(collectionList.elementAt(j).date).substring(0,Utils.getFormattedDate(collectionList.elementAt(j).date).length-4);
    }



    getFilteredEggsCollections(str_date, end_date);

    setState(() {

    });

  }

  void getFilteredEggsCollections(String st,String end) async {

    await DatabaseHelper.instance.database;


    eggs = await DatabaseHelper.getFilteredEggs(f_id,"All",st,end);


    setState(() {

    });

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
                          Utils.setupInvoiceInitials("EGGS_REPORT".tr(),pdf_formatted_date_filter);
                          prepareListData();

                           Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 1,)),
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
                              Text(date_filter_name, style: TextStyle(fontSize: 14),),
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
                  child: Column(children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('SUMMARY'.tr(),style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
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
                            series: <CartesianSeries<Eggs_Chart_Item, String>>[

                              ColumnSeries(borderRadius: BorderRadius.all(Radius.circular(10)),color:Colors.green,name: 'Collections',dataSource: collectionList, xValueMapper: (Eggs_Chart_Item collItem, _) => collItem.date, yValueMapper: (Eggs_Chart_Item collItem, _)=> collItem.total,),
                              ColumnSeries(borderRadius: BorderRadius.all(Radius.circular(10)),color:Colors.red,name: 'Reductions',dataSource: reductionList, xValueMapper: (Eggs_Chart_Item collItem, _) => collItem.date, yValueMapper: (Eggs_Chart_Item collItem, _)=> collItem.total,),

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
                        Text('Total Collected'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('$total_eggs_collected',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Used'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('-$total_eggs_reduced',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remaining Eggs'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text('$total_eggs',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: total_eggs>=0 ? Colors.black : Colors.red),),

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
                        child: Text('Collections/Reductions'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),)),
                  ),

                  eggs.length > 0 ? Container(
                    width: widthScreen,
                    height: eggs.length * 115,
                    child: ListView.builder(
                        itemCount: eggs.length,
                        scrollDirection: Axis.vertical,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),
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

                            child: Container(
                              color: Colors.white,
                              height: 100,
                              child: Row( children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    margin: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(margin: EdgeInsets.all(0), child: Text(eggs.elementAt(index).f_name!.tr() + " ", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),
                                                Container(margin: EdgeInsets.all(0), child: Text(eggs.elementAt(index).isCollection == 1? '(Collected)'.tr():'(Reduced)'.tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: eggs.elementAt(index).isCollection == 1? Colors.green:Colors.red),)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Image.asset("assets/eggs_count.png", width: 40, height: 40,),
                                                Container( margin: EdgeInsets.only(right: 5, left: 5), child: Text(eggs.elementAt(index).total_eggs.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 20, color:eggs.elementAt(index).isCollection == 0?Colors.black:Colors.black),)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_month, size: 25,),
                                            Container(margin: EdgeInsets.all(5), child: Text(Utils.getFormattedDate(eggs.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),

                                          ],
                                        ),

                                        // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                      ],),
                                  ),
                                ),


                              ]),
                            ),
                          );

                        }),
                  ) : Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          Text('No Eggs Collected/Reduced in given period'.tr(), style: TextStyle(fontSize: 15, color: Colors.black54),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),),

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



  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String pdf_formatted_date_filter = 'THIS_MONTH'.tr();
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'.tr()){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'TODAY'.tr()+" ("+Utils.getFormattedDate(str_date)+")";

    }
    else if (filter == 'YESTERDAY'.tr()){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";

    }
    else if (filter == 'THIS_MONTH'.tr()){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'THIS_MONTH'.tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST_MONTH'.tr()){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";

    }else if (filter == 'LAST3_MONTHS'.tr()){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST6_MONTHS'.tr()){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'THIS_YEAR'.tr()){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'LAST_YEAR'.tr()){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";

    }else if (filter == 'ALL_TIME'.tr()){
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

  void prepareListData() async {

    int collected = 0, reduced = 0, reserve = 0;

    Utils.egg_report_list.clear();
    Utils.TOTAL_EGG_COLLECTED = total_eggs_collected.toString();
    Utils.TOTAL_EGG_REDUCED = total_eggs_reduced.toString();
    Utils.EGG_RESERVE = total_eggs.toString();


    if(f_id == -1)
    {
       for(int i=0; i<flocks.length; i++){


         collected = await DatabaseHelper.getUniqueEggCalculations(flocks
             .elementAt(i)
             .f_id, 1, str_date, end_date);
         reduced = await DatabaseHelper.getUniqueEggCalculations(flocks
             .elementAt(i)
             .f_id, 0, str_date, end_date);
         reserve = collected - reduced;

         Utils.egg_report_list.add(Egg_Report_Item(f_name: flocks
             .elementAt(i)
             .f_name,
             collected: collected,
             reduced: reduced,
             reserve: reserve));
       }

    } else
    {
      collected = await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);
      reduced = await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);
      reserve = collected - reduced;

      Flock? flock = await getSelectedFlock();

      Utils.egg_report_list.add(Egg_Report_Item(f_name: flock!.f_name, collected: collected, reduced: reduced, reserve: reserve));

    }

  }

  Future<Flock?> getSelectedFlock() async{

    Flock? flock = null;

    for(int i=0;i<flocks.length;i++){
      if(f_id == flocks.elementAt(i).f_id){
        flock = flocks.elementAt(i);
        break;
      }
    }

    return flock;

  }

}

