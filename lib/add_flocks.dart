import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/flock_image.dart';
import 'model/sub_category_item.dart';
import 'model/transaction_item.dart';

class ADDFlockScreen extends StatefulWidget {
  const ADDFlockScreen({Key? key}) : super(key: key);

  @override
  _ADDFlockScreen createState() => _ADDFlockScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ADDFlockScreen extends State<ADDFlockScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  int activeStep = 0;

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [
    'EGG',
    'MEAT',
    'EGG_MEAT',
    'OTHER',
  ];

  List<String> acqusitionList = [
    'PURCHASED',
    'HATCHED',
    'GIFT',
    'OTHER',
  ];

  List<Bird> birds = [];

  int chosen_index = 0;

  final amountController = TextEditingController();
  final personController = TextEditingController();
  @override
  void initState() {
    super.initState();

    _purposeselectedValue = _purposeList[1];
    _acqusitionselectedValue = acqusitionList[1];
    birdcountController.text = '10';

    getList();
    getBirds();
    Utils.showInterstitial();
    Utils.setupAds();

  }


  List<Flock> flocks = [];
  bool no_flock = true;
  void getList() async {

    DateTime dateTime = DateTime.now();

    date = DateFormat('yyyy-MM-dd').format(dateTime);

    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getFlocks();

    if(flocks.length == 0)
    {
      no_flock = true;
      print("NO_FLOCKS".tr());
    }

    _paymentMethodList = await DatabaseHelper.getSubCategoryList(5);

    if(_paymentMethodList.length > 0) {
      for (int i = 0; i < _paymentMethodList.length; i++) {
        _visiblePaymentMethodList.add(_paymentMethodList
            .elementAt(i)
            .name!);
      }
    }else{
      _visiblePaymentMethodList.add("Cash");
    }

    payment_method = _visiblePaymentMethodList[0];

    setState(() {

    });

  }

