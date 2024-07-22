import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class NewEggCollection extends StatefulWidget {

  Eggs? eggs;
  bool isCollection;
  NewEggCollection({Key? key, required this.isCollection, required this.eggs}) : super(key: key);

  @override
  _NewEggCollection createState() => _NewEggCollection(this.isCollection);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewEggCollection extends State<NewEggCollection>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

   bool isCollection;
  _NewEggCollection(this.isCollection);

  @override
  void dispose() {
    super.dispose();

  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _reductionReasons = [
    'SOLD'.tr(),'PERSONAL_USE'.tr(),'MORTALITY'.tr(),'LOST'.tr(),'OTHER'.tr()];

  int chosen_index = 0;

  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    if(widget.eggs != null) {

      isEdit = true;
      date = widget.eggs!.date!;
      totalEggsController.text = "${widget.eggs!.total_eggs}";
      goodEggsController.text ="${widget.eggs!.good_eggs}";
      badEggsController.text =  "${widget.eggs!.bad_eggs}";
      notesController.text = "${widget.eggs!.short_note!}";
      _reductionReasonValue = "${widget.eggs!.reduction_reason}";
      _purposeselectedValue = widget.eggs!.f_name!;

    }else
    {
      DateTime dateTime = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(dateTime);

      _reductionReasonValue = _reductionReasons[0];
      totalEggsController.text = "10";
      goodEggsController.text ="5";
      badEggsController.text =  "5";

    }

    getList();
    Utils.showInterstitial();
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

    _purposeselectedValue = _purposeList[0];

    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose date";
  final nameController = TextEditingController();
  final totalEggsController = TextEditingController();
  final goodEggsController = TextEditingController();
  final badEggsController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;

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
                                Navigator.pop(context,"Egg ADDED");
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
                          SizedBox(height: 10,width: widthScreen),
                          activeStep == 0? Container(
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text(
                                      isCollection? isEdit? "EDIT".tr() +" "+ "COLLECTION".tr(): "NEW".tr()+" "+ "Collection" : isEdit? "EDIT".tr() +" "+ "REDUCTION".tr():"NEW".tr()+" "+"REDUCTION".tr(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    )),
                                SizedBox(height: 20,width: widthScreen),
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

                                SizedBox(height: 10,width: widthScreen),
                                Column(
                                  children: [
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Good Eggs'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                                            onChanged: (text) {
                                              if (text.isEmpty){
                                                good_eggs = 0;
                                              }else{
                                                good_eggs = int.parse(text);
                                              }
                                              calculateTotalEggs();
                                            },
                                            controller: goodEggsController,
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
                                              hintText: 'Good Eggs'.tr(),
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
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Bad Eggs'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                            onChanged: (text) {
                                              if (text.isEmpty){
                                                bad_eggs = 0;
                                              }else{
                                                bad_eggs = int.parse(text);
                                              }

                                              calculateTotalEggs();
                                            },
                                            controller: badEggsController,
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
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(20))),
                                              hintText: "Bad Eggs".tr(),
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
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Total Eggs'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                            readOnly: true,
                                            controller: totalEggsController,
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
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(20))),
                                              hintText: "Total Eggs".tr(),
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
                              ],
                            ),
                          ):SizedBox(width: 1,),

                          activeStep==1? Container(
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text(
                                      "Choose date".tr() +" and "+"Description".tr(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    )),
                                SizedBox(height: 20,width: widthScreen),

                                !isCollection? SizedBox(height: 10,width: widthScreen): SizedBox(height: 0,width: widthScreen),
                                !isCollection? Column(
                                  children: [
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('REDUCTIONS_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                                      child: getReductionList(),
                                    ),
                                  ],
                                ):SizedBox(height: 0,width: widthScreen),

                                SizedBox(height: 10,width: widthScreen),
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
                                      child: Text(Utils.getFormattedDate(date), style: TextStyle(
                                          color: Colors.black, fontSize: 16),),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 10,width: widthScreen),
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
                                SizedBox(height: 10,width: widthScreen),

                              ],
                            ),
                          ):SizedBox(width: 1,),


                          InkWell(
                            onTap: () async {

                              good_eggs = int.parse(goodEggsController.text);
                              bad_eggs = int.parse(badEggsController.text);

                              activeStep++;
                              if(activeStep==1) {
                               bool emptyCheck = true;
                                if(goodEggsController.text.toString().trim() == ""
                                    || badEggsController.text.toString().trim() =="")
                                {
                                 activeStep--;
                                 Utils.showToast("PROVIDE_ALL".tr());

                                }
                               setState(() {

                               });
                              }

                              if(activeStep==2) {
                                await DatabaseHelper.instance.database;
                                if (isCollection){
                                  if(isEdit){
                                    widget.eggs!.f_id = getFlockID();
                                    widget.eggs!.f_name = _purposeselectedValue;
                                    widget.eggs!.date = this.date;
                                    widget.eggs!.good_eggs = int.parse(goodEggsController.text);
                                    widget.eggs!.bad_eggs =  int.parse(badEggsController.text);
                                    widget.eggs!.total_eggs = int.parse(
                                        totalEggsController.text);
                                    widget.eggs!.short_note = notesController.text;
                                    await DatabaseHelper.updateEggCollection(widget.eggs!);

                                    Utils.showToast("SUCCESSFUL".tr());
                                    Navigator.pop(context, "Egg ADDED");
                                  }else {
                                    int? id = await DatabaseHelper
                                        .insertEggCollection(Eggs(
                                        f_id: getFlockID(),
                                        f_name: _purposeselectedValue,
                                        image: '',
                                        good_eggs: this.good_eggs,
                                        bad_eggs: bad_eggs,
                                        total_eggs: int.parse(
                                            totalEggsController.text),
                                        short_note: notesController.text,
                                        date: date,
                                        reduction_reason: '',
                                        isCollection: 1));
                                    Utils.showToast("SUCCESSFUL".tr());
                                    Navigator.pop(context, "Egg ADDED");
                                  }
                                }else{
                                  if(isEdit){
                                    widget.eggs!.f_id = getFlockID();
                                    widget.eggs!.f_name = _purposeselectedValue;
                                    widget.eggs!.date = this.date;
                                    widget.eggs!.good_eggs =  int.parse(goodEggsController.text);
                                    widget.eggs!.bad_eggs = int.parse(badEggsController.text);
                                    widget.eggs!.reduction_reason = _reductionReasonValue;
                                    widget.eggs!.total_eggs = int.parse(
                                        totalEggsController.text);
                                    widget.eggs!.short_note = notesController.text;
                                    await DatabaseHelper.updateEggCollection(widget.eggs!);

                                    Utils.showToast("SUCCESSFUL".tr());
                                    Navigator.pop(context, "Egg ADDED");
                                  } else {
                                    int? id = await DatabaseHelper
                                        .insertEggCollection(Eggs(
                                        f_id: getFlockID(),
                                        f_name: _purposeselectedValue,
                                        image: '',
                                        good_eggs: int.parse(goodEggsController.text),
                                        bad_eggs: int.parse(badEggsController.text),
                                        total_eggs: int.parse(totalEggsController.text),
                                        short_note: notesController.text,
                                        date: date,
                                        reduction_reason: _reductionReasonValue,
                                        isCollection: 0));
                                    Utils.showToast("SUCCESSFUL".tr());
                                    Navigator.pop(context, "Egg Reduced");
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
                              margin: EdgeInsets.all(20),
                              child: Text(
                                activeStep==0? "NEXT".tr() : "CONFIRM".tr(),
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

    if(date.toLowerCase().contains("Choose date")){
      valid = false;
      print("Select Date");
    }

    if(totalEggsController.text.length == 0){
      valid = false;
      print("No eggs added");
    }



    return valid;

  }

  void calculateTotalEggs() {
    totalEggsController.text = (good_eggs + bad_eggs).toString();
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
