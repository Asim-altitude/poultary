import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class DailyFeedScreen extends StatefulWidget {
  const DailyFeedScreen({Key? key}) : super(key: key);

  @override
  _DailyFeedScreen createState() => _DailyFeedScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _DailyFeedScreen extends State<DailyFeedScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();

    getList();
    getEggCollectionList();
  }

  bool no_colection = true;
  List<Feeding> feedings = [];
  List<String> flock_name = [];
  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    feedings = await DatabaseHelper.getAllFeedings();


    feed_total = feedings.length;

    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = "All Feedings";

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
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            addNewCollection();
          },
          child: Container(
            height: 50,
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: const BorderRadius.all(
                  Radius.circular(5.0)),
              border: Border.all(
                color:  Colors.green,
                width: 2.0,
              ),
            ),
            child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, color: Colors.white, size: 30,),
              Text('New Feeding', style: TextStyle(
                  color: Colors.white, fontSize: 18),)
            ],),
          ),
        ),
      ),
      body:SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
            child:SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [

              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
                child: Container(
                  decoration: BoxDecoration(
                     boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple, //(x,y)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 60,
                        height: 60,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            applied_filter_name,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          )),

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
                      margin: EdgeInsets.only(top: 10,left: 25,right: 5),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(10.0)),
                        border: Border.all(
                          color:  Colors.deepPurple,
                          width: 2.0,
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
                            color: Colors.transparent,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(10.0)),
                            border: Border.all(
                              color:  Colors.deepPurple,
                              width: 2.0,
                            ),
                          ),
                          margin: EdgeInsets.only(right: 30,top: 15,bottom: 5),
                          padding: EdgeInsets.only(left: 5,right: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(date_filter_name, style: TextStyle(fontSize: 14),),
                              Icon(Icons.arrow_drop_down, color: Colors.deepPurple,),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
              /*Container(
                height: 50,
                width: widthScreen ,
                margin: EdgeInsets.only(left: 25,right: 25,bottom: 5),
                child: Row(children: [

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 1;
                        filter_name ='All';
                        getFilteredTransactions(str_date, end_date);
                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected == 1 ? Colors.deepPurple : Colors.transparent,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)
                              ,bottomLeft: Radius.circular(10)),
                          border: Border.all(
                            color:  Colors.deepPurple,
                            width: 2.0,
                          ),
                        ),
                        child: Text('All', style: TextStyle(
                            color: selected==1 ? Colors.white : Colors.deepPurple, fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 2;
                        isCollection = 1;
                        filter_name ='Medication';
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==2 ? Colors.deepPurple : Colors.transparent,


                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 2.0,
                          ),
                        ),
                        child: Text('Medication', style: TextStyle(
                            color: selected==2 ? Colors.white : Colors.deepPurple, fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 3;
                        filter_name ='Vaccination';
                        isCollection = 0;
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==3 ? Colors.deepPurple : Colors.transparent,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(10)
                              ,bottomRight: Radius.circular(10)),
                          border: Border.all(
                            color:  Colors.deepPurple,
                            width: 2.0,
                          ),
                        ),
                        child: Text('Vaccination', style: TextStyle(
                            color: selected==3 ? Colors.white : Colors.deepPurple, fontSize: 14),),
                      ),
                    ),
                  ),
                ],),
              )*/
              feedings.length > 0 ? Container(
                height: heightScreen - 220,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: feedings.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          Utils.selected_feeding = feedings.elementAt(index);
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SingleFlockScreen()),
                        );},
                        child: Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 3,
                          child: Container(
                            height: 100,
                            /*decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),*/
                            child: Row( children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  margin: EdgeInsets.all(10),
                                  child: Column(children: [
                                    Row(
                                      children: [
                                        Container(margin: EdgeInsets.all(0), child: Text(feedings.elementAt(index).feed_name!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),)),
                                        Container(margin: EdgeInsets.all(0), child: Text(" ("+feedings.elementAt(index).f_name!+")", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),

                                      ],
                                    ),

                                    Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(margin: EdgeInsets.all(5), child: Text(Utils.getFormattedDate(feedings.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),))),
                                   // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                  ],),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Row(
                                      children: [
                                        Container(  child: Text(feedings.elementAt(index).quantity.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),)),
                                        Text("kg", style: TextStyle(color: Colors.black, fontSize: 16),)
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
              ) : Center(
                child: Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Text('No Feedings added', style: TextStyle(fontSize: 18, color: Colors.black),),
                    ],
                  ),
                ),
              ),

                   /* Text(
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
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiRepeatScreen()),
                    );*//*
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
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiScreen()),
                    );*//*
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
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//*
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
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//*
                  }),*/
                  ]
      ),),),),),);
  }

  Future<void> addNewCollection() async{
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewFeeding()),
    );

    getFilteredTransactions(str_date, end_date);
  }



  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Form Wide',bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0));

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
            getFilteredTransactions(str_date, end_date);

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

  String filter_name = "All";
  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('Date Filter'),
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

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    feedings = await DatabaseHelper.getFilteredFeeding(f_id,filter_name,st,end);

    setState(() {

    });

  }


  List<String> filterList = ['Today','Yesterday','This Month', 'Last Month','Last 3 months', 'Last 6 months','This Year',
    'Last Year','All Time'];

  String date_filter_name = "This Month";
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'Today'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'Yesterday'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'This Month'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

    }else if (filter == 'Last Month'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);


    }else if (filter == 'Last 3 months'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
    }else if (filter == 'Last 6 months'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
    }else if (filter == 'This Year'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
    }else if (filter == 'Last Year'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
    }else if (filter == 'All Time'){
      index = 8;
      str_date ="";
      end_date ="";
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
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
}

