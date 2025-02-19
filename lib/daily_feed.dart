import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auto_feed_management.dart';
import 'database/databse_helper.dart';
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

  bool isAutoFeedEnabled = false;

  @override
  void dispose() {
    super.dispose();

  }

  int _other_filter = 2;
  void getFilters() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();
    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    if(Utils.selected_flock != null)
      _purposeselectedValue = Utils.selected_flock!.f_name;
    else {
      _purposeselectedValue = _purposeList[0];
      Utils.selected_flock = flocks[0];
    }
    f_id = getFlockID();

    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

    getData(date_filter_name);

  }

  Future<void> _addManualFeedingRecord() async {
    // Check if automatic feed management is turned on
    if (isAutoFeedEnabled) {
      // Show bottom dialog asking for confirmation
      bool? shouldProceed = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Automatic Feed Enabled".tr(), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color: Utils.getThemeColorBlue()),),
                SizedBox(height: 20,),
                Text(
                  'auto_feed_msg'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false); // User cancels
                      },
                      child: Text("CANCEL".tr(), style: TextStyle(color: Colors.grey),),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        addNewCollection();// User proceeds
                      },
                      child: Text("Still Proceed".tr()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      // If user cancels, return early
      if (shouldProceed == false) {
        return;
      }
    }else{
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>  NewFeeding()),
      );
    }

    // Proceed with adding the manual feeding record
    // Your logic for adding manual feeding record here
    print("Adding manual feeding record...");

  }


  @override
  void initState() {
    super.initState();
    getFilters();

    Utils.setupAds();

  }

  bool no_colection = true;
  List<Feeding> feedings = [], tempFeed = [];
  List<String> flock_name = [];
  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    tempFeed = await DatabaseHelper.getAllFeedings();
    feedings = tempFeed.reversed.toList();
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
            _addManualFeedingRecord();
          },
          child: Container(
            height: 50,
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Utils.getThemeColorBlue(),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: Offset(0, 1), // changes position of shadow
                ),
              ],
              borderRadius: const BorderRadius.all(
                  Radius.circular(5.0)),
              border: Border.all(
                color:  Utils.getThemeColorBlue(),
                width: 2.0,
              ),
            ),
            child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, color: Colors.white, size: 30,),
              Text('NEW_FEEDING'.tr(), style: TextStyle(
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
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              applied_filter_name.tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      InkWell(
                        onTap: () {
                          openSortDialog(context, (selectedSort) {
                            setState(() {
                              sortOption = selectedSort == "date_desc"
                                  ? "Date (New)"
                                  : "Date (Old)";
                              sortSelected = selectedSort == "date_desc"
                                  ? "DESC" : "ASC";
                            });

                            getFilteredTransactions(str_date, end_date);

                          });
                        },
                        child: Container(
                          height: 50,
                          width: 130,
                          color: Colors.white.withAlpha(40),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(sortOption, style: TextStyle(fontSize: 12, color: Colors.white))),
                              Icon(Icons.sort, color: Colors.white),

                            ],
                          ),
                        ),
                      ),

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
                          color: selected == 1 ? Utils.getThemeColorBlue() : Colors.transparent,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)
                              ,bottomLeft: Radius.circular(10)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('All', style: TextStyle(
                            color: selected==1 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
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
                          color: selected==2 ? Utils.getThemeColorBlue() : Colors.transparent,


                          border: Border.all(
                            color: Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('Medication', style: TextStyle(
                            color: selected==2 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
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
                          color: selected==3 ? Utils.getThemeColorBlue() : Colors.transparent,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(10)
                              ,bottomRight: Radius.circular(10)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('Vaccination', style: TextStyle(
                            color: selected==3 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                ],),
              )*/
              Visibility(
                visible: !isAutoFeedEnabled,
                child: InkWell(
                  onTap: () async {
                   await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  AutomaticFeedManagementScreen()),
                    );

                   SharedPreferences prefs = await SharedPreferences.getInstance();
                   isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

                   setState(() {

                   });

                  },
                  child: Container(height: 60,
                    width: widthScreen,
                    margin: EdgeInsets.all(10.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
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
                    child: Row(
                      children: [
                        Expanded(child: Text('Automatic Feed Management'.tr(), style: TextStyle(color: Utils.getThemeColorBlue(), fontSize: 15, fontWeight: FontWeight.w600),)),
                        Icon(Icons.arrow_forward_ios_rounded, color: Utils.getThemeColorBlue(), size: 30,)
                      ],
                    ),
                  ),
                ),
              ),
              feedings.length > 0 ? Container(
                height: heightScreen - (isAutoFeedEnabled? 50:100),
                width: widthScreen,

                child: ListView.builder(
                    itemCount: feedings.length,
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.only(bottom: 250),
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.only(left: 10, right: 10, top:  10),
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
                          child: Row( children: [
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.all(10),
                                child: Column(children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child:
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTapDown: (TapDownDetails details) {
                                            selected_id = feedings.elementAt(index).id;
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
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.all(0), child: Text(feedings.elementAt(index).feed_name!.tr(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),)),
                                      Container(margin: EdgeInsets.all(0), child: Text(" ("+feedings.elementAt(index).f_name!.tr()+")", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Row(
                                      children: [
                                        Container(margin: EdgeInsets.all(0), child: Text('Consumption'.tr()+': ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                        Container(  child: Text(feedings.elementAt(index).quantity.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),
                                        Text("KG".tr(), style: TextStyle(color: Colors.black, fontSize: 16),)
                                      ],
                                    ),
                                  ),
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Row(
                                        children: [
                                          Container(margin: EdgeInsets.all(0), child: Text('DATE'.tr()+': ', style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),

                                          Container(margin: EdgeInsets.only(left: 5), child: Text(Utils.getFormattedDate(feedings.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                                        ],
                                      )),

                                  Container(
                                    margin: EdgeInsets.all(5),
                                    child: Row(
                                      children: [
                                        Icon(Icons.format_quote,size: 15,),
                                        SizedBox(width: 3,),
                                        Container(
                                          width: widthScreen-70,
                                          child: Text(
                                            feedings.elementAt(index).short_note!.isEmpty ? 'NO_NOTES'.tr() : feedings.elementAt(index).short_note!
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
                        ),
                      );

                    }),
              ) : Utils.getCustomEmptyMessage("assets/pfeed.png", "NO_FFEDING")

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
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewFeeding()),
    );

    getFilteredTransactions(str_date, end_date);
  }



  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

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

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;

    feedings = await DatabaseHelper.getFilteredFeedingWithSort(f_id,filter_name,st,end,sortSelected);
    //feedings = tempFeed.reversed.toList();
    setState(() {

    });

  }


  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();

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

  int getFlockID() {


    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }

  int? selected_id = 0;
  int? selected_index = 0;
  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      color: Colors.white,
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
            "DELETE_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),


      ],
      elevation: 8.0,
    ).then((value) async{
      if (value != null) {
        if(value == 2){
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewFeeding(feeding: feedings.elementAt(selected_index!),)),
          );

          getFilteredTransactions(str_date, end_date);
        }
        else if(value == 1){
          showAlertDialog(context);
        }else {
          print(value);
        }
      }
    });
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
        DatabaseHelper.deleteItem("Feeding", selected_id!);
        feedings.removeAt(selected_index!);
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

  String sortSelected = "DESC"; // Default label
  String sortOption = "Date (Newest)";
  void openSortDialog(BuildContext context, Function(String) onSortSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sort By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              ListTile(
                title: Text("Date (Newest)"),
                onTap: () {
                  onSortSelected("date_desc");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Date (Oldest)"),
                onTap: () {
                  onSortSelected("date_asc");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


}

