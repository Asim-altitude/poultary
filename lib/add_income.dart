import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/finance_flock_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/transaction_item.dart';

class NewIncome extends StatefulWidget {
  TransactionItem? transactionItem;
   NewIncome({Key? key, required this.transactionItem}) : super(key: key);

  @override
  _NewIncome createState() => _NewIncome();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewIncome extends State<NewIncome>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();
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

  String date = "Choose date";
  String displayDate = "";
  String payment_method = "Cash";
  String payment_status = "CLEARED";

  final quantityController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final howmanyController = TextEditingController();
  final soldtoController = TextEditingController();

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

      print(payment_status);
      print(payment_method);

    }

    getList();
    getIncomeCategoryList();
    getPayMethodList();
    Utils.setupAds();

  }

   List<Flock> flocks = [];
   void getList() async {

     if(!isEdit) {
       await DatabaseHelper.instance.database;
       flocks = await DatabaseHelper.getFlocks();
       is_specific_flock = true;
       if(flocks.length > 1){
         flocks.insert(0, Flock(f_id: -1,
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

       for (int i = 0; i < flocks.length; i++) {
         _purposeList.add(flocks.elementAt(i).f_name);
         total_birds += flocks
             .elementAt(i)
             .active_bird_count!;
       }

       _purposeselectedValue = _purposeList[0];
       howmanyController.text = "";
       DateTime dateTime = DateTime.now();
       date = DateFormat('yyyy-MM-dd').format(dateTime);


     }else{

       _purposeselectedValue = widget.transactionItem!.f_name;
       _purposeList.add(_purposeselectedValue);
       howmanyController.text = widget.transactionItem!.how_many;
       date = widget.transactionItem!.date;

       if(widget.transactionItem!.f_id! != -1) {
         Flock? flock = await DatabaseHelper.getSingleFlock(
             widget.transactionItem!.f_id!);
         flocks.add(flock!);
         is_specific_flock = true;
       }else{
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

    if(_paymentMethodList.length > 0) {
      for (int i = 0; i < _paymentMethodList.length; i++) {
        _visiblePaymentMethodList.add(_paymentMethodList
            .elementAt(i)
            .name!);
      }
    }else{
      _visiblePaymentMethodList.add("Cash");
    }

    if(!isEdit)
    payment_method = _visiblePaymentMethodList[0];
    print(payment_method);

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

    } else{
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

  void checkSelectedOption(){

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

                      ),  EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 1 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 3'.tr(),

                      ),

                    ],
                    onStepReached: (index) =>
                        setState(() => activeStep = index),
                  ),

                  SizedBox(height: 30,),
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                        activeStep==0? Column(children: [
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                                isEdit?'Edit'.tr() +" "+ "Income".tr() : "NEW_INCOME".tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Utils.getThemeColorBlue(),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              )),
                             SizedBox(height: 40,width: widthScreen),

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
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('PURPOSE1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                                      color:  purpose_option_invalid? Colors.red:Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: getSaleTypeList(),
                                ),
                              ],
                            ),
                          (is_bird_sale && is_specific_flock)? Container(alignment: Alignment.center,child: Text('Auto_reduction'.tr(), style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w200),)):SizedBox(width: 1,),

                          choose_option ? Column(
                            children: [
                              SizedBox(height: 10,width: widthScreen),
                              Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Income Categories'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                              Row(
                                children: [Expanded(
                                  child: Container(
                                    height: 70,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.all(10),
                                    margin: EdgeInsets.only(left: 20, right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(70),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0)),
                                      border: Border.all(
                                        color: income_option_invalid? Colors.red:Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: getMySaleOptionsList(),
                                  ),
                                ),InkWell(
                                  onTap: (){
                                    addNewIncomOption();
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0)),

                                    ),
                                    margin: EdgeInsets.only(right: 20),
                                    child: Text(
                                      "+",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),],
                              )
                            ],
                          ):SizedBox(width: 1,),

                          SizedBox(height: 10,width: widthScreen),
                            Container(

                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('HOW_MANY'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                        Container(
                                          height: 70,
                                          padding: EdgeInsets.all(0),
                                          margin: EdgeInsets.only(left: 20,right: 5,),
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
                                                readOnly: (!is_specific_flock && is_bird_sale),
                                                onTap: () {
                                                  if(!is_specific_flock && is_bird_sale){
                                                    showBottomDialog();
                                                  }
                                                },
                                                controller: howmanyController,
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
                                                  hintText: 'HOW_MANY'.tr(),
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
                                  ),
                                  Expanded(
                                      child: Column(
                                        children: [
                                          Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 5,bottom: 5),child: Text('SALE_AMOUNT'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                          Container(
                                            height: 70,
                                            padding: EdgeInsets.all(0),
                                            margin: EdgeInsets.only( right: 20),
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
                                                  controller: amountController,
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
                                                  decoration:  InputDecoration(
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                        BorderRadius.all(Radius.circular(20))),
                                                    hintText: 'SALE_AMOUNT'.tr(),
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
                                      )) ,
                                ],
                              ),),
                          ],):SizedBox(width: 1,),


                          activeStep==1?  Column(children: [
                            Container(
                                margin: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Payment Info".tr(),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )),
                            SizedBox(height: 20,width: widthScreen),
                            Column(
                              children: [
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Payment Method'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                  child: getPaymentMethodList(),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,width: widthScreen),
                            Column(
                              children: [
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Payment Status'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                  child: getPaymentStatusList(),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,width: widthScreen),
                            Column(
                              children: [
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('SOLD_TO'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

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
                                        controller: soldtoController,
                                        textInputAction: TextInputAction.next,
                                        decoration:  InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(20))),
                                          hintText: 'SOLD_TO_HINT'.tr(),
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
                          ],):SizedBox(width: 1,),


                          activeStep==2?  Column(children: [
                            Container(
                                margin: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Date_DESC".tr(),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Utils.getThemeColorBlue(),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )),
                            SizedBox(height: 20,width: widthScreen),
                            Column(
                              children: [
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                Container(
                                  width: widthScreen,
                                  height: 70,
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
                                  child: InkWell(
                                    onTap: () {
                                      pickDate();
                                    },
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(left: 10),

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
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('HOW_MUCH'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
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
                          ],):SizedBox(width: 1,),


                          SizedBox(height: 10,width: widthScreen),
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

        DatabaseHelper.updateFlockBirds(
            active_birds, getFlockID());

        int? flock_detail_id = await DatabaseHelper
            .insertFlockDetail(Flock_Detail(
            f_id: getFlockID(),
            item_type: 'Reduction',
            item_count: int.parse(
                howmanyController.text),
            acqusition_type: "",
            acqusition_date: date,
            reason: "Bird Sale".tr(),
            short_note: notesController.text,
            f_name: _purposeselectedValue,
            transaction_id: transactionn_id.toString()

        ));

        await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), flock_detail_id.toString());

      }
    }else if(is_specific_flock && is_bird_sale && isEdit){
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
              Flock_Detail flock_detail_1 = Flock_Detail(f_id: getFlockID(), f_name: _purposeselectedValue, item_type: flock_detail.item_type, item_count: second_reduction, acqusition_type: flock_detail.acqusition_type, acqusition_date: flock_detail.acqusition_date, reason: flock_detail.reason, short_note: notesController.text, transaction_id: transactionn_id.toString());
              flock_detail_1.f_detail_id = f_detail_id;
              await DatabaseHelper.updateFlock(flock_detail_1);


            }else{
              int diff = second_reduction - first_reduction;
              int current_active = getActiveBirds(getFlockID());
              current_active = current_active - diff;
              await DatabaseHelper.updateFlockBirds(current_active, getFlockID());
              Flock_Detail flock_detail_1 = Flock_Detail(f_id: getFlockID(), f_name: _purposeselectedValue, item_type: flock_detail.item_type, item_count: second_reduction, acqusition_type: flock_detail.acqusition_type, acqusition_date: flock_detail.acqusition_date, reason: flock_detail.reason, short_note:  notesController.text, transaction_id: transactionn_id.toString());
              flock_detail_1.f_detail_id = f_detail_id;
              await DatabaseHelper.updateFlock(flock_detail_1);


            }

          }

          await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), f_detail_id.toString());

        }
      }catch(ex){
        print(ex);
      }
    }else if(!is_specific_flock && is_bird_sale && !isEdit){
      print("FARMWIDE+BIRDSALE+NEW");

      for(int i = 0;i<financeList.length;i++){
        if(financeList.elementAt(i).isActive) {
          await reduceBirdsFarmWide(i, transactionn_id);
        }
      }
      await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), farm_wide_f_detail_id);

    }else if(!is_specific_flock && is_bird_sale && isEdit){
      print("FARMWIDE+BIRDSALE+EDIT");
      for(int i = 0;i<financeList.length;i++){
        await reduceBirdsFarmWideEdit(i);
      }
      await DatabaseHelper.updateLinkedTransaction(transactionn_id.toString(), farm_wide_f_detail_id);

    }

  }

  String farm_wide_f_detail_id = "";
  Future<int> reduceBirdsFarmWide(int index, int transactionn_id) async{

    try {
      print("reduceBirdsFarmWide $index $transactionn_id");
      FinanceFlockItem financeFlockItem = financeList.elementAt(index);

      int active_birds = getActiveBirds(financeFlockItem.id!);
      if (financeFlockItem.selected_birds <
          active_birds) {
        active_birds = active_birds - financeFlockItem.selected_birds;

        print(active_birds);
        DatabaseHelper.updateFlockBirds(active_birds, financeFlockItem.id!);
        print("reduceBirdsFarmWide BIRDS UPDATED $active_birds ${financeFlockItem.name}");

        int? flock_detail_id = await DatabaseHelper
            .insertFlockDetail(Flock_Detail(
            f_id: financeFlockItem.id!,
            item_type: 'Reduction',
            item_count: financeFlockItem.selected_birds,
            acqusition_type: "",
            acqusition_date: date,
            reason: "Bird Sale".tr(),
            short_note: notesController.text,
            f_name: financeFlockItem.name,
            transaction_id: transactionn_id.toString()));

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
        transaction_id: widget.transactionItem!.id.toString());
    object.f_detail_id = f_detail_id;

    await DatabaseHelper.updateFlock(object);


    if (index == 0)
      farm_wide_f_detail_id = f_detail_id.toString();
    else
      farm_wide_f_detail_id =
          farm_wide_f_detail_id + "," + f_detail_id.toString();

    print("ID $farm_wide_f_detail_id");

    return 0;
  }

  bool invalidInput() {

    bool invalid = false;
    if(howmanyController.text.isEmpty)
    {
      invalid = true;

    }
    else if(num.parse(howmanyController.text) == 0)
    {
      invalid = true;
    }

    if(amountController.text.isEmpty){
      invalid = true;
    }

    else if(num.parse(amountController.text) == 0){
      invalid = true;
    }

    if(num.parse(howmanyController.text) >= getActiveBirds(getFlockID()) && is_specific_flock && is_bird_sale){
      invalid = true;
      int count = getActiveBirds(getFlockID()) - 1;
      Utils.showToast("You cannot reduce more than".tr() +" "+ count.toString() + " " + "Birds".tr());
    }

    if(purpose_option_invalid){
      invalid = true;
    }

    if(choose_option){
      if(income_option_invalid){
        invalid = true;
      }
    }

    return invalid;
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

  List<String> paymentStatusList = ['CLEARED'.tr(),'UNCLEAR'.tr(),'RECONCILED'.tr()];

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
