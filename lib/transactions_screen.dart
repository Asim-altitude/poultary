import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_expense.dart';
import 'package:poultary/add_income.dart';
import 'package:poultary/add_reduce_flock.dart';
import 'package:poultary/model/feed_stock_history.dart';
import 'package:poultary/model/medicine_stock_history.dart';
import 'package:poultary/model/stock_expense.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/model/vaccine_stock_history.dart';
import 'package:poultary/multiuser/model/egg_record.dart';
import 'package:poultary/multiuser/model/feedstockfb.dart';
import 'package:poultary/multiuser/model/financeItem.dart';
import 'package:poultary/multiuser/model/medicinestockfb.dart';
import 'package:poultary/multiuser/model/vaccinestockfb.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/view_transaction.dart';
import 'package:sqflite/sqflite.dart';
import 'add_eggs.dart';
import 'database/databse_helper.dart';
import 'model/egg_income.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreen createState() => _TransactionsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _TransactionsScreen extends State<TransactionsScreen> with SingleTickerProviderStateMixin, RefreshMixin{

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.FINANCE
          || event == FireBaseUtils.FLOCKS
          || event == FireBaseUtils.EGGS)
      {
        getData(date_filter_name);
      }
    }
    catch(ex)
    {
      print(ex);
    }
  }

  double widthScreen = 0;
  double heightScreen = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void dispose() {
    super.dispose();
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
  }

  int _other_filter = 2;
  void getFilters() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    addNewColumn();

    _purposeselectedValue = Utils.selected_flock==null? _purposeList[0] : Utils.selected_flock!.f_name;

    f_id = getFlockID();
    Utils.SELECTED_FLOCK = _purposeselectedValue;
    Utils.SELECTED_FLOCK_ID = f_id;
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    getData(date_filter_name);

  }

  void addNewColumn() async {
    try{
      int c = await DatabaseHelper.addColumnInFlockDetail();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int c = await DatabaseHelper.addColumnInFTransactions();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int? c = await DatabaseHelper.updateLinkedFlocketailNullValue();
      print("Flock Details Update Info $c");

      int? t = await DatabaseHelper.updateLinkedTransactionNullValue();
      print("Transactions Update Info $t");
    }catch(ex){
      print(ex);
    }
  }

  @override
  void initState() {
    super.initState();

    getFilters();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

    AnalyticsUtil.logScreenView(screenName: "transaction_screen");
  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }


  bool no_colection = true;
  List<TransactionItem> transactionList = [], tempList = [];
  List<String> flock_name = [];
  void getAllTransactions() async {

    await DatabaseHelper.instance.database;

    tempList = await DatabaseHelper.getAllTransactions();
    transactionList = tempList.reversed.toList();

    feed_total = transactionList.length;

    setState(() {

    });

  }

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    tempList = await DatabaseHelper.getFilteredTransactionsWithSort(f_id,filter_name,st,end,sortSelected);

    transactionList = tempList.reversed.toList();
    feed_total = transactionList.length;

    setState(() {

    });

  }

  int feed_total = 0;
  String applied_filter_name = "INCOME_EXPENSE";
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];


  int selected = 1;
  int f_id = -1;

  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);
      child:
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10.0), // Round bottom-left corner
            bottomRight: Radius.circular(10.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              applied_filter_name.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  openSortDialog(context, (selectedSort) {
                    setState(() {
                      sortOption = selectedSort == "date_desc" ? "Date (New)" : "Date (Old)";
                      sortSelected = selectedSort == "date_desc" ? "DESC" : "ASC";
                    });

                    getFilteredTransactions(str_date, end_date);
                  });
                },
                child: Container(
                  height: 45,
                  width: 130,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sortOption.tr(),
                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.sort, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ],
            backgroundColor: Colors.blue, // Customize the color
            elevation: 8, // Gives it a more elevated appearance
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Container(
          height: 60, // Slightly increased height for better tap accessibility
          width: widthScreen,
          padding: EdgeInsets.symmetric(horizontal: 10), // Added padding for better spacing
          child: Row(
            children: [
              /// 🟢 Income Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_transaction"))
                    {
                      Utils.showMissingPermissionDialog(context, "add_transaction");
                      return;
                    }

                    showIncomeTypeSelector(context);
                   // addNewIncome();
                  },
                  borderRadius: BorderRadius.circular(10), // Smooth rounded ripple effect
                  child: Container(
                    height: 55, // Increased for better touch area
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400], // Gradient for modern effect
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade900.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 26), // Slightly reduced size for better alignment
                        SizedBox(width: 6), // Space between icon and text
                        Text(
                          'Income'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10), // Space between buttons

              /// 🔴 Expense Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_transaction"))
                    {
                      Utils.showMissingPermissionDialog(context, "add_transaction");
                      return;
                    }

                    addNewExpense();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade700, Colors.red.shade400], // Red gradient for expense
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade900.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove, color: Colors.white, size: 26), // "Remove" icon for better visual cue
                        SizedBox(width: 6),
                        Text(
                          'Expense'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getScreenBackground(),
            child:Column(children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),

              Expanded(child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:  [

                      /*ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue],
                     // colors: [Utils.getThemeColorBlue().withOpacity(0.9), Utils.getThemeColorBlue()],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      /// Back Button
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),

                      /// Title
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 12),
                          child: Text(
                            applied_filter_name.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      /// Sort Button
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          openSortDialog(context, (selectedSort) {
                            setState(() {
                              sortOption = selectedSort == "date_desc" ? "Date (New)" : "Date (Old)";
                              sortSelected = selectedSort == "date_desc" ? "DESC" : "ASC";
                            });

                            getFilteredTransactions(str_date, end_date);
                          });
                        },
                        child: Container(
                          height: 45,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sortOption.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.sort, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
                      Center(
                        child: Container(
                          padding: EdgeInsets.only(top: 2),
                          margin: EdgeInsets.symmetric(horizontal: 10), // Margin of 10 on left & right
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3, // 60% of available space
                                child: SizedBox(
                                  height: 55,
                                  child: _buildDropdownField(
                                    "Select Item",
                                    _purposeList,
                                    _purposeselectedValue,
                                        (String? newValue) {
                                      _purposeselectedValue = newValue!;

                                      f_id = getFlockID();
                                      Utils.SELECTED_FLOCK = newValue;
                                      Utils.SELECTED_FLOCK_ID = f_id;
                                      print("SELECTED_FLOCK $f_id");
                                      getFilteredTransactions(str_date, end_date);

                                    },
                                    width: double.infinity,
                                    height: 45,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5), // Space between the dropdowns
                              Expanded(
                                flex: 2, // 40% of available space
                                child: SizedBox(
                                  height: 55,
                                  child: _buildDropdownField(
                                    "Select Item",
                                    filterList,
                                    date_filter_name,
                                        (String? newValue) {
                                      date_filter_name = newValue!;
                                      getData(date_filter_name);
                                    },
                                    width: double.infinity,
                                    height: 45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 55,
                        width: widthScreen,
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white.withOpacity(0.1), // Light transparent background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildFilterButton('All', 1, Colors.blue),
                            buildFilterButton('Income', 2, Colors.green),
                            buildFilterButton('Expense', 3, Colors.red),
                          ],
                        ),
                      ),

                      transactionList.length > 0 ?

                      Container(
                        height: heightScreen,
                        width: widthScreen,
                        child: Padding(
                          padding: Utils.isShowAdd? const EdgeInsets.only(bottom: 370) : const EdgeInsets.only(bottom: 300), // Adjust this value as needed
                          child: ListView.builder(
                              itemCount: transactionList.length,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        /// **Title & Menu (Aligned in Same Row)**
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                transactionList.elementAt(index).type == 'Income'
                                                    ? transactionList.elementAt(index).sale_item.tr()
                                                    : transactionList.elementAt(index).expense_item.tr(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Utils.getThemeColorBlue(),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            /// **Options Menu**
                                            GestureDetector(
                                              onTapDown: (TapDownDetails details) {
                                                selected_id = transactionList.elementAt(index).id;
                                                selected_index = index;
                                                showMemberMenu(details.globalPosition);
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.grey.shade200,
                                                ),
                                                child: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade700),
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// **Divider (Title Section)**
                                        Container(
                                          margin: EdgeInsets.symmetric(vertical: 6),
                                          height: 1,
                                          color: Colors.grey.shade300,
                                        ),

                                        /// **Item & Quantity**
                                        Row(
                                          children: [
                                            Icon(Icons.shopping_bag, size: 16, color: Colors.blueAccent),
                                            SizedBox(width: 5),
                                            Text(
                                              transactionList.elementAt(index).f_name.tr(),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "(${transactionList.elementAt(index).how_many} "+"ITEMS".tr()+")",
                                              style: TextStyle(fontSize: 14, color: Colors.black54),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 6),
                                        /// **Quantity & Unit Price (Second Line)**
                                        Row(
                                          children: [
                                            Text(
                                              "${transactionList[index].how_many ?? 0} " + "ITEMS".tr(),
                                              style: TextStyle(fontSize: 14, color: Colors.black),
                                            ),
                                            SizedBox(width: 10),
                                            Text("•", style: TextStyle(color: Colors.grey, fontSize: 15)),
                                            SizedBox(width: 10),
                                            Text(
                                              "${"UNIT_PRICE".tr()}: ${(transactionList[index].unitPrice ?? 0).toStringAsFixed(2)} ${Utils.currency}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: (transactionList[index].unitPrice ?? 0) == 0
                                                    ? Colors.grey // dim if unit price is still 0
                                                    : Colors.blueGrey.shade700,
                                                fontStyle: (transactionList[index].unitPrice ?? 0) == 0
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                              ),
                                            ),
                                          ],
                                        ),


                                        SizedBox(height: 6),

                                        /// **Transaction Amount & Payment Status**
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            /// **Income/Expense Label**
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: transactionList.elementAt(index).type.toLowerCase() == 'income'
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                transactionList.elementAt(index).type.tr(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: transactionList.elementAt(index).type.toLowerCase() == 'income'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),

                                            /// **Amount**
                                            Row(
                                              children: [
                                                Text(
                                                  transactionList.elementAt(index).amount.toString(),
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                                ),
                                                SizedBox(width: 4),
                                                Text(Utils.currency, style: TextStyle(color: Colors.black, fontSize: 14)),
                                              ],
                                            ),

                                            /// **Payment Status (Colored Tag)**
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Text(
                                                transactionList.elementAt(index).payment_status.toUpperCase().tr(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: transactionList.elementAt(index).payment_status.toLowerCase() == "cleared"
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 8),

                                        /// **Transaction Details**
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.25),
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                transactionList[index].type!.toLowerCase() == 'income'
                                                    ? Icons.trending_up
                                                    : Icons.trending_down,
                                                size: 18,
                                                color: transactionList[index].type!.toLowerCase() == 'income'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),

                                              const SizedBox(width: 10),

                                              /// Two columns evenly spaced
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    /// Left column (constrained)
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            transactionList[index].type!.toLowerCase() == 'income'
                                                                ? 'Sold To'.tr()
                                                                : 'Paid To'.tr(),
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.black54,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            transactionList[index].sold_purchased_from,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    const SizedBox(width: 12),

                                                    /// Right column (fixed width naturally)
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          "On".tr(),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          Utils.getFormattedDate(
                                                            transactionList[index].date.toString(),
                                                          ),
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 6),

                                        /// **Notes Section**
                                        Row(
                                          children: [
                                            Icon(Icons.notes, size: 15, color: Colors.grey.shade700),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                transactionList.elementAt(index).short_note!.isEmpty ? 'NO_NOTES'.tr() : transactionList.elementAt(index).short_note!,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 14, color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// **Sync Info Icon**
                                        if(Utils.isMultiUSer)
                                          GestureDetector(
                                            onTap: () {
                                              TransactionItem item = transactionList[index];
                                              String updated_at = item.last_modified == null
                                                  ? "Unknown".tr()
                                                  : DateFormat("dd MMM yyyy hh:mm a").format(item.last_modified!);

                                              String updated_by = item.modified_by == null || item.modified_by!.isEmpty
                                                  ? "System".tr()
                                                  : item.modified_by!;

                                              Utils.showSyncInfo(context, updated_at, updated_by);
                                            },
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Sync Info",
                                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );


                              }),
                        ),) : Utils.getCustomEmptyMessage("assets/pfinance.png", "No Income/Expense added")


                    ]
                ),))
            ],),),),);
  }

  /// Function to Build Filter Buttons
  Widget buildFilterButton(String label, int index, Color color) {
    bool isSelected = selected == index;

    return Flexible( // Use Flexible instead of Expanded
      child: InkWell(
        onTap: () {
          setState(() {
            filter_name = label;
            selected = index;
            getFilteredTransactions(str_date, end_date);
          });
        },
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 45,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade300,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.check, color: Colors.white, size: 18), // ✅ Checkmark only on selected
              if (isSelected) SizedBox(width: 6),
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showIncomeTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.egg, color: Colors.orange),
                title:  Text("Egg Sale".tr()),
                onTap: () async {

                  Navigator.pop(context); // close bottom sheet
                  // ✅ Redirect to Egg Collection -> Reduce screen

                  if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_eggs"))
                  {
                    Utils.showMissingPermissionDialog(context, "add_eggs");
                    return;
                  }

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  NewEggCollection(isCollection: false, eggs: null, reason: "SOLD",)),);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title:  Text("Other Income".tr()),
                onTap: () {
                  Navigator.pop(context);
                  // ✅ Redirect to your existing Add Income screen
                  addNewIncome();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildDropdownField(
      String label,
      List<String> items,
      String selectedValue,
      Function(String?) onChanged, {
        double width = double.infinity,
        double height = 70,
      }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Utils.getThemeColorBlue(), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          icon: Padding(
            padding: EdgeInsets.only(right: 5),
            child: Icon(Icons.arrow_drop_down_circle, color: Colors.blue, size: 25),
          ),
          isExpanded: true,
          style: TextStyle(fontSize: 16, color: Colors.black),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(value.tr(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> addNewIncome() async {
    var txt = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewIncome(transactionItem: null, selectedIncomeType: null, selectedExpenseType: null,)),
    );

    getData(date_filter_name);
  }

  Future<void> addNewExpense() async{
   var txt = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewExpense(transactionItem: null,)),
    );

   getData(date_filter_name);
  }
  int getFlockID() {


    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }

  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          _purposeselectedValue = newValue!;

          f_id = getFlockID();
          Utils.SELECTED_FLOCK = newValue;
          Utils.SELECTED_FLOCK_ID = f_id;
          print("SELECTED_FLOCK $f_id");
          getFilteredTransactions(str_date, end_date);
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String filter_name = "All";
  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,widthScreen - 40, widthScreen),
          );
        });
  }


    Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

    return Container(
      height: height, // Change as per your requirement
      width: width, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filterList.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {

              setState(() {
                date_filter_name = filterList.elementAt(index);
              });

              getData(date_filter_name);
              Navigator.pop(bcontext);
            },
            child: ListTile(
              title: Text(filterList.elementAt(index)),
            ),
          );
        },
      ),
    );
  }

  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'DATE_RANGE'){
      _pickDateRange();
    }

  }

  DateTimeRange? selectedDateRange;
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year - 5); // Allows past 5 years
    DateTime lastDate = DateTime(now.year + 5); // Allows future 5 years

    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: selectedDateRange ?? DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      var inputFormat = DateFormat('yyyy-MM-dd');
      selectedDateRange = pickedRange;
      str_date = inputFormat.format(pickedRange.start);
      end_date = inputFormat.format(pickedRange.end);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date, end_date);

    }
  }

  int? selected_id = 0;
  int? selected_index = 0;
  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),

      items: [
        PopupMenuItem(
          value: 2,
          child: Text(
            "EDIT_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            transactionList.elementAt(selected_index!).flock_update_id!= "-1" ? "VIEW_RECORD".tr() : "DELETE_RECORD".tr(),

            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),

      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 2) {
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_transaction"))
          {
            Utils.showMissingPermissionDialog(context, "edit_transaction");
            return;
          }

          if(transactionList.elementAt(selected_index!).type == "Income") {

            if(transactionList.elementAt(selected_index!).sale_item == "Egg Sale"){
              EggTransaction? eggTransaction = await DatabaseHelper.getEggsByTransactionItemId(transactionList.elementAt(selected_index!).id!);
              if(eggTransaction != null) {
                Eggs? eggs = await DatabaseHelper.getSingleEggsByID(
                    eggTransaction.eggItemId);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewEggCollection(isCollection: false,
                            eggs: eggs,
                            reason: null,)),
                );
              }else{
                var txt = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewIncome(transactionItem: transactionList.elementAt(
                              selected_index!),
                            selectedIncomeType: null,
                            selectedExpenseType: null,)),
                );
              }
            }else {
              var txt = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NewIncome(transactionItem: transactionList.elementAt(
                            selected_index!),
                          selectedIncomeType: null,
                          selectedExpenseType: null,)),
              );
            }

            getAllTransactions();
          }else{
            var txt = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  NewExpense(transactionItem: transactionList.elementAt(selected_index!),)),
            );

            getAllTransactions();
          }
        }
        else if(value == 1){
          if(transactionList.elementAt(selected_index!).flock_update_id!= "-1"){
            print(selected_index);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  ViewCompleteTransaction(transaction_id: transactionList.elementAt(selected_index!).id.toString(), isTransaction: true, flock_detail_id: '-1',)),
            );

            getData(date_filter_name);
          }else {
            if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_transaction"))
            {
              Utils.showMissingPermissionDialog(context, "delete_transaction");
              return;
            }

            StockExpense? stockExpense = await DatabaseHelper.getByTransactionItemId(transactionList.elementAt(selected_index!).id!);

            if(stockExpense != null){
              showDeleteStockAlertDialog(context);
              return;
            }

            showAlertDialog(context);
          }
        }else {
          print(value);
        }
      }
    });
  }

  showInfoMessage(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Take Action".tr()),
      onPressed:  () async {

       // Utils.selected_flock = await DatabaseHelper.getSingleFlock(transactionList.elementAt(selected_index!).f_id!);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>  AddReduceFlockScreen()),
        );

        getData(date_filter_name);
        Navigator.pop(context);

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Auto Generated".tr()),
      content: Text("AUTO_GENERATED_TRANS".tr()),
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

  String? getFlockSyncID(int f_id) {

    String? selected_id = "unknown";
    for(int i=0;i<flocks.length;i++) {
      if(f_id == flocks.elementAt(i).f_id){
        selected_id = flocks.elementAt(i).sync_id;
        break;
      }
    }

    return selected_id;
  }

  showDeleteStockAlertDialog(BuildContext context) {

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
        TransactionItem item = transactionList.elementAt(selected_index!);
        item.f_sync_id = getFlockSyncID(item.f_id!);

        StockExpense? stockExpense = await DatabaseHelper.getByTransactionItemId(transactionList.elementAt(selected_index!).id!);

        MedicineStockHistory? medicineStockHistory = await DatabaseHelper.getMedicineStockHistotyByID(stockExpense!.stockItemId.toString());
        FeedStockHistory? feedStockHistory = await DatabaseHelper.getFeedStockHistotyByID(stockExpense.stockItemId.toString());
        VaccineStockHistory? vaccineStockHistory = await DatabaseHelper.getVaccineStockHistotyByID(stockExpense.stockItemId.toString());


        try {
          if (Utils.isMultiUSer && Utils.hasFeaturePermission("delete_transaction")) {

            item.modified_by = Utils.currentUser!.email;
            item.last_modified = Utils.getTimeStamp();
            item.farm_id = Utils.currentUser!.farmId;
            item.sync_status = SyncStatus.DELETED;

            if(medicineStockHistory!= null && item.expense_item.toLowerCase().contains("medicine")){

              medicineStockHistory.modified_by = Utils.currentUser!.email;
              medicineStockHistory.last_modified = Utils.getTimeStamp();
              medicineStockHistory.farm_id = Utils.currentUser!.farmId;
              medicineStockHistory.sync_status = SyncStatus.DELETED;

              MedicineStockFB medicineStockFB = MedicineStockFB(stock: medicineStockHistory);
              medicineStockFB.modified_by = Utils.currentUser!.email;
              medicineStockFB.last_modified = Utils.getTimeStamp();
              medicineStockFB.farm_id = Utils.currentUser!.farmId;
              medicineStockFB.sync_id = medicineStockHistory.sync_id;
              medicineStockFB.sync_status = SyncStatus.DELETED;

              medicineStockFB.transaction = item;

              await FireBaseUtils.updateMedicineStock(medicineStockFB);

              print("MEDICINE DELETED");

            }else if(vaccineStockHistory!= null && item.expense_item.toLowerCase().contains("vaccine")){

              vaccineStockHistory.modified_by = Utils.currentUser!.email;
              vaccineStockHistory.last_modified = Utils.getTimeStamp();
              vaccineStockHistory.farm_id = Utils.currentUser!.farmId;
              vaccineStockHistory.sync_status = SyncStatus.DELETED;

              VaccineStockFB vaccineStockFB = VaccineStockFB(stock: vaccineStockHistory);
              vaccineStockFB.modified_by = Utils.currentUser!.email;
              vaccineStockFB.last_modified = Utils.getTimeStamp();
              vaccineStockFB.farm_id = Utils.currentUser!.farmId;
              vaccineStockFB.sync_id = vaccineStockHistory.sync_id;
              vaccineStockFB.sync_status = SyncStatus.DELETED;

              vaccineStockFB.transaction = item;

              await FireBaseUtils.updateVaccineStock(vaccineStockFB);

              print("VACCINE DELETED");

            }else if(feedStockHistory!= null && item.expense_item.toLowerCase().contains("feed")){
              feedStockHistory.modified_by = Utils.currentUser!.email;
              feedStockHistory.last_modified = Utils.getTimeStamp();
              feedStockHistory.farm_id = Utils.currentUser!.farmId;
              feedStockHistory.sync_status = SyncStatus.DELETED;

              FeedStockFB feedStockFB = FeedStockFB(stock: feedStockHistory);
              feedStockFB.modified_by = Utils.currentUser!.email;
              feedStockFB.last_modified = Utils.getTimeStamp();
              feedStockFB.farm_id = Utils.currentUser!.farmId;
              feedStockFB.sync_id = feedStockHistory.sync_id;
              feedStockFB.sync_status = SyncStatus.DELETED;


              feedStockFB.transaction = item;

              await FireBaseUtils.updateFeedStockHistory(feedStockFB);

              print("FEED DELETED");
            }

          }
        }
        catch(ex){
          print(ex);
        }

        DatabaseHelper.deleteItem("Transactions", selected_id!);
        transactionList.removeAt(selected_index!);


        if(medicineStockHistory!= null && item.expense_item.toLowerCase().contains("medicine")){
          await deleteMedicineStock(medicineStockHistory.id!);
        }else if(vaccineStockHistory!= null && item.expense_item.toLowerCase().contains("vaccine")){
          await deleteVaccineStock(vaccineStockHistory.id!);
        }else if(feedStockHistory!= null && item.expense_item.toLowerCase().contains("feed")){
          await DatabaseHelper.deleteFeedStock(feedStockHistory.id!);
        }

        Utils.showToast("DONE");
        Navigator.pop(context);
        setState(() {

        });


      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Text("RU_SURE_STOCK_DELETE".tr()),
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


  Future<int?> deleteVaccineStock(int id) async{

    Database? _database = await DatabaseHelper.instance.database;
    return await _database?.delete(
      'VaccineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );

  }

  Future<int?> deleteMedicineStock(int id) async{

    Database? _database = await DatabaseHelper.instance.database;
    return await _database?.delete(
      'MedicineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );
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
        TransactionItem item = transactionList.elementAt(selected_index!);
        item.f_sync_id = getFlockSyncID(item.f_id!);

        EggTransaction? eggTransaction = await DatabaseHelper.getEggsByTransactionItemId(selected_id!);

        if(eggTransaction!= null){
          Eggs? eggs = await DatabaseHelper.getSingleEggsByID(eggTransaction.eggItemId);
          DatabaseHelper.deleteItem("Eggs", eggTransaction.eggItemId);
          DatabaseHelper.deleteByEggItemId(eggTransaction.eggItemId);

          try {
            if (Utils.isMultiUSer &&
                Utils.hasFeaturePermission("delete_transaction")) {
              EggRecord eggRecord = EggRecord(eggs: eggs!);
              eggRecord.transaction = item;
              eggRecord.sync_id = eggs.sync_id;
              eggRecord.sync_status = SyncStatus.DELETED;
              eggRecord.farm_id = Utils.currentUser!.farmId;
              eggRecord.last_modified = Utils.getTimeStamp();

              await FireBaseUtils.deleteEggRecord(eggRecord);
            }
          }
          catch(ex){
            print(ex);
          }

        }else{

          try {
            if (Utils.isMultiUSer && Utils.hasFeaturePermission("delete_transaction")) {

              FinanceItem financeItem = FinanceItem(transaction: item);
              financeItem.sync_id = item.sync_id;
              financeItem.sync_status = SyncStatus.DELETED;
              financeItem.farm_id = Utils.currentUser!.farmId;
              financeItem.last_modified = Utils.getTimeStamp();

              await FireBaseUtils.deleteFinanceRecord(financeItem);
            }
          }
          catch(ex){
            print(ex);
          }
        }

        DatabaseHelper.deleteItem("Transactions", selected_id!);
        transactionList.removeAt(selected_index!);
        Utils.showToast("DONE");
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

  String sortSelected = "DESC"; // Default label
  String sortOption = "Date (New)";
  void openSortDialog(BuildContext context, Function(String) onSortSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sort By".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              ListTile(
                title: Text("Date (New)".tr()),
                onTap: () {
                  onSortSelected("date_desc");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Date (Old)".tr()),
                onTap: () {
                  onSortSelected("date_asc");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


}

