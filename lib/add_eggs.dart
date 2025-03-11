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

  // List of possible bird egg colors
  final List<String> eggColors = [
    'white',
    'brown',
    'blue',
    'green',
    'speckled',
    'pink',
    'cream',
    'olive',
  ];

  // Selected color
  String? selectedColor = "";

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
    'SOLD','PERSONAL_USE','LOST','OTHER'];

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
      selectedColor = widget.eggs!.egg_color;

    }else
    {
      DateTime dateTime = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(dateTime);

      _reductionReasonValue = _reductionReasons[0];
      totalEggsController.text = "10";
      goodEggsController.text ="5";
      badEggsController.text =  "5";
      selectedColor = eggColors[0];
    }

    getList();
    Utils.showInterstitial();
    Utils.setupAds();

  }

  List<Flock> flocks = [];
  void getList() async {

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
        bottomNavigationBar:  Container(
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
                      try {
                        if (isCollection) {
                          if (isEdit) {
                            widget.eggs!.f_id = getFlockID();
                            widget.eggs!.f_name =
                                _purposeselectedValue;
                            widget.eggs!.date = this.date;
                            widget.eggs!.egg_color = selectedColor;
                            widget.eggs!.good_eggs =
                                int.parse(goodEggsController.text);
                            widget.eggs!.bad_eggs =
                                int.parse(badEggsController.text);
                            widget.eggs!.total_eggs = int.parse(
                                totalEggsController.text);
                            widget.eggs!.short_note =
                                notesController.text;
                            await DatabaseHelper.updateEggCollection(
                                widget.eggs!);

                            Utils.showToast("SUCCESSFUL".tr());
                            Navigator.pop(context, "Egg ADDED");
                          }
                          else {
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
                                isCollection: 1,
                                egg_color: selectedColor));
                            Utils.showToast("SUCCESSFUL".tr());
                            Navigator.pop(context, "Egg ADDED");
                          }
                        } else {
                          if (isEdit) {
                            widget.eggs!.f_id = getFlockID();
                            widget.eggs!.f_name =
                                _purposeselectedValue;
                            widget.eggs!.date = this.date;
                            widget.eggs!.egg_color = selectedColor;
                            widget.eggs!.good_eggs =
                                int.parse(goodEggsController.text);
                            widget.eggs!.bad_eggs =
                                int.parse(badEggsController.text);
                            widget.eggs!.reduction_reason =
                                _reductionReasonValue;
                            widget.eggs!.total_eggs = int.parse(
                                totalEggsController.text);
                            widget.eggs!.short_note =
                                notesController.text;
                            await DatabaseHelper.updateEggCollection(
                                widget.eggs!);

                            Utils.showToast("SUCCESSFUL".tr());
                            Navigator.pop(context, "Egg ADDED");
                          }
                          else {
                            int? id = await DatabaseHelper
                                .insertEggCollection(Eggs(
                                f_id: getFlockID(),
                                f_name: _purposeselectedValue,
                                image: '',
                                good_eggs: int.parse(
                                    goodEggsController.text),
                                bad_eggs: int.parse(
                                    badEggsController.text),
                                total_eggs: int.parse(
                                    totalEggsController.text),
                                short_note: notesController.text,
                                date: date,
                                reduction_reason: _reductionReasonValue,
                                isCollection: 0,
                                egg_color: selectedColor));
                            Utils.showToast("SUCCESSFUL".tr());
                            Navigator.pop(context, "Egg Reduced");
                          }
                        }
                      }
                      catch (ex) {
                        activeStep = 2;
                        Utils.showToast(ex.toString());
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
                        customStep: _buildStepIcon(Icons.egg, 0),
                        title: 'Eggs'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.color_lens, 1),
                        title: 'DATE'.tr()+" & " +"Color".tr(),
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
                          SizedBox(height: 10,width: widthScreen),
                          activeStep == 0? Container(
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
                                    isCollection
                                        ? isEdit
                                        ? "EDIT".tr() + " " + "COLLECTION".tr()
                                        : "NEW".tr() + " " + "Collection".tr()
                                        : isEdit
                                        ? "EDIT".tr() + " " + "Reduction".tr()
                                        : "NEW".tr() + " " + "Reduction".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Choose Flock
                                _buildInputLabel("CHOOSE_FLOCK_1".tr(), Icons.list_alt),
                                SizedBox(height: 5),
                                _buildDropdownField(getDropDownList()),

                                SizedBox(height: 20),

                                // Good Eggs Input
                                _buildInputLabel("Good Eggs".tr(), Icons.egg),
                                SizedBox(height: 5),
                                _buildInputFieldIntFLoat(
                                  goodEggsController,
                                  "Enter Good Eggs".tr(),
                                  Icons.check_circle,
                                  onChanged: (text) {
                                    good_eggs = text.isEmpty ? 0 : int.parse(text);
                                    calculateTotalEggs();
                                  },
                                  isFloat: false
                                ),

                                SizedBox(height: 20),

                                // Bad Eggs Input
                                _buildInputLabel("Bad Eggs".tr(), Icons.egg_outlined),
                                SizedBox(height: 5),
                                _buildInputFieldIntFLoat(
                                  badEggsController,
                                  "Enter Bad Eggs".tr(),
                                  Icons.cancel,
                                  onChanged: (text) {
                                    bad_eggs = text.isEmpty ? 0 : int.parse(text);
                                    calculateTotalEggs();
                                  },
                                  isFloat: false
                                ),

                                SizedBox(height: 20),

                                // Total Eggs (Read-Only)
                                _buildInputLabel("Total Eggs".tr(), Icons.shopping_basket),
                                SizedBox(height: 8),
                                _buildInputField(
                                  totalEggsController,
                                  "Total Eggs".tr(),
                                  Icons.numbers,
                                  readOnly: true,

                                ),
                              ],
                            ),
                          )

                              :SizedBox(width: 1,),

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
                                    "Choose Date & Description".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Reduction List (Only if not Collection)
                                if (!isCollection) ...[
                                  _buildInputLabel("REDUCTIONS_1".tr(), Icons.remove_circle_outline),
                                  SizedBox(height: 8),
                                  _buildDropdownField(getReductionList()),
                                  SizedBox(height: 20),
                                ],

                                // Egg Color Selection
                                _buildInputLabel("EGG".tr()+" "+ "Color".tr(), Icons.palette),
                                SizedBox(height: 8),
                                _buildDropdownField(
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration.collapsed(hintText: null), // Disable default decoration
                                    value: selectedColor,
                                    hint: Text('Select Egg Color'.tr()),
                                    items: eggColors.map((color) {
                                      return DropdownMenuItem(
                                        value: color,
                                        child: Text(color.tr(), style: TextStyle(fontSize: 16)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedColor = value;
                                      });
                                    },
                                    icon: Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue()),
                                    dropdownColor: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Date Selection
                                _buildInputLabel("DATE".tr(), Icons.calendar_today),
                                SizedBox(height: 8),
                                _buildDatePickerField(),

                                SizedBox(height: 20),

                                // Description Field
                                _buildInputLabel("DESCRIPTION_1".tr(), Icons.notes),
                                SizedBox(height: 8),
                                _buildTextAreaField(notesController, "NOTES_HINT".tr()),

                                SizedBox(height: 20),
                              ],
                            ),
                          )
                              :SizedBox(width: 1,),


                        /*  InkWell(
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
                                try {
                                  if (isCollection) {
                                    if (isEdit) {
                                      widget.eggs!.f_id = getFlockID();
                                      widget.eggs!.f_name =
                                          _purposeselectedValue;
                                      widget.eggs!.date = this.date;
                                      widget.eggs!.egg_color = selectedColor;
                                      widget.eggs!.good_eggs =
                                          int.parse(goodEggsController.text);
                                      widget.eggs!.bad_eggs =
                                          int.parse(badEggsController.text);
                                      widget.eggs!.total_eggs = int.parse(
                                          totalEggsController.text);
                                      widget.eggs!.short_note =
                                          notesController.text;
                                      await DatabaseHelper.updateEggCollection(
                                          widget.eggs!);

                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context, "Egg ADDED");
                                    }
                                    else {
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
                                          isCollection: 1,
                                          egg_color: selectedColor));
                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context, "Egg ADDED");
                                    }
                                  } else {
                                    if (isEdit) {
                                      widget.eggs!.f_id = getFlockID();
                                      widget.eggs!.f_name =
                                          _purposeselectedValue;
                                      widget.eggs!.date = this.date;
                                      widget.eggs!.egg_color = selectedColor;
                                      widget.eggs!.good_eggs =
                                          int.parse(goodEggsController.text);
                                      widget.eggs!.bad_eggs =
                                          int.parse(badEggsController.text);
                                      widget.eggs!.reduction_reason =
                                          _reductionReasonValue;
                                      widget.eggs!.total_eggs = int.parse(
                                          totalEggsController.text);
                                      widget.eggs!.short_note =
                                          notesController.text;
                                      await DatabaseHelper.updateEggCollection(
                                          widget.eggs!);

                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context, "Egg ADDED");
                                    }
                                    else {
                                      int? id = await DatabaseHelper
                                          .insertEggCollection(Eggs(
                                          f_id: getFlockID(),
                                          f_name: _purposeselectedValue,
                                          image: '',
                                          good_eggs: int.parse(
                                              goodEggsController.text),
                                          bad_eggs: int.parse(
                                              badEggsController.text),
                                          total_eggs: int.parse(
                                              totalEggsController.text),
                                          short_note: notesController.text,
                                          date: date,
                                          reduction_reason: _reductionReasonValue,
                                          isCollection: 0,
                                          egg_color: selectedColor));
                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context, "Egg Reduced");
                                    }
                                  }
                                }
                                catch(ex){
                                  activeStep = 2;
                                  Utils.showToast(ex.toString());
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
*/
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

// Custom Input Field with More Space
  Widget _buildInputField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool readOnly = false,
        Function(String)? onChanged,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Utils.getThemeColorBlue(), size: 24),
          SizedBox(width: 15),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              readOnly: readOnly,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFieldIntFLoat(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool readOnly = false,
        Function(String)? onChanged,
        bool isFloat = false, // New optional parameter
      }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Utils.getThemeColorBlue(), size: 24),
          SizedBox(width: 15),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: isFloat
                  ? TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  isFloat ? RegExp(r'^\d*\.?\d*$') : RegExp(r'^\d+$'),
                ),
              ],
              readOnly: readOnly,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }


// Custom Dropdown Field (More Open & Spacious)
  Widget _buildDropdownField(Widget dropdownWidget) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: dropdownWidget,
    );
  }

  // Custom Date Picker Field
  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
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
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            Icon(Icons.date_range, color: Utils.getThemeColorBlue()),
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
        maxLines: 2,
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
    return Container(
      margin: EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Icon(icon, color: Utils.getThemeColorBlue(), size: 22),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
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
