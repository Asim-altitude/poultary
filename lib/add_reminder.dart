import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/events_databse_helper.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/event_item.dart';
import 'model/flock.dart';

class NewEventReminder extends StatefulWidget {

  MyEvent? myEvent;

  NewEventReminder({Key? key,  required this.myEvent}) : super(key: key);

  @override
  _NewEventReminder createState() => _NewEventReminder();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewEventReminder extends State<NewEventReminder>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;


  @override
  void dispose() {
    super.dispose();

  }

  String _purposeselectedValue = "";
  String _reminderValue = "";


  List<String> _purposeList = [];

  List<String> _reminderList = ["Vaccination".tr(),"Medication".tr(),"Birds Sale".tr(), "Birds Purchase".tr(),"Egg Collection".tr(),"Cleanliness".tr(),"Inventory Purchase".tr(),"Financial Settlements".tr(),"Repairing".tr(),"Other".tr()];

  int chosen_index = 0;

  bool isEdit = false;

  @override
  void initState() {
    super.initState();

    if(widget.myEvent != null) {
      isEdit = true;
      date = widget.myEvent!.date!;
      _purposeselectedValue = widget.myEvent!.flock_name!;
      _reminderValue = widget.myEvent!.event_name!;
      notesController.text = widget.myEvent!.event_detail!;
      nameController.text = widget.myEvent!.event_name!;
    }

    getList();
    Utils.setupAds();
  }

  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    if(!isEdit) {
      _purposeselectedValue = _purposeList[0];
      _reminderValue = _reminderList[0];
    }

    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose date";
  bool isDateChosen = false;
  final nameController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;
  bool isOther = false;

  int good_eggs = 0;
  int bad_eggs = 0;
  int activeStep = 0;


