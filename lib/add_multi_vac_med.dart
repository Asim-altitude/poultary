import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/multiuser/model/multi_health_record.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/category_item.dart';
import 'model/flock.dart';
import 'model/health/multi_medicine.dart';
import 'model/medicine_stock_summary.dart';
import 'model/vaccine_stock_summary.dart';
import 'multiuser/utils/SyncStatus.dart';

class NewMultiVaccineMedicine extends StatefulWidget {
  Vaccination_Medication? vaccination_medication;
  NewMultiVaccineMedicine({Key? key, this.vaccination_medication}) : super(key: key);

  @override
  _NewMultiVaccineMedicine createState() => _NewMultiVaccineMedicine();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewMultiVaccineMedicine extends State<NewMultiVaccineMedicine>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _diseaseelectedValue = "";
  String _medselectedValue = "";
  String _acqusitionselectedValue = "";
  String _selectedUnit = "";

  List<String> doctorList = [];
  List<String> _purposeList = [];
  List<String> _diseaseList = [], medicineList = [];
  List<SubItem> _subItemList = [], medSubItem = [];

  List<String> _unitList = ["Tab","Cap","mg","g","kg","Vial","ml","L","Dust","Drop","Dose","Strip","Packet","Piece","Dozen","Carton","Spoon","Cup","Biscuit"];

  List<String> _selectedunitList = [];


  int chosen_index = 0;

  bool isEdit = false;

  String date = "Choose date";

