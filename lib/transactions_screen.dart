import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/add_expense.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/add_income.dart';
import 'package:poultary/add_reduce_flock.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/view_transaction.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreen createState() => _TransactionsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _TransactionsScreen extends State<TransactionsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  int _other_filter = 2;
  void getFilters() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    addNewColumn();

    _purposeselectedValue = Utils.selected_flock!.f_name;
    f_id = getFlockID();
    Utils.SELECTED_FLOCK = _purposeselectedValue;
    Utils.SELECTED_FLOCK_ID = f_id;
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    getData(date_filter_name);

  }

  void addNewColumn() async{
    try{
      int c = await DatabaseHelper.addColumnInFlockDetail();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int c = await DatabaseHelper.addColumnInFTransactions();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int? c = await DatabaseHelper.updateLinkedFlocketailNullValue();
      print("Flock Details Update Info $c");

      int? t = await DatabaseHelper.updateLinkedTransactionNullValue();
      print("Transactions Update Info $t");
    }catch(ex){
      print(ex);
    }
  }

  @override
  void initState() {
    super.initState();

    getFilters();
    Utils.setupAds();

  }

  bool no_colection = true;
  List<TransactionItem> transactionList = [];
  List<String> flock_name = [];
  void getAllTransactions() async {

    await DatabaseHelper.instance.database;

    transactionList = await DatabaseHelper.getAllTransactions();


    feed_total = transactionList.length;

    setState(() {

    });

  }

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    transactionList = await DatabaseHelper.getFilteredTransactions(f_id,filter_name,st,end);

    feed_total = transactionList.length;

    setState(() {

    });

  }

  int feed_total = 0;
  String applied_filter_name = "INCOME_EXPENSE";
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];


  int selected = 1;
  int f_id = -1;

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
        child: Container(
          height: 50,
          width: widthScreen,
          child: Row(children: [

            Expanded(
              child: InkWell(
                onTap: () {
                  addNewIncome();
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
                    Text('Income'.tr(), style: TextStyle(
                        color: Colors.white, fontSize: 18),)
                  ],),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  addNewExpense();
                },
                child: Container(
                  height: 50,
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(5.0)),
                    border: Border.all(
                      color:  Colors.red,
                      width: 2.0,
                    ),
                  ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add, color: Colors.white, size: 30,),
                    Text('Expense'.tr(), style: TextStyle(
                        color: Colors.white, fontSize: 18),)
                  ],),
                ),
              ),
            ),
          ],),
        ),
        elevation: 0,
      ),
      body:SafeArea(
        top: false,
          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getScreenBackground(),
            child:SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
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
                      Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            applied_filter_name.tr(),
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
                      margin: EdgeInsets.only(top: 10,left: 10,right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(10.0)),
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
                                Radius.circular(10.0)),
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
                height: 50,
                width: widthScreen ,
                margin: EdgeInsets.only(left: 10,right: 10,bottom: 5),
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
                    color: selected == 1 ? Utils.getThemeColorBlue() : Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10)
                    ,bottomLeft: Radius.circular(10)),
                    border: Border.all(
                      color:  Utils.getThemeColorBlue(),
                      width: 1.0,
                    ),
                  ),
                  child: Text('All'.tr(), style: TextStyle(
                      color: selected==1 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                ),
              ),
      ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 2;
                        filter_name ='Income';
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==2 ? Utils.getThemeColorBlue() : Colors.white,

                          border: Border.all(
                            color: Utils.getThemeColorBlue(),
                            width: 1.0,
                          ),
                        ),
                        child: Text('Income'.tr(), style: TextStyle(
                           color: selected==2 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 3;
                        filter_name ='Expense';
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==3 ? Utils.getThemeColorBlue() : Colors.white,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(10)
                              ,bottomRight: Radius.circular(10)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 1.0,
                          ),
                        ),
                        child: Text('Expense'.tr(), style: TextStyle(
                            color: selected==3 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                ],),
              ),
              
              transactionList.length > 0 ? Container(
                margin: EdgeInsets.only(top: 0,bottom: 200),
                height: heightScreen -300,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: transactionList.length,
                    scrollDirection: Axis.vertical,
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
                          padding: EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child:
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                        selected_id = transactionList.elementAt(index).id;
                                        selected_index = index;
                                        showMemberMenu(details.globalPosition);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        padding: EdgeInsets.all(5),
                                        child: Image.asset('assets/options.png'),
                                      ),
                                    ),

                                  ],
                                ),),
                              /*(transactionList.elementAt(index).flock_update_id.isEmpty || transactionList.elementAt(index).flock_update_id != "-1")? Align(
                                alignment: Alignment.topRight,
                                child:
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                         showInfoMessage(context);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(5),
                                        child: Text('Auto Generated'.tr(), style: TextStyle(fontWeight: FontWeight.w300, color: Colors.red),),
                                      ),
                                    ),

                                  ],
                                ),) : SizedBox(width: 1,),*/
                              Align(
                                alignment: Alignment.centerLeft,
                              child:Container(child: Text( textAlign:TextAlign.left,style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()), transactionList.elementAt(index).type == 'Income'? transactionList.elementAt(index).sale_item.tr() : transactionList.elementAt(index).expense_item.tr()),),),
                              Row(
                                children: [
                                  Container(child: Text(style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black), transactionList.elementAt(index).f_name.tr(),)),
                                  Container(child: Text(style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black), "("+transactionList.elementAt(index).how_many+" Items)",)),

                                ],
                              ),

                              Row( children: [
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(  child: Text(transactionList.elementAt(index).type!.toLowerCase() == 'income'? 'Sold To'.tr()+":":'Paid To'.tr()+":", style: TextStyle(fontSize: 14, color: Colors.black),)),
                                            Text(transactionList.elementAt(index).sold_purchased_from, style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black, fontSize: 14),),
                                            Text(" On ".tr(), style: TextStyle(color: Colors.black, fontSize: 14),),
                                            Container(child: Text(Utils.getFormattedDate(transactionList.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),

                                          ],
                                        ),

                                        Container(
                                          margin: EdgeInsets.only(right: 10,top: 5),
                                          child: Row(
                                            children: [
                                              Container(  child: Text(transactionList.elementAt(index).type!.tr()+": ", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: transactionList.elementAt(index).type!.toLowerCase() == 'income'? Colors.green: Colors.red),)),

                                              Container( margin: EdgeInsets.only(left: 5),  child: Text(transactionList.elementAt(index).amount.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                                              Text(Utils.currency, style: TextStyle(color: Colors.black, fontSize: 14),),
                                              Text(" ("+transactionList.elementAt(index).payment_status.toUpperCase().tr()+")", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black, fontSize: 14),)

                                            ],
                                          ),
                                        ),

                                        Container(
                                          margin: EdgeInsets.only(top: 5),
                                          child: Row(
                                            children: [
                                              Icon(Icons.format_quote,size: 15,),
                                              SizedBox(width: 3,),
                                              Container(
                                                width: widthScreen-70,
                                                child: Text(
                                                  transactionList.elementAt(index).short_note!.isEmpty ? 'NO_NOTES'.tr() : transactionList.elementAt(index).short_note!
                                                  ,maxLines: 3, style: TextStyle(fontSize: 14, color: Colors.black),),
                                              ),
                                            ],
                                          ),
                                        )
                                        // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                      ],),
                                  ),
                                ),

                              ]),
                            ],
                          ) ,
                        ),
                      );

                    }),
              ) : Utils.getCustomEmptyMessage("assets/pfinance.png", "No Income/Expense added")

                   /* Text(
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
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//*
                  }),*/
                  ]
      ),),),),),);
  }

  Future<void> addNewIncome() async {
    var txt = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewIncome(transactionItem: null,)),
    );

    getData(date_filter_name);
  }

  Future<void> addNewExpense() async{
   var txt = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewExpense(transactionItem: null,)),
    );

   getData(date_filter_name);
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

            f_id = getFlockID();
            Utils.SELECTED_FLOCK = newValue;
            Utils.SELECTED_FLOCK_ID = f_id;
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
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }
    getFilteredTransactions(str_date, end_date);

  }

  int? selected_id = 0;
  int? selected_index = 0;
  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),

      items: [
        PopupMenuItem(
          value: 2,
          child: Text(
            "EDIT_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            transactionList.elementAt(selected_index!).flock_update_id!= "-1" ? "VIEW_RECORD".tr() : "DELETE_RECORD".tr(),

            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),

      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 2) {


          if(transactionList.elementAt(selected_index!).type == "Income") {
            var txt = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  NewIncome(transactionItem: transactionList.elementAt(selected_index!),)),
            );

            getAllTransactions();
          }else{
            var txt = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  NewExpense(transactionItem: transactionList.elementAt(selected_index!),)),
            );

            getAllTransactions();
          }
        }
        else if(value == 1){
          if(transactionList.elementAt(selected_index!).flock_update_id!= "-1"){
            print(selected_index);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  ViewCompleteTransaction(transaction_id: transactionList.elementAt(selected_index!).id.toString(), isTransaction: true,)),
            );

            getData(date_filter_name);
          }else {
            showAlertDialog(context);
          }
        }else {
          print(value);
        }
      }
    });
  }

  showInfoMessage(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Take Action".tr()),
      onPressed:  () async {

       // Utils.selected_flock = await DatabaseHelper.getSingleFlock(transactionList.elementAt(selected_index!).f_id!);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>  AddReduceFlockScreen()),
        );

        getData(date_filter_name);
        Navigator.pop(context);

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Auto Generated".tr()),
      content: Text("AUTO_GENERATED_TRANS".tr()),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DELETE".tr()),
      onPressed:  () {
        DatabaseHelper.deleteItem("Transactions", selected_id!);
        transactionList.removeAt(selected_index!);
        Utils.showToast("DONE".tr());
        Navigator.pop(context);
        setState(() {

        });


      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Text("RU_SURE".tr()),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

}

