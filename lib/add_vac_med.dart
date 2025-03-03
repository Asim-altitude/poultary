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
                        customStep: _buildStepIcon(Icons.medical_information, 0),
                        title: 'Medicine'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.date_range, 1),
                        title: 'DATE'.tr(),
                      ),

                    ],
                    onStepReached: (index) => setState(() => activeStep = index),
                  ),

                  Container(
                    height: heightScreen - 150,
                    alignment: Alignment.center,
                    child: Column(
                        children: [
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
                              // Title
                              Center(
                                child: Text(
                                  Utils.vaccine_medicine.toLowerCase().contains("medi")
                                      ? (isEdit ? 'EDIT'.tr() + " " + 'Medication'.tr() : 'NEW_MEDICATION'.tr())
                                      : (isEdit ? 'EDIT'.tr() + " " + 'Vaccination'.tr() : 'NEW_VACCINATION'.tr()),
                                  style: TextStyle(
                                    color: Utils.getThemeColorBlue(),
                                    fontSize: 22,
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

                              // Choose Disease
                              _buildInputLabel("Choose Disease".tr(), Icons.sick),
                              SizedBox(height: 8),
                              _buildDropdownField(getDiseaseTypeList()),

                              SizedBox(height: 20),

                              // Medicine Name
                              _buildInputLabel("Medicine".tr(), Icons.medical_services),
                              SizedBox(height: 8),
                              _buildTextField(medicineController, "MED_NAME".tr()),

                              SizedBox(height: 20),

                              // Bird Count
                              _buildInputLabel("BIRDS_COUNT".tr(), Icons.numbers),
                              SizedBox(height: 8),
                              _buildNumberField(bird_countController, "BIRDS_COUNT".tr()),
                            ],
                          ),
                        )
                            : SizedBox(width: 1,),
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
                                  "DATE".tr() + " & " + "Doctor_Name".tr(),
                                  style: TextStyle(
                                    color: Utils.getThemeColorBlue(),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Date Picker
                              _buildInputLabel("DATE".tr(), Icons.calendar_today),
                              SizedBox(height: 8),
                              _buildDatePickerField(),

                              SizedBox(height: 20),

                              // Doctor Name
                              _buildInputLabel("Doctor_Name".tr(), Icons.person),
                              SizedBox(height: 8),
                              _buildTextField(doctorController, "Doctor_Name".tr()),

                              SizedBox(height: 20),

                              // Description
                              _buildInputLabel("DESCRIPTION_1".tr(), Icons.description),
                              SizedBox(height: 8),
                              _buildMultilineTextField(notesController, "NOTES_HINT".tr()),
                            ],
                          ),
                        )
                            : SizedBox(width: 1,),



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

// Custom Date Picker Field
  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () {
        pickDate();
      },
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
            Text(
              Utils.getFormattedDate(date),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
          ],
        ),
      ),
    );
  }

// Custom Text Field
  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      ),
    );
  }

// Custom Multiline Text Field
  Widget _buildMultilineTextField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      ),
    );
  }


// Custom Dropdown Field
  Widget _buildDropdownField(Widget dropdown) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: dropdown,
    );
  }

// Custom Number Field
  Widget _buildNumberField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;
            return text.isEmpty ? newValue : double.tryParse(text) == null ? oldValue : newValue;
          }),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
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
