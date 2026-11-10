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
import 'package:poultary/model/sub_category_item.dart';
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

    transactionList = _applyPaymentFilters(tempList.reversed.toList());
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

  // UI-only: which cards are expanded (keyed by record id)
  final Set<int> _expandedIds = {};
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
                  openSortFilterChooser(context);
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
                          _hasActiveFilter() ? "Filtered".tr() : sortOption.tr(),
                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 22),
                          if (_hasActiveFilter())
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                      color: Colors.green.shade600,
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
                      color: Colors.red.shade600,
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
            if(_isBannerAdReady)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                    height: 60.0,
                    width: Utils.WIDTH_SCREEN,
                    child: AdWidget(ad: _bannerAd)
                ),
              ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // ── Dropdowns (original code, unchanged) ──
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

                        // ── NEW: Summary card ──
                        _buildSummaryCard(),

                        // ── Compact filter (same handlers) ──
                        Container(
                          margin: EdgeInsets.fromLTRB(10, 6, 10, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      buildFilterButton('All', 1, Colors.blue),
                                      buildFilterButton('Income', 2, Colors.green),
                                      buildFilterButton('Expense', 3, Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "${transactionList.length} ${'records'.tr()}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (transactionList.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) => _buildTxnCard(index),
                        childCount: transactionList.length,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Utils.getCustomEmptyMessage("assets/pfinance.png", "No Income/Expense added"),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],),),),);
  }

  /// Function to Build Filter Buttons (compact segmented style - logic unchanged)
  Widget buildFilterButton(String label, int index, Color color) {
    bool isSelected = selected == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            filter_name = label;
            selected = index;
            getFilteredTransactions(str_date, end_date);
          });
        },
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
                : [],
          ),
          child: Text(
            label.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? color : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════ UI HELPERS (redesign – display only) ═══════════════

  int _cardKey(int index) => transactionList[index].id ?? -(index + 1);

  double _amt(TransactionItem t) => double.tryParse(t.amount.toString()) ?? 0;

  String _fmtMoney(double v) => NumberFormat('#,##0.##').format(v);

  Widget _buildSummaryCard() {
    double income = 0, expense = 0, pending = 0;
    for (final t in transactionList) {
      final double a = _amt(t);
      if (t.type.toLowerCase() == 'income') {
        income += a;
      } else {
        expense += a;
      }
      if (t.payment_status.toLowerCase() != 'cleared') pending += a;
    }
    final double net = income - expense;
    final Color netColor = net < 0 ? Colors.red.shade700 : (net > 0 ? Colors.green.shade700 : Colors.black87);
    final String periodLabel = date_filter_name == 'DATE_RANGE'
        ? '$str_date  →  $end_date'
        : date_filter_name.tr();

    return Container(
      margin: EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Net Balance".tr().toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.blueGrey),
                ),
              ),
              SizedBox(width: 8),
              Text(periodLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  "${net < 0 ? '−' : (net > 0 ? '+' : '')}${_fmtMoney(net.abs())}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: netColor, height: 1.1),
                ),
              ),
              SizedBox(width: 8),
              Text(Utils.currency, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _summaryTile("Income".tr(), _fmtMoney(income), Colors.green.shade700, Colors.green.withOpacity(0.08)),
              SizedBox(width: 10),
              _summaryTile("Expense".tr(), _fmtMoney(expense), Colors.red.shade700, Colors.red.withOpacity(0.07)),
            ],
          ),
          if (pending > 0)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: Colors.orange.shade800),
                  SizedBox(width: 6),
                  Text(
                    "${'Pending'.tr()}: ${_fmtMoney(pending)} ${Utils.currency}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _detailCell(String label, String value) {
    final double cellWidth = (widthScreen - 24 - 24 - 12 - 50) / 2;
    return SizedBox(
      width: cellWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTxnCard(int index) {
    final TransactionItem item = transactionList[index];
    final bool isIncome = item.type.toLowerCase() == 'income';
    final Color accent = isIncome ? Colors.green.shade700 : Colors.red.shade700;
    final int key = _cardKey(index);
    final bool expanded = _expandedIds.contains(key);
    final bool cleared = item.payment_status.toLowerCase() == 'cleared';
    final String title = isIncome ? item.sale_item.tr() : item.expense_item.tr();
    final String dateText = Utils.getFormattedDate(item.date.toString());
    final String note = item.short_note ?? '';
    final double unitPrice = item.unitPrice ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          /// ── Collapsed header (always visible) ──
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedIds.remove(key);
                } else {
                  _expandedIds.add(key);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: accent, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "${item.sold_purchased_from} · $dateText",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isIncome ? '+' : '−'}${_fmtMoney(_amt(item))} ${Utils.currency}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                      ),
                      SizedBox(height: 3),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cleared ? Colors.green.withOpacity(0.14) : Colors.orange.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.payment_status.toUpperCase().tr(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cleared ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),

          /// ── Expanded details ──
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
              padding: EdgeInsets.fromLTRB(62, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _detailCell("Flock".tr(), item.f_name.tr()),
                      _detailCell("ITEMS".tr(), "${item.how_many ?? 0}"),
                      _detailCell("UNIT_PRICE".tr(), "${unitPrice.toStringAsFixed(2)} ${Utils.currency}"),
                      _detailCell("Payment".tr(), item.payment_method.tr()),
                      _detailCell(isIncome ? 'Sold To'.tr() : 'Paid To'.tr(), item.sold_purchased_from),
                      _detailCell("On".tr(), dateText),
                    ],
                  ),
                  if (note.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (Utils.isMultiUSer) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            String updated_at = item.last_modified == null
                                ? "Unknown".tr()
                                : DateFormat("dd MMM yyyy hh:mm a").format(item.last_modified!);

                            String updated_by = item.modified_by == null || item.modified_by!.isEmpty
                                ? "System".tr()
                                : item.modified_by!;

                            Utils.showSyncInfo(context, updated_at, updated_by);
                          },
                          child: Container(
                            height: 44,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                                SizedBox(width: 4),
                                Text("Sync Info", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          selected_id = item.id;
                          selected_index = index;
                          showMemberMenu(details.globalPosition);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.more_vert, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                : SizedBox(width: double.infinity),
          ),
        ],
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
          value: 3,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "VIEW_INFO".tr(),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "EDIT_RECORD".tr(),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
        if (transactionList.elementAt(selected_index!).flock_update_id == "-1")
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "DELETE_RECORD".tr(),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
          ),
      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if (value == 3) {
          // View Info
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionInfoScreen(
                transaction: transactionList.elementAt(selected_index!),
              ),
            ),
          );
        } else if(value == 2) {
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
          // Delete (only reachable when flock_update_id == "-1")
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
        } else {
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

  String? selectedTransactionName; // null = All
  List<String> getDistinctTransactionNames(List<TransactionItem> list) {
    return list
        .map((e) => e.expense_item ?? e.sale_item) // pick whichever exists
        .where((name) => name != null && name.trim().isNotEmpty)
        .map((name) => name!.trim())
        .toSet()
        .toList()
      ..sort(); // optional: alphabetical order
  }

  // ── Payment Method filter: null = All, "Cash" | "Online" | "Other"
  String? filterPaymentMethod;
  // ── Payment Type filter: null = All, "Cleared" | "Uncleared" | "Reconciled"
  String? filterPaymentType;

  String? filterPerson;

  bool _hasActiveFilter() =>
      filterPaymentMethod != null || filterPaymentType != null;

  List<TransactionItem> _applyPaymentFilters(List<TransactionItem> list) {
    return list.where((t) {

      bool methodOk = filterPaymentMethod == null ||
          t.payment_method.toLowerCase() == filterPaymentMethod!.toLowerCase();

      bool typeOk = filterPaymentType == null ||
          t.payment_status.toLowerCase() == filterPaymentType!.toLowerCase();

      /* bool personOk = filterPerson == null ||
          t.sold_purchased_from.toLowerCase() == filterPerson!.toLowerCase();
*/
      return methodOk && typeOk;

    }).toList();
  }

  /// Shows a small bottom sheet asking the user to pick Sort or Filter
  void openSortFilterChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.sort, color: Colors.blue.shade700),
                ),
                title: Text("Sort".tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text(sortOption.tr(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  openUpdatedSortDialog(
                    context,
                    getDistinctTransactionNames(transactionList),
                        (selectedSort, transactionName) {
                      setState(() {
                        sortSelected = selectedSort;
                        sortOption =
                        selectedSort == "DESC" ? "Date (New)" : "Date (Old)";
                        selectedTransactionName = transactionName;
                      });
                      getFilteredTransactions(str_date, end_date);
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hasActiveFilter()
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.filter_list,
                      color: _hasActiveFilter()
                          ? Colors.orange.shade700
                          : Colors.green.shade700),
                ),
                title: Text("Filter".tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text(
                  _hasActiveFilter() ? "Filters active".tr() : "All transactions".tr(),
                  style: TextStyle(
                    color: _hasActiveFilter()
                        ? Colors.orange.shade700
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  openFilterDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> methodOptions = [];

  void buildPaymentMethods(List<SubItem> payMethods) {
    methodOptions = [];

    /// Default ALL option
    methodOptions.add({
      'label': 'All',
      'icon': Icons.select_all,
      'color': Colors.blue,
    });

    /// Icons to rotate
    List<IconData> icons = [
      Icons.money,
      Icons.account_balance,
      Icons.phone_android,
      Icons.credit_card,
      Icons.wallet,
      Icons.payments,
    ];

    /// Colors to rotate
    List<Color> colors = [
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.teal,
      Colors.red,
    ];

    for (int i = 0; i < payMethods.length; i++) {
      final method = payMethods[i];

      methodOptions.add({
        'label': method.name,
        'icon': icons[i % icons.length],
        'color': colors[i % colors.length],
      });
    }
  }
  /// Filter bottom sheet: Payment Method + Payment Type
  void openFilterDialog(BuildContext context) async {

    List<SubItem> pay_methods = await DatabaseHelper.getSubCategoryList(5);
    // List<String> persons = await DatabaseHelper.getUniquePersons();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        String? tempMethod = filterPaymentMethod;
        String? tempType = filterPaymentType;
        String? tempPerson = "All";

        buildPaymentMethods(pay_methods);

        final List<Map<String, dynamic>> typeOptions = [
          {'label': 'All', 'icon': Icons.select_all, 'color': Colors.blue},
          {'label': 'CLEARED', 'icon': Icons.check_circle_outline, 'color': Colors.green},
          {'label': 'UNCLEAR', 'icon': Icons.pending_outlined, 'color': Colors.orange},
          {'label': 'RECONCILED', 'icon': Icons.verified_outlined, 'color': Colors.teal},
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter".tr(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (tempMethod != null || tempType != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempMethod = null;
                              tempType = null;
                            });
                          },
                          child: Text("Clear All".tr(),
                              style: TextStyle(color: Colors.red.shade400)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Payment Method
                  Text("Payment Method".tr(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: methodOptions.map((opt) {
                      final label = opt['label'] as String;
                      final isSelected = label == 'All'
                          ? tempMethod == null
                          : tempMethod == label;
                      final color = opt['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempMethod = label == 'All' ? null : label;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                            isSelected ? color : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(label.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // ── Payment Type
                  Text("Payment Type".tr(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: typeOptions.map((opt) {
                      final label = opt['label'] as String;
                      final isSelected = label == 'All'
                          ? tempType == null
                          : tempType == label;
                      final color = opt['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempType = label == 'All' ? null : label;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                            isSelected ? color : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(label.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Text("SOLD_TO".tr(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  /*  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...["All", ...persons].map((name) {
                        final isSelected = name == "All"
                            ? tempPerson == null
                            : tempPerson == name;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempPerson = name == "All" ? null : name;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),

                  const SizedBox(height: 24),*/

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          filterPaymentMethod = tempMethod;
                          filterPaymentType = tempType;
                          filterPerson = tempPerson;
                        });
                        Navigator.pop(ctx);
                        // Re-apply filters on the already-fetched list
                        setState(() {
                          transactionList =
                              _applyPaymentFilters(tempList.reversed.toList());
                        });
                      },
                      child: Text("Apply".tr(),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
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

  void openUpdatedSortDialog(
      BuildContext context,
      List<String> transactionNames,
      Function(String sort, String? transactionName) onApply,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        String tempSort = sortSelected;
        String? tempTransaction = selectedTransactionName;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  /// SORT SECTION
                  Text("Sort By".tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  RadioListTile<String>(
                    value: "DESC",
                    groupValue: tempSort,
                    title: Text("Date (New)".tr()),
                    onChanged: (value) {
                      setState(() => tempSort = value!);
                    },
                  ),

                  RadioListTile<String>(
                    value: "ASC",
                    groupValue: tempSort,
                    title: Text("Date (Old)".tr()),
                    onChanged: (value) {
                      setState(() => tempSort = value!);
                    },
                  ),

                  const Divider(height: 30),

                  /// TRANSACTION FILTER SECTION
                  Text("Transaction Type".tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: transactionNames.length + 1,
                      itemBuilder: (context, index) {
                        String name =
                        index == 0 ? "All" : transactionNames[index - 1];

                        bool isSelected = name == "All"
                            ? tempTransaction == null
                            : tempTransaction == name;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: Colors.green.shade600,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color:
                              isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) {
                              setState(() {
                                tempTransaction =
                                name == "All" ? null : name;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// APPLY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        onApply(tempSort, tempTransaction);
                        Navigator.pop(context);
                      },
                      child: Text("Apply".tr(),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Info Screen
// ─────────────────────────────────────────────────────────────────────────────
class TransactionInfoScreen extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionInfoScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type?.toLowerCase() == 'income';
    final Color typeColor = isIncome ? Colors.green : Colors.red;
    final Color typeBg = isIncome ? Colors.green.shade50 : Colors.red.shade50;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            backgroundColor: Colors.blue,
            elevation: 8,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Transaction Info".tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isIncome
                              ? (transaction.sale_item ?? '').tr()
                              : (transaction.expense_item ?? '').tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Utils.getThemeColorBlue(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          (transaction.type ?? '').tr(),
                          style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isIncome ? Icons.trending_up : Icons.trending_down,
                        color: typeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${transaction.amount ?? 0} ${Utils.currency}",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: typeColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Summary ───────────────────────────────────────────────────
            _sectionTitle("Summary".tr()),
            _infoCard([
              _infoRow(Icons.calendar_today, "Date".tr(),
                  Utils.getFormattedDate(transaction.date.toString())),
              _divider(),
              _infoRow(Icons.store, "Flock / Farm".tr(),
                  (transaction.f_name ?? '').tr()),
              _divider(),
              _infoRow(
                isIncome ? Icons.person_outline : Icons.person_outline,
                isIncome ? "Sold To".tr() : "Paid To".tr(),
                transaction.sold_purchased_from ?? '-',
              ),
              _divider(),
              _infoRow(Icons.production_quantity_limits, "Quantity".tr(),
                  "${transaction.how_many ?? 0} ${"ITEMS".tr()}"),
              _divider(),
              _infoRow(
                Icons.price_change_outlined,
                "Unit Price".tr(),
                "${(transaction.unitPrice ?? 0).toStringAsFixed(2)} ${Utils.currency}",
              ),
            ]),

            const SizedBox(height: 14),

            // ── Payment Details ───────────────────────────────────────────
            _sectionTitle("Payment Details".tr()),
            _infoCard([
              _infoRow(
                Icons.payment,
                "Payment Method".tr(),
                (transaction.payment_method?.isEmpty ?? true)
                    ? '-'
                    : transaction.payment_method!.tr(),
              ),
              _divider(),
              _infoRow(
                Icons.verified_outlined,
                "Payment Status".tr(),
                (transaction.payment_status?.isEmpty ?? true)
                    ? '-'
                    : transaction.payment_status!.toUpperCase().tr(),
                valueColor:
                transaction.payment_status?.toLowerCase() == 'cleared'
                    ? Colors.green
                    : Colors.orange,
              ),
            ]),

            const SizedBox(height: 14),

            // ── Notes ─────────────────────────────────────────────────────
            _sectionTitle("Notes".tr()),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (transaction.short_note?.isEmpty ?? true)
                          ? 'NO_NOTES'.tr()
                          : transaction.short_note!,
                      style: TextStyle(
                        fontSize: 14,
                        color: (transaction.short_note?.isEmpty ?? true)
                            ? Colors.grey
                            : Colors.black87,
                        fontStyle: (transaction.short_note?.isEmpty ?? true)
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      title,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 0.5),
    ),
  );

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.10),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade100);

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      );
}