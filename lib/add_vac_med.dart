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
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class NewVaccineMedicine extends StatefulWidget {
  Vaccination_Medication? vaccination_medication;
  NewVaccineMedicine({Key? key, this.vaccination_medication}) : super(key: key);

  @override
  _NewVaccineMedicine createState() => _NewVaccineMedicine();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewVaccineMedicine extends State<NewVaccineMedicine>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _diseaseelectedValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _diseaseList = [];
  List<SubItem> _subItemList = [];

  int chosen_index = 0;

  bool isEdit = false;

  String date = "CHOOSE_DATE".tr();
  final bird_countController = TextEditingController();
  final doctorController = TextEditingController();
  final medicineController = TextEditingController();
  final notesController = TextEditingController();


  @override
  void initState() {
    super.initState();

    if(widget.vaccination_medication != null){
      isEdit = true;
      _purposeselectedValue = widget.vaccination_medication!.f_name!;
      _diseaseelectedValue = widget.vaccination_medication!.disease!;
      date = widget.vaccination_medication!.date!;
      bird_countController.text = "${widget.vaccination_medication!.bird_count!}";
      doctorController.text = "${widget.vaccination_medication!.doctor_name!}";
      medicineController.text = "${widget.vaccination_medication!.medicine!}";
      notesController.text = "${widget.vaccination_medication!.short_note!}";


    }

    getList();
    getDiseaseList();
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

  void getDiseaseList() async {
    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(4);

    _subItemList.insert(0,SubItem(c_id: 3,id: -1,name: 'Choose Disease'));

    for(int i=0;i<_subItemList.length;i++){
      _diseaseList.add(_subItemList.elementAt(i).name!);
    }

    _diseaseelectedValue = _diseaseList[0];

    print(_diseaseelectedValue);


    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;



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
                            color: Colors.green, //(x,y)
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
                                Utils.vaccine_medicine.toLowerCase().contains("medi")? isEdit?'EDIT'.tr() + 'MEDICATION'.tr():'NEW_MEDICATION'.tr():isEdit?'EDIT'.tr() + 'VACCINATION'.tr():'NEW_VACCINATION'.tr(),
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
                            child: getDiseaseTypeList(),
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
                            child: Container(
                              child: SizedBox(
                                width: widthScreen,
                                height: 70,
                                child: TextFormField(
                                  maxLines: null,
                                  expands: true,
                                  controller: medicineController,
                                  keyboardType: TextInputType.multiline,
                                  textAlign: TextAlign.start,
                                  textInputAction: TextInputAction.next,
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: 'MED_NAME'.tr(),
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
                                  controller: bird_countController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: 'BIRDS_COUNT'.tr(),
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
                                  color: Colors.white,
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
                            height: 70,
                            margin: EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                            child: Container(
                              child: SizedBox(
                                width: widthScreen,
                                height: 70,
                                child: TextFormField(
                                  maxLines: null,
                                  expands: true,
                                  controller: doctorController,
                                  keyboardType: TextInputType.multiline,
                                  textAlign: TextAlign.start,
                                  textInputAction: TextInputAction.next,
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                    hintText: "VAC_MED_BY".tr(),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 14),
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

                                await DatabaseHelper.instance.database;

                                if(isEdit) {
                                  Vaccination_Medication med_vacc = Vaccination_Medication(
                                    f_id: getFlockID(),
                                    disease: _diseaseelectedValue,
                                    medicine: medicineController.text,
                                    date: date,
                                    type: Utils.vaccine_medicine.toLowerCase()
                                        .contains("medi")
                                        ? 'Medication'
                                        : 'Vaccination',
                                    short_note: notesController.text,
                                    bird_count: int.parse(
                                        bird_countController.text),
                                    doctor_name: doctorController.text,
                                    f_name: _purposeselectedValue,);
                                  med_vacc.id = widget.vaccination_medication!.id!;
                                  int? id = await DatabaseHelper.updateHealth(
                                      med_vacc);
                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                }
                                else {
                                  Vaccination_Medication med_vacc = Vaccination_Medication(
                                    f_id: getFlockID(),
                                    disease: _diseaseelectedValue,
                                    medicine: medicineController.text,
                                    date: date,
                                    type: Utils.vaccine_medicine.toLowerCase()
                                        .contains("medi")
                                        ? 'Medication'
                                        : 'Vaccination',
                                    short_note: notesController.text,
                                    bird_count: int.parse(
                                        bird_countController.text),
                                    doctor_name: doctorController.text,
                                    f_name: _purposeselectedValue,);
                                  int? id = await DatabaseHelper.insertMedVac(
                                      med_vacc);
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

  Widget getDiseaseTypeList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _diseaseelectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _diseaseelectedValue = newValue!;

            print("Selected Disease $_diseaseelectedValue");

          });
        },
        items: _diseaseList.map<DropdownMenuItem<String>>((String value) {
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
      print("Select Date");
    }

    if(bird_countController.text.length == 0){
      valid = false;
      print("Add Birds Total added");
    }
    
    if (getDiseaseID() == -1){
      valid = false;
      print("Add Disease type");
    }

    if (medicineController.text.isEmpty){
      valid = false;
      print("Add Medicine type");
    }

    if (doctorController.text.isEmpty){
      valid = false;
      print("Add Doctor ");
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

  int getDiseaseID() {

    int selected_id = -1;
    for(int i=0;i<_subItemList.length;i++){
      if(_diseaseelectedValue.toLowerCase() == _subItemList.elementAt(i).name!.toLowerCase()){
        selected_id = _subItemList.elementAt(i).id!;
        break;
      }
    }

    print("selected disease id $selected_id");

    return selected_id;
  }

}
