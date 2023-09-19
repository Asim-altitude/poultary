import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'add_flocks.dart';
import 'all_reports_screen.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'model/flock.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreen createState() => _DashboardScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _DashboardScreen extends State<DashboardScreen> {

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();


    getData();
    getList();
  }

  String str_date='',end_date='';
  void getData() async{

    await DatabaseHelper.instance.database;

    DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);
    DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

    var inputFormat = DateFormat('yyyy-MM-dd');
    str_date = inputFormat.format(firstDayCurrentMonth);
    end_date = inputFormat.format(lastDayCurrentMonth);

    gross_income = await DatabaseHelper.getTransactionsTotal(-1, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(-1, "Expense", str_date, end_date);

    net_income = gross_income - total_expense;

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
      print('No Flocks');
    }

    flock_total = flocks.length;

    setState(() {

    });

  }

  List<_PieData> _piData =[];

  int flock_total = 0;


  int gross_income = 0;
  int total_expense = 0;
  int net_income = 0;

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
              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                child: Container(
                  width: widthScreen,
                  height: 52,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Utils.getThemeColorBlue()
                      ),
                    ],
                  ),
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
                              "Poultary Dashboard",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),),

                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(16),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  color: Colors.white,
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
                  Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Financial Summary ',style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Utils.getThemeColorBlue()),),
                        ],
                      )),
                  Text('(This month)',style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black),),

                  SizedBox(height: 10,width: widthScreen,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width:140,
                        child:Align(
                          alignment: Alignment.centerLeft,
                          child:Text('Gross Income',style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black),),

                        ),),

                      Container(
                        width:140,
                        child:Align(
                          alignment: Alignment.centerRight,
                        child:Text('$gross_income'+ Utils.currency,style: TextStyle(fontSize: 19, fontWeight: FontWeight.normal, color: Colors.black),),

                      ),),
                    ],),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width:140,
                        child:Align(
                          alignment: Alignment.centerLeft,
                          child:Text('Gross Expense',style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black),),

                        ),),

                      Container(
                        width:140,
                        child:Align(
                          alignment: Alignment.centerRight,
                          child:Text('-$total_expense'+ Utils.currency,style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.red),),

                        ),),


                    ],),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Net Income',style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),),
                      Text('$net_income'+ Utils.currency,style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: net_income>=0? Utils.getThemeColorBlue():Colors.red),),

                    ],)
                ],),),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('All Flocks ',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                            Text("(" + flocks.length.toString() + ")",style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),

                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ADDFlockScreen()),
                            );

                            getList();

                          },
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 130,
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Utils.getThemeColorBlue(),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(30.0)),
                                    border: Border.all(
                                      color:  Utils.getThemeColorBlue(),
                                      width: 2.0,
                                    ),
                                  ),child: Text("+New Flock", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.white),))),
                        ),


                      ],
                    )),
              ),
              SizedBox(height: 8,),
              flocks.length > 0 ? Container(
                height: heightScreen/2,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: flocks.length,
                    scrollDirection: Axis.vertical,
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

                        },
                        child:Container(
                          margin: EdgeInsets.only(left: 16,right: 16,top: 8,bottom: 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),

                              color: Colors.white,
                              border: Border.all(color: Colors.blueAccent,width: 1.0)
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
                                        Text("Birds", style: TextStyle(color: Colors.black, fontSize: 14),)
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
              ) : Container(
                  alignment:  Alignment.center,
                  margin: EdgeInsets.only(top: 20),
                  child: Text('No Flocks Added Yet.',style: TextStyle( fontSize: 14,color: Colors.black),)),
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
                  color: Colors.deepPurple,
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
                              color: Colors.deepPurple,
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
                        color: Colors.deepPurple,
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
                        color: Colors.deepPurple,
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
                        color: Colors.deepPurple,
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
                        color: Colors.deepPurple,
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



}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);
  final String xData;
  final num yData;
  final String? text;
}