  bool isPurchase = false;
  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];

  void getBirds() async {

    await DatabaseHelper.instance.database;
    birds = await DatabaseHelper.getBirds();
    for (int i = 0; i< birds.length;i++){
      print(birds.elementAt(i).name);
      print(birds.elementAt(i).image);
      print(birds.elementAt(i).id);
    }

    birds.add(Bird(id: 100, image: "assets/other.jpg", name: 'Other'));

    nameController.text = birds.elementAt(chosen_index).name + " FLock ${flocks.length + 1}";

    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose date";
  final nameController = TextEditingController();
  final birdcountController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;


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
                  Visibility(
                    visible: false,
                    child: ClipRRect(
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
                                    color: Utils.getThemeColorBlue(), size: 30),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Container(
                                margin: EdgeInsets.only(left: 10),
                                child: Text(
                                  "NEW_FLOCK".tr(),
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
                  ),
                  SizedBox(height: 30,),
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
                      EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 2 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 3'.tr(),
                      ),

                    ],
                    onStepReached: (index) =>
                        setState(() => activeStep = index),
                  ),
                  activeStep == 0?
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      SizedBox(height: 20,),
                      Container(
                    margin: EdgeInsets.only(left: 10,top: 16,bottom: 8),
                    child: Text(
                      "BIRD_TYPES".tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Utils.getThemeColorBlue(),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )),
                      Container(
                        height: 186,
                        width: widthScreen,
                        margin: EdgeInsets.only(left: 15),
                        child: ListView.builder(
                      itemCount: birds.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return  index == chosen_index? InkWell(
                          onTap: () {
                            chosen_index = index;
                            nameController.text = birds.elementAt(chosen_index).name.tr() + "FLock".tr() + "${flocks.length + 1}";

                            setState(() {

                            });
                          },
                          child: Container(
                            margin: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Utils.getThemeColorBlue(),
                                width: 3.0,
                              ),
                            ),
                            child: Column( children: [
                              Container(
                                margin: EdgeInsets.all(10),
                                height: 100, width: 100,
                                child: Image.asset(birds.elementAt(index).image, fit: BoxFit.contain,),
                              ),
                              Container(
                                width: 100,
                                height: 50,
                                child:Text(birds.elementAt(index).name.tr(), textAlign: TextAlign.center,style: TextStyle( fontSize: 16, color: Colors.black),),),
                            ]),
                          ),
                        ): InkWell(
                          onTap: (){
                            chosen_index = index;
                            nameController.text = birds.elementAt(chosen_index).name.tr() + "FLock".tr() + "${flocks.length + 1}";
                            setState(() {

                            });
                          },
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),
                            child: Column( children: [
                              Container(
                                margin: EdgeInsets.all(10),
                                height: 100, width: 100,
                                child: Image.asset(birds.elementAt(index).image, fit: BoxFit.contain,),),

                              Container(
                                width: 100,
                                height: 50,
                                child:Text(birds.elementAt(index).name.tr(), textAlign: TextAlign.center,style: TextStyle( fontSize: 16, color: Colors.black),),),                              ]),
                          ),
                        );

                      }),
                      ),
                      SizedBox(height: 20,),
                      Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25, bottom: 5),child: Text('FLOCK_NAME'.tr(), style: TextStyle(fontSize: 14,  color: Colors.black, fontWeight: FontWeight.bold),)),

                    Container(
                      width: widthScreen,
                      height: 70,
                      padding: EdgeInsets.all(0),
                      margin: EdgeInsets.only(left: 20, right: 20),
                      decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius:
                    BorderRadius.all(Radius.circular(20))),
                      child: Container(
                        child: SizedBox(
                    width: widthScreen,
                    height: 70,
                    child: TextFormField(
                      maxLines: null,
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration:  InputDecoration(
                        fillColor: Colors.white.withAlpha(70),
                        border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(20))),
                        hintText: 'FLOCK_NAME'.tr(),
                        hintStyle: TextStyle(
                            color: Colors.grey, fontSize: 16),
                        labelStyle: TextStyle(
                            color: Colors.black, fontSize: 16),
                      ),
                    ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,width: widthScreen),

                        Row(
                          children: [
                            Expanded(
                              flex: 2, // First item takes 1 flex
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    margin: EdgeInsets.only(left: 25, bottom: 5),
                                    child: Text(
                                      'NUMBER_BIRDS'.tr(),
                                      style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    height: 70,
                                    padding: EdgeInsets.all(0),
                                    margin: EdgeInsets.only(left: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: TextFormField(
                                        maxLines: null,
                                        expands: true,
                                        controller: birdcountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                                          TextInputFormatter.withFunction((oldValue, newValue) {
                                            final text = newValue.text;
                                            return text.isEmpty
                                                ? newValue
                                                : double.tryParse(text) == null
                                                ? oldValue
                                                : newValue;
                                          }),
                                        ],
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(20)),
                                          ),
                                          hintText: 'NUMBER_BIRDS'.tr(),
                                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                          labelStyle: TextStyle(color: Colors.black, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2, // Second item takes 2 flex
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    margin: EdgeInsets.only(left: 10, bottom: 5),
                                    child: Text(
                                      'PURPOSE1'.tr(),
                                      style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    height: 70,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.all(10),
                                    margin: EdgeInsets.only(left: 10, right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(70),
                                      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                      border: Border.all(color: Colors.grey, width: 1.0),
                                    ),
                                    child: getDropDownList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      ],),
                  ):SizedBox(width: 1,),

                  activeStep==1?
                  Column(
                    children: [
                      SizedBox(height: 30),
                      Text(
                        "Financial Info".tr(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Utils.getThemeColorBlue(),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 50, width: widthScreen),

                      // Acquisition Dropdown (Always Enabled)
                      Container(
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.only(left: 25, bottom: 5),
                        child: Text(
                          'ACQUSITION'.tr(),
                          style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        width: widthScreen,
                        height: 70,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(left: 20, right: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(70),
                          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: getAcqusitionDropDownList(),
                      ),
                      SizedBox(height: 15, width: widthScreen),

                      // Disable all other UI components when isPurchase is false
                      AbsorbPointer(
                        absorbing: !isPurchase, // Disables interaction when isPurchase is false
                        child: Opacity(
                          opacity: isPurchase ? 1.0 : 0.5, // Visually indicate the UI is disabled
                          child: Column(
                            children: [
                              // Expense Amount
                              Container(
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.only(left: 20, bottom: 5),
                                child: Text(
                                  'EXPENSE_AMOUNT'.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                height: 70,
                                padding: EdgeInsets.all(0),
                                margin: EdgeInsets.only(right: 20, left: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(70),
                                  borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                ),
                                child: SizedBox(
                                  width: widthScreen,
                                  height: 60,
                                  child: TextFormField(
                                    maxLines: null,
                                    expands: true,
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                        final text = newValue.text;
                                        return text.isEmpty ? newValue : double.tryParse(text) == null ? oldValue : newValue;
                                      }),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                                      hintText: 'EXPENSE_AMOUNT'.tr(),
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                      labelStyle: TextStyle(color: Colors.black, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),

                              // Payment Method & Payment Status (Row)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 20),
                                        Container(
                                          alignment: Alignment.topLeft,
                                          margin: EdgeInsets.only(left: 25, bottom: 5),
                                          child: Text(
                                            'Payment Method'.tr(),
                                            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: 70,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.only(left: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(70),
                                            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: getPaymentMethodList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 20),
                                        Container(
                                          alignment: Alignment.topLeft,
                                          margin: EdgeInsets.only(left: 25, bottom: 5),
                                          child: Text(
                                            'Payment Status'.tr(),
                                            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: 70,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.only(left: 10, right: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(70),
                                            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: getPaymentStatusList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 15, width: widthScreen),

                              // Paid To
                              Container(
                                alignment: Alignment.topLeft,
                                margin: EdgeInsets.only(left: 25, bottom: 5),
                                child: Text(
                                  'PAID_TO1'.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                width: widthScreen,
                                height: 70,
                                padding: EdgeInsets.all(0),
                                margin: EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(70),
                                  borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                ),
                                child: SizedBox(
                                  width: widthScreen,
                                  height: 60,
                                  child: TextFormField(
                                    maxLines: null,
                                    expands: true,
                                    controller: personController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                                      hintText: 'PAID_TO_HINT'.tr(),
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                      labelStyle: TextStyle(color: Colors.black, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ):SizedBox(width: 1,),


                  activeStep==2? Column(children: [

                    SizedBox(height: 30,),

                    Text(
                      "Flock Images and Description".tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Utils.getThemeColorBlue(),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 30,width: widthScreen),

                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                    Container(
                      width: widthScreen,
                      height: 70,
                      margin: EdgeInsets.only(left: 20, right: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(70),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(20.0)),
                        border: Border.all(
                          color:  Colors.grey,
                          width: 1.0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          pickDate();
                        },
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 10),

                          child: Text(Utils.getFormattedDate(date), style: TextStyle(
                              color: Colors.black, fontSize: 16),),
                        ),
                      ),
                    ),

                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25, top: 15),child: Text('FLOCK_IMAGES'.tr(), style: TextStyle(fontSize: 14,  color: Colors.black, fontWeight: FontWeight.bold),)),

                    Container(
                      margin: EdgeInsets.only(left: 20, right: 20),
                      padding: EdgeInsets.only(bottom: 10, left: 5, right: 5),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(10.0)),
                        border: Border.all(
                          color:  Colors.grey,
                          width: 1.0,
                        ),
                      ),
                      child: Column(children: [
                        SizedBox(height: 40,width: widthScreen),

                        imagesAdded? Container(
                          height: 80,
                          width: widthScreen - 40,
                          margin: EdgeInsets.only(left: 10),
                          child: ListView.builder(
                              itemCount: imageFileList!.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                    margin: EdgeInsets.all(10),
                                    height: 80, width: 80,
                                    child: Image.file(File(imageFileList![index].path,), fit: BoxFit.cover,
                                    ));
                              }),
                        ) : Container( height: 80,
                            width: widthScreen - 135,margin: EdgeInsets.only(left: 15), alignment: Alignment.center, child: Text('NO_IMAGES'.tr())),
                        InkWell(
                          onTap: () {
                            selectImages();
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: widthScreen - 40,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: Utils.getThemeColorBlue(),
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                              child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add, color: Colors.white,),
                                Text('IMAGES'.tr(), style: TextStyle(
                                    color: Colors.white, fontSize: 14),)
                              ],),
                            ),
                          ),
                        ),
                      ],),
                    ),
                    SizedBox(height: 30,width: widthScreen),
                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25, bottom: 5),child: Text('FLOCK_DESC'.tr(), style: TextStyle(fontSize: 14,  color: Colors.black, fontWeight: FontWeight.bold),)),

                    Container(
                      width: widthScreen,
                      height: 100,
                      margin: EdgeInsets.only(left: 20, right: 20),
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
                                  color: Colors.black, fontSize: 16),
                              labelStyle: TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],) : SizedBox(width: 1,),

                  SizedBox(height: 10,width: widthScreen),
                  InkWell(
                    onTap: () async {
                      bool validate = checkValidation();

                      activeStep++;
                      if(activeStep==1){
                        if(nameController.text != "" && birdcountController.text!= ""){

                        }else{
                          activeStep--;
                          Utils.showToast("PROVIDE_ALL".tr());
                        }
                      }

                      if(activeStep==2){
                        if(!checkValidationOption()){
                          activeStep--;
                          Utils.showToast("PROVIDE_ALL".tr());
                        }else if (nameController.text != "" && birdcountController.text!= ""){
                          notesController.text = nameController.text +" "+"Added on".tr()+" "+Utils.getFormattedDate(date) +" "+"with".tr() +" "+ birdcountController.text + " " + "BIRDS".tr();
                        }else{
                          activeStep--;
                          Utils.showToast("PROVIDE_ALL".tr());
                        }
                      }

                      if(activeStep==3){
                        if(validate) {
                          print("Everything Okay");
                          await DatabaseHelper.instance.database;
                          int? id = await DatabaseHelper.insertFlock(Flock(f_id: 1, f_name: nameController.text, bird_count: int.parse(birdcountController.text)
                            , purpose: _purposeselectedValue, acqusition_type: _acqusitionselectedValue, acqusition_date: date, notes: notesController.text, icon: birds.elementAt(chosen_index).image, active_bird_count: int.parse(birdcountController.text), active: 1, flock_new: 1,
                          ));

                          if(isPurchase){

                            await DatabaseHelper.instance.database;
                            TransactionItem transaction_item = TransactionItem(
                                flock_update_id: "-1",
                                f_id: id!,
                                date: date,
                                sale_item: "",
                                expense_item: "Flock Purchase".tr(),
                                type: "Expense",
                                amount: amountController.text,
                                payment_method: payment_method,
                                payment_status: payment_status,
                                sold_purchased_from: personController
                                    .text,
                                short_note: notesController.text,
                                how_many: birdcountController.text,
                                extra_cost: "",
                                extra_cost_details: "",
                                f_name: nameController.text);
                            int? tr_id = await DatabaseHelper
                                .insertNewTransaction(transaction_item);

                            Flock_Detail f_detail = Flock_Detail(
                                f_id: id,
                                item_type: 'Addition',
                                item_count: int.parse(birdcountController.text),
                                acqusition_type: _acqusitionselectedValue,
                                acqusition_date: date,
                                reason: "",
                                short_note: notesController.text,
                                f_name: nameController.text,
                                transaction_id: tr_id!.toString());

                            int? flock_detail_id = await DatabaseHelper
                                .insertFlockDetail(f_detail);

                            await DatabaseHelper.updateLinkedTransaction(tr_id.toString(), flock_detail_id.toString());


                          }else{
                            Flock_Detail f_detail = Flock_Detail(
                                f_id: id!,
                                item_type: 'Addition',
                                item_count: int.parse(birdcountController.text),
                                acqusition_type: _acqusitionselectedValue,
                                acqusition_date: date,
                                reason: "",
                                short_note: notesController.text,
                                f_name: nameController.text,
                                transaction_id: "-1" );

                            int? flock_detail_id = await DatabaseHelper
                                .insertFlockDetail(f_detail);

                          }

                          if (base64Images.length > 0){
                            insertFlockImages(id);
                          }else{
                            Utils.showToast("FLOCK_CREATED".tr());
                            Navigator.pop(context);
                          }

                        }else{
                          activeStep--;
                          Utils.showToast("PROVIDE_ALL".tr());
                        }
                      }

                      setState(() {

                      });


                     /* if(validate){
                        print("Everything Okay");
                        await DatabaseHelper.instance.database;
                        int? id = await DatabaseHelper.insertFlock(Flock(f_id: 1, f_name: nameController.text, bird_count: int.parse(birdcountController.text)
                          , purpose: _purposeselectedValue, acqusition_type: _acqusitionselectedValue, acqusition_date: date, notes: notesController.text, icon: birds.elementAt(chosen_index).image, active_bird_count: int.parse(birdcountController.text), active: 1,
                        ));

                        if (base64Images.length > 0){
                          insertFlockImages(id);
                        }else{
                          Utils.showToast("FLOCK_CREATED".tr());
                          Navigator.pop(context);
                        }

                      }else{
                        Utils.showToast("PROVIDE_ALL".tr());
                      }*/
                    },
                    child: Container(
                      width: widthScreen,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(6.0)),
                        border: Border.all(
                          color:  Utils.getThemeColorBlue(),
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
                      margin: EdgeInsets.all( 20),
                      child: Text(
                        activeStep<=1? "Next".tr():"Finish".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void isFinanceInfo(){
    for(int i=0;i<acqusitionList.length;i++){
      if(_acqusitionselectedValue == acqusitionList[i]){
        if(i == 0){
          isPurchase = true;
        }else{
          isPurchase = false;
        }
      }
    }
    setState(() {

    });
  }

  String payment_method = "Cash";
  String payment_status = "CLEARED";
  Widget getPaymentMethodList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ""),
        isDense: true,
        value: payment_method,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            payment_method = newValue!;

          });
        },
        items: _visiblePaymentMethodList.map<DropdownMenuItem<String>>((String value) {
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

  List<String> paymentStatusList = ['CLEARED','UNCLEAR','RECONCILED'];

  Widget getPaymentStatusList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: payment_status,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            payment_status = newValue!;

          });
        },
        items: paymentStatusList.map<DropdownMenuItem<String>>((String value) {
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



  Widget getAcqusitionDropDownList() {
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
            isFinanceInfo();
          });
        },
        items: acqusitionList.map<DropdownMenuItem<String>>((String value) {
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
  Widget getDropDownList() {
    return Container(
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



    final ImagePicker imagePicker = ImagePicker();
    List<XFile>? imageFileList = [];

    void selectImages() async {
      final List<XFile>? selectedImages = await
      imagePicker.pickMultiImage();
      if (selectedImages!.isNotEmpty) {
        imageFileList!.addAll(selectedImages);
      }
      print("Image List Length:" + imageFileList!.length.toString());

      saveImagesDB();

      imagesAdded = true;

      setState((){});
    }


  void pickDate() async{

     DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null) {
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      print(formattedDate);
      notesController.text = nameController.text +" "+"Added on".tr()+" "+Utils.getFormattedDate(formattedDate) +" "+"with".tr() +" "+ birdcountController.text + " " + "BIRDS".tr();
      //formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  bool checkValidationOption(){

    bool valid = true;

    if(_acqusitionselectedValue.toLowerCase().contains("ACQUSITION_TYPE".tr()) ||
        _acqusitionselectedValue.toLowerCase().contains("ACQUSITION_TYPE"))
    {
      valid = false;
      print("Select Acqusition Type");
    }

    if(isPurchase){
      if(amountController.text.isEmpty)
        valid = false;

      if(personController.text.isEmpty)
        valid = false;

    }


    return valid;
  }

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(birdcountController.text.isEmpty){
      valid = false;
      print("Select Bird Count");
    }

    if(nameController.text.isEmpty){
      valid = false;
      print("Select Flock Name");
    }

    return valid;

  }

  List<String> base64Images = [];
  
  void saveImagesDB() async {

        base64Images.clear();

        File file;
      for (int i=0;i<imageFileList!.length;i++) {

        file = await Utils.convertToJPGFileIfRequiredWithCompression(File(imageFileList!.elementAt(i).path));
        final bytes = File(file.path).readAsBytesSync();
        String base64Image =  base64Encode(bytes);
        base64Images.add(base64Image);

        print("img_pan : $base64Image");
        
      }
  }

  void insertFlockImages(int? id) {

    if (base64Images.length > 0){

      for (int i=0;i<base64Images.length;i++){
        Flock_Image image = Flock_Image(f_id: id,image: base64Images.elementAt(i));
        DatabaseHelper.insertFlockImages(image);
      }

      print("Images Inserted");
      Utils.showToast("FLOCK_CREATED".tr());
      Navigator.pop(context);
    }

  }



}
