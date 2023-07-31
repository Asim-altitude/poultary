import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/add_expense.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/add_income.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/utils/utils.dart';

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

  @override
  void initState() {
    super.initState();

    getAllTransactions();
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

  int feed_total = 0;

  String applied_filter_name = "Income/Expense";

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
          height: 60,
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
                    Text('Income', style: TextStyle(
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
                    Text('Expense', style: TextStyle(
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
          color: Colors.white,
            child:SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
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

              transactionList.length > 0 ? Container(
                margin: EdgeInsets.only(top: 0),
                height: heightScreen - 200,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: transactionList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          Utils.selected_transaction = transactionList.elementAt(index);
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SingleFlockScreen()),
                        );},
                        child: Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 2,

                          child: Container(
                            height: 130,
                            child: Column(
                              children: [
                                Container(child: Text(style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black), transactionList.elementAt(index).type.toLowerCase().contains("income")? transactionList.elementAt(index).sale_item : transactionList.elementAt(index).expense_item),),
                                Row( children: [
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.all(10),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(right: 10),
                                            child: Row(
                                              children: [
                                                Container(  child: Text(transactionList.elementAt(index).amount.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),)),
                                                Text("USD", style: TextStyle(color: Colors.black, fontSize: 14),)
                                              ],
                                            ),
                                          ),

                                          Container(child: Text(Utils.getFormattedDate(transactionList.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                          // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                        ],),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Container(margin: EdgeInsets.all(5), child: Text(transactionList.elementAt(index).type!, style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color:transactionList.elementAt(index).type!.toLowerCase().contains("income")? Colors.green : Colors.red),)),
                                    ],
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
                        Text('No Income/Expense added', style: TextStyle(fontSize: 18, color: Colors.black),),

                      ],
                    ),
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

  void addNewIncome(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewIncome()),
    );
  }

  void addNewExpense(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewExpense()),
    );
  }
}

