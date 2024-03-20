import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class NewFeeding extends StatefulWidget {
   Feeding? feeding;
   NewFeeding({Key? key, this.feeding}) : super(key: key);

  @override
  _NewFeeding createState() => _NewFeeding();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewFeeding extends State<NewFeeding>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _feedselectedValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _feedList = [];
  List<SubItem> _subItemList = [];

  int chosen_index = 0;
  bool isEdit = false;


  @override
  void initState() {
    super.initState();

    if(widget.feeding != null)
    {
      isEdit = true;
      date = widget.feeding!.date!;
      _purposeselectedValue = widget.feeding!.f_name;
      _feedselectedValue = widget.feeding!.feed_name!;
      quantityController.text = widget.feeding!.quantity!;
      notesController.text = widget.feeding!.short_note!;

    }
    getList();
    getFeedList();
    Utils.showInterstitial();
    Utils.setupAds();

  }

  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'FARM_WIDE'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    _purposeselectedValue = _purposeList[0];


    setState(() {

    });

  }

  void getFeedList() async {
    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(3);

    _subItemList.insert(0,SubItem(c_id: 3,id: -1,name: 'Choose Feed'));

    for(int i=0;i<_subItemList.length;i++){
      _feedList.add(_subItemList.elementAt(i).name!);
    }

    _feedselectedValue = _feedList[0];

    print(_feedselectedValue);


    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "CHOOSE_DATE".tr();
  final quantityController = TextEditingController();
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
                                isEdit?"EDIT".tr() + "FEEDING".tr():"NEW_FEEDING".tr(),
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
                            child: getFeedTypeList(),
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
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: "FEED_QUANTITY_HINT".tr(),
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
                                color: Colors.white60,
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
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: 'NOTES_HINT'.tr(),
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

                                if(isEdit){
                                  await DatabaseHelper.instance.database;

                                  Feeding feeding = Feeding(
                                    f_id: getFlockID(),
                                    short_note: notesController.text,
                                    date: date,
                                    feed_name: _feedselectedValue,
                                    quantity: quantityController.text,
                                    f_name: _purposeselectedValue,);
                                  feeding.id = widget.feeding!.id;
                                  int? id = await DatabaseHelper
                                      .updateFeeding(feeding);

                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                } else {
                                  await DatabaseHelper.instance.database;
                                  int? id = await DatabaseHelper
                                      .insertNewFeeding(Feeding(
                                    f_id: getFlockID(),
                                    short_note: notesController.text,
                                    date: date,
                                    feed_name: _feedselectedValue,
                                    quantity: quantityController.text,
                                    f_name: _purposeselectedValue,));
                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                }

                              }else{
                                Utils.showToast("PROVIDE_ALL".tr());
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
                                "CONFIRM".tr(),
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

  Widget getFeedTypeList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _feedselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _feedselectedValue = newValue!;

            print("Selected Feed $_feedselectedValue");

          });
        },
        items: _feedList.map<DropdownMenuItem<String>>((String value) {
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

    if(date.toLowerCase().contains("DATE".tr())){
      valid = false;
      print("SELECT_DATE".tr());
    }

    if(quantityController.text.length == 0){
      valid = false;
      print("Add quantity added");
    }
    
    if (getFeedID() == -1){
      valid = false;
      print("Add feed type");
    }

    return valid;

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

  int getFeedID() {

    int selected_id = -1;
    for(int i=0;i<_subItemList.length;i++){
      if(_feedselectedValue.toLowerCase() == _subItemList.elementAt(i).name!.toLowerCase()){
        selected_id = _subItemList.elementAt(i).id!;
        break;
      }
    }

    print("selected feed id $selected_id");

    return selected_id;
  }

}
