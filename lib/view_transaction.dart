import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'add_birds.dart';
import 'add_expense.dart';
import 'add_income.dart';
import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/finance_flock_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';

class ViewCompleteTransaction extends StatefulWidget {

  String transaction_id;
  bool isTransaction;
  ViewCompleteTransaction({Key? key, required this.transaction_id, required this.isTransaction})
      : super(key: key);

  @override
  _ViewCompleteTransaction createState() => _ViewCompleteTransaction();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ViewCompleteTransaction extends State<ViewCompleteTransaction>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  TransactionItem? transactionItem = null;

  @override
  void initState() {
    super.initState();
    getData();

  }

  List<Flock_Detail> flock_details = [];
  void getData() async {

    await DatabaseHelper.instance.database;

    print("Transaction ID ${widget.transaction_id}");
    transactionItem = await DatabaseHelper.getSingleTransaction(widget.transaction_id);

    if(transactionItem != null) {

      print("Transaction $transactionItem");
      if (transactionItem!.flock_update_id.contains(",")) {
        List<String> item_ids = transactionItem!.flock_update_id.split(",");
        flock_details = [];
        print(item_ids);
        for (int i = 0; i < item_ids.length; i++) {
          print("F DETAIL ID ${item_ids[i]}");
          Flock_Detail? flock_detail = await DatabaseHelper
              .getSingleFlockDetails(int.parse(item_ids[i]));
          // Flock flock = await DatabaseHelper.getSingleFlock(flock_detail.f_id);
          if (flock_detail != null) {
            flock_details.add(flock_detail);
          }
        }
      }
      else {
        flock_details = [];
        Flock_Detail? flock_detail = await DatabaseHelper.getSingleFlockDetails(
            int.parse(transactionItem!.flock_update_id));
        // Flock flock = await DatabaseHelper.getSingleFlock(flock_detail.f_id);
        if (flock_detail != null) {
          flock_details.add(flock_detail);
        }
      }

      if(flock_details.length == 0){

      }

    }else{
      Utils.showToast("No Transaction found".tr());
      Navigator.pop(context);
    }

    setState(() {

    });

  }


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
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          child: Container(
            height: 60,
            width: widthScreen,
            child: Row(children: [

              Expanded(
                child: InkWell(
                  onTap: () {
                    editRecord();
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Utils.getThemeColorBlue(),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(20.0)),
                      border: Border.all(
                        color:  Utils.getThemeColorBlue(),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 2,
                          offset: Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit, color: Colors.white, size: 25,),SizedBox(width: 4,),
                      Text('EDIT_RECORD'.tr(), style: TextStyle(
                          color: Colors.white, fontSize: 16),)
                    ],),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    showAlertDialog(context);
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(20.0)),
                      border: Border.all(
                        color:  Colors.red,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 2,
                          offset: Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.delete, color: Colors.white, size: 25,),SizedBox(width: 4,),
                      Text('DELETE_RECORD'.tr(), style: TextStyle(
                          color: Colors.white, fontSize: 16),)
                    ],),
                  ),
                ),
              ),
            ],),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: Container(
            width: widthScreen,
            height: heightScreen,
            color: Utils.getThemeColorBlue(),
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
                                "View Complete Transaction".tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              )),

                        ],
                      ),
                    ),
                  ),
                 transactionItem!= null? Container(
                    margin: EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 0),

                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [

                          Align(
                            alignment: Alignment.centerLeft,
                            child:Container(child: Text( textAlign:TextAlign.left,style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()), transactionItem!.type == 'Income'? transactionItem!.sale_item.tr() : transactionItem!.expense_item.tr()),),),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("${Utils.currency}${transactionItem!.amount}",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: transactionItem!.type == "Income"? Colors.white : Colors.white),),
                              Text(" ("+transactionItem!.type.tr().tr()+")",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w100, color: Colors.white70),),

                            ],),

                          Row( children: [
                            Expanded(
                              child: Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(child: Icon(Icons.calendar_month, color: Colors.white70,) ),
                                        Text(" "+Utils.getFormattedDate(transactionItem!.date), style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white, fontSize: 14),),

                                      ],
                                    ),
                                    SizedBox(height: 5,),
                                    Row(
                                      children: [
                                        Container(child: Image.asset('assets/payment_method_ico.png', width: 25, height: 25, color: Colors.white70,) ),
                                        Text(" "+transactionItem!.payment_method, style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white, fontSize: 14),),
                                        Text(" ("+transactionItem!.payment_status+")", style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white70, fontSize: 14),),

                                      ],
                                    ),
                                    SizedBox(height: 5,),

                                    Row(
                                      children: [
                                        Container(child: Image.asset('assets/trade_ico.png', width: 25, height: 25, color: Colors.white70,) ),

                                        Container( child: Text(transactionItem!.type.toLowerCase() == 'income'? ' From'.tr()+":":' To'.tr()+":", style: TextStyle(fontSize: 14, color: Colors.white70),)),
                                        Text(" "+transactionItem!.sold_purchased_from, style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white, fontSize: 14),),

                                      ],
                                    ),



                                    Container(
                                      margin: EdgeInsets.only(top: 5),
                                      child: Row(
                                        children: [
                                          Icon(Icons.format_quote,size: 25,color: Colors.white70,),
                                          SizedBox(width: 3,),
                                          Container(
                                            width: widthScreen - 100,
                                            child: Text(
                                              transactionItem!.short_note.isEmpty ? 'NO_NOTES'.tr() : transactionItem!.short_note
                                              ,maxLines: 3, style: TextStyle(fontSize: 14, color: Colors.white),),
                                          ),
                                        ],
                                      ),
                                    )
                                    // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                  ],),
                              ),
                            ),

                          ]),
                        ],
                      ) ,
                    ),
                  ) : SizedBox(width: 1,),
                  Container(
                    margin: EdgeInsets.only(top: 50),
                    height: heightScreen,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      color: Utils.getScreenBackground(),

                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: widthScreen/2,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(transactionItem!.type == "Income"? "Reductions":"Additions",style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),),

                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                        // Container(width: widthScreen,height: 60,
                        // ),
                        SizedBox(height: 8,),
                        Container(
                          height: flock_details.length * 140,
                          width: widthScreen - 10,
                          child: ListView.builder(
                              itemCount: flock_details.length,
                              scrollDirection: Axis.vertical,
                              physics: const NeverScrollableScrollPhysics(),

                              itemBuilder: (BuildContext context, int index) {
                                return  Container(
                                  margin: EdgeInsets.only(left: 15, right: 15, top: 10),
                                  padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: Offset(0, 1), // changes position of shadow
                                        ),
                                      ],
                                      color: Colors.white70,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0)),
                                      border: Border.all(
                                        color:  Colors.white70,
                                        width: 2.0,
                                      ),
                                    ),
                                  child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Column(
                                              children: [
                                                Container(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(flock_details.elementAt(index).f_name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),)),
                                                Container(child: Text(transactionItem!.type == "Expense"? flock_details.elementAt(index).acqusition_type:flock_details.elementAt(index).reason.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Utils.getThemeColorBlue()),)),

                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(child: Text(flock_details.elementAt(index).item_count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Utils.getThemeColorBlue()),)),
                                                Container(child: Text(" "+"Birds".tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.black),)),

                                              ],
                                            ),

                                          ],
                                        )
                                      ]
                                      ),
                                );

                              }),
                        )
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void editRecord() async{

    if(widget.isTransaction){
      if(transactionItem!.type == "Income") {
        var txt = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>  NewIncome(transactionItem: transactionItem,)),
        );

        getData();
      }else{
        var txt = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>  NewExpense(transactionItem: transactionItem,)),
        );

        getData();
      }
    }else{
      if(flock_details.length > 1){
        if(transactionItem!.type == "Income") {
          var txt = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  NewIncome(transactionItem: transactionItem,)),
          );

          getData();
        }else{
          var txt = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  NewExpense(transactionItem: transactionItem,)),
          );

          getData();
        }
      }else{
        if(flock_details.elementAt(0).item_type == "Addition") {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    NewBirdsCollection(isCollection: true,
                        flock_detail: flock_details.elementAt(0))),
          );

          getData();

        }else{
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    NewBirdsCollection(isCollection: false,
                        flock_detail: flock_details.elementAt(0))),
          );

          getData();

        }
      }
    }


  }

  showAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DELETE".tr()),
      onPressed:  () async {

        if(transactionItem!.type == "Income"){
          for(int i=0;i<flock_details.length;i++){

            int birds_to_delete = flock_details
                .elementAt(i)
                .item_count;
            print("F_ID ${flock_details
                .elementAt(i)
                .f_id}");
            Flock? flock = await DatabaseHelper
                .getSingleFlock(flock_details
                .elementAt(i)
                .f_id);
            if(flock == null){
              await DatabaseHelper.deleteItem("Flock_Detail", flock_details
                  .elementAt(i)
                  .f_detail_id!);
            }else {
              int current_birds = flock.active_bird_count!;
              current_birds = current_birds + birds_to_delete;

              await DatabaseHelper.updateFlockBirds(
                  current_birds, flock_details
                  .elementAt(i)
                  .f_id);

              await DatabaseHelper.deleteItem("Flock_Detail", flock_details
                  .elementAt(i)
                  .f_detail_id!);
            }
          }
        }else{
          for(int i=0;i<flock_details.length;i++){

            int birds_to_delete = flock_details
                .elementAt(i)
                .item_count;
            print("F_ID ${flock_details
                .elementAt(i)
                .f_id}");
            Flock? flock = await DatabaseHelper
                .getSingleFlock(flock_details
                .elementAt(i)
                .f_id);

            if(flock == null){
              await DatabaseHelper.deleteItem("Flock_Detail", flock_details
                  .elementAt(i)
                  .f_detail_id!);
            }else {
              int current_birds = flock!.active_bird_count!;
              current_birds = current_birds - birds_to_delete;

              await DatabaseHelper.updateFlockBirds(
                  current_birds, flock_details
                  .elementAt(i)
                  .f_id);
              await DatabaseHelper.deleteItem("Flock_Detail", flock_details
                  .elementAt(i)
                  .f_detail_id!);
            }
          }
        }

        await DatabaseHelper.deleteItem("Transactions", transactionItem!.id!);
        Utils.showToast("RECORD_DELETED".tr());
        Navigator.pop(context);
        Navigator.pop(context);

        setState(() {

        });

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Text("RU_SURE".tr()),
      actions: [
        cancelButton,
        continueButton,
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



}
