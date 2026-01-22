import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/events_databse_helper.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
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
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }



  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _reminderValue = "";


  List<String> _purposeList = [];

  List<String> _reminderList = ["Vaccination","Medication","Birds Sale", "Birds Purchase","Egg Collection","Cleanliness","Inventory Purchase","Financial Settlements","Repairing","Other"];

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
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
    AnalyticsUtil.logScreenView(screenName: "add_reminder");
  }

  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

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
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // removes the shadow
        scrolledUnderElevation: 0, // removes shadow when scrolling (Flutter 3.7+)
        surfaceTintColor: Colors.transparent, // removes Material3 tint
        backgroundColor: Utils.getScreenBackground(), // Customize the color
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Utils.getThemeColorBlue()),
          onPressed: () {
            Navigator.pop(context); // Navigates back
          },
        ),
      ),


      bottomNavigationBar: InkWell(
        onTap: () async {
          activeStep++;
          if(activeStep==1){
            if(isOther){
              if(nameController.text.isEmpty)
              {
                activeStep--;
                Utils.showToast("PROVIDE_ALL");
              }
            }
          }

          if(activeStep==2)
          {
            if(notesController.text.isEmpty || !isDateChosen) {
              activeStep--;
              Utils.showToast("PROVIDE_ALL");
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
                Utils.showToast("Reminder Added");
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
                Utils.showToast("Reminder Added");
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
            borderRadius: BorderRadius.circular(30), // More rounded
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
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
      ),
      body: SafeArea(
        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
          child: Column(children: [
            Utils.showBannerAd(_bannerAd, _isBannerAdReady),
            Expanded(child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30,width: widthScreen),

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
                        title: 'Step 1'.tr(),
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
                        title: 'Step 2'.tr(),

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
                          SizedBox(height: 50,width: widthScreen),
                          activeStep == 0? Container(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isEdit? "EDIT".tr() +" "+ "Reminder".tr(): "NEW".tr()+" "+ "Reminder",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 50,width: widthScreen),
                                /*Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('CHOOSE_FLOCK_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                              ),*/

                                _buildInputLabel("CHOOSE_FLOCK_1", Icons.pets),
                                _buildDropdownField(getDropDownList()),

                                SizedBox(height: 20,width: widthScreen),
                                /*Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Reminder Title'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                              ),*/

                                _buildInputLabel("Reminder Title", Icons.title),
                                if(_reminderValue!='')
                                  _buildDropdownField(getRzeminderDropDownList()),

                                SizedBox(height: 20,width: widthScreen),

                                isOther? _buildInputLabel("Reminder Title", Icons.title) : SizedBox(width: 1,),
                                isOther? _buildTextAreaField(nameController, "Reminder Title",1): SizedBox(width: 1,),

                                /*     isOther? Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Reminder Title'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)): SizedBox(width: 1,),
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
    */
                              ],
                            ),
                          ):SizedBox(width: 1,),

                          activeStep==1? Container(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
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

                                _buildInputLabel("DATE", Icons.calendar_today),
                                _buildDateField(date, pickDate),

                                /* Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                              ),*/
                                SizedBox(height: 20,width: widthScreen),

                                _buildInputLabel("About Reminder", Icons.calendar_today),
                                _buildTextAreaField(notesController, "About Reminder".tr(),3),

                                /*

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

    */

                                SizedBox(height: 10,width: widthScreen),

                              ],
                            ),
                          ):SizedBox(width: 1,),

                          SizedBox(height: 25,width: widthScreen),



                        ]),
                  ),
                ],
              ),
            ))
          ],),
        ),
      ),
    );
  }

  // Custom Date Picker Field
  Widget _buildDateField(String dateText, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateText.tr(), style: TextStyle(fontSize: 16, color: Colors.black)),
            Icon(Icons.calendar_today, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }


  // Custom Text Area for Description
  Widget _buildTextAreaField(TextEditingController controller, String hint, int mx_lines) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: mx_lines,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      ),
    );
  }

  // Custom Input Label with Icon
  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Utils.getThemeColorBlue(), size: 20),
        SizedBox(width: 8),
        Text(
          label.tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ],
    );
  }
// Custom Dropdown Field
  Widget _buildDropdownField(Widget dropdownWidget) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: dropdownWidget,
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
              value.tr(),
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
              value.tr(),
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


  void pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevent selection before today
      lastDate: DateTime(2050),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // Convert DateTime and TimeOfDay to a formatted string
        String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);

        // Convert TimeOfDay to a 12-hour format with AM/PM
        final now = DateTime.now();
        final selectedDateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
        String formattedTime = DateFormat('hh:mm a').format(selectedDateTime);

        print("$formattedDate - $formattedTime");

        setState(() {
          isDateChosen = true;
          date = "$formattedDate - $formattedTime"; // Update the UI
        });
      }
    }
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
