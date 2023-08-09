import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/utils.dart';

import 'birds_report_screen.dart';
import 'model/feed_item.dart';
import 'model/flock.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreen createState() => _ReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ReportsScreen extends State<ReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }




  @override
  void initState() {
    super.initState();
     try
     {
       getList();
       getData(date_filter_name);
     }
     catch(ex){
       print(ex);
     }

  }

  int total_flock_birds = 0;
  int total_birds_added = 0;
  int total_birds_reduced = 0;
  int current_birds = 0;
  int total_eggs = 0;

  int gross_income = 0;
  int total_expense = 0;
  int net_income = 0;

  int vac_count = 0;
  int med_count = 0;
  int total_health_count = 0;

  int total_eggs_collected = 0;
  int total_eggs_reduced = 0;

  int total_feed_consumption = 0;


  void clearValues(){

    total_flock_birds = 0;
    total_birds_reduced = 0;
    total_birds_added = 0;
    current_birds = 0;
    total_eggs_reduced =0;
    total_eggs_collected =0;
    total_eggs =0;

    gross_income = 0;
    total_expense =0;
    net_income =0;

  }

  List<Feeding> feedings = [];

  void getAllData() async{

    clearValues();

    total_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(f_id, str_date, end_date);

    total_birds_added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

    total_birds_reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);

    total_birds_added = total_birds_added + total_flock_birds;
    current_birds = total_birds_added - total_birds_reduced;

    total_eggs_collected = await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);

    total_eggs_reduced = await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);

    total_eggs = total_eggs_collected - total_eggs_reduced;

    feedings = await DatabaseHelper.getTopMostUsedFeeds(f_id, str_date, end_date);

    total_feed_consumption = await DatabaseHelper.getTotalFeedConsumption(f_id, str_date, end_date);

    gross_income = await DatabaseHelper.getTransactionsTotal(f_id, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(f_id, "Expense", str_date, end_date);

    net_income = gross_income - total_expense;

    vac_count = await DatabaseHelper.getHealthTotal(f_id, "Vaccination", str_date, end_date);
    med_count = await DatabaseHelper.getHealthTotal(f_id, "Medication", str_date, end_date);

    total_health_count = med_count + vac_count;

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
          color: Color(0x00D3D3D3),
            child: SingleChildScrollView(
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
                          child: Container(
                              width: 30,
                              height: 30,
                              child: Image.asset("assets/income.png", color: Colors.white,)),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              "All Reports",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        margin: EdgeInsets.only(right: 10),
                        child: Image.asset('assets/pdf_icon.png'),
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
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(5.0)),
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
                                Radius.circular(5.0)),
                            border: Border.all(
                              color:  Colors.deepPurple,
                              width: 2.0,
                            ),
                          ),
                          margin: EdgeInsets.only(right: 10,top: 15,bottom: 5),
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

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BirdsReportsScreen()),
                  );
                },
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.grey,
                  color: Colors.white,
                  margin: EdgeInsets.all(10),
                  child: Container(
                    width: widthScreen,
                     padding: EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.all(Radius.circular(5)),

                     ),
                   child: Column(children: [
                   Align(
                       alignment: Alignment.topLeft,
                       child: Row(
                         children: [

                           Text('Birds Summary',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                         ],
                       )),

                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                     Text('Total Added',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                     Text('$total_birds_added',style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.black),),

                   ],),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Total Reduced',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                         Text('-$total_birds_reduced',style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.red),),

                       ],),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Current Birds',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                         Text('$current_birds',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),),

                       ],)
             ],),),
                ),
              ),

              Card(
                elevation: 2,
                shadowColor: Colors.grey,
                color: Colors.white,
                margin: EdgeInsets.all(10),
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
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('Eggs Summary',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                          ],
                        )),
                    SizedBox(height: 20,width: widthScreen,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Collected',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('$total_eggs_collected',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Used',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('-$total_eggs_reduced',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remaining Eggs',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text('$total_eggs',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: total_eggs>=0 ? Colors.black : Colors.red),),

                      ],)
                  ],),),
              ),

              Card(
                elevation: 2,
                shadowColor: Colors.grey,
                color: Colors.white,
                margin: EdgeInsets.all(10),
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
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('Feed Consumption',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                          ],
                        )),
                    SizedBox(height: 20,width: widthScreen,),
                    Container(
                      height: 100,
                      width: widthScreen,
                      child: ListView.builder(
                          itemCount: feedings.length,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (BuildContext context, int index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(feedings.elementAt(index).feed_name!,style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                                Text(feedings.elementAt(index).quantity! +" kg",style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                              ],);

                          }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Consumption',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text(total_feed_consumption.toString() +" kg",style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),),

                      ],)
                  ],),),
              ),

              Card(
                elevation: 2,
                shadowColor: Colors.grey,
                color: Colors.white,
                margin: EdgeInsets.all(10),
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
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('Income/Expense',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                          ],
                        )),
                    SizedBox(height: 20,width: widthScreen,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gross Income',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('$gross_income',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Expense',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('-$total_expense',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.red),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Income',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text('$net_income',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),),

                      ],)
                  ],),),
              ),

               Card(
                elevation: 2,
                shadowColor: Colors.grey,
                color: Colors.white,
                margin: EdgeInsets.all(10),
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
                    Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          children: [

                            Text('Health Summary',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),),
                          ],
                        )),
                    SizedBox(height: 20,width: widthScreen,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vaccinations',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('$vac_count',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Medications',style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),),
                        Text('$med_count',style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),),

                      ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),
                        Text('$total_health_count',style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),),

                      ],)
                  ],),),
              ),

             /* Container( margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      "View Reports",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: widthScreen, height: 40,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image( image: AssetImage(
                                    'assets/add_reduce.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Stock Report",
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
                          //STOCK REPORT
                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/egg.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Egg Collection Report",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/feed.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Feeding Reports",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/health.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Health Reports",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/income.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Financial Reports",
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

                        }),
                  ],
                ),
              ),*/
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



  List<String> filterList = ['Today','Yesterday','This Month', 'Last Month','Last 3 months', 'Last 6 months','This Year',
    'Last Year','All Time'];

  String date_filter_name = "This Month";
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'Today'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getAllData();
    }
    else if (filter == 'Yesterday'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getAllData();
    }
    else if (filter == 'This Month'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();

    }else if (filter == 'Last Month'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();


    }else if (filter == 'Last 3 months'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();
    }else if (filter == 'Last 6 months'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();
    }else if (filter == 'This Year'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();
    }else if (filter == 'Last Year'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getAllData();
    }else if (filter == 'All Time'){
      index = 8;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-50,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
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

}

