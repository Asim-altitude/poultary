
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/feed_batch_summary.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/stock/stock_screen.dart';
import 'package:poultary/sub_category_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'feed_batch_screen.dart';
import 'model/feed_batch.dart';
import 'model/feed_stock_summary.dart';
import 'model/flock.dart';
import 'multiuser/utils/SyncStatus.dart';

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
  String availableStock = "0.0";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _feedList = [];
  List<SubItem> _subItemList = [];
  List<FeedStockSummary>? _stockSummary = [];
  int chosen_index = 0;
  bool isEdit = false;

  Future<void> fetchStockSummary() async {
    _stockSummary = await DatabaseHelper.getFeedStockSummary();
    setState(() {

    });
    // Update UI after fetching data
  }
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

    }else{
      quantityController.text = "5";
    }

    getList();
    getFeedList();
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


  String getAvailableStock() {
    String availableStock = "0.0"; // Always reset at start

    // Check stockSummary first
    for (var item in _stockSummary ?? []) {
      if (item.feedName.toLowerCase() == _feedselectedValue.toLowerCase()) {
        availableStock = item.availableStock.toStringAsFixed(2);
        return availableStock; // exit immediately if found
      }
    }

    // If not found and batches exist, check batches
    for (var batch in batches) {
      if (batch.feedName.toLowerCase() == _feedselectedValue.toLowerCase()) {
        availableStock = batch.availableStock.toStringAsFixed(2);
        return availableStock;
      }
    }

    return availableStock; // default "0.0"
  }

  List<FeedStockSummary> batches = [];
  void getFeedList() async {
    await DatabaseHelper.instance.database;

    _feedList = [];
    _subItemList = await DatabaseHelper.getSubCategoryList(3);
    batches = await DatabaseHelper.getFeedBatchStockSummary();

    for(int i=0;i<_subItemList.length;i++){
      _feedList.add(_subItemList.elementAt(i).name!);
    }

    for(int i=0;i<batches.length;i++){
      _feedList.add(batches.elementAt(i).feedName);
    }

    if(!isEdit)
    _feedselectedValue = _feedList[0];

    print(_feedselectedValue);

    if(!Utils.checkIfContains(_feedList, _feedselectedValue))
      _feedList.add(_feedselectedValue);


    try {
      fetchStockSummary();
    }catch(e){
      print(e);
    }


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

                  if(activeStep==1) {
                    if (quantityController.text
                        .trim()
                        .length == 0) {
                      activeStep--;
                      Utils.showToast("PROVIDE_ALL");
                    }else{
                      setState(() {

                      });
                    }
                  }

                  if(activeStep==2){

                    if(isEdit){
                      await DatabaseHelper.instance.database;

                      Feeding feeding = Feeding(
                        f_id: getFlockID(),
                        short_note: notesController.text,
                        date: date,
                        feed_name: _feedselectedValue,
                        quantity: quantityController.text,
                        f_name: _purposeselectedValue,
                          sync_id: widget.feeding!.sync_id,
                          sync_status: SyncStatus.UPDATED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                          f_sync_id: getFlockSyncID());
                      feeding.id = widget.feeding!.id;

                      int? id = await DatabaseHelper
                          .updateFeeding(feeding);

                      if(Utils.isMultiUSer && Utils.hasFeaturePermission('edit_feed'))
                      {
                        await FireBaseUtils.updateFeedingRecord(feeding);
                      }

                      Utils.showToast("SUCCESSFUL");
                      Navigator.pop(context);
                    } else {
                      Feeding feeding = Feeding(
                          f_id: getFlockID(),
                          short_note: notesController.text,
                          date: date,
                          feed_name: _feedselectedValue,
                          quantity: quantityController.text,
                          f_name: _purposeselectedValue,
                          sync_id: Utils.getUniueId(),
                          sync_status: SyncStatus.SYNCED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                          f_sync_id: getFlockSyncID()
                      );
                      await DatabaseHelper.instance.database;
                      int? id = await DatabaseHelper
                          .insertNewFeeding(feeding);
                      Utils.showToast("SUCCESSFUL");

                      if(Utils.isMultiUSer && Utils.hasFeaturePermission('add_feed'))
                      {
                        await FireBaseUtils.uploadFeedingRecord(feeding);
                      }

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

                SizedBox(height: 10,),                /*ClipRRect(
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
                ),*/
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
                      customStep: _buildStepIcon(Icons.food_bank_outlined, 0),
                      title: 'Feed'.tr(),
                    ),
                    EasyStep(
                      customStep: _buildStepIcon(Icons.date_range, 1),
                      title: 'DATE'.tr(),
                    ),

                  ],
                  onStepReached: (index) => setState(() => activeStep = index),
                ),
                Container(
                  // height: heightScreen - 250,
                  margin: EdgeInsets.only(top: 10),
                  child: Column(

                      children: [
                        Container(
                            margin: EdgeInsets.only(left: 10),
                            child: Text(
                              isEdit?"EDIT".tr() +" "+"FEEDING".tr():"NEW_FEEDING".tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Utils.getThemeColorBlue(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),

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
                                 "Feed".tr()+" & "+ "Quantity".tr(),
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

                             // Choose Feed Type
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 _buildInputLabel("Choose Feed".tr(), Icons.grass),

                                 InkWell(
                                     onTap: () {
                                       showFeedOptionsDialog(context);
                                     },
                                     child: Icon(Icons.add_circle, size: 27, color: Colors.blue,)),
                               ],
                             ),
                             SizedBox(height: 8),
                             _buildDropdownField(getFeedTypeList()),
                             if(!_feedselectedValue.isEmpty)
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Container(
                                     margin: EdgeInsets.only(right: 10),
                                       alignment: Alignment.centerRight,
                                       child: Text('Stock'.tr()+': ${getAvailableStock()}'+Utils.selected_unit.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: getAvailableStock()=="0.0"? Colors.red :Colors.green),),),
                                  getAvailableStock()=="0.0"? InkWell(
                                    onTap: () async{
                                       await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FeedStockScreen(),
                                        ),
                                      );

                                       fetchStockSummary();
                                       setState(() {

                                       });

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
                               ),

                             SizedBox(height: 20),

                             // Feed Quantity Input
                             _buildInputLabel("Quantity".tr()+" (${Utils.selected_unit.tr()})", Icons.scale),
                             SizedBox(height: 8),
                             _buildNumberInputField(quantityController, "FEED_QUANTITY_HINT".tr()),

                             SizedBox(height: 20),
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
                       )
                           :SizedBox(width: 1,),


                        /*SizedBox(height: 10,width: widthScreen),
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
    );
  }


  void showFeedOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.fastfood, color: Colors.green),
                  title: Text("New Feed".tr(), style: TextStyle(fontSize: 16)),
                  onTap: () async {
                    Utils.selected_category = 3;
                    Utils.selected_category_name = "Feed";
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubCategoryScreen(),
                      ),
                    );
                    getFeedList();
                    setState(() {

                    });
                    Navigator.pop(context);
                    // Handle New Feed action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.inventory, color: Colors.blue),
                  title: Text("New Feed Batch".tr(), style: TextStyle(fontSize: 16)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FeedBatchScreen(),
                      ),
                    );
                    getFeedList();
                    setState(() {

                    });
                    // Handle New Feed Batch action
                  },
                ),
              ],
            ),
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


  void pickDate() async {

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
