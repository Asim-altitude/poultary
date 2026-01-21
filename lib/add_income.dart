import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/sale_contractor_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/sub_category_screen.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'model/finance_flock_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/sale_contractor.dart';
import 'model/transaction_item.dart';
import 'multiuser/model/financeItem.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/SyncStatus.dart';

class NewIncome extends StatefulWidget {

   TransactionItem? transactionItem;
   String? selectedIncomeType; String? selectedExpenseType;
   NewIncome({Key? key, required this.transactionItem,required this.selectedIncomeType, required this.selectedExpenseType}) : super(key: key);

  @override
  _NewIncome createState() => _NewIncome();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewIncome extends State<NewIncome>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;

  @override
  void dispose() {
    howmanyController.removeListener(_updateAmount);
    unitPriceController.removeListener(_updateAmount);
    howmanyController.dispose();
    unitPriceController.dispose();
    amountController.dispose();
    super.dispose();
    try{
      _myNativeAd.dispose();
    }catch(ex){

    }

  }

  String _purposeselectedValue = "";
  String _saleselectedValue = "Sale Item";
  String _mysaleselectedValue = "-Choose Option-";

  List<String> _purposeList = [];
  List<String> _saleItemList = [];
  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];
  List<SubItem> _subItemList = [];
  List<SubItem> _mysubItemList = [];
  List<String> _mysaleItemList = [];

  int chosen_index = 0;

  int total_birds = 0;

  bool includeExtras = false;
  bool isEdit = false;

  Flock? currentFlock = null;

  bool _validate = false;

  FinanceItem? financeItem = null;

  String date = "Choose date";
  String displayDate = "";
  String payment_method = "Cash";
  String payment_status = "CLEARED";

  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final unitPriceController = TextEditingController();
  final howmanyController = TextEditingController();
  final soldtoController = TextEditingController();

  List<SaleContractor> contractors = [];
  SaleContractor? selectedContractor;
  @override
  void initState() {
    super.initState();

    if(widget.transactionItem != null)
    {
      isEdit = true;

      _purposeselectedValue = widget.transactionItem!.f_name;
      date = widget.transactionItem!.date;
      _saleselectedValue = widget.transactionItem!.sale_item;
      notesController.text = widget.transactionItem!.short_note;
      howmanyController.text = widget.transactionItem!.how_many;
      soldtoController.text = widget.transactionItem!.sold_purchased_from;
      amountController.text = widget.transactionItem!.amount;

      try {
        double unitPrice = widget.transactionItem!.unitPrice ?? 0;
        if (unitPrice == 0) {
          double totalPrice = double.tryParse(widget.transactionItem!.amount) ??
              0;
          int how_many = int.tryParse(widget.transactionItem!.how_many) ?? 0;
          if (how_many > 0) {
            unitPrice = totalPrice / how_many;
            widget.transactionItem!.unitPrice = unitPrice;
          }
        }
      }catch(ex){
        print(ex);
      }

      unitPriceController.text = widget.transactionItem!.unitPrice!.toString();



    }else if(widget.selectedIncomeType != null){
      _saleselectedValue = widget.selectedIncomeType!;
    }else if(widget.selectedExpenseType != null){
      _saleselectedValue = widget.selectedIncomeType!;
    }

    howmanyController.addListener(_updateAmount);
    unitPriceController.addListener(_updateAmount);

    getList();
    getIncomeCategoryList();
    getPayMethodList();
    if(Utils.isShowAdd){
      _loadNativeAds();
    }
    AnalyticsUtil.logScreenView(screenName: "add_income");
  }
  _loadNativeAds(){
    _myNativeAd = NativeAd(
      adUnitId: Utils.NativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // or medium
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => _isNativeAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed: $error');
        },
      ),
    );


    _myNativeAd.load();

  }




  List<String> contractorNames = [];
   List<Flock> flocks = [];
   void getList() async {

     contractors = await DatabaseHelper.getContractors();
     if(contractors.length > 0) {
       selectedContractor = contractors[0];
       soldtoController.text = selectedContractor!.name;
     }

     if(!isEdit) {
       await DatabaseHelper.instance.database;
       flocks = await DatabaseHelper.getFlocks();
       is_specific_flock = true;
       /*if(flocks.length > 1){
         *//*flocks.insert(0, Flock(f_id: -1,
             f_name: 'Farm Wide'.tr(),
             bird_count: 0,
             purpose: '',
             acqusition_date: '',
             acqusition_type: '',
             notes: '',
             icon: '',
             active_bird_count: 0,
             active: 1, flock_new: 1));*//*
         is_specific_flock = false;
       }*/

       for (int i = 0; i < flocks.length; i++)
       {
         _purposeList.add(flocks.elementAt(i).f_name);
         total_birds += flocks
             .elementAt(i)
             .active_bird_count!;
       }

       _purposeselectedValue = _purposeList[0];
       howmanyController.text = "";
       DateTime dateTime = DateTime.now();
       date = DateFormat('yyyy-MM-dd').format(dateTime);

     }
     else
     {

       _purposeselectedValue = widget.transactionItem!.f_name;
       _purposeList.add(_purposeselectedValue);
       howmanyController.text = widget.transactionItem!.how_many;
       date = widget.transactionItem!.date;

       if(widget.transactionItem!.f_id! != -1) {
         Flock? flock = await DatabaseHelper.getSingleFlock(widget.transactionItem!.f_id!);
         flocks.add(flock!);
         is_specific_flock = true;
       } else{
         flocks.add(Flock(f_id: -1,
             f_name: 'Farm Wide'.tr(),
             bird_count: 0,
             purpose: '',
             acqusition_date: '',
             acqusition_type: '',
             notes: '',
             icon: '',
             active_bird_count: 0,
             active: 1, flock_new: 1));
         is_specific_flock = false;
       }

     }

    setState(() {

    });

  }




  void getPayMethodList() async {
    await DatabaseHelper.instance.database;

    _paymentMethodList = await DatabaseHelper.getSubCategoryList(5);
    _visiblePaymentMethodList = [];
    if(_paymentMethodList.length > 0) {
      for (int i = 0; i < _paymentMethodList.length; i++) {
        _visiblePaymentMethodList.add(_paymentMethodList
            .elementAt(i)
            .name!);

        print("ADD_PAY_METHOD $i ${_paymentMethodList
            .elementAt(i)
            .name!}");

      }
    }else{
      _visiblePaymentMethodList.add("Cash");
    }

    if(!isEdit)
    payment_method = _visiblePaymentMethodList[0];
    print("PAY_METHOD $payment_method");

    if(!Utils.checkIfContains(_visiblePaymentMethodList, payment_method))
      _visiblePaymentMethodList.add(payment_method);

    setState(() {

    });

  }

  void updateIncomeCategories() async {
    _mysaleItemList = [];
    _mysubItemList = await DatabaseHelper.getSubCategoryList(1);

    _mysaleItemList.add("-Choose Option-");
    for(int i=0;i<_mysubItemList.length;i++){

      if(_mysubItemList.elementAt(i).name! != "Egg Sale")
        _mysaleItemList.add(_mysubItemList.elementAt(i).name!);

    }
    setState(() {

    });
  }

  void getIncomeCategoryList() async {
    await DatabaseHelper.instance.database;
    if(isEdit){
      _saleselectedValue = widget.transactionItem!.sale_item;
      _saleItemList.add(_saleselectedValue);

      print(_saleselectedValue);
      print("ID ${widget.transactionItem!.flock_update_id}");
      choose_option = false;
      purpose_option_invalid = false;
      if(widget.transactionItem!.flock_update_id != "-1"){
        is_bird_sale = true;

        if(widget.transactionItem!.flock_update_id.contains(",") ||
            widget.transactionItem!.f_id == -1)
        {
            is_specific_flock = false;
            List<String> item_ids = widget.transactionItem!.flock_update_id.split(",");
            print(item_ids);
            for(int i=0;i<item_ids.length;i++){
              print("F DETAIL ID ${item_ids[i]}");
              if(!item_ids[i].isEmpty) {
                Flock_Detail? flock_detail = await DatabaseHelper
                    .getSingleFlockDetails(int.parse(item_ids[i]));
                Flock? flock = await DatabaseHelper.getSingleFlock(
                    flock_detail!.f_id);
                FinanceFlockItem financeFlockItem = new FinanceFlockItem(
                    id: flock_detail.f_id,
                    name: flock_detail.f_name,
                    active_birds: flock!.active_bird_count!,
                    selected_birds: flock_detail.item_count,
                    isActive: true);
                financeList.add(financeFlockItem);
              }
            }

        }
        else
        {
            is_specific_flock = true;
        }

      }else{
        is_bird_sale = false;
      }

    } else if(widget.selectedIncomeType != null || widget.selectedExpenseType != null){
      if(widget.selectedIncomeType != null){
        _saleItemList.clear();
        _saleItemList.add(widget.selectedIncomeType!);
        isOther = true;
      }else{
        _saleItemList.clear();
        _saleItemList.add(widget.selectedExpenseType!);
        isOther = true;
      }
    }
    else{
      _mysubItemList = await DatabaseHelper.getSubCategoryList(1);
      _mysaleItemList = [];
      _mysaleItemList.add("-Choose Option-");
      for(int i=0;i<_mysubItemList.length;i++){

        if(_mysubItemList.elementAt(i).name! != "Egg Sale")
          _mysaleItemList.add(_mysubItemList.elementAt(i).name!);

      }

      _saleItemList = [];
      _saleItemList.add("-Choose Purpose-");
      _saleItemList.add("Flock Sale");
      _saleItemList.add("Egg Sale");
      _saleItemList.add("Other Income");

      _saleselectedValue = _saleItemList[0];
      is_bird_sale = false;

      print(_saleItemList);
    }


    setState(() {

    });

  }

  bool is_bird_sale = false, is_specific_flock = false,
      isOther = false, choose_option = false,
      income_option_invalid = true, purpose_option_invalid = true;

  void checkSelectedOption() {

    if(widget.selectedIncomeType != null || widget.selectedExpenseType != null){
      choose_option = false;
      is_bird_sale = false;
      purpose_option_invalid = false;
      return;
    }

    for(int i=0;i<_saleItemList.length;i++){
      if(_saleselectedValue == _saleItemList[i]){
        if(i == 0){
          choose_option = false;
          is_bird_sale = false;
          purpose_option_invalid = true;
        }
        else if(i == 1){
          choose_option = false;
          is_bird_sale = true;
         // _purposeselectedValue = Utils.selected_flock!.f_name;
          purpose_option_invalid = false;
          if(getFlockID() == -1)
            showBottomDialog();

        }else if(i == _saleItemList.length-1){
          choose_option = true;
          is_bird_sale = false;
          purpose_option_invalid = false;
        }else{
          choose_option = false;
          is_bird_sale = false;
          purpose_option_invalid = false;
        }
      }
    }
    setState(() {

    });

  }

  void checkIncomeOption(){

    for(int i=0;i<_mysaleItemList.length;i++){
      if(_mysaleselectedValue == _mysaleItemList[i]){
        if(i == 0){
          income_option_invalid = true;
        }else{
          income_option_invalid = false;
        }
      }
    }
    setState(() {

    });

  }


  void _updateAmount() {
    try {
      final howMany = double.tryParse(howmanyController.text) ?? 0;
      final unitPrice = double.tryParse(unitPriceController.text) ?? 0;
      final total = howMany * unitPrice;

      // Update amount field (without triggering rebuilds or loops)
      amountController.text = total.toStringAsFixed(2);
      setState(() {

      });
    }
    catch(ex){
      print(ex);
    }
  }


  int activeStep = 0;

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
                  if(activeStep==1){
                    if(invalidInput())
                    {
                      activeStep--;
                      Utils.showToast("PROVIDE_ALL");
                    }else{
                      setState(() {

                      });
                    }
                  }

                  if(activeStep==2){
                    if(!invalidInput() && soldtoController.text.trim().length>0)
                    {
                      setState(() {

                      });
                    }else{
                      activeStep--;
                      Utils.showToast("PROVIDE_ALL");
                    }
                  }

                  if(activeStep==3)
                  {

                    if(isEdit)
                    {
                      await DatabaseHelper.instance.database;
                      TransactionItem transaction_item = TransactionItem(
                          f_id: getFlockID(),
                          date: date,
                          sale_item: choose_option?_mysaleselectedValue : _saleselectedValue,
                          expense_item: "",
                          type: "Income",
                          amount: amountController.text,
                          payment_method: payment_method,
                          payment_status: payment_status,
                          sold_purchased_from: soldtoController
                              .text,
                          short_note: notesController.text,
                          how_many: howmanyController.text,
                          unitPrice: double.parse(unitPriceController.text),
                          extra_cost: "",
                          extra_cost_details: "",
                          f_name: _purposeselectedValue, flock_update_id: '-1',
                          sync_id: widget.transactionItem!.sync_id,
                          sync_status: SyncStatus.SYNCED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                          f_sync_id: getFlockSyncID());

                      transaction_item.id = widget.transactionItem!.id;

                      int? id = await DatabaseHelper
                          .updateTransaction(transaction_item);

                      financeItem = FinanceItem(transaction: transaction_item);
                      financeItem!.sync_id = transaction_item.sync_id;
                      financeItem!.sync_status = SyncStatus.UPDATED;
                      financeItem!.last_modified = Utils.getTimeStamp();
                      financeItem!.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                      financeItem!.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';


                      reduceBirds(widget.transactionItem!.id!);
                      Utils.showToast("SUCCESSFUL");
                      Navigator.pop(context);
                    }
                    else
                    {

                      print("Everything Okay");
                      await DatabaseHelper.instance.database;
                      TransactionItem transaction_item = TransactionItem(
                          f_id: getFlockID(),
                          date: date,
                          sale_item: choose_option? _mysaleselectedValue : _saleselectedValue,
                          expense_item: "",
                          type: "Income",
                          amount: amountController.text,
                          payment_method: payment_method,
                          payment_status: payment_status,
                          sold_purchased_from: soldtoController
                              .text,
                          short_note: notesController.text,
                          how_many: howmanyController.text,
                          unitPrice: double.parse(unitPriceController.text),
                          extra_cost: "",
                          extra_cost_details: "",
                          f_name: _purposeselectedValue, flock_update_id: '-1',
                          sync_id: Utils.getUniueId(),
                          sync_status: SyncStatus.SYNCED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                          f_sync_id: getFlockSyncID());
                      int? id = await DatabaseHelper
                          .insertNewTransaction(transaction_item);

                      financeItem = FinanceItem(transaction: transaction_item);
                      financeItem!.sync_id = transaction_item.sync_id;
                      financeItem!.sync_status = SyncStatus.SYNCED;
                      financeItem!.last_modified = Utils.getTimeStamp();
                      financeItem!.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                      financeItem!.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';


                      if(widget.selectedIncomeType != null){
                        if(widget.selectedIncomeType!.toLowerCase()=="egg sale"){

                        }
                      }else if (widget.selectedExpenseType != null){

                      } else {
                        reduceBirds(id!);
                      }
                      Utils.showToast("SUCCESSFUL");
                      Navigator.pop(context);
                    }

                    AnalyticsUtil.logAddTransaction(type: "Income", amount: double.parse(amountController.text));
                  }
                },
                child: Container(
                  height: 55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: activeStep == 2
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
                        activeStep == 2 ? "SAVE".tr() : "Next".tr(),
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
          child:Column(children: [
            if (_isNativeAdLoaded && _myNativeAd != null)
              Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AdWidget(ad: _myNativeAd),
              ),

            Expanded(child:  SingleChildScrollView(
              child: Column(
                children: [
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
                        customStep: _buildStepIcon(Icons.wallet_giftcard, 0),
                        title: 'Income'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.payments, 1),
                        title: 'Payment Info'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.date_range, 1),
                        title: 'DATE'.tr(),
                      ),

                    ],
                    onStepReached: (index) => setState(() => activeStep = index),
                  ),

                  SizedBox(height: 0,),
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          activeStep==0? Container(
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
                                    isEdit ? "Edit".tr() + " " + "Income".tr() : "NEW_INCOME".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15),
                                // Flock Selection
                                _buildInputLabel("CHOOSE_FLOCK_1".tr(), Icons.pets),
                                SizedBox(height: 8),
                                _buildDropdownField(getDropDownList()),
                                SizedBox(height: 15),
                                // Purpose Selection
                                _buildInputLabel("PURPOSE1".tr(), Icons.assignment),
                                SizedBox(height: 8),
                                _buildDropdownField(getSaleTypeList()),
                                SizedBox(height: 10),

                                if (is_bird_sale && is_specific_flock)
                                  Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Center(
                                      child: Text(
                                        "Auto_reduction".tr(),
                                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w200),
                                      ),
                                    ),
                                  ),

                                // Income Categories
                                if (choose_option) ...[
                                  SizedBox(height: 10),
                                  _buildInputLabel("Income Categories".tr(), Icons.category),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _buildDropdownField(getMySaleOptionsList())),
                                      SizedBox(width: 10),
                                      _buildAddButton(addNewIncomOption),
                                    ],
                                  ),
                                ],

                                SizedBox(height: 15),

                                // How Many & Sale Amount
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInputLabel("HOW_MANY".tr(), Icons.confirmation_num),
                                          SizedBox(height: 8),
                                          _buildNumberField(howmanyController, "HOW_MANY".tr(), readOnly: !is_specific_flock && is_bird_sale, onTap: () {
                                            if (!is_specific_flock && is_bird_sale) showBottomDialog();
                                          }),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInputLabel("UNIT_PRICE".tr(), Icons.attach_money),
                                          SizedBox(height: 8),
                                          _buildNumberField(unitPriceController, "UNIT_PRICE".tr(), allowFloat: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 15),

                                Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel("SALE_AMOUNT".tr(), Icons.attach_money),
                                      SizedBox(height: 8),
                                      _buildNumberField(amountController, "SALE_AMOUNT".tr(), allowFloat: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              :SizedBox(width: 1,),


                          activeStep==1?  Container(
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
                                    "Payment Info".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Payment Method
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInputLabel("Payment Method".tr(), Icons.payment),
                                    InkWell(
                                        onTap: () async {
                                          Utils.selected_category = 5;
                                          Utils.selected_category_name = "Payment Method";
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SubCategoryScreen(),
                                            ),
                                          );
                                          getPayMethodList();
                                          setState(() {

                                          });
                                        },
                                        child: Icon(Icons.add_circle, size: 27, color: Colors.blue,)),
                                  ],
                                ),
                                SizedBox(height: 8),
                                _buildDropdownField(getPaymentMethodList()),

                                SizedBox(height: 20),

                                // Payment Status
                                _buildInputLabel("Payment Status".tr(), Icons.check_circle),
                                SizedBox(height: 8),
                                _buildDropdownField(getPaymentStatusList()),

                                SizedBox(height: 20),

                                // Sold To
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInputLabel("SOLD_TO".tr(), Icons.person),
                                    InkWell(
                                        onTap: () async{
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>  SaleContractorScreen()),
                                          );
                                          contractors = await DatabaseHelper.getContractors();
                                          if(contractors.length >0) {
                                            selectedContractor = contractors[0];
                                            soldtoController.text = selectedContractor!.name;
                                          }
                                          setState(() {

                                          });
                                        },
                                        child: Container(
                                            margin: EdgeInsets.only(right: 10),
                                            child: Icon(Icons.add, color: Utils.getThemeColorBlue(),))),
                                  ],
                                ),
                                SizedBox(height: 8),
                                contractors.length == 0?
                                _buildInputField(soldtoController, "SOLD_TO_HINT".tr(), Icons.person)
                                    : _buildDropdownContractor(getContractorDropDown())

                              ],
                            ),
                          )
                              :SizedBox(width: 1,),


                          activeStep==2?  Container(
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
                                    "Date_DESC".tr(),
                                    style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Date Selection
                                _buildInputLabel("DATE".tr(), Icons.calendar_today),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(70),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey, width: 1),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      pickDate();
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.black54),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            Utils.getFormattedDate(date),
                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                // Notes Input
                                _buildInputLabel("DESCRIPTION_1".tr(), Icons.notes),
                                SizedBox(height: 8),
                                TextFormField(
                                  maxLines: 2,
                                  controller: notesController,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    hintText: "NOTES_HINT".tr(),
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          )
                              :SizedBox(width: 1,),


                          /*SizedBox(height: 10,width: widthScreen),
                        InkWell(
                          onTap: () async {
                            bool validate = checkValidation();

                            activeStep++;
                            if(activeStep==1){
                              if(invalidInput())
                              {
                                activeStep--;
                                Utils.showToast("PROVIDE_ALL".tr());
                              }else{
                               setState(() {

                               });
                              }
                            }

                            if(activeStep==2){
                              if(!invalidInput() && soldtoController.text.trim().length>0)
                              {
                                setState(() {

                                });
                              }else{
                                activeStep--;
                                Utils.showToast("PROVIDE_ALL".tr());
                              }
                            }

                            if(activeStep==3){

                              if(isEdit){
                                await DatabaseHelper.instance.database;
                                TransactionItem transaction_item = TransactionItem(
                                    f_id: getFlockID(),
                                    date: date,
                                    sale_item: choose_option?_mysaleselectedValue : _saleselectedValue,
                                    expense_item: "",
                                    type: "Income",
                                    amount: amountController.text,
                                    payment_method: payment_method,
                                    payment_status: payment_status,
                                    sold_purchased_from: soldtoController
                                        .text,
                                    short_note: notesController.text,
                                    how_many: howmanyController.text,
                                    extra_cost: "",
                                    extra_cost_details: "",
                                    f_name: _purposeselectedValue, flock_update_id: '-1');

                                transaction_item.id = widget.transactionItem!.id;

                                int? id = await DatabaseHelper
                                    .updateTransaction(transaction_item);

                                reduceBirds(widget.transactionItem!.id!);
                                Utils.showToast("SUCCESSFUL".tr());
                                Navigator.pop(context);
                              }else {
                                print("Everything Okay");
                                await DatabaseHelper.instance.database;
                                TransactionItem transaction_item = TransactionItem(
                                    f_id: getFlockID(),
                                    date: date,
                                    sale_item: choose_option?_mysaleselectedValue : _saleselectedValue,
                                    expense_item: "",
                                    type: "Income",
                                    amount: amountController.text,
                                    payment_method: payment_method,
                                    payment_status: payment_status,
                                    sold_purchased_from: soldtoController
                                        .text,
                                    short_note: notesController.text,
                                    how_many: howmanyController.text,
                                    extra_cost: "",
                                    extra_cost_details: "",
                                    f_name: _purposeselectedValue, flock_update_id: '-1');
                                int? id = await DatabaseHelper
                                    .insertNewTransaction(transaction_item);
                                reduceBirds(id!);
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
                              activeStep<=1?"NEXT":"CONFIRM".tr(),
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
            ))
          ],),
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller,
      String hint, IconData icon, {
        bool readOnly = false,
        VoidCallback? onTap,
        // Optional argument to allow float input
      }) {
    return Container(
      height: 70, // Matches dropdown height
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 3,
            offset: Offset(0, 2), // Slight elevation
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon!, color: Utils.getThemeColorBlue(), size: 24), // Icon added for better UI
          SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.text,
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(fontSize: 16, color: Colors.black), // Match dropdown text
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
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

  // Reusable Form Field Container
  Widget _buildFormFieldContainer({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            height: 70,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 3,
                  offset: Offset(0, 2), // Slight elevation
                ),
              ],
            ),
            child: child,
          ),
        ],
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

// Custom Dropdown Field (Increased Height)
  Widget _buildDropdownField(Widget dropdownWidget) {
    return Container(
      height: 65, // Increased height
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Center(child: dropdownWidget), // Ensuring it is vertically centered
    );
  }

  // Custom Dropdown Field (Increased Height)
  Widget _buildDropdownContractor(Widget dropdownWidget) {
    return Container(
      height: 75, // Increased height
      padding: EdgeInsets.symmetric(horizontal: 5),

      child: Center(child: dropdownWidget), // Ensuring it is vertically centered
    );
  }

// Custom Number Input Field (Matches Dropdown Height & Supports Integer/Float)
  Widget _buildNumberField(
      TextEditingController controller,
      String hint, {
        bool readOnly = false,
        VoidCallback? onTap,
        bool allowFloat = false, // Optional argument to allow float input
      }) {
    return Container(
      height: 70, // Matches dropdown height
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 3,
            offset: Offset(0, 2), // Slight elevation
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.numbers, color: Utils.getThemeColorBlue(), size: 15), // Icon added for better UI
          SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: allowFloat),
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(fontSize: 16, color: Colors.black), // Match dropdown text
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  allowFloat ? RegExp(r"^\d*\.?\d*$") : RegExp(r"^\d*$"),
                ), // Allows only numbers or float based on flag
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add New Income Option Button
  Widget _buildAddButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  int getActiveBirds(int f_id) {
    int active_birds = 0;
    for(int i=0;i<flocks.length;i++){
      if(f_id == flocks.elementAt(i).f_id){
        active_birds = flocks.elementAt(i).active_bird_count!;
        break;
      }
    }

    return active_birds;
  }

  Future<void> reduceBirds(int transactionn_id) async {
    print("Reduce Birds Function");
    print("TransactionID $transactionn_id");

    if(is_specific_flock && is_bird_sale && !isEdit){
      print("SPECIFIC FLOCK+BIRDSALE+NEW");
      int active_birds = getActiveBirds(getFlockID());
      if (int.parse(howmanyController.text) <
          active_birds) {
        active_birds = active_birds -
            int.parse(
                howmanyController.text);
        print(active_birds);

        await DatabaseHelper.updateFlockBirds(
            active_birds, getFlockID());

        if(Utils.isMultiUSer)
        uploadBirdsToServer(getFlockID(), active_birds);

        Flock_Detail flock_detail = Flock_Detail(
            f_id: getFlockID(),
            item_type: 'Reduction',
            item_count: int.parse(
                howmanyController.text),
            acqusition_type: "",
            acqusition_date: date,
            reason: "Bird Sale".tr(),
            short_note: notesController.text,
            f_name: _purposeselectedValue,
            transaction_id: transactionn_id.toString(),
            sync_id: Utils.getUniueId(),
            sync_status: SyncStatus.SYNCED,
            last_modified: Utils.getTimeStamp(),
            modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
            farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
            f_sync_id: getFlockSyncID()
        );
        int? flock_detail_id = await DatabaseHelper
            .insertFlockDetail(flock_detail);
        financeItem!.flockDetails = [];
        financeItem!.flockDetails?.add(flock_detail);
        await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), flock_detail_id.toString());

        if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
          await FireBaseUtils.uploadExpenseRecord(financeItem!);
        }
      }
    }
    else if(is_specific_flock && is_bird_sale && isEdit){
      try {
        print("SPECIFIC FLOCK+BIRDSALE+EDIT");

        int f_detail_id = int.parse(widget.transactionItem!.flock_update_id);
        if (f_detail_id != -1) {
          Flock_Detail? flock_detail = await DatabaseHelper.getSingleFlockDetails(f_detail_id);
          if(flock_detail!= null){
            int first_reduction = flock_detail.item_count;
            int second_reduction = int.parse(howmanyController.text);
            if(first_reduction > second_reduction){
              int diff = first_reduction - second_reduction;
              int current_active = getActiveBirds(getFlockID());
              current_active = current_active + diff;
              await DatabaseHelper.updateFlockBirds(current_active, getFlockID());

              if(Utils.isMultiUSer)
              uploadBirdsToServer(getFlockID(), current_active);

              Flock_Detail flock_detail_1 = Flock_Detail(f_id: getFlockID(), f_name: _purposeselectedValue, item_type: flock_detail.item_type, item_count: second_reduction, acqusition_type: flock_detail.acqusition_type, acqusition_date: flock_detail.acqusition_date, reason: flock_detail.reason, short_note: notesController.text, transaction_id: transactionn_id.toString(),
                  sync_id: flock_detail.sync_id,
                  sync_status: SyncStatus.UPDATED,
                  last_modified: Utils.getTimeStamp(),
                  modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                  farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                  f_sync_id: getFlockSyncID());
              flock_detail_1.f_detail_id = f_detail_id;
              await DatabaseHelper.updateFlock(flock_detail_1);

              financeItem!.flockDetails = [];
              financeItem!.flockDetails?.add(flock_detail_1);
              if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
                await FireBaseUtils.updateExpenseRecord(financeItem!);
              }

            }else{
              int diff = second_reduction - first_reduction;
              int current_active = getActiveBirds(getFlockID());
              current_active = current_active - diff;
              await DatabaseHelper.updateFlockBirds(current_active, getFlockID());

              if(Utils.isMultiUSer)
              uploadBirdsToServer(getFlockID(), current_active);

              Flock_Detail flock_detail_1 = Flock_Detail(f_id: getFlockID(), f_name: _purposeselectedValue, item_type: flock_detail.item_type, item_count: second_reduction, acqusition_type: flock_detail.acqusition_type, acqusition_date: flock_detail.acqusition_date, reason: flock_detail.reason, short_note:  notesController.text, transaction_id: transactionn_id.toString(),
                  sync_id: flock_detail.sync_id,
                  sync_status: SyncStatus.UPDATED,
                  last_modified: Utils.getTimeStamp(),
                  modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                  farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                  f_sync_id: getFlockSyncID());
              flock_detail_1.f_detail_id = f_detail_id;
              await DatabaseHelper.updateFlock(flock_detail_1);

              financeItem!.flockDetails = [];
              financeItem!.flockDetails?.add(flock_detail_1);

              if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
                await FireBaseUtils.updateExpenseRecord(financeItem!);
              }

            }

          }

          await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), f_detail_id.toString());

        }
      }catch(ex){
        print(ex);
      }
    }
    else if(!is_specific_flock && is_bird_sale && !isEdit){
      print("FARMWIDE+BIRDSALE+NEW");

      for(int i = 0;i<financeList.length;i++){
        if(financeList.elementAt(i).isActive) {
          await reduceBirdsFarmWide(i, transactionn_id);
        }
      }
      await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), farm_wide_f_detail_id);
      if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
        await FireBaseUtils.uploadExpenseRecord(financeItem!);
      }
    }
    else if(!is_specific_flock && is_bird_sale && isEdit){
      print("FARMWIDE+BIRDSALE+EDIT");
      for(int i = 0;i<financeList.length;i++){
        await reduceBirdsFarmWideEdit(i);
      }
      await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), farm_wide_f_detail_id);

      if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
        await FireBaseUtils.updateExpenseRecord(financeItem!);
      }
    }
    else
    {
      if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_transaction")) {
        await FireBaseUtils.uploadExpenseRecord(financeItem!);
      }
    }

  }


  Future<void> uploadBirdsToServer(int id, int active_birds) async{
    Flock? flock = await DatabaseHelper.getSingleFlock(id);
    flock!.active_bird_count = active_birds;
    await FireBaseUtils.updateFlock(flock);
  }

  String farm_wide_f_detail_id = "";
  Future<int> reduceBirdsFarmWide(int index, int transactionn_id) async{

    try {

      if(financeItem!.flockDetails == null)
        financeItem!.flockDetails = [];

      print("reduceBirdsFarmWide $index $transactionn_id");
      FinanceFlockItem financeFlockItem = financeList.elementAt(index);

      int active_birds = getActiveBirds(financeFlockItem.id!);
      if (financeFlockItem.selected_birds <
          active_birds) {
        active_birds = active_birds - financeFlockItem.selected_birds;

        print(active_birds);
        DatabaseHelper.updateFlockBirds(active_birds, financeFlockItem.id!);
        print("reduceBirdsFarmWide BIRDS UPDATED $active_birds ${financeFlockItem.name}");

        if(Utils.isMultiUSer)
        uploadBirdsToServer(financeFlockItem.id!, active_birds);

        Flock_Detail flock_detail = Flock_Detail(
            f_id: financeFlockItem.id!,
            item_type: 'Reduction',
            item_count: financeFlockItem.selected_birds,
            acqusition_type: "",
            acqusition_date: date,
            reason: "Bird Sale".tr(),
            short_note: notesController.text,
            f_name: financeFlockItem.name,
            transaction_id: transactionn_id.toString(),
            sync_id: Utils.getUniueId(),
            sync_status: SyncStatus.SYNCED,
            last_modified: Utils.getTimeStamp(),
            modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
            farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
            f_sync_id: getFlockSyncID());
        int? flock_detail_id = await DatabaseHelper
            .insertFlockDetail(flock_detail);

        financeItem!.flockDetails?.add(flock_detail);


        if (index == 0)
          farm_wide_f_detail_id = flock_detail_id.toString();
        else
          farm_wide_f_detail_id =
              farm_wide_f_detail_id + "," + flock_detail_id.toString();

        print("ID $farm_wide_f_detail_id");
      }
    }
    catch(ex){
      print(ex);
    }

    return 0;
  }
  Future<int> reduceBirdsFarmWideEdit(int index) async{

    if(financeItem!.flockDetails == null)
      financeItem!.flockDetails = [];

    FinanceFlockItem financeFlockItem = financeList.elementAt(index);

    int f_detail_id = int.parse(widget.transactionItem!.flock_update_id.split(",")[index]);
    Flock_Detail? flock_detail = await DatabaseHelper.getSingleFlockDetails(f_detail_id);
    Flock? flock = await DatabaseHelper.getSingleFlock(financeFlockItem.id!);

    int first_reduction = flock_detail!.item_count;
    int active_birds = flock!.active_bird_count!;
    if (financeFlockItem.selected_birds < first_reduction) {
      int diff = first_reduction - financeFlockItem.selected_birds;

      active_birds = active_birds + diff;
      print(active_birds);

      DatabaseHelper.updateFlockBirds(
          active_birds, financeFlockItem.id!);


    }else{
      int diff =  financeFlockItem.selected_birds - first_reduction;

      active_birds = active_birds - diff;
      print(active_birds);

      DatabaseHelper.updateFlockBirds(
          active_birds, financeFlockItem.id!);
    }


    Flock_Detail object = new Flock_Detail(
        f_id: financeFlockItem.id!,
        item_type: 'Reduction',
        item_count: financeFlockItem.selected_birds,
        acqusition_type: "",
        acqusition_date: date,
        reason: "Bird Sale".tr(),
        short_note: notesController.text,
        f_name: financeFlockItem.name,
        transaction_id: widget.transactionItem!.id.toString(),
        sync_id: flock_detail.sync_id,
        sync_status: SyncStatus.SYNCED,
        last_modified: Utils.getTimeStamp(),
        modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
        farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
        f_sync_id: getFlockSyncID());
    object.f_detail_id = f_detail_id;

    await DatabaseHelper.updateFlock(object);

    financeItem!.flockDetails?.add(object);


    if (index == 0)
      farm_wide_f_detail_id = f_detail_id.toString();
    else
      farm_wide_f_detail_id =
          farm_wide_f_detail_id + "," + f_detail_id.toString();

    print("ID $farm_wide_f_detail_id");

    return 0;
  }

  bool invalidInput() {

    try {
      bool invalid = false;
      if (howmanyController.text.isEmpty) {
        invalid = true;
      }
      else if (num.parse(howmanyController.text) == 0) {
        invalid = true;
      }

      if (amountController.text.isEmpty) {
        invalid = true;
      }

      else if (num.parse(amountController.text) == 0) {
        invalid = true;
      }

      if (num.parse(howmanyController.text) >= getActiveBirds(getFlockID()) &&
          is_specific_flock && is_bird_sale) {
        invalid = true;
        int count = getActiveBirds(getFlockID()) - 1;
        Utils.showToast(
            "You cannot reduce more than".tr() + " " + count.toString() + " " +
                "Birds".tr());
      }

      if (purpose_option_invalid) {
        invalid = true;
      }

      if (choose_option) {
        if (income_option_invalid) {
          invalid = true;
        }
      }

      return invalid;
    }
    catch(e){
      return true;
    }
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
              if(!isEdit) {
                howmanyController.text = total_birds.toString();
                // _saleselectedValue = _saleItemList[0];
                is_specific_flock = false;
                // purpose_option_invalid = true;
                if (is_bird_sale)
                  showBottomDialog();
              }

            }else {
              if(!isEdit) {
                howmanyController.text = getActiveBirdsbyName().toString();
                is_specific_flock = true;
              }
            }
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

  showErrorMessage(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Ok".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );


    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Unsupported Operation".tr()),
      content: Text("Unsupported Operation Message".tr()),
      actions: [
        cancelButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  Widget getSaleTypeList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _saleselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _saleselectedValue = newValue!;
            if(!isEdit)
              checkSelectedOption();

            print("Selected Sale Item $_saleselectedValue");

          });
        },
        items: _saleItemList.map<DropdownMenuItem<String>>((String value) {
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

  Widget getMySaleOptionsList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _mysaleselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _mysaleselectedValue = newValue!;
            checkIncomeOption();
            print("Selected Sale Item $_mysaleselectedValue");

          });
        },
        items: _mysaleItemList.map<DropdownMenuItem<String>>((String value) {
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
            print(payment_method);

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

  Widget getContractorDropDown() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<SaleContractor>(
        value: selectedContractor,
        decoration: InputDecoration(
          labelText: 'Select Contractor',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: contractors.map((contractor) {
          return DropdownMenuItem<SaleContractor>(
            value: contractor,
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contractor.name, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
                    Text(" (${contractor.type})", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedContractor = value;
              soldtoController.text = selectedContractor!.name;
            });
          }
        },
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
        date = formattedDate;
        displayDate = Utils.getFormattedDate(date);//set output date to TextField value.
      });
    } else {}
  }

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(howmanyController.text.isEmpty){
      valid = false;
      print("Add how many ");
    }

    if(soldtoController.text.isEmpty){
      valid = false;
      print("Add Sold to");
    }

    if(amountController.text.isEmpty){
      valid = false;
      print("Add amount");
    }

    if (_saleselectedValue.toLowerCase().contains("Sale Item".tr())){
      valid = false;
      print("No sale item slected");
    }

    if (payment_method.toLowerCase().contains("Payment Method".tr())){
      valid = false;
      print("No payment method slected");
    }

    if (payment_status.toLowerCase().contains("Payment Status".tr())){
      valid = false;
      print("No payment status slected");
    }


    return valid;

  }

  String? getFlockSyncID() {

    String? selected_id = "unknown";
    for(int i=0;i<flocks.length;i++) {
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

  int getActiveBirdsbyName() {

    int selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        selected_id = flocks.elementAt(i).active_bird_count!;
        break;
      }
    }

    return selected_id;
  }

  int getFeedID() {

    int selected_id = -1;
    for(int i=0;i<_subItemList.length;i++){
      if(_saleselectedValue.toLowerCase() == _subItemList.elementAt(i).name!.toLowerCase()){
        selected_id = _subItemList.elementAt(i).id!;
        break;
      }
    }

    print("selected Sale id $selected_id");

    return selected_id;
  }

  List<FinanceFlockItem> financeList = [];


  /*void showAllFlocksForReduction(){

    financeList = [];
    for(int i=1;i<flocks.length;i++){
      FinanceFlockItem financeFlockItem = new FinanceFlockItem(id: flocks.elementAt(i).f_id, name: flocks.elementAt(i).f_name, active_birds: flocks.elementAt(i).active_bird_count!, selected_birds: 0);
      financeList.add(financeFlockItem);
      print("FinanceList ${financeList.length}");
    }

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: Container(
          padding: EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Reduce birds from specific flocks".tr(), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Utils.getThemeColorBlue()),),
              Text('Auto_reduction'.tr(), style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w200),),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 80,
                  height: 40,
                  margin: EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    color: Utils.getThemeColorBlue(),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child:  Text('Done'.tr(), style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),),),
              ),
              Container(
                height: flocks.length * 60,
                width: widthScreen,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: financeList.length,
                  itemBuilder: (BuildContext context, int index)
                  {
                   return Container(
                      height: 50,
                       margin: EdgeInsets.only(left: 10,right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        color: Colors.white12,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 2,
                            offset: Offset(0, 1), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: Container(margin: EdgeInsets.only(left: 20,),child: Text(financeList.elementAt(index).name,
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color: Utils.getThemeColorBlue()),))),
                          Expanded(child: Container(child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              InkWell(
                                  onTap: (){
                                    int count = financeList.elementAt(index).selected_birds;

                                    print("Count $count");
                                    if(count > 0)
                                    {
                                      setState(() {
                                        count--;
                                        financeList.elementAt(index).selected_birds = count;
                                      });
                                    }

                                  },
                                  child: Icon(Icons.remove_circle,size: 30,color: Utils.getThemeColorBlue(),)),
                              Container(
                                  margin: EdgeInsets.only(left: 10, right: 10),
                                  child: Text("${financeList.elementAt(index).selected_birds}", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color: Colors.black),)),
                              InkWell(
                                  onTap: (){

                                    int count = financeList.elementAt(index).selected_birds;
                                    print("Count $count");

                                    if(count < financeList.elementAt(index).active_birds)
                                    {
                                      count++;
                                      financeList.elementAt(index).selected_birds = count;
                                    }

                                    setState(() {
                                    });

                                  },
                                  child: Icon(Icons.add_circle,size: 30,color: Utils.getThemeColorBlue(),))

                            ],
                          ),))
                        ],
                      ),
                    );

                  },
                ),
              ),
            ],
          )
        ),
      ),
    );
  }
*/

  int birds_total = 0;
  void updateTotalBirds(){
    birds_total = 0;
    for(int i=0;i<financeList.length;i++){
      if(financeList.elementAt(i).isActive)
      birds_total = birds_total + financeList.elementAt(i).selected_birds;
    }
    if(is_bird_sale && !is_specific_flock)
       howmanyController.text = birds_total.toString();

    setState(() {

    });

  }

  void showBottomDialog(){
    updateTotalBirds();
    if(financeList.isEmpty) {
      for (int i = 1; i < flocks.length; i++) {
        FinanceFlockItem financeFlockItem = FinanceFlockItem(
          id: flocks
              .elementAt(i)
              .f_id,
          name: flocks
              .elementAt(i)
              .f_name,
          active_birds: flocks
              .elementAt(i)
              .active_bird_count!,
          selected_birds: 1, isActive: false,
        );
        financeList.add(financeFlockItem);
        print("FinanceList ${financeList.length}");
      }
    }

    showAllFlocksForReduction();

  }

  void showAllFlocksForReduction() {

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              controller: ModalScrollController.of(context),
              child: Container(
                padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Reduce birds from specific flocks".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                      ),
                    ),
                    Text(
                      'Auto_reduction'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: (){
                          updateTotalBirds();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 80,
                          height: 40,
                          margin: EdgeInsets.all(10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            color: Utils.getThemeColorBlue(),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: Offset(0, 1), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Text(
                            'Done'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: financeList.length * 100,
                      width: widthScreen,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: financeList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            height: 50,
                            margin: EdgeInsets.only(left: 5, right: 5, top:10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              color: Colors.white12,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 1), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                               !isEdit ? Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.centerLeft,
                                    child: CheckboxListTile(
                                      title: Text(""),
                                      activeColor: Utils.getThemeColorBlue(),
                                       value: financeList.elementAt(index).isActive,
                                      onChanged: (newValue) {
                                        setState(() {
                                          if(financeList.elementAt(index).isActive)
                                            financeList.elementAt(index).isActive = false;
                                          else
                                            financeList.elementAt(index).isActive = true;

                                          updateTotalBirds();
                                        });
                                      },
                                      controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                    ),
                                  ),
                                ) : SizedBox(width: 1,),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 20),
                                    child: Text(
                                      financeList.elementAt(index).name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Utils.getThemeColorBlue(),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if(financeList.elementAt(index).isActive) {
                                              setState(() {
                                                int count = financeList
                                                    .elementAt(index)
                                                    .selected_birds;
                                                if (count > 1) {
                                                  financeList
                                                      .elementAt(index)
                                                      .selected_birds = --count;
                                                }

                                                updateTotalBirds();
                                              });
                                            }
                                          },
                                          child: Icon(
                                            Icons.remove_circle,
                                            size: 30,
                                            color: financeList.elementAt(index).isActive? Utils.getThemeColorBlue() : Colors.grey,
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.only(left: 10, right: 10),
                                          child: Text(
                                            "${financeList.elementAt(index).selected_birds}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: financeList.elementAt(index).isActive? Colors.black : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if(financeList.elementAt(index).isActive) {
                                              setState(() {
                                                int count = financeList
                                                    .elementAt(index)
                                                    .selected_birds;
                                                if (count < financeList
                                                    .elementAt(index)
                                                    .active_birds) {
                                                  financeList
                                                      .elementAt(index)
                                                      .selected_birds = ++count;
                                                }

                                                updateTotalBirds();
                                              });
                                            }
                                          },
                                          child: Icon(
                                            Icons.add_circle,
                                            size: 30,
                                            color: financeList.elementAt(index).isActive? Utils.getThemeColorBlue() : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void addNewIncomOption() {

    final nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("New Income".tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Name'.tr(),
                      ),
                    ),

                    InkWell(
                      onTap: () async {
                        print(nameController.text);

                        if(!nameController.text.isEmpty){
                          await DatabaseHelper.insertNewSubItem(SubItem(c_id: 1, name: nameController.text));
                          updateIncomeCategories();
                          Navigator.pop(context);
                        }

                      },
                      child: Container(
                        width: widthScreen,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Utils.getThemeColorBlue(),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(50.0)),
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
                    ),

                  ],
                ),
              ),
            ),
          );
        });
  }



}
