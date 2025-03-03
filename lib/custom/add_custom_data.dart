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
        bottomNavigationBar: Container(
          margin: EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show Previous Button only if activeStep > 0
              if (activeStep > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        activeStep--;
                      });
                    },
                    child: Container(
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
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
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                          SizedBox(width: 5),
                          Text(
                            "Previous".tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Next or Finish Button
              Expanded(
                child: GestureDetector(
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
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: activeStep == 1
                            ? [Utils.getThemeColorBlue(), Colors.greenAccent] // Finish Button
                            : [Utils.getThemeColorBlue(), Colors.blueAccent], // Next Button
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // More rounded
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activeStep == 1 ? "SAVE".tr() : "Next".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          activeStep == 1 ? Icons.check_circle : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    activeStepTextColor: Colors.blue.shade900,
                    finishedStepTextColor: Utils.getThemeColorBlue(),
                    internalPadding: 20, // Reduce padding for better spacing
                    stepShape: StepShape.circle,
                    stepBorderRadius: 20,
                    borderThickness: 3, // Balanced progress line thickness
                    showLoadingAnimation: false,
                    stepRadius: 15, // Reduced step size to fit screen
                    showStepBorder: false,
                    lineStyle: LineStyle(
                      lineLength: 50,
                      lineType: LineType.normal,
                      defaultLineColor: Colors.grey.shade300,
                      activeLineColor: Colors.blueAccent,
                      finishedLineColor: Utils.getThemeColorBlue(),
                    ),
                    steps: [
                      EasyStep(
                        customStep: _buildStepIcon(Icons.backup_table_sharp, 0),
                        title: 'Quantity'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.date_range, 1),
                        title: 'DATE'.tr(),
                      ),

                    ],
                    onStepReached: (index) => setState(() => activeStep = index),
                  ),
                  Container(
                    alignment: Alignment.center,

                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 40,width: widthScreen),

                          Center(
                            child: Text(
                              isEdit?"EDIT".tr() +" ${widget.customCategory.name.tr()}":"NEW".tr()+" ${widget.customCategory.name.tr()}",
                              style: TextStyle(
                                color: Utils.getThemeColorBlue(),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 30,width: widthScreen),

                          activeStep==0? Container(
                            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            padding: EdgeInsets.all(18),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Title
                                Center(
                                  child: Text(
                                  "Quantity".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Choose Flock
                                _buildInputLabel("CHOOSE_FLOCK_1".tr(), Icons.pets),
                                SizedBox(height: 8),
                                _buildDropdownField(getDropDownList()),

                                SizedBox(height: 20),

                                // Feed Quantity Input
                                _buildInputLabel('Quantity'.tr()+"(${widget.customCategory.unit.tr()})", Icons.scale),
                                SizedBox(height: 8),
                                _buildNumberInputField(quantityController,'Quantity'.tr()+"(${widget.customCategory.unit.tr()})"),

                                SizedBox(height: 20),
                              ],
                            ),
                          ):SizedBox(width: 1,),
                          /*Container(
                            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            padding: EdgeInsets.all(18),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Title
                                Center(
                                  child: Text(
                                    isEdit?"EDIT".tr() +" ${widget.customCategory.name.tr()}":"NEW".tr()+" ${widget.customCategory.name.tr()}",
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Choose Flock
                                _buildInputLabel("CHOOSE_FLOCK_1".tr(), Icons.pets),
                                SizedBox(height: 8),
                                _buildDropdownField(getDropDownList()),

                                SizedBox(height: 20),

                                // Feed Quantity Input
                                _buildInputLabel('Quantity'.tr()+"(${widget.customCategory.unit})", Icons.scale),
                                SizedBox(height: 8),
                                _buildNumberInputField(quantityController,'Quantity'.tr()+"(${widget.customCategory.unit})"),

                                SizedBox(height: 20),
                              ],
                            ),
                          )*/
                          activeStep==1? Container(
                            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            padding: EdgeInsets.all(18),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Center(
                                  child: Text(
                                    "DATE".tr()+" & "+ "DESCRIPTION_1".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Date Picker
                                _buildInputLabel("DATE".tr(), Icons.calendar_today),
                                SizedBox(height: 8),
                                _buildDateField(Utils.getFormattedDate(date), pickDate),

                                SizedBox(height: 20),

                                // Description Input
                                _buildInputLabel("DESCRIPTION_1".tr(), Icons.description),
                                SizedBox(height: 8),
                                _buildTextAreaField(notesController, "NOTES_HINT".tr()),

                                SizedBox(height: 20),
                              ],
                            ),
                          ):SizedBox(width: 1,),


                         /* SizedBox(height: 10,width: widthScreen),
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
                          )*/

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

  Widget _buildStepIcon(IconData icon, int step) {
    bool isActive = activeStep == step; // Current step
    bool isFinished = activeStep > step; // Completed steps

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFinished
            ? Utils.getThemeColorBlue() // Completed step
            : isActive
            ? Utils.getThemeColorBlue() // Current step
            : Colors.grey.shade400, // Upcoming step
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isFinished ? Icons.check : icon, // ✅ Show tick if step is done
          color: Colors.white,
          size: 20,
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
            Text(dateText, style: TextStyle(fontSize: 16, color: Colors.black)),
            Icon(Icons.calendar_today, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

// Custom Text Area for Description
  Widget _buildTextAreaField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
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
          label,
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

  // Custom Number Input Field
  Widget _buildNumberInputField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r"^\d*\.?\d*$"),
          ), // Allows only numbers or float based on flag
        ],
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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
