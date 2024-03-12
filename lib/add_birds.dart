import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class NewBirdsCollection extends StatefulWidget {

  bool isCollection;
  NewBirdsCollection({Key? key, required this.isCollection}) : super(key: key);

  @override
  _NewBirdsCollection createState() => _NewBirdsCollection(this.isCollection);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewBirdsCollection extends State<NewBirdsCollection>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

   bool isCollection;
  _NewBirdsCollection(this.isCollection);

  @override
  void dispose() {
    super.dispose();

  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _reductionReasons = ['--Reduction Reason--',
    'Sold','Personal Use','Mortality','Lost/Stolen','Other'];

  List<String> acqusitionList = [
    '--Acqusition Type--',
    'Purchased',
    'Hatched on Form',
    'Gift',
    'Other',
  ];
  int chosen_index = 0;

  int active_bird_count = 0;

  String max_hint = "";

  @override
  void initState() {
    super.initState();

    _reductionReasonValue = _reductionReasons[0];
    _acqusitionselectedValue = acqusitionList[0];
    getList();
    Utils.showInterstitial();
    Utils.setupAds();

  }

  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;


    flocks = await DatabaseHelper.getFlocks();

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    _purposeselectedValue = _purposeList[0];


    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose Date";
  final nameController = TextEditingController();
  final totalBirdsController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;

  int good_eggs = 0;
  int bad_eggs = 0;


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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Utils.getAdBar(),

                  ClipRRect(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: isCollection ? Colors.green : Colors.red, //(x,y)
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
                                isCollection? 'Add Birds' : 'Reduce Birds',
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

                  Container(
                    margin: EdgeInsets.only(top: 30),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 70,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),
                            child: getDropDownList(),
                          ),


                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 70,
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                            child: Container(
                              child: SizedBox(
                                width: widthScreen,
                                height: 60,
                                child: TextFormField(
                                  maxLines: null,
                                  expands: true,
                                  controller: totalBirdsController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: 'Birds count',
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                    labelStyle: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                         Container(
                             margin: EdgeInsets.only(left: 20),
                             child: Text(max_hint, style: TextStyle(color: Colors.red, fontSize: 14),)),
                         !isCollection? SizedBox(height: 10,width: widthScreen): SizedBox(height: 0,width: widthScreen),
                         !isCollection? Container(
                            width: widthScreen,
                            height: 70,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),
                            child: getReductionList(),
                          ):SizedBox(height: 0,width: widthScreen),

                         isCollection? Container(
                            width: widthScreen,
                            height: 70,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),
                            child: getAcqusitionList(),
                          ):SizedBox(height: 0,width: widthScreen),

                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 70,
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                            child: InkWell(
                              onTap: () {
                                pickDate();
                              },
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10.0)),
                                  border: Border.all(
                                    color:  Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(Utils.getFormattedDate(date), style: TextStyle(
                                    color: Colors.black, fontSize: 16),),
                              ),
                            ),
                          ),

                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 120,
                            padding: EdgeInsets.all(5),
                            margin: EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                            child: Container(
                              child: SizedBox(
                                width: widthScreen,
                                height: 100,
                                child: TextFormField(
                                  maxLines: 2,
                                  maxLength: 80,
                                  controller: notesController,
                                  keyboardType: TextInputType.multiline,
                                  textAlign: TextAlign.start,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: 'Write short note',
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                    labelStyle: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
                            onTap: () async {
                              bool validate = checkValidation();

                              if(validate){
                                print("Everything Okay");
                                await DatabaseHelper.instance.database;


                                if(isCollection){

                                  int active_birds = getFlockActiveBirds();
                                  active_birds = active_birds + int.parse(totalBirdsController.text);
                                  print(active_birds);

                                  DatabaseHelper.updateFlockBirds(active_birds, getFlockID());

                                  int? id = await DatabaseHelper.insertFlockDetail(Flock_Detail(f_id: getFlockID(), item_type: isCollection? 'Addition':'Reduction', item_count: int.parse(totalBirdsController.text), acqusition_type: _acqusitionselectedValue, acqusition_date: date, reason: _reductionReasonValue, short_note: notesController.text, f_name: _purposeselectedValue));
                                  Utils.showToast("Birds Added");

                                  Navigator.pop(context);

                                }else{
                                  int active_birds = getFlockActiveBirds();

                                  if (int.parse(totalBirdsController.text) < active_birds) {

                                    active_birds = active_birds - int.parse(totalBirdsController.text);
                                    print(active_birds);

                                    DatabaseHelper.updateFlockBirds(
                                        active_birds, getFlockID());

                                    int? id = await DatabaseHelper
                                        .insertFlockDetail(Flock_Detail(
                                        f_id: getFlockID(),
                                        item_type: isCollection
                                            ? 'Addition'
                                            : 'Reduction',
                                        item_count: int.parse(
                                            totalBirdsController.text),
                                        acqusition_type: _acqusitionselectedValue,
                                        acqusition_date: date,
                                        reason: _reductionReasonValue,
                                        short_note: notesController.text, f_name: _purposeselectedValue));

                                    Utils.showToast("Birds Reduced");
                                    Navigator.pop(context);
                                  }else{

                                    max_hint = "Cannot reduce more than $active_birds";
                                    setState(() {

                                    });

                                  }
                                }

                              }else{
                                Utils.showToast("Provide all required info");
                              }
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
                              margin: EdgeInsets.all( 20),
                              child: Text(
                                "Confirm",
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
          setState((){
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

  Widget getReductionList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _reductionReasonValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _reductionReasonValue = newValue!;

          });
        },
        items: _reductionReasons.map<DropdownMenuItem<String>>((String value) {
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

  Widget getAcqusitionList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _acqusitionselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _acqusitionselectedValue = newValue!;

          });
        },
        items: acqusitionList.map<DropdownMenuItem<String>>((String value) {
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
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null) {
      print(
          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }


    if(isCollection) {
      if (_acqusitionselectedValue.toLowerCase().contains("acqusition")) {
        valid = false;
        print("Select Acqusition Type");
      }
    }

    if(!isCollection) {
      if (_reductionReasonValue.toLowerCase().contains("reduction")) {
        valid = false;
        print("Select Reduction reason");
      }
    }

    if(totalBirdsController.text.length <=0){
      valid = false;
      print("add birds count");
    }


    return valid;

  }


  int getFlockID() {

    int selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return selected_id;
  }

  int getFlockActiveBirds() {

    int? selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).active_bird_count;
        break;
      }
    }

    return selected_id!;
  }



}