  final qtycountController = TextEditingController();
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
      _diseaseList.add(_diseaseelectedValue);
      date = widget.vaccination_medication!.date;
      bird_countController.text = "${widget.vaccination_medication!.bird_count}";
      doctorController.text = "${widget.vaccination_medication!.doctor_name}";
      _medselectedValue = "${widget.vaccination_medication!.medicine}";
      notesController.text = "${widget.vaccination_medication!.short_note}";
      qtycountController.text = widget.vaccination_medication!.quantity;
      _selectedUnit = widget.vaccination_medication!.unit;
      _selectedunitList.add(_selectedUnit);
      getUsageItems();
    }

   // getDiseaseList();
    getList();
    Utils.setupAds();

    AnalyticsUtil.logScreenView(screenName: "add_health");
  }

  int? medicineCategoryID = -1;
  int activeStep = 0;
  List<Flock> flocks = [];
  List<MedicineStockSummary>? _stockSummary = [];
  List<VaccineStockSummary>? _vaccineStockSummary = [];

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

    _stockSummary = await DatabaseHelper.getMedicineStockSummary();
    _vaccineStockSummary = await DatabaseHelper.getVaccineStockSummary();

    doctorList = (await DatabaseHelper.getDistinctDoctorNames())!;

    String type = "Vaccine";
    if( Utils.vaccine_medicine.toLowerCase().contains("medi"))
      type = "Medicine";

    CategoryItem item = CategoryItem(id: null, name: type);
    medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);

    medSubItem = await DatabaseHelper.getSubCategoryList(medicineCategoryID!);

    for(int i=0;i<medSubItem.length;i++){
      medicineList.add(medSubItem.elementAt(i).name!);
    }


    CategoryItem disease = CategoryItem(id: null, name: "Disease");
    medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(disease);

    _subItemList = await DatabaseHelper.getSubCategoryList(medicineCategoryID!);

    for(int i=0;i<_subItemList.length;i++){
      _diseaseList.add(_subItemList.elementAt(i).name!);
    }

      if(!isEdit) {
        _medselectedValue = medicineList[0];
        _diseaseelectedValue = _diseaseList[0];
        print(_medselectedValue);
        populateAvailableUnits();
        TreatmentEntry treatmentEntry = TreatmentEntry(medicineName: _medselectedValue, diseaseName: _diseaseelectedValue, unit: "Tab", quantity: 1);
        multiMedicineList.add(treatmentEntry);
      }


    setState(() {

    });

  }

  void reloadStocks() async{
    _stockSummary = await DatabaseHelper.getMedicineStockSummary();
    _vaccineStockSummary = await DatabaseHelper.getVaccineStockSummary();

    setState(() {

    });

  }

  String availableStock = "0.0";
  String getAvailableStock() {

    availableStock = "0.0";
    String selectedMed = _medselectedValue.trim().toLowerCase();

    if(Utils.vaccine_medicine.toLowerCase().contains("medi")) {
      // Iterate through stock summary
      for (int i = 0; i < _stockSummary!.length; i++) {
        String stockMed = _stockSummary![i].medicineName.trim().toLowerCase();

        if (selectedMed == stockMed && _selectedUnit == _stockSummary![i].unit) {
            availableStock = _stockSummary![i].availableStock.toString();
        }
      }
    }else{
      for (int i = 0; i < _vaccineStockSummary!.length; i++) {
        String stockMed = _vaccineStockSummary![i].vaccineName.trim().toLowerCase();

        if (selectedMed == stockMed && _selectedUnit == _vaccineStockSummary![i].unit) {
          availableStock = _vaccineStockSummary![i].availableStock.toString();
        }
      }
    }

    return availableStock;

  }

  void populateAvailableUnits() {
    if (isEdit) return;

    // Ensure _selectedunitList is reset
    _selectedunitList = [];

    // Use a Set to store unique units
    Set<String> uniqueUnits = {};

    // Normalize selected medicine name (trim & lowercase)
    String selectedMed = _medselectedValue.trim().toLowerCase();

    if(Utils.vaccine_medicine.toLowerCase().contains("medi")) {
      // Iterate through stock summary
      for (int i = 0; i < _stockSummary!.length; i++) {
        String stockMed = _stockSummary![i].medicineName.trim().toLowerCase();

        if (selectedMed == stockMed) {
          uniqueUnits.add(_stockSummary![i].unit);
          print("SELECTED: " + _stockSummary![i].medicineName + " UNIT: " +
              _stockSummary![i].unit);
        }
      }
    }else{
      for (int i = 0; i < _vaccineStockSummary!.length; i++) {
        String stockMed = _vaccineStockSummary![i].vaccineName.trim().toLowerCase();

        if (selectedMed == stockMed) {
          uniqueUnits.add(_vaccineStockSummary![i].unit);
          print("SELECTED: " + _vaccineStockSummary![i].vaccineName + " UNIT: " +
              _vaccineStockSummary![i].unit);
        }
      }
    }

    // Convert to list
    _selectedunitList = uniqueUnits.toList();

    // If no units found, keep existing units
    if (_selectedunitList.isEmpty) {
      _selectedunitList = _unitList;
    }

    _selectedUnit = _selectedunitList[0];
    print("Final selected units: $_selectedunitList");
  }


  void getDiseaseList() async {

    if(isEdit)
      return;

    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(4);

    _diseaseList = [];

    for(int i=0;i<_subItemList.length;i++){
      _diseaseList.add(_subItemList.elementAt(i).name!);
    }

    if(!isEdit)
    _diseaseelectedValue = _diseaseList[0];

    print(_diseaseelectedValue);


    setState(() {

    });

  }

  Future<void> updateMultiRecords(int usageId) async {
    List<MedicineUsageItem> medList = [];
    for (var entry in multiMedicineList) {
      if (entry.id == null) {
        MedicineUsageItem item = MedicineUsageItem(
          usageId: usageId,
          medicineName: entry.medicineName!,
          diseaseName: entry.diseaseName!,
          unit: entry.unit!,
          quantity: entry.quantity ?? 0.0,
          sync_id: Utils.getUniueId(),
          last_modified: Utils.getTimeStamp(),
          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
        );

        await DatabaseHelper.insertMedicineUsageItem(item);
        medList.add(item);
      } else {
        MedicineUsageItem item = MedicineUsageItem(
          id: entry.id,
          usageId: usageId,
          medicineName: entry.medicineName!,
          diseaseName: entry.diseaseName!,
          unit: entry.unit!,
          quantity: entry.quantity ?? 0.0,
          sync_id: entry.sync_id,
          last_modified: Utils.getTimeStamp(),
          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
        );

        await DatabaseHelper.updateMedicineUsageItem(item);
        medList.add(item);
      }
    }

    multiHealthRecord!.usageItems = medList;
  }

  Future<void> addMultiRecords(int usageId) async {
    List<MedicineUsageItem> medList = [];
    for (var entry in multiMedicineList) {
      MedicineUsageItem item = MedicineUsageItem(
        usageId: usageId,
        medicineName: entry.medicineName!,
        diseaseName: entry.diseaseName!,
        unit: entry.unit!,
        quantity: entry.quantity ?? 0.0,
        sync_id: Utils.getUniueId(),
        last_modified: Utils.getTimeStamp(),
        modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
        farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
      );

      await DatabaseHelper.insertMedicineUsageItem(item);
      medList.add(item);
    }

    multiHealthRecord!.usageItems = medList;
  }

  MultiHealthRecord? multiHealthRecord;
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

                  if(activeStep==1)
                  {

                   /* if(qtycountController.text.trim().length==0)
                    {
                      activeStep--;
                      Utils.showToast("PROVIDE_ALL");
                    }else{
                      setState(() {

                      });
                    }*/
                    setState(() {

                    });
                  }

                  if(activeStep==2){

                    if(doctorController.text.trim().length==0 /*|| qtycountController.text.isEmpty */|| bird_countController.text.isEmpty){
                      activeStep--;
                      Utils.showToast("PROVIDE_ALL");
                    }else{
                      multiHealthRecord = MultiHealthRecord();
                      if(isEdit)
                      {
                        Vaccination_Medication med_vacc = Vaccination_Medication(
                          f_id: getFlockID(),
                          disease: "",
                          medicine: "",
                          date: date,
                          type: Utils.vaccine_medicine.toLowerCase()
                              .contains("medi")
                              ? 'Medication'
                              : 'Vaccination',
                          short_note: notesController.text,
                          bird_count: int.parse(
                              bird_countController.text),
                          doctor_name: doctorController.text,
                          f_name: _purposeselectedValue, quantity: qtycountController.text, unit: _selectedUnit,
                            sync_id: widget.vaccination_medication!.sync_id,
                            sync_status: SyncStatus.UPDATED,
                            last_modified: Utils.getTimeStamp(),
                            modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                            farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                            f_sync_id: getFlockSyncID());

                        med_vacc.id = widget.vaccination_medication!.id!;
                        int? id = await DatabaseHelper.updateHealth(med_vacc);

                        multiHealthRecord!.record = med_vacc;

                        await updateMultiRecords(med_vacc.id!);
                        Utils.showToast("SUCCESSFUL");

                        if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_health")){
                          await FireBaseUtils.updateMultiHealthRecord(multiHealthRecord!);
                        }

                        Navigator.pop(context);
                      }
                      else
                      {
                        Vaccination_Medication med_vacc = Vaccination_Medication(
                          f_id: getFlockID(),
                          disease: "",
                          medicine: "",
                          date: date,
                          type: Utils.vaccine_medicine.toLowerCase()
                              .contains("medi")
                              ? 'Medication'
                              : 'Vaccination',
                          short_note: notesController.text,
                          bird_count: int.parse(
                              bird_countController.text),
                          doctor_name: doctorController.text,
                          f_name: _purposeselectedValue, quantity: qtycountController.text, unit: _selectedUnit,
                            sync_id: Utils.getUniueId(),
                            sync_status: SyncStatus.SYNCED,
                            last_modified: Utils.getTimeStamp(),
                            modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                            farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                            f_sync_id: getFlockSyncID());
                        int? id = await DatabaseHelper.insertMedVac(med_vacc);
                        multiHealthRecord!.record = med_vacc;
                        await addMultiRecords(id!);
                        Utils.showToast("SUCCESSFUL");

                        if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_health")){
                          await FireBaseUtils.uploadMultiHealthRecord(multiHealthRecord!);
                        }
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

                /*ClipRRect(
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
    */

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
                  // height: heightScreen - 140,
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
                            SizedBox(height: 5),
                            _buildSimpleDropdownField(getDropDownList()),

                            SizedBox(height: 15),

                            // Choose Disease
                            /*Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInputLabel("Choose Disease".tr(), Icons.sick),
                                InkWell(
                                    onTap: () async {
                                      Utils.selected_category = 4;
                                      Utils.selected_category_name = "Disease";
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubCategoryScreen(),
                                        ),
                                      );
                                      getDiseaseList();
                                      setState(() {

                                      });
                                    },
                                    child: Icon(Icons.add_circle, size: 27, color: Colors.blue,)),
                              ],
                            ),*/
                            /*SizedBox(height: 5),
                            _buildDropdownField(getDiseaseTypeList()),
*/
                            SizedBox(height: 15),
                            // Choose Medicine
                          /*  Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInputLabel(Utils.vaccine_medicine.toLowerCase().contains("medi")? "Medicine name".tr() : "Vaccine name".tr(), Icons.medical_information),
                                InkWell(
                                    onTap: () async {
                                      if(Utils.vaccine_medicine.toLowerCase().contains("medi")) {
                                        Utils.selected_category = medicineCategoryID!;
                                        Utils.selected_category_name = "Medicine";
                                      }else{
                                        Utils.selected_category = medicineCategoryID!;
                                        Utils.selected_category_name = "Vaccine";
                                      }
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubCategoryScreen(),
                                        ),
                                      );
                                      getDiseaseList();
                                      setState(() {

                                      });
                                    },
                                    child: Icon(Icons.add_circle, size: 27, color: Colors.blue,)),
                              ],
                            ),
                            SizedBox(height: 5),
                            _buildDropdownField(getMedicineTypeList()),
                            SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    child: Column(
                                      children: [
                                        _buildInputLabel("Quantity".tr(), Icons.numbers),
                                        SizedBox(height: 8),
                                        _buildFLoatField(qtycountController, "Quantity".tr()),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Container(
                                    child: Column(
                                      children: [
                                        _buildInputLabel("Select Unit".tr(), Icons.accessibility_sharp),
                                        SizedBox(height: 8),
                                        _buildDropdownField(getUnitTypeList()),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if(!_medselectedValue.isEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    alignment: Alignment.centerRight,
                                    child: Text('Stock'.tr()+': ${getAvailableStock()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: getAvailableStock()=="0.0"? Colors.red :Colors.green),),),
                                  getAvailableStock()=="0.0"? InkWell(
                                    onTap: () async{
                                      if(Utils.vaccine_medicine.toLowerCase().contains("medi")) {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MedicineStockScreen(id: medicineCategoryID!),
                                          ),);
                                        reloadStocks();

                                      }else{
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VaccineStockScreen(id: medicineCategoryID!),
                                          ),
                                        );

                                        reloadStocks();
                                      }

                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: 100,
                                      padding: EdgeInsets.all(5),
                                      margin: EdgeInsets.only(top: 5),
                                      decoration: BoxDecoration(
                                        color: Utils.getThemeColorBlue(),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                      ),
                                      child: Text('Add Stock'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),),
                                    ),
                                  ): SizedBox(width: 1,)
                                ],
                              ),*/

                            Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: multiMedicineList.length,
                                  itemBuilder: (context, i) => buildMultiMedicineItem(i),
                                ),

                                SizedBox(height: 10),

                                /// ➕ Add New Entry Button
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 300),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        TreatmentEntry treatmentEntry = TreatmentEntry(medicineName: _medselectedValue, diseaseName: _diseaseelectedValue, unit: "Tab", quantity: 1);
                                        multiMedicineList.add(treatmentEntry);
                                      });
                                    },
                                    child: Visibility(
                                      visible: isEdit? false : true,
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Utils.getThemeColorBlue(),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, color: Colors.white),
                                            SizedBox(width: 6),
                                            Text("Add Another Treatment".tr(), style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            )

                          ],
                        ),
                      )
                          : SizedBox(width: 1,),
                      activeStep==1? Container(
                        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                            SizedBox(height: 15),
    // Bird Count
                            _buildInputLabel("BIRDS_COUNT".tr(), Icons.numbers),
                            SizedBox(height: 5),
                            _buildNumberField(bird_countController, "BIRDS_COUNT".tr()),
                            SizedBox(height: 15),
                            // Date Picker
                            _buildInputLabel("DATE".tr(), Icons.calendar_today),
                            SizedBox(height: 5),
                            _buildDatePickerField(),

                            SizedBox(height: 15),

                            // Doctor Name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInputLabel("Doctor_Name".tr(), Icons.person),
                               doctorList.length >0? InkWell(
                                   onTap: () {
                                     showDoctorNameDialog(context, doctorList, (value) {
                                       doctorController.text = value;
                                       setState(() {

                                       });
                                     });
                                   },
                                   child: Icon(Icons.list_alt, color: Colors.blue, size: 25,)) : SizedBox.shrink()
                              ],
                            ),
                            SizedBox(height: 5),
                            _buildTextField(doctorController, "Doctor_Name".tr()),

                            SizedBox(height: 15),

                            // Description
                            _buildInputLabel("DESCRIPTION_1".tr(), Icons.description),
                            SizedBox(height: 8),
                            _buildMultilineTextField(notesController, "NOTES_HINT".tr()),
                          ],
                        ),
                      ) : SizedBox(width: 1,),

                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget buildMultiMedicineItem(int index) {
    final entry = multiMedicineList[index];

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Treatment".tr()+" ${index + 1}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                if (index > 0 && !isEdit)
                  InkWell(
                      onTap: () => setState(() => multiMedicineList.removeAt(index)),
                      child: Icon(Icons.close, color: Colors.red, size: 22)),
              ],
            ),

            SizedBox(height: 10),

            // Disease Dropdown
            _titleWithIcon("Disease".tr(), Icons.sick, () async {
              /*int? catID = await DatabaseHelper.addCategoryIfNotExists(
                CategoryItem(id: null, ca: "Disease", category_type: '', name: ''),
              );
              await addNewItem(catID!, 0);*/
            }),

            SizedBox(height: 6),

            _buildDropdownField(
              _diseaseList,
              value: entry.diseaseName,
              onChanged: (value) {
                setState(() {
                  entry.diseaseName = value;
                });
              },
            ),

            SizedBox(height: 12),

            // Medicine Dropdown
            _titleWithIcon(
              Utils.vaccine_medicine.toLowerCase().contains("medi") ? "Medicine" : "Vaccine",
              Icons.medication_rounded,
                  () async {
                String type = Utils.vaccine_medicine.toLowerCase().contains("medi")
                    ? "Medicine"
                    : "Vaccine";

               /* int? catID = await DatabaseHelper.addCategoryIfNotExists(
                  CategoryItem(id: null, category_name: type, category_type: ''),
                );
                await addNewItem(catID!, 1);*/
              },
            ),

            SizedBox(height: 6),

            _buildDropdownField(
              medicineList,
              value: entry.medicineName,
              onChanged: (value) {
                setState(() {
                  entry.medicineName = value;
                });
              },
            ),

            SizedBox(height: 12),

            Row(
              children: [
                // Qty Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quantity".tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      _buildFloatField(
                        value: entry.quantity,
                        onChanged: (v) {
                          setState(() {
                            entry.quantity = v ?? 0.0;
                          });
                        },
                      )

                    ],
                  ),
                ),
                SizedBox(width: 10),
                // Unit Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Unit".tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      _buildDropdownField(
                        _unitList,
                        value: entry.unit,
                        onChanged: (value) {
                          setState(() => entry.unit = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // STOCK DISPLAY
            if (entry.medicineId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildStockWidget(entry, index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _titleWithIcon(String text, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        InkWell(onTap: onAdd, child: Icon(Icons.add_circle, size: 20, color: Utils.getThemeColorBlue())),
      ],
    );
  }

  Widget _buildStockWidget(TreatmentEntry entry, int index) {
    bool outOfStock = entry.availableStock <= 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: outOfStock ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Stock: ${entry.availableStock}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: outOfStock ? Colors.red : Colors.green,
            ),
          ),
          if (outOfStock)
            InkWell(
              onTap: () async {
                // Implement your stock add logic here
              },
              child: Text("Add Stock",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue())),
            )
        ],
      ),
    );
  }

  Widget _buildDropdownField(
      List<String> items, {
        required String? value,
        required Function(String?) onChanged,
        String hint = "Select",
      }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Custom Dropdown Field
  Widget _buildSimpleDropdownField(Widget dropdown) {
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


  Future<void> showDoctorNameDialog(BuildContext context, List<String> doctorNames, Function(String) onSelected) async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Doctor",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: doctorNames.length,
                  itemBuilder: (context, index) {
                    final name = doctorNames[index];
                    return ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text(name),
                      onTap: () {
                        Navigator.pop(context); // close dialog
                        onSelected(name); // return selected name
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        maxLines: 2,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
      ),
    );
  }


/*
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
*/

// Custom Number Field
  Widget _buildNumberField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // Allows digits and one decimal point
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;

            // Allow empty input
            if (text.isEmpty) return newValue;

            // Prevent multiple decimal points
            if (text.contains('.') && text.split('.').length > 2) {
              return oldValue;
            }

            // Ensure valid float
            return double.tryParse(text) == null ? oldValue : newValue;
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

  Widget _buildFLoatField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true), // Enables decimal input
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')), // Allows digits and up to 2 decimal places
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;

            // Allow empty input
            if (text.isEmpty) return newValue;

            // Prevent multiple decimal points
            if (text == ".") return oldValue; // Disallow single dot input at start
            if (text.contains('..')) return oldValue; // Prevent multiple decimal points

            // Ensure valid float
            return double.tryParse(text) == null ? oldValue : newValue;
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

  /*// Custom Number Field
  Widget _buildFloatField(TextEditingController controller, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[0-9].")),
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
*/
  Widget _buildFloatField({
    required double? value,
    required Function(double?) onChanged,
    String hint = "Qty",
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextFormField(
        initialValue: value != null && value != 0.0 ? value.toString() : "",
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;
            if (text.isEmpty) return newValue;
            if (text.contains('..')) return oldValue;
            if (text == ".") return oldValue;
            return double.tryParse(text) == null ? oldValue : newValue;
          }),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        onChanged: (txt) {
          if (txt.isEmpty) {
            onChanged(null);
          } else {
            onChanged(double.tryParse(txt));
          }
        },
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

  Widget getMedicineTypeList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _medselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _medselectedValue = newValue!;
            if (!isEdit)
              populateAvailableUnits();

            setState(() {});
            print("Selected Medicine $_medselectedValue");

          });
        },
        items: medicineList.map<DropdownMenuItem<String>>((String value) {
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

  Widget getUnitTypeList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _selectedUnit,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _selectedUnit = newValue!;

            print("Selected Unit $_selectedUnit");

          });
        },
        items: _selectedunitList.map<DropdownMenuItem<String>>((String value) {
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



    if (doctorController.text.isEmpty){
      valid = false;
      print("Add Doctor ");
    }


    return valid;

  }

  String? getFlockSyncID() {

    String? selected_id = "unknown";
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).sync_id;
        break;
      }
    }

    return selected_id;
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


  List<TreatmentEntry> multiMedicineList = [];

  Future<void> getUsageItems() async {
    var mMedicineList = await DatabaseHelper.getMedicineItemsByUsage(widget.vaccination_medication!.id!);

    for(int i=0;i<mMedicineList.length;i++){
      MedicineUsageItem medicineUsageItem = mMedicineList[i];
      TreatmentEntry treatmentEntry = TreatmentEntry(id: medicineUsageItem.id,diseaseName: medicineUsageItem.diseaseName, medicineName: medicineUsageItem.medicineName, sync_id: medicineUsageItem.sync_id, quantity: medicineUsageItem.quantity, unit: medicineUsageItem.unit);
      multiMedicineList.add(treatmentEntry);
    }

    setState(() {

    });

  }



}


class TreatmentEntry {
  int? id;
  int? diseaseId;
  String? diseaseName;

  int? medicineId;
  String? medicineName;

  String? unit;
  double quantity;

  String? sync_id;

  double availableStock; // optional stored to avoid recalculation

  TreatmentEntry({
    this.id,
    this.diseaseId,
    this.diseaseName,
    this.medicineId,
    this.medicineName,
    this.unit,
    this.sync_id,
    this.quantity = 0,
    this.availableStock = 0,
  });
}
