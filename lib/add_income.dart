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
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';
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
  String _saleselectedValue = "Sale Item".tr();

  List<String> _purposeList = [];
  List<String> _saleItemList = [];
  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];
  List<SubItem> _subItemList = [];

  int chosen_index = 0;

  int total_birds = 0;

  bool includeExtras = false;
  bool isEdit = false;

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose date";
  String displayDate = "";
  String payment_method = "Payment Method".tr();
  String payment_status = "Payment Status".tr();

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
      payment_status = widget.transactionItem!.payment_status;
      payment_method = widget.transactionItem!.payment_method;
      notesController.text = widget.transactionItem!.short_note;
      howmanyController.text = widget.transactionItem!.how_many;
      soldtoController.text = widget.transactionItem!.sold_purchased_from;
      amountController.text = widget.transactionItem!.amount;

    }

    getList();
    getIncomeCategoryList();
    getPayMethodList();
    Utils.setupAds();

  }

  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
      total_birds += flocks.elementAt(i).active_bird_count!;
    }

    _purposeselectedValue = _purposeList[0];
    howmanyController.text = total_birds.toString();

    setState(() {

    });

  }

  void getPayMethodList() async {
    await DatabaseHelper.instance.database;

    _paymentMethodList = await DatabaseHelper.getSubCategoryList(5);

    _paymentMethodList.insert(0,SubItem(c_id: 3,id: -1,name: 'Payment Method'.tr()));

    for(int i=0;i<_paymentMethodList.length;i++){
      _visiblePaymentMethodList.add(_paymentMethodList.elementAt(i).name!);
    }

    payment_method = _visiblePaymentMethodList[0];

    print(_visiblePaymentMethodList);

    setState(() {

    });

  }

  void getIncomeCategoryList() async {
    await DatabaseHelper.instance.database;

    _subItemList = await DatabaseHelper.getSubCategoryList(1);

    _subItemList.insert(0,SubItem(c_id: 3,id: -1,name: 'Sale item'.tr()));

    for(int i=0;i<_subItemList.length;i++){
      _saleItemList.add(_subItemList.elementAt(i).name!);
    }

    _saleselectedValue = _saleItemList[0];

    print(_saleItemList);


    setState(() {

    });

  }



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
                            color: Utils.getThemeColorBlue(), //(x,y)
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
                                isEdit?'Edit'.tr() +" "+ "Income".tr() : "NEW_INCOME".tr(),
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
                            child: getSaleTypeList(),
                          ),

                          SizedBox(height: 10,width: widthScreen),
                          
                          
                          Container(
                            
                            child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 70,
                                  padding: EdgeInsets.all(0),
                                  margin: EdgeInsets.only(left: 20,right: 5,),
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
                                        controller: howmanyController,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        decoration:  InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.all(Radius.circular(10))),
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
                              ),
                              Expanded(
                                 child: Container(
                               height: 70,
                               padding: EdgeInsets.all(0),
                               margin: EdgeInsets.only( right: 20),
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
                                     controller: amountController,
                                     keyboardType: TextInputType.number,
                                     textInputAction: TextInputAction.next,
                                     decoration:  InputDecoration(
                                       border: OutlineInputBorder(
                                           borderRadius:
                                           BorderRadius.all(Radius.circular(10))),
                                       hintText: 'SALE_AMOUNT'.tr(),
                                       hintStyle: TextStyle(
                                           color: Colors.grey, fontSize: 16),
                                       labelStyle: TextStyle(
                                           color: Colors.black, fontSize: 16),
                                     ),
                                   ),
                                 ),
                               ),
                             )) ,
                            ],
                          ),),

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
                            child: getPaymentMethodList(),
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
                            child: getPaymentStatusList(),
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
                                  controller: soldtoController,
                                  textInputAction: TextInputAction.next,
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
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

                                if(isEdit){

                                  await DatabaseHelper.instance.database;
                                  TransactionItem transaction_item = TransactionItem(
                                      f_id: getFlockID(),
                                      date: date,
                                      sale_item: _saleselectedValue,
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
                                      f_name: _purposeselectedValue);

                                  transaction_item.id = widget.transactionItem!.id;

                                  int? id = await DatabaseHelper
                                      .updateTransaction(transaction_item);
                                  Utils.showToast("SUCCESSFUL".tr());
                                  Navigator.pop(context);
                                }else {
                                  print("Everything Okay");
                                  await DatabaseHelper.instance.database;
                                  TransactionItem transaction_item = TransactionItem(
                                      f_id: getFlockID(),
                                      date: date,
                                      sale_item: _saleselectedValue,
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
                                      f_name: _purposeselectedValue);
                                  int? id = await DatabaseHelper
                                      .insertNewTransaction(transaction_item);
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
            int f_id = getFlockID();
            if (f_id == -1){
              howmanyController.text = total_birds.toString();
            }else {
              howmanyController.text = getActiveBirds().toString();
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

  List<String> paymentStatusList = ['Payment Status'.tr(),'CLEARED'.tr(),'UNCLEAR'.tr(),'RECONCILED'.tr()];

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

  int getActiveBirds() {

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

}
