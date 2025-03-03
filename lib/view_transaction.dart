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
import 'model/flock.dart';
import 'model/flock_detail.dart';

class ViewCompleteTransaction extends StatefulWidget {

  String transaction_id;
  String flock_detail_id;
  bool isTransaction;
  ViewCompleteTransaction({Key? key, required this.transaction_id, required this.flock_detail_id, required this.isTransaction})
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
    print(transactionItem);
    if(transactionItem != null) {

      print("Transaction $transactionItem");
      if (transactionItem!.flock_update_id.contains(",")) {
        List<String> item_ids = transactionItem!.flock_update_id.split(",");
        flock_details = [];
        print(item_ids);
        for (int i = 0; i < item_ids.length; i++) {
          print("F DETAIL ID ${item_ids[i]}");
          if(!item_ids[i].isEmpty) {
            Flock_Detail? flock_detail = await DatabaseHelper
                .getSingleFlockDetails(int.parse(item_ids[i]));
            // Flock flock = await DatabaseHelper.getSingleFlock(flock_detail.f_id);
            if (flock_detail != null) {
              flock_details.add(flock_detail);
            }
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
          print('F_DETAIL_LIST ${flock_details.length}');
        }
      }

      if(flock_details.length == 0){

      }

    }else{
      Utils.showToast("No Transaction found".tr());
      DatabaseHelper.updateLinkedFlockDetail(widget.flock_detail_id, "-1");
      Flock_Detail? flock_detail = await DatabaseHelper.getSingleFlockDetails(int.parse(widget.flock_detail_id));
      Navigator.pop(context);
      if(flock_detail?.item_type == "Addition") {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  NewBirdsCollection(isCollection: true,
                      flock_detail: flock_detail)),
        );


      }else{
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  NewBirdsCollection(isCollection: false,
                      flock_detail: flock_detail)),
        );

      }

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
        bottomNavigationBar: Container(
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Edit Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    editRecord();
                  },
                  borderRadius: BorderRadius.circular(25),
                  splashColor: Colors.blue.withOpacity(0.3),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 55,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform: Matrix4.translationValues(0, 0, 0),
                          child: Icon(Icons.edit, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'EDIT_RECORD'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Delete Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    showAlertDialog(context);
                  },
                  borderRadius: BorderRadius.circular(25),
                  splashColor: Colors.red.withOpacity(0.3),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 55,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform: Matrix4.translationValues(0, 0, 0),
                          child: Icon(Icons.delete, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DELETE_RECORD'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
            color: Utils.getThemeColorBlue(),
            child: SingleChildScrollViewWithStickyFirstWidget(
              child: Column(
                children: [
                  Utils.getDistanceBar(),
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)), // Smooth bottom corners
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue(), Utils.getThemeColorBlue()],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Back Button with Ripple Effect
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(25),
                            splashColor: Colors.white.withOpacity(0.3),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            ),
                          ),
                          SizedBox(width: 15),

                          // Title Text
                          Expanded(
                            child: Text(
                              "View Complete Transaction".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  transactionItem!= null? Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15), // Semi-transparent effect
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3), // Light border for glass effect
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction Title
                        Text(
                          transactionItem!.type == 'Income'
                              ? transactionItem!.sale_item.tr()
                              : transactionItem!.expense_item.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Amount & Type
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${Utils.currency}${transactionItem!.amount}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: transactionItem!.type == "Income"
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: transactionItem!.type == "Income"
                                    ? Colors.greenAccent.withOpacity(0.2)
                                    : Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                transactionItem!.type.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: transactionItem!.type == "Income"
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(thickness: 1, color: Colors.white.withOpacity(0.2), height: 20),

                        // Transaction Details
                        _buildDetailRow(Icons.calendar_today, Utils.getFormattedDate(transactionItem!.date)),
                        _buildDetailRow(Icons.payment, "${transactionItem!.payment_method.tr()} (${transactionItem!.payment_status.tr()})"),
                        _buildDetailRow(Icons.swap_horiz,
                            transactionItem!.type.toLowerCase() == 'income'
                                ? 'From'.tr() + ": " + transactionItem!.sold_purchased_from
                                : 'To'.tr() + ": " + transactionItem!.sold_purchased_from,
                            isBold: true
                        ),

                        // Notes (if available)
                        if (transactionItem!.short_note.isNotEmpty) ...[
                          SizedBox(height: 10),
                          _buildDetailRow(Icons.notes, transactionItem!.short_note, isItalic: true),
                        ],
                      ],
                    ),
                  )
                      : SizedBox(width: 1,),
                  Container(
                    margin: EdgeInsets.only(top: 50),
                    height: heightScreen,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      color: Utils.getScreenBackground(),
                    ),
                    child: Column(
                      children: [
                        // Title
                        Container(
                          margin: EdgeInsets.only(left: 20, right: 20, top: 10),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              transactionItem!.type == "Income" ? "Reductions".tr() : "Additions".tr(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // List of Flock Details
                        Expanded(
                          child: ListView.builder(
                            itemCount: flock_details.length,
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left Section: Flock Name & Type
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset("assets/bird_icon.png", width: 30, height: 30,),
                                            SizedBox(width: 6),
                                            Text(
                                              flock_details.elementAt(index).f_name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(Icons.merge_type_outlined, color: Colors.grey, size: 25),
                                            SizedBox(width: 6),
                                            Text(
                                              transactionItem!.type == "Expense"
                                                  ? flock_details.elementAt(index).acqusition_type.tr()
                                                  : flock_details.elementAt(index).reason.toString().tr(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Utils.getThemeColorBlue(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Right Section: Bird Count
                                    Row(
                                      children: [
                                        Icon(Icons.tag, color: Colors.black87, size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          flock_details.elementAt(index).item_count.toString(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Utils.getThemeColorBlue(),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Birds".tr(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
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

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDetailRow(IconData icon, String text, {bool isBold = false, bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                color: Colors.white,
              ),
            ),
          ),
        ],
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

        try {
          if (transactionItem!.type == "Income") {
            print("INCOME");
            for (int i = 0; i < flock_details.length; i++) {
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
              if (flock == null) {
                print("FLOCK NULL");
                await DatabaseHelper.deleteItemWithFlockID(
                    "Flock_Detail", flock_details
                    .elementAt(i)
                    .f_detail_id!);
              } else {
                print("FLOCK FOUND");
                int current_birds = flock.active_bird_count!;
                current_birds = current_birds + birds_to_delete;

                await DatabaseHelper.updateFlockBirds(
                    current_birds, flock_details
                    .elementAt(i)
                    .f_id);
                print("BIRD UPDATED");

                await DatabaseHelper.deleteItemWithFlockID(
                    "Flock_Detail", flock_details
                    .elementAt(i)
                    .f_detail_id!);
                print("DELETE FLOCK DETAIL");
              }
            }
          } else {
            print("EXPENSE ");
            for (int i = 0; i < flock_details.length; i++) {
              int birds_to_delete = flock_details
                  .elementAt(i)
                  .item_count;
              print('BIRDS_TO_DELETE $birds_to_delete');
              print("F_ID ${flock_details
                  .elementAt(i)
                  .f_id}");
              Flock? flock = await DatabaseHelper
                  .getSingleFlock(flock_details
                  .elementAt(i)
                  .f_id);

              if (flock == null) {
                print("FLOCK NULL");
                await DatabaseHelper.deleteItemWithFlockID(
                    "Flock_Detail", flock_details
                    .elementAt(i)
                    .f_detail_id!);
              } else {
                print("FLOCK FOUND");
                int current_birds = flock.active_bird_count!;
                current_birds = current_birds - birds_to_delete;

                await DatabaseHelper.updateFlockBirds(
                    current_birds, flock_details
                    .elementAt(i)
                    .f_id);
                print("BIRD UPDATED");

                await DatabaseHelper.deleteItemWithFlockID(
                    "Flock_Detail", flock_details
                    .elementAt(i)
                    .f_detail_id!);
                print("DELETE FLOCK DETAIL");
              }
            }
          }

          await DatabaseHelper.deleteItem("Transactions", transactionItem!.id!);
          Utils.showToast("RECORD_DELETED".tr());
          Navigator.pop(context);
          Navigator.pop(context);

          setState(() {

          });
        }
        catch(ex){
          Utils.showToast(ex.toString());
        }
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
