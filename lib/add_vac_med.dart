import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/flock.dart';

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

  String date = "Choose date";
  final bird_countController = TextEditingController();
  final doctorController = TextEditingController();
  final medicineController = TextEditingController();
  final notesController = TextEditingController();


  @override
  void initState() {
    super.initState();

    if(widget.vaccination_medication != null){
      isEdit = true;
      _purposeselectedValue = widget.vaccination_medication!.f_name;
      _diseaseelectedValue = widget.vaccination_medication!.disease;
      date = widget.vaccination_medication!.date;
      bird_countController.text = "${widget.vaccination_medication!.bird_count}";
      doctorController.text = "${widget.vaccination_medication!.doctor_name}";
      medicineController.text = "${widget.vaccination_medication!.medicine}";
      notesController.text = "${widget.vaccination_medication!.short_note}";

    }

    getList();
    getDiseaseList();
    Utils.setupAds();

  }

  int activeStep = 0;
  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
      total_birds += flocks.elementAt(i).active_bird_count!;
    }

    if(!isEdit) {
      DateTime dateTime = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(dateTime);
      _purposeselectedValue = Utils.selected_flock!.f_name;
      bird_countController.text = total_birds.toString();
    }

    setState(() {

    });

  }

  void getDiseaseList() async {
    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(4);

    for(int i=0;i<_subItemList.length;i++){
      _diseaseList.add(_subItemList.elementAt(i).name!);
    }

    if(!isEdit)
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
                                  color: Utils.getThemeColorBlue(), size: 30),
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
                    height: heightScreen - 150,
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        activeStep==0? Container(
                            child: Column(children: [
                              Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    Utils.vaccine_medicine.toLowerCase().contains("medi")? isEdit?'EDIT'.tr()+" "+ 'Medication'.tr():'NEW_MEDICATION'.tr():isEdit?'EDIT'.tr()+" "+ 'Vaccination'.tr():'NEW_VACCINATION'.tr(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: Utils.getThemeColorBlue(),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  )),
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
                              SizedBox(height: 10,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Choose Disease'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                    child: getDiseaseTypeList(),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Medicine'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                  Container(
                                    width: widthScreen,
                                    height: 70,
                                    margin: EdgeInsets.only(left: 20, right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(70),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0)),

                                    ),
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
                                                BorderRadius.all(Radius.circular(20))),
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
                                ],
                              ),
                              SizedBox(height: 10,width: widthScreen),
                              Column(
                                children: [
                                  Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('BIRDS_COUNT'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                  Container(
                                    width: widthScreen,
                                    height: 70,
                                    padding: EdgeInsets.all(0),
                                    margin: EdgeInsets.only(left: 20, right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(70),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0)),

                                    ),
                                    child: Container(
                                      child: SizedBox(
                                        width: widthScreen,
                                        height: 60,
                                        child: TextFormField(
                                          maxLines: null,
                                          expands: true,
                                          controller: bird_countController,
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
                                          decoration:  InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.all(Radius.circular(20))),
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
                                ],
                              ),
                            ],),
                          ): SizedBox(width: 1,),
                        activeStep==1? Container(child: Column(children: [
                          SizedBox(height: 10,width: widthScreen),
                          Column(
                            children: [
                              Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    "DATE".tr()+" and "+"Doctor_Name".tr(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: Utils.getThemeColorBlue(),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  )),
                              Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                              Container(
                                width: widthScreen,
                                height: 70,
                                margin: EdgeInsets.only(left: 20, right: 20),
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

                          SizedBox(height: 10,width: widthScreen),
                          Column(
                            children: [
                              Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Doctor_Name'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                              Container(
                                width: widthScreen,
                                height: 70,
                                margin: EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(70),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20.0)),
                                ),
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
                                            BorderRadius.all(Radius.circular(20))),
                                        hintText: "Doctor_Name".tr(),
                                        hintStyle: TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                        labelStyle: TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10,width: widthScreen),
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
                        ],),): SizedBox(width: 1,),


                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
                            onTap: () async {

                              activeStep++;

                              if(activeStep==1){

                                if(medicineController.text.trim().length==0
                                    || bird_countController.text.trim().length==0)
                                {
                                  activeStep--;
                                  Utils.showToast("PROVIDE_ALL".tr());
                                }else{
                                  setState(() {

                                  });
                                }

                              }


                              if(activeStep==2){

                                if(doctorController.text.trim().length==0){
                                  activeStep--;
                                  Utils.showToast("PROVIDE_ALL".tr());
                                }else{
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
                                  } else {
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
                                activeStep==0? "NEXT" : "CONFIRM".tr(),
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
             int f_id = getFlockID();
             if (f_id == -1){
               bird_countController.text = total_birds.toString();
             }else {
               bird_countController.text = getBirdsCount().toString();
             }
             setState(() {

             });

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

  int total_birds = 0;

  int getBirdsCount() {

    int birds_count = 0;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        birds_count = flocks.elementAt(i).active_bird_count!;
        break;
      }
    }

    return birds_count;
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