  @override
  Widget build(BuildContext context) {
    double safeAreaHeight = MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom = MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height -
        (safeAreaHeight + safeAreaHeightBottom);
    child:
    return SafeArea(
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Container(
            width: widthScreen,
            height: heightScreen,
            color: Utils.getScreenBackground(),
            child: SingleChildScrollViewWithStickyFirstWidget(
              child: Column(
                children: [
                  Utils.getDistanceBar(),

                  ClipRRect(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:  Utils.getScreenBackground(), //(x,y)
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
                                  color: Utils.getThemeColorBlue(), size: 30),
                              onTap: () {
                                Navigator.pop(context,"Reminder ADDED");
                              },
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                               "",
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
                  EasyStepper(
                    activeStep: activeStep,
                    activeStepTextColor: Utils.getThemeColorBlue(),
                    finishedStepTextColor: Utils.getThemeColorBlue(),
                    internalPadding: 30,
                    showLoadingAnimation: false,
                    stepRadius: 12,
                    showStepBorder: true,
                    steps: [
                      EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 0 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 1',
                      ),
                      EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 1 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 2',

                      ),

                    ],
                    onStepReached: (index) =>
                        setState(() => activeStep = index),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 30,width: widthScreen),
                          activeStep == 0? Container(
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text(
                                      isEdit? "EDIT".tr() +" "+ "Reminder".tr(): "NEW".tr()+" "+ "Reminder",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    )),

                                SizedBox(height: 40,width: widthScreen),
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('CHOOSE_FLOCK_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                Container(
                                  width: widthScreen,
                                  height: 70,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(70),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20.0)),
                                    border: Border.all(
                                      color:  Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: getDropDownList(),
                                ),

                                SizedBox(height: 20,width: widthScreen),
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Reminder Title'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                if(_reminderValue!='')
                                Container(
                                  width: widthScreen,
                                  height: 70,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(70),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20.0)),
                                    border: Border.all(
                                      color:  Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: getRzeminderDropDownList(),
                                ),

                                SizedBox(height: 20,width: widthScreen),

                               isOther? Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Reminder Title'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)): SizedBox(width: 1,),
                               isOther? Container(
                                  width: widthScreen,
                                  height: 70,
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(70),
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                  child: Container(
                                    child: SizedBox(
                                      width: widthScreen,
                                      height: 70,
                                      child: TextFormField(
                                        maxLines: 2,
                                        controller: nameController,
                                        keyboardType: TextInputType.multiline,
                                        textAlign: TextAlign.start,
                                        textInputAction: TextInputAction.done,
                                        decoration:  InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(10))),
                                          hintText: 'Reminder Title'.tr(),
                                          hintStyle: TextStyle(
                                              color: Colors.black, fontSize: 16),
                                          labelStyle: TextStyle(
                                              color: Colors.black, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ) : SizedBox(width: 1,),

                              ],
                            ),
                          ):SizedBox(width: 1,),

                          activeStep==1? Container(
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text(
                                      "Reminder date".tr() +" - "+"About Reminder".tr(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    )),
                                SizedBox(height: 20,width: widthScreen),


                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                Container(
                                  width: widthScreen,
                                  height: 70,
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                                  child: InkWell(
                                    onTap: () {
                                      pickDate();
                                    },
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(left: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(70),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20.0)),
                                        border: Border.all(
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(Utils.getReminderFormattedDate(date), style: TextStyle(
                                          color: Colors.black, fontSize: 16),),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20,width: widthScreen),

                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('About Reminder'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                Container(
                                  width: widthScreen,
                                  height: 100,
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(70),
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                  child: Container(
                                    child: SizedBox(
                                      width: widthScreen,
                                      height: 100,
                                      child: TextFormField(
                                        maxLines: 2,
                                        controller: notesController,
                                        keyboardType: TextInputType.multiline,
                                        textAlign: TextAlign.start,
                                        textInputAction: TextInputAction.done,
                                        decoration:  InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(10))),
                                          hintText: 'About Reminder'.tr(),
                                          hintStyle: TextStyle(
                                              color: Colors.black, fontSize: 16),
                                          labelStyle: TextStyle(
                                              color: Colors.black, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),


                                SizedBox(height: 10,width: widthScreen),

                              ],
                            ),
                          ):SizedBox(width: 1,),

                          SizedBox(height: 25,width: widthScreen),

                          InkWell(
                            onTap: () async {
                              activeStep++;
                              if(activeStep==1){
                                if(isOther){
                                  if(nameController.text.isEmpty)
                                  {
                                    activeStep--;
                                    Utils.showToast("PROVIDE_ALL".tr());
                                  }
                                }
                              }

                              if(activeStep==2)
                              {
                                if(notesController.text.isEmpty || !isDateChosen) {
                                  activeStep--;
                                  Utils.showToast("PROVIDE_ALL".tr());
                                }
                                else
                                {
                                  DateTime datetime = DateFormat("dd MMM yyyy - hh:mm a").parse(Utils.getReminderFormattedDate(date)); // DateTime.parse();
                                  int notification_time = ((datetime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch) / 1000).round();
                                  print("TIME $notification_time");

                                  if(isEdit){
                                    MyEvent myevent = MyEvent(widget.myEvent!.id, getFlockID(),
                                        _purposeselectedValue,
                                        isOther
                                            ? nameController.text
                                            : _reminderValue,
                                        notesController.text ,1, date, 1);
                                    await EventsDatabaseHelper.instance
                                        .database;

                                    EventsDatabaseHelper.updateEvent(myevent);
                                    Utils.showToast("Reminder Added".tr());
                                    Navigator.pop(context);

                                  } else {
                                    MyEvent myevent = MyEvent(-1, getFlockID(),
                                        _purposeselectedValue,
                                        isOther
                                            ? nameController.text
                                            : _reminderValue,
                                        notesController.text, 1, date, 1);
                                    await EventsDatabaseHelper.instance
                                        .database;

                                    EventsDatabaseHelper.insertNewEvent(myevent);
                                    Utils.showNotification(Utils.generateRandomNumber(), myevent.event_name!, myevent.event_detail!, notification_time);
                                    Utils.showToast("Reminder Added".tr());
                                    Navigator.pop(context);
                                  }
                                }
                              }

                              setState(() {

                              });
                            },
                            child: Container(
                              width: widthScreen,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Utils.getThemeColorBlue(),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                                border: Border.all(
                                  color:  Utils.getThemeColorBlue(),
                                  width: 2.0,
                                ),
                              ),
                              margin: EdgeInsets.all(20),
                              child: Text(
                                activeStep==0? "Next".tr() : "CONFIRM".tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )

                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void isLastValue(){

    for(int i=0;i<_reminderList.length;i++){
      if(_reminderValue == _reminderList[i]){
        if(i == _reminderList.length -1){
          isOther = true;
        }else{
          isOther = false;
        }
      }
    }

    setState(() {

    });

  }

  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _purposeselectedValue = newValue!;

          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget getRzeminderDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _reminderValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _reminderValue = newValue!;
             isLastValue();
          });
        },
        items: _reminderList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  void pickDate() async{

     DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2050));

     TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (pickedDate != null && pickedTime != null) {
      print(pickedDate);
      print(pickedTime);//pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      String formattedTime = "${pickedTime.hour}:${pickedTime.minute}";
      print(formattedDate +" "+ formattedTime);
      isDateChosen = true;//formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate +" "+ formattedTime; //set output date to TextField value.
      });
    } else {}
  }

  int getFlockID() {

    int selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        selected_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return selected_id;
  }

}
