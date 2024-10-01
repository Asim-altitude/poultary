import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_birds.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/view_transaction.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';

class AddReduceFlockScreen extends StatefulWidget {

  AddReduceFlockScreen({Key? key}) : super(key: key);

  @override
  _AddReduceFlockScreen createState() => _AddReduceFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _AddReduceFlockScreen extends State<AddReduceFlockScreen> with SingleTickerProviderStateMixin{

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

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }
    _purposeselectedValue = Utils.selected_flock!.f_name;
    f_id = getFlockID();
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    addNewColumn();

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

  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

  int selected = 1;
  int f_id = -1;

  bool no_colection = true;
  List<Flock_Detail> list = [];
  List<String> flock_name = [];

  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFlockDetails();
    egg_total = list.length;

    setState(() {

    });

  }

  int egg_total = 0;

  String applied_filter_name = "All Additions/Reductions";

  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline_sharp, color: Colors.white, size: 25,),SizedBox(width: 4,),
                    Text('ADD_BIRDS'.tr(), style: TextStyle(
                        color: Colors.white, fontSize: 16),)
                  ],),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  reduceCollection();
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.indeterminate_check_box_outlined, color: Colors.white, size: 25,),SizedBox(width: 4,),
                    Text('REDUCE_BIRDS'.tr(), style: TextStyle(
                        color: Colors.white, fontSize: 16),)
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
                        filter_name ='Addition';
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
                        child: Text('Addition'.tr(), style: TextStyle(
                            color: selected==2 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 3;
                        filter_name ='Reduction';
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
                        child: Text('Reduction'.tr(), style: TextStyle(
                            color: selected==3 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                ],),
              ),

              list.length > 0 ? Container(
                height: heightScreen - 290,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: list.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          },
                        child: Container(
                          margin: EdgeInsets.only(left: 8,right: 8,top: 8,bottom: 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: Offset(0, 1), // changes position of shadow
                              ),
                            ],
                              color: Colors.white,
                          ),
                        child: Container(
                          color: Colors.white,
                          child:Column(
                            children: [
                              list.elementAt(index).transaction_id!= "-1"?Align(
                                alignment: Alignment.topRight,
                                child:
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) async {
                                        selected_id = list.elementAt(index).f_detail_id;
                                        selected_index = index;
                                        if(list.elementAt(selected_index!).transaction_id != "-1") {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>  ViewCompleteTransaction(transaction_id: list.elementAt(selected_index!).transaction_id, isTransaction: false,)),
                                          );

                                          getData(date_filter_name);
                                        }else {
                                          showMemberMenu(
                                              details.globalPosition);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(5),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.all(5),
                                              child: Text('View Details'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w200, color: Utils.getThemeColorBlue()),)),

                                          ],
                                        ),
                                      ),
                                    ),

                                  ],
                                ),)  : Align(
                                alignment: Alignment.topRight,
                                child:
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) async {
                                        selected_id = list.elementAt(index).f_detail_id;
                                        selected_index = index;
                                        if(list.elementAt(selected_index!).transaction_id != "-1") {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>  ViewCompleteTransaction(transaction_id: list.elementAt(selected_index!).transaction_id, isTransaction: false,)),
                                          );

                                          getData(date_filter_name);
                                        }else {
                                          showMemberMenu(
                                              details.globalPosition);
                                        }
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        padding: EdgeInsets.all(5),
                                        child: Image.asset(list.elementAt(index).transaction_id!= "-1"?'assets/view_icon.png':'assets/options.png'),
                                      ),
                                    ),

                                  ],
                                ),) ,
                              Row( children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    padding: EdgeInsets.only(left: 10,right: 10,bottom: 10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,children: [
                                      Row(
                                        children: [
                                          Container(margin: EdgeInsets.all(0), child: Text(list.elementAt(index).f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),)),
                                          Container(margin: EdgeInsets.all(0), child: Text(" ("+list.elementAt(index).item_type.tr()+")", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: list.elementAt(index)!.item_type=='Reduction'? Colors.red:Colors.green),)),
                                        ],
                                      ),
                                      Container(
                                        child: Column(
                                          children: [
                                            Container(
                                              child: Row(
                                                children: [
                                                  Container( margin: EdgeInsets.only(right: 5), child: Text(list.elementAt(index).item_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 20, color:list.elementAt(index).item_type == 'Addition'?Colors.black:Colors.black),)),
                                                  Text("BIRDS".tr(), style: TextStyle(color: Colors.black, fontSize: 12),),
                                                  Text("  "+"ON".tr() , style: TextStyle(color: Utils.getThemeColorBlue(),fontWeight: FontWeight.bold, fontSize: 14),),
                                                  Align(
                                                      alignment: Alignment.topLeft,
                                                      child: Container(margin: EdgeInsets.all(5), child: Text(Utils.getFormattedDate(list.elementAt(index).acqusition_date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      list.elementAt(index).item_type == 'Reduction'? Align(
                                          alignment: Alignment.topLeft,
                                          child: Container( child: Text(list.elementAt(index).reason.toString().toUpperCase(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Utils.getThemeColorBlue()),))) : Align(
                                          alignment: Alignment.topLeft,
                                          child: Container( child: Text(list.elementAt(index).acqusition_type.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Utils.getThemeColorBlue()),))),
                                      // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                    ],),
                                  ),
                                ),

                              ]),
                              Container(
                                margin: EdgeInsets.only(left: 10,right: 10,bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.format_quote,size: 15,),
                                    SizedBox(width: 3,),
                                    Container(
                                      width: widthScreen - 60,
                                      child: Text(
                                        list.elementAt(index).short_note.isEmpty? 'NO_NOTES'.tr() : list.elementAt(index).short_note
                                      ,maxLines: 3, style: TextStyle(fontSize: 14, color: Colors.black),),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ),
                      ),
                      );

                    }),
              ) : Utils.getCustomEmptyMessage("assets/add_reduce_.png", "NO_BIRDS_ADD_REDUCE")


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



  Future<void> addNewCollection() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: true,flock_detail: null)),
    );

    getData(date_filter_name);
    ;
  }

  Future<void> reduceCollection() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: false,flock_detail: null)),
    );

    getData(date_filter_name);
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

            Utils.SELECTED_FLOCK = _purposeselectedValue;
            Utils.SELECTED_FLOCK_ID = getFlockID();
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
            title: Text("DATE_FILTER".tr()),
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


    list = await DatabaseHelper.getFilteredFlockDetails(f_id,filter_name,st,end);


    setState(() {

    });

  }


  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String pdf_formatted_date_filter = 'THIS_MONTH'.tr();
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'.tr()){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Today ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'YESTERDAY'.tr()){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'THIS_MONTH'.tr()){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "This Month ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_MONTH'.tr()){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+str_date+"-"+end_date+")";

    }else if (filter == 'LAST3_MONTHS'.tr()){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST6_MONTHS'.tr()){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+str_date+"-"+end_date+")";
    }else if (filter == 'THIS_YEAR'.tr()){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_YEAR'.tr()){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+str_date+"-"+end_date+")";

    }else if (filter == 'ALL_TIME'.tr()){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'ALL_TIME'.tr();
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


  //RECORD DELETEION AND PDF

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
        ), PopupMenuItem(
          value: 1,
          child: Text(
            list.elementAt(selected_index!).transaction_id!= "-1" ? "VIEW_RECORD".tr() : "DELETE_RECORD".tr(),
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
        if(value == 2){
          if(list.elementAt(selected_index!).item_type == "Addition") {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: true,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }else{
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: false,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }
        }
        else if(value == 1){
          if(list.elementAt(selected_index!).transaction_id != "-1")
          {
            // View Complete Record

            print(selected_index);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  ViewCompleteTransaction(transaction_id: list.elementAt(selected_index!).transaction_id, isTransaction: false,)),
            );

            getData(date_filter_name);
          }
          else
          {
            showAlertDialog(context);
          }
        }else {
          print(value);
        }
      }
    });
  }

  showCautionDialog(BuildContext context) {

    // set up the buttons

    Widget continueButton = TextButton(
      child: Text("VIEW_INFO".tr()),
      onPressed:  () async {

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("INFO".tr()),
      content: Text("MULTIPLE_OPERATIONS".tr()),
      actions: [
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
      onPressed:  () async {
        if(list.elementAt(selected_index!).f_id != -1) {

          if(list.elementAt(selected_index!).transaction_id != "-1"){
            if(list.elementAt(selected_index!).transaction_id.contains(","))
            {
              /*Flock flock = await DatabaseHelper
                    .getSingleFlock(list.elementAt(selected_index!).f_id);
                int active_birds = */

            }else{

              await DatabaseHelper.deleteItem("Transaction",int.parse(list
                  .elementAt(selected_index!).transaction_id));

              int birds_to_delete = list
                  .elementAt(selected_index!)
                  .item_count;
              Flock flock = await DatabaseHelper
                  .getSingleFlock(list
                  .elementAt(selected_index!)
                  .f_id);
              int current_birds = flock.active_bird_count!;

              if (list
                  .elementAt(selected_index!)
                  .item_type == "Addition")
                current_birds = current_birds - birds_to_delete;
              else
                current_birds = current_birds + birds_to_delete;

              await DatabaseHelper.updateFlockBirds(
                  current_birds, list
                  .elementAt(selected_index!)
                  .f_id);
            }
          }else {
            int birds_to_delete = list
                .elementAt(selected_index!)
                .item_count;
            Flock flock = await DatabaseHelper
                .getSingleFlock(list
                .elementAt(selected_index!)
                .f_id);
            int current_birds = flock.active_bird_count!;

            if (list
                .elementAt(selected_index!)
                .item_type == "Addition")
              current_birds = current_birds - birds_to_delete;
            else
              current_birds = current_birds + birds_to_delete;

            await DatabaseHelper.updateFlockBirds(
                current_birds, list
                .elementAt(selected_index!)
                .f_id);
          }

        }
        DatabaseHelper.deleteItem("Flock_Detail", selected_id!);
        list.removeAt(selected_index!);
        Utils.showToast("RECORD_DELETED".tr());
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

