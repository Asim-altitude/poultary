import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/dashboard.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'add_flocks.dart';
import 'all_reports_screen.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'model/farm_item.dart';
import 'model/flock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreen createState() => _HomeScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _HomeScreen extends State<HomeScreen> {

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();

    _piData.add(_PieData("Income", 2000,'2000'));
    _piData.add(_PieData("Expense", 500,'500'));

    getList();
    getCurrency();
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
  int _selectedTab = 0;

  _changeTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  List _pages = [
    Center(
      child: DashboardScreen(),
    ),
    Center(
      child: ReportsScreen(),
    ),
    Center(
      child: SettingsScreen(),
    ),

  ];


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
      bottomNavigationBar:
    ClipRRect(
    borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
    topRight: Radius.circular(10.0),
    ),
    child:
    BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => _changeTab(index),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Utils.getThemeColorBlue(),

        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.area_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],

      ),),
      body: _pages[_selectedTab])); /*SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
            child:Center(

            child: SingleChildScrollView(

            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Container(
                  margin: EdgeInsets.only(left: 10,top: 20),
                  child: Text(
                    "All FLocks( $flock_total)",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  )),
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
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Add New Flock", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),

              Container(
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
                        child: Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 3,
                          child: Container(
                            height: 130,
                            *//*decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),*//*
                            child: Row( children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  margin: EdgeInsets.all(10),
                                  child: Column( children: [
                                    Container(margin: EdgeInsets.all(5), child: Text(flocks.elementAt(index).f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
                                    Container(margin: EdgeInsets.all(0), child: Text(flocks.elementAt(index).acqusition_type, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                                    Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),

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
                                        Container( margin: EdgeInsets.only(right: 5), child: Text(flocks.elementAt(index).active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
                                        Text("Birds", style: TextStyle(color: Colors.black, fontSize: 16),)
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            ]),
                          ),
                        ),
                      );

                    }),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoryScreen()),
                  );
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Category Set up", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReportsScreen()),
                  );
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Reports", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),
              *//*Center(
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
  }

  void getCurrency() async{
    try {
      await DatabaseHelper.instance.database;

      List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();
      Utils.currency = farmSetup
          .elementAt(0)
          .currency;

    }
    catch(ex){
      print(ex);
    }

  }



}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);
  final String xData;
  final num yData;
  final String? text;
}

