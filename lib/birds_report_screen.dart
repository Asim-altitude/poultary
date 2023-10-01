import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'model/feed_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/flock_report_item.dart';

class BirdsReportsScreen extends StatefulWidget {
  const BirdsReportsScreen({Key? key}) : super(key: key);

  @override
  _BirdsReportsScreen createState() => _BirdsReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _BirdsReportsScreen extends State<BirdsReportsScreen> with SingleTickerProviderStateMixin{

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
       date_filter_name = Utils.applied_filter;
       getList();

       getData(date_filter_name);
     }
     catch(ex){
       print(ex);
     }

  }

  List<Flock_Detail> list = [];
  List<String> flock_name = [];

  int egg_total = 0;

  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFlockDetails();

    egg_total = list.length;

    setState(() {

    });

  }

  int total_flock_birds = 0;
  int total_birds_added = 0;
  int total_birds_reduced = 0;
  int current_birds = 0;



  void clearValues(){

    total_flock_birds = 0;
    total_birds_reduced = 0;
    total_birds_added = 0;
    current_birds = 0;
    list = [];

  }

  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    total_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(f_id, str_date, end_date);

    total_birds_added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

    total_birds_reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);

    total_birds_added = total_birds_added + total_flock_birds;
    current_birds = total_birds_added - total_birds_reduced;

    getFilteredBirds(str_date, end_date);

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
           color: Utils.getScreenBackground(),
            child: SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
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
                              "Birds Report",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      InkWell(
                        onTap: (){
                          Utils.setupInvoiceInitials("Flock Report",pdf_formatted_date_filter);
                          prepareListData();

                          Utils.TOTAL_BIRDS_ADDED = total_birds_added.toString();
                          Utils.TOTAL_BIRDS_REDUCED = total_birds_reduced.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 0,)),
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

              Card(
                elevation: 10,
                shadowColor: Colors.blue,
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

                         Text('Summary',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
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
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                    margin: EdgeInsets.all(10),
                    child: Text('Addition/Reductions',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),)),
              ),

              list.length > 0 ? Container(
                height: heightScreen - 220,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: list.length,
                    scrollDirection: Axis.vertical,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),

                              color: Colors.white,
                              border: Border.all(color: Colors.blueAccent,width: 1.0)
                          ),

                          child: Container(
                            height: 130,
                            color: Colors.white,
                            child: Row( children: [
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,children: [
                                    Row(
                                      children: [
                                        Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index)!.f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),
                                        Container(margin: EdgeInsets.all(0), child: Text(" ("+list.elementAt(index)!.item_type+")", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: list.elementAt(index)!.item_type=='Reduction'? Colors.red:Colors.black),)),
                                      ],
                                    ),
                                    Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(margin: EdgeInsets.all(5), child: Text(Utils.getFormattedDate(list.elementAt(index).acqusition_date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),))),
                                    list.elementAt(index).item_type == 'Reduction'? Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(margin: EdgeInsets.all(5), child: Text(list.elementAt(index).reason.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),))) : Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(margin: EdgeInsets.all(5), child: Text(list.elementAt(index).acqusition_type.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),))),
                                    // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                  ],),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    color: Colors.white,
                                    child: Row(
                                      children: [
                                        Container( margin: EdgeInsets.only(right: 5), child: Text(list.elementAt(index).item_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color:list.elementAt(index).item_type == 'Addition'?Colors.black:Colors.black),)),
                                        Text("Birds", style: TextStyle(color: Colors.black, fontSize: 12),)
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
                      Text('No Birds Added/Reduced in given period', style: TextStyle(fontSize: 15, color: Colors.black54),),
                    ],
                  ),
                ),
              ),

            ]
      ),),),),),);
  }

  void getFilteredBirds(String st,String end) async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFilteredFlockDetails(f_id,"All",st,end);

    setState(() {

    });

  }

  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Form Wide',bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

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
  String pdf_formatted_date_filter = "This Month";
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

      pdf_formatted_date_filter = "Today ("+str_date+")";

    }
    else if (filter == 'Yesterday'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Yesterday ("+Utils.getFormattedDate(str_date)+")";

    }
    else if (filter == 'This Month'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "This Month ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+")";
    }else if (filter == 'Last Month'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Last Month ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+"))";

    }else if (filter == 'Last 3 months'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "Last 3 months ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+"))";
    }else if (filter == 'Last 6 months'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "Last 6 months ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+"))";
    }else if (filter == 'This Year'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "This Year ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+"))";
    }else if (filter == 'Last Year'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Last Year ("+Utils.getFormattedDate(str_date)+" to "+Utils.getFormattedDate(end_date)+"))";

    }else if (filter == 'All Time'){
      index = 8;
      str_date ="";
      end_date ="";
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "All Time (START to END)";
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

  void prepareListData() async{

    List<Flock_Report_Item> list = [];
    int? added = 0,reduced = 0,init_flock_birds = 0,active_birds = 0,total_added =0,total_reduced=0;

    if(f_id == -1) {
      for (int i = 0; i < flocks.length; i++) {
        if (flocks
            .elementAt(i)
            .f_id != -1) {
          init_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(flocks
              .elementAt(i)
              .f_id, str_date, end_date);

          added = await DatabaseHelper.getBirdsCalculations(flocks
              .elementAt(i)
              .f_id, "Addition", str_date, end_date);

          reduced = await DatabaseHelper.getBirdsCalculations(flocks
              .elementAt(i)
              .f_id, "Reduction", str_date, end_date);

          list.add(Flock_Report_Item(f_name: flocks
              .elementAt(i)
              .f_name,
              date: flocks
                  .elementAt(i)
                  .acqusition_date,
              active_bird_count: flocks
                  .elementAt(i)
                  .active_bird_count,
              addition: (added + init_flock_birds),
              reduction: reduced));

           total_added = total_added! + init_flock_birds! + added;
           total_reduced = total_reduced! + reduced;
          active_birds = active_birds! + flocks
              .elementAt(i)
              .active_bird_count!;
        }
      }
    }else{
      init_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(f_id, str_date, end_date);

      added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

      reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);

      Flock? f = await getSelectedFlock();

      list.add(Flock_Report_Item(f_name: f!.f_name,
          date: f!
              .acqusition_date,
          active_bird_count: f!
              .active_bird_count,
          addition: (added + init_flock_birds),
          reduction: reduced));

       total_added = total_added! + init_flock_birds! + added;
        total_reduced = total_reduced! + reduced;
      active_birds = f!
          .active_bird_count!;
    }
    Utils.TOTAL_ACTIVE_BIRDS = active_birds.toString();
    Utils.TOTAL_BIRDS_ADDED = total_added.toString();
    Utils.TOTAL_BIRDS_REDUCED = total_reduced.toString();
    Utils.flock_report_list = list;

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

