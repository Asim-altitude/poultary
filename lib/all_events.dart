import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/event_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'add_reminder.dart';
import 'database/databse_helper.dart';
import 'database/events_databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({Key? key}) : super(key: key);

  @override
  _AllEventsScreen createState() => _AllEventsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _AllEventsScreen extends State<AllEventsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }




  @override
  void initState() {
    super.initState();
    //requestPermission();

    getList();
    getAllEvents();
    checkPermissions();
  }

  void checkPermissions() async {
    bool isGranted = await Utils.isAndroidPermissionGranted();
    if(!isGranted){
      Utils.requestPermissions();
    }
  }

  List<MyEvent> events = [];
  List<String> flock_name = [];


  String applied_filter_name = "All Reminders";

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
                  addNewEvent();
                },
                child: Container(
                  height: 50,
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Utils.getThemeColorBlue(),
                    borderRadius: const BorderRadius.all(
                        Radius.circular(5.0)),
                    border: Border.all(
                      color:  Utils.getThemeColorBlue(),
                      width: 2.0,
                    ),
                  ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add, color: Colors.white, size: 30,),
                    Text('New Event Reminder'.tr(), style: TextStyle(
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
                        child: SizedBox(width: 2,),
                      ),
                      Container(

                          child: Text(
                            applied_filter_name.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          )),

                    ],
                  ),
                ),
              ),

              Visibility(
                visible: false,
                child: Container(
                  height: 50,
                  width: widthScreen ,
                  margin: EdgeInsets.only(left: 10,right: 10,bottom: 5),
                  child: Row(children: [

                    Expanded(
                      child: InkWell(
                        onTap: () {
                          selected = 1;
                          filter_name ='All';
                          active = -1;
                          getAllEvents();
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
                          isCollection = 1;
                          filter_name ='1';
                          active = 1;
                          getAllEvents();
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
                          child: Text('Active'.tr(), style: TextStyle(
                              color: selected==2 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          selected = 3;
                          filter_name ='0';
                          isCollection = 0;
                          active = 0;
                          getAllEvents();

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
                          child: Text('Expired'.tr(), style: TextStyle(
                              color: selected==3 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                        ),
                      ),
                    ),
                  ],),
                ),
              ),

              events.length > 0 ? Container(
                height: heightScreen - 100,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: events.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.only(left: 8,right: 8,top: 8,bottom: 0),
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
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.only(left: 10,right: 10,top: 4,bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child:
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTapDown: (TapDownDetails details) {
                                              selected_id = events.elementAt(index).id;
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
                                    Row(
                                      children: [
                                        Container(margin: EdgeInsets.all(0), child: Text(events.elementAt(index).event_name!.tr(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),)),
                                        Container(margin: EdgeInsets.all(0), child: Text(" ("+ events.elementAt(index).flock_name!.tr()+") ", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.grey),)),

                                      ],
                                    ),
                                    Container(margin: EdgeInsets.all(0), child: Text(events.elementAt(index).event_detail!, style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),

                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      child: Row(
                                        children: [
                                          Icon(Icons.notifications_active, size: 25, color: Utils.getThemeColorBlue(),),
                                          Text("".tr(), style: TextStyle(color: Colors.black, fontSize: 12),),
                                          Text(" On".tr(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),),
                                          Container(margin: EdgeInsets.all(5), child: Text(Utils.getReminderFormattedDate(events.elementAt(index).date.toString()), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)),
                                        ],
                                      ),
                                    ),

                                    Container(
                                        alignment: Alignment.centerRight,
                                        margin: EdgeInsets.all(0), child: Text(events.elementAt(index).type == 0 ?"EXPIRED".tr():"ACTIVE".tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: events.elementAt(index).type == 0 ? Colors.red: Colors.green),)),

                                    // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                  ],),
                              ),
                            ),

                          ]),
                        ),
                      );

                    }),
              ) : Utils.getCustomEmptyMessage("assets/reminder.png", "No Reminders Added")

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

  Future<void> addNewEvent() async {

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewEventReminder(myEvent: null,)),
    );
    print(result);
    getAllEvents();

  }


  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

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


  String filter_name = "All";

  int active = -1;
  void getAllEvents() async {

    await EventsDatabaseHelper.instance.database;

    events = await EventsDatabaseHelper.getAllReminders(active);

    int notification_time = 0;
    DateTime datetime;
    for(int i=0;i<events.length;i++)
    {
       datetime = DateFormat("dd MMM yyyy - hh:mm a").parse(Utils.getReminderFormattedDate(events.elementAt(i).date!)); // DateTime.parse();
       notification_time = ((datetime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch) / 1000).round();
      if(notification_time < 0){
        events.elementAt(i).type = 0;
      }
    }

    setState(() {

    });

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
      color: Colors.white,
      items: [

        PopupMenuItem(
          value: 1,
          child: Text(
            "DELETE_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        )
      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        /*if(value == 2){
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  NewEventReminder(myEvent: events.elementAt(selected_index!),)),
          );

          getAllEvents();
        }
        else*/
        if(value == 1) {
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
        EventsDatabaseHelper.deleteEventItem(selected_id!);
        events.removeAt(selected_index!);
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

