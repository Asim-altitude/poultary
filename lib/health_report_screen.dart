import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'model/egg_item.dart';
import 'model/feed_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/health_report_item.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({Key? key}) : super(key: key);

  @override
  _HealthReportScreen createState() => _HealthReportScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _HealthReportScreen extends State<HealthReportScreen> with SingleTickerProviderStateMixin{

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

  List<Vaccination_Medication> list = [];
  List<String> flock_name = [];

  int egg_total = 0;

  int vac_count = 0;
  int med_count = 0;
  int total_health_count = 0;

  void clearValues(){

     vac_count = 0;
     med_count = 0;
     total_health_count = 0;
     list = [];

  }

  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    vac_count = await DatabaseHelper.getHealthTotal(f_id, "Vaccination", str_date, end_date);
    med_count = await DatabaseHelper.getHealthTotal(f_id, "Medication", str_date, end_date);

    total_health_count = med_count + vac_count;

    getFilteredTransactions(str_date, end_date);

    setState(() {

    });

  }

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    list = await DatabaseHelper.getFilteredMedication(f_id,"All",st,end);

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
                              "Birds Health Report",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      InkWell(
                        onTap: () {
                          Utils.setupInvoiceInitials("Birds Health Report",pdf_formatted_date_filter);
                          prepareListData();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 4,)),
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

                            Text('Health Summary',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
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
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                    margin: EdgeInsets.all(10),
                    child: Text('Medications/Vaccinations',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),)),
              ),

              list.length > 0 ? Container(
                height: heightScreen - 120,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: list.length,
                    scrollDirection: Axis.vertical,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(3)),

                            color: Colors.white,
                            border: Border.all(color: Colors.blueAccent,width: 1.0)
                        ),

                        child: Container(
                          color: Colors.white,
                          child: Row( children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.all(10),
                                child: Column( children: [
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).medicine!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),)),
                                      Container(margin: EdgeInsets.all(0), child: Text("("+list.elementAt(index).f_name!+")", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Utils.getThemeColorBlue()),)),

                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).type == 'Medication'?'Medicated by: ':'Vaccinated by: ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                      Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).doctor_name!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),

                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.all(0), child: Text('Disease: ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                      Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).disease!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),

                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).type == 'Medication'?'Medicated on: ':'Vaccinated on: ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                      Container(margin: EdgeInsets.all(5), child: Text(Utils.getFormattedDate(list.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),

                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Row(
                                      children: [
                                        Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).type == 'Medication'? 'Medicated birds: ':'Vaccinated birds: ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                        Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).bird_count!.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),

                                      ],
                                    ),
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
                      Text('No Medications/Vaccinations in given period', style: TextStyle(fontSize: 15, color: Colors.black54),),
                    ],
                  ),
                ),
              ),
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

  String date_filter_name = "This Month",pdf_formatted_date_filter = "This Month";
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

    if(filter == 'Today' || filter == 'Yesterday'){
      pdf_formatted_date_filter = filter +"("+str_date+")";
    }else{
      pdf_formatted_date_filter = filter +"("+str_date+" to "+end_date+")";
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

  void prepareListData() {

    Utils.TOTAL_MEDICATIONS = med_count.toString();
    Utils.TOTAL_VACCINATIONS = vac_count.toString();

    Utils.medication_report_list.clear();
    Utils.vaccine_report_list.clear();
    for(int i=0;i<list.length;i++){

      Vaccination_Medication vaccination_medication = list.elementAt(i);
      if(vaccination_medication.type == 'Medication'){
        Utils.medication_report_list.add(Health_Report_Item(f_name: vaccination_medication.f_name, date: Utils.getFormattedDate(vaccination_medication.date), medicine_name: vaccination_medication.medicine, disease_name: vaccination_medication.disease, birds: vaccination_medication.bird_count.toString()));
      }else{
        Utils.vaccine_report_list.add(Health_Report_Item(f_name: vaccination_medication.f_name, date: Utils.getFormattedDate(vaccination_medication.date), medicine_name: vaccination_medication.medicine, disease_name: vaccination_medication.disease, birds: vaccination_medication.bird_count.toString()));

      }
    }

  }

}

