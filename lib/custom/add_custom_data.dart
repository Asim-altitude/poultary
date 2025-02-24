import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/custom_category.dart';
import 'package:poultary/model/custom_category_data.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import '../database/databse_helper.dart';
import '../model/flock.dart';

class NewCustomData extends StatefulWidget {
  CustomCategoryData? customCategoryData;
  CustomCategory customCategory;
  NewCustomData({Key? key, this.customCategoryData,required this.customCategory}) : super(key: key);

  @override
  _NewCustomData createState() => _NewCustomData();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewCustomData extends State<NewCustomData>
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

    if(widget.customCategoryData!= null)
    {
      isEdit = true;
      date = widget.customCategoryData!.date;
      _purposeselectedValue = widget.customCategoryData!.fName;
      quantityController.text = widget.customCategoryData!.quantity.toString();
      notesController.text = widget.customCategoryData!.note;

    }else{
      quantityController.text = "5";
    }

    getList();
    Utils.showInterstitial();
    Utils.setupAds();

  }



  List<Flock> flocks = [];
  void getList() async {
    if (!isEdit) {
      DateTime dateTime = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(dateTime);
    }

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    if(!isEdit)
      _purposeselectedValue = Utils.selected_flock!.f_name;


    setState(() {

    });

  }

  void getFeedList() async {
    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(3);

    for(int i=0;i<_subItemList.length;i++){
      _feedList.add(_subItemList.elementAt(i).name!);
    }

    if(!isEdit)
      _feedselectedValue = _feedList[0];

    print(_feedselectedValue);


    setState(() {

    });

  }

  Flock? currentFlock = null;

  int activeStep = 0;
  bool _validate = false;

  String date = "Choose date";
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
                            color: Utils.getScreenBackground(), //(x,y)
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
                                  color:Utils.getThemeColorBlue(), size: 30),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),


                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
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
                    height: heightScreen - 250,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                                isEdit?"EDIT".tr() +" ${widget.customCategory.name.tr()}":"NEW".tr()+" ${widget.customCategory.name.tr()}",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Utils.getThemeColorBlue(),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              )),
                          SizedBox(height: 40,width: widthScreen),

                          activeStep==0? Container(
                            child: Column(children: [
                              SizedBox(height: 20,width: widthScreen),
                              Column(
                                children: [
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
                                        color:  Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: getDropDownList(),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text(widget.customCategory.cat_type.tr()+' '+'Quantity'.tr()+"(${widget.customCategory.unit})", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                  Container(
                                    width: widthScreen,
                                    height: 70,
                                    padding: EdgeInsets.all(0),
                                    margin: EdgeInsets.only(left: 20, right: 20),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(70),
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                    child: Container(
                                      child: SizedBox(
                                        width: widthScreen,
                                        height: 60,
                                        child: TextFormField(
                                          maxLines: null,
                                          expands: true,
                                          controller: quantityController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
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
                                                borderRadius:
                                                BorderRadius.all(Radius.circular(20))),
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
                                ],
                              ),
                            ],),
                          ):SizedBox(width: 1,),

                          activeStep==1? Container(child: Column(
                            children: [
                              SizedBox(height: 10,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                  Container(
                                    width: widthScreen,
                                    height: 70,
                                    margin: EdgeInsets.only(left: 20, right: 20),
                                    decoration: BoxDecoration(

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
                                          color: Colors.grey.withAlpha(70),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20.0)),
                                          border: Border.all(
                                            color:  Colors.grey,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(Utils.getFormattedDate(date), style: TextStyle(
                                            color: Colors.black, fontSize: 16),),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DESCRIPTION_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                                ],
                              ),
                            ],
                          ),):SizedBox(width: 1,),


                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
                            onTap: () async {

                              activeStep++;

                              if(activeStep==1) {
                                if (quantityController.text
                                    .trim()
                                    .length == 0) {
                                  activeStep--;
                                  Utils.showToast("PROVIDE_ALL".tr());
                                }else{
                                  setState(() {

                                  });
                                }
                              }

                              if(activeStep==2){

                                if(isEdit){
                                  await DatabaseHelper.instance.database;

                                  CustomCategoryData custom_data = CustomCategoryData(fId: getFlockID(), cId: widget.customCategory.id!, cType: widget.customCategory.cat_type, cName: widget.customCategory.name, itemType: widget.customCategory.itemtype, quantity: double.parse(quantityController.text), unit: widget.customCategory.unit, date: date, fName: _purposeselectedValue, note: notesController.text);

                                  custom_data.id = widget.customCategoryData!.id;
                                  int? id = await DatabaseHelper
                                      .updateCustomCategoryData(custom_data);

                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                } else {
                                  await DatabaseHelper.instance.database;

                                  CustomCategoryData custom_data = CustomCategoryData(fId: getFlockID(), cId: widget.customCategory.id!, cType: widget.customCategory.cat_type, cName: widget.customCategory.name, itemType: widget.customCategory.itemtype, quantity: double.parse(quantityController.text), unit: widget.customCategory.unit, date: date, fName: _purposeselectedValue, note: notesController.text);

                                  int? id = await DatabaseHelper
                                      .insertCategoryData(custom_data);
                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                }

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
                                activeStep==0?"NEXT".tr():"CONFIRM".tr(),
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
