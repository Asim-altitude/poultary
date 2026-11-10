import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_birds.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/view_transaction.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/transaction_item.dart';
import 'multiuser/model/birds_modification.dart';
import 'multiuser/model/financeItem.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class AddReduceFlockScreen extends StatefulWidget {

  AddReduceFlockScreen({Key? key}) : super(key: key);

  @override
  _AddReduceFlockScreen createState() => _AddReduceFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _AddReduceFlockScreen extends State<AddReduceFlockScreen> with SingleTickerProviderStateMixin, RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.BIRDS || event == FireBaseUtils.FLOCKS) {
        getData(date_filter_name);
      }
    }
    catch(ex){
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

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }
    _purposeselectedValue = Utils.selected_flock==null? _purposeList[0] : Utils.selected_flock!.f_name;

    f_id = getFlockID();
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    addNewColumn();

    getData(date_filter_name);

  }

  void addNewColumn() async{
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

    AnalyticsUtil.logScreenView(screenName: "add_reduce_flock");
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

  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

  int selected = 1;
  int f_id = -1;

  bool no_colection = true;
  List<Flock_Detail> list = [];
  List<String> flock_name = [];

  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFlockDetails();
    egg_total = list.length;

    setState(() {

    });

  }

  int egg_total = 0;

  // UI-only: which cards are expanded (keyed by record id)
  final Set<int> _expandedIds = {};

  String applied_filter_name = "All Additions/Reductions";

  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Container(
            height: 65,
            width: widthScreen,
            child: Row(
              children: [
                /// Add Birds Button
                Expanded(
                  child: InkWell(
                    onTap: () => addNewCollection(),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 55,
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade700, Colors.green.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_sharp, color: Colors.white, size: 28),
                          SizedBox(width: 6),
                          Text(
                            'ADD_BIRDS'.tr(),
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Reduce Birds Button
                Expanded(
                  child: InkWell(
                    onTap: () => reduceCollection(),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 55,
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.red.shade600, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle_outline, color: Colors.red.shade600, size: 28),
                          SizedBox(width: 6),
                          Text(
                            'REDUCE_BIRDS'.tr(),
                            style: TextStyle(color: Colors.red.shade600, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                        // ── Dropdowns (unchanged logic) ──
                        Center(
                          child: Container(
                            padding: EdgeInsets.only(top: 2),
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height: 55,
                                    child: _buildDropdownField(
                                      "Select Item",
                                      _purposeList,
                                      _purposeselectedValue,
                                          (String? newValue) {
                                        _purposeselectedValue = newValue!;
                                        getFlockID();
                                        getFilteredTransactions(str_date, end_date);
                                      },
                                      width: double.infinity,
                                      height: 45,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 55,
                                    child: _buildDropdownField(
                                      "Select Item",
                                      filterList,
                                      date_filter_name,
                                          (String? newValue) {
                                        setState(() {
                                          date_filter_name = newValue!;
                                          getData(date_filter_name);
                                        });
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
                                      buildFilterButton('Addition', 2, Colors.green),
                                      buildFilterButton('Reduction', 3, Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "${list.length} ${'records'.tr()}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (list.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) => _buildFlockCard(index),
                        childCount: list.length,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Utils.getCustomEmptyMessage("assets/add_reduce_.png", "NO_BIRDS_ADD_REDUCE"),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],),),),);
  }

  // ═══════════════ UI HELPERS (redesign – display only) ═══════════════

  int _cardKey(int index) => list[index].f_detail_id ?? -(index + 1);

  Widget _buildSummaryCard() {
    int added = 0, reduced = 0;
    for (final d in list) {
      if (d.item_type == 'Reduction') {
        reduced += d.item_count;
      } else {
        added += d.item_count;
      }
    }
    final int net = added - reduced;
    final nf = NumberFormat.decimalPattern();
    final String periodLabel = date_filter_name == 'DATE_RANGE'
        ? '$str_date  →  $end_date'
        : date_filter_name.tr();
    final Color netColor = net < 0 ? Colors.red.shade700 : (net > 0 ? Colors.green.shade700 : Colors.black87);

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
                  "Flock Movement".tr().toUpperCase(),
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
              Text(
                "${net > 0 ? '+' : (net < 0 ? '−' : '')}${nf.format(net.abs())}",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: netColor, height: 1.1),
              ),
              SizedBox(width: 8),
              Text("Birds".tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _summaryTile("Addition".tr(), "+${nf.format(added)}", Colors.green.shade700, Colors.green.withOpacity(0.08)),
              SizedBox(width: 10),
              _summaryTile("Reduction".tr(), "−${nf.format(reduced)}", Colors.red.shade700, Colors.red.withOpacity(0.07)),
            ],
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _detailCell(String label, String value) {
    final double cellWidth = (widthScreen - 20 - 24 - 12 - 50) / 2;
    return SizedBox(
      width: cellWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFlockCard(int index) {
    final Flock_Detail item = list[index];
    final bool hasTransaction = item.transaction_id != "-1";
    final bool isReduction = item.item_type == 'Reduction';
    final Color accent = isReduction ? Colors.red.shade700 : Colors.green.shade700;
    final int key = _cardKey(index);
    final bool expanded = _expandedIds.contains(key);
    final nf = NumberFormat.decimalPattern();
    final String reasonText = isReduction ? item.reason.toString().tr() : item.acqusition_type.toString().tr();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    child: Icon(isReduction ? Icons.remove : Icons.add, color: accent, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utils.getFormattedDate(item.acqusition_date.toString()),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "${item.f_name} · $reasonText",
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
                        "${isReduction ? '−' : '+'}${nf.format(item.item_count)}",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: accent),
                      ),
                      Text("BIRDS".tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
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
                      _detailCell("Flock".tr(), item.f_name),
                      _detailCell("Type".tr(), item.item_type.tr()),
                      _detailCell(isReduction ? "Reason".tr() : "Source".tr(), reasonText),
                      _detailCell("Date".tr(), Utils.getFormattedDate(item.acqusition_date.toString())),
                    ],
                  ),
                  if (item.short_note.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notes, size: 18, color: Colors.black54),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.short_note,
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
                    children: [
                      if (hasTransaction)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              selected_id = item.f_detail_id;
                              selected_index = index;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewCompleteTransaction(
                                    transaction_id: item.transaction_id,
                                    isTransaction: false,
                                    flock_detail_id: '$selected_id',
                                  ),
                                ),
                              );
                              getData(date_filter_name);
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.visibility, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    "View Details".tr(),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Spacer(),
                      if (Utils.isMultiUSer) ...[
                        SizedBox(width: 8),
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
                      ],
                      if (!hasTransaction) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            selected_id = item.f_detail_id;
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

  Future<void> addNewCollection() async{

    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_birds"))
    {
      Utils.showMissingPermissionDialog(context, "add_birds");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: true,flock_detail: null)),
    );

    getData(date_filter_name);
    ;
  }

  Future<void> reduceCollection() async {

    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_birds"))
    {
      Utils.showMissingPermissionDialog(context, "add_birds");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: false,flock_detail: null)),
    );

    getData(date_filter_name);
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
          setState(() {
            _purposeselectedValue = newValue!;

            Utils.SELECTED_FLOCK = _purposeselectedValue;
            Utils.SELECTED_FLOCK_ID = getFlockID();
            getFilteredTransactions(str_date, end_date);

          });
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
            title: Text("DATE_FILTER".tr()),
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

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    list = await DatabaseHelper.getFilteredFlockDetailsWithSort(f_id,filter_name,st,end,sortSelected);


    setState(() {

    });

  }


  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Today ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY" + " ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "This Month ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_MONTH'+ " ("+str_date+"-"+end_date+")";

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST3_MONTHS"+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST6_MONTHS"+" ("+str_date+"-"+end_date+")";
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
      pdf_formatted_date_filter = 'THIS_YEAR'+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_YEAR' +" ("+str_date+"-"+end_date+")";

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'ALL_TIME';
    }else if (filter == 'DATE_RANGE'){
      index = 9;
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


  int getFlockID() {

    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }


  //RECORD DELETEION AND PDF

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
        ), PopupMenuItem(
          value: 1,
          child: Text(
            list.elementAt(selected_index!).transaction_id!= "-1" ? "VIEW_RECORD".tr() : "DELETE_RECORD".tr(),
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
        if(value == 2){

          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_birds"))
          {
            Utils.showMissingPermissionDialog(context, "edit_birds");
            return;
          }

          if(list.elementAt(selected_index!).item_type == "Addition") {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: true,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }else{
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: false,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }
        }
        else if(value == 1)
        {
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_birds"))
          {
            Utils.showMissingPermissionDialog(context, "delete_birds");
            return;
          }

          if(list.elementAt(selected_index!).transaction_id != "-1")
          {
            // View Complete Record

            print(selected_index);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  ViewCompleteTransaction(transaction_id: list.elementAt(selected_index!).transaction_id, isTransaction: false, flock_detail_id: '$selected_id',)),
            );

            getData(date_filter_name);
          }
          else
          {
            showAlertDialog(context);
          }

        }else {
          print(value);
        }
      }
    });
  }

  showCautionDialog(BuildContext context) {

    // set up the buttons

    Widget continueButton = TextButton(
      child: Text("VIEW_INFO".tr()),
      onPressed:  () async {

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("INFO".tr()),
      content: Text("MULTIPLE_OPERATIONS".tr()),
      actions: [
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
        if(list.elementAt(selected_index!).f_id != -1) {

          if(list.elementAt(selected_index!).transaction_id != "-1"){
            if(list.elementAt(selected_index!).transaction_id.contains(","))
            {
              /*Flock flock = await DatabaseHelper
                    .getSingleFlock(list.elementAt(selected_index!).f_id);
                int active_birds = */

            }else{

              await DatabaseHelper.deleteItem("Transactions", int.parse(list
                  .elementAt(selected_index!).transaction_id));

              int birds_to_delete = list
                  .elementAt(selected_index!)
                  .item_count;
              Flock? flock = await DatabaseHelper
                  .getSingleFlock(list
                  .elementAt(selected_index!)
                  .f_id);
              int current_birds = flock!.active_bird_count!;

              if (list
                  .elementAt(selected_index!)
                  .item_type == "Addition")
                current_birds = current_birds - birds_to_delete;
              else
                current_birds = current_birds + birds_to_delete;

              await DatabaseHelper.updateFlockBirds(
                  current_birds, list
                  .elementAt(selected_index!)
                  .f_id);

              if(Utils.isMultiUSer){
                Flock? flock = await DatabaseHelper.getSingleFlock(list
                    .elementAt(selected_index!)
                    .f_id);
                flock!.active_bird_count = current_birds;
                await FireBaseUtils.updateFlock(flock);

                list.elementAt(selected_index!).f_sync_id = getFlockSyncID(list
                    .elementAt(selected_index!).f_id);
                list.elementAt(selected_index!).sync_status = SyncStatus.DELETED;
                BirdsModification modification = BirdsModification(flockDetail: list
                    .elementAt(selected_index!));

                modification.last_modified = Utils.getTimeStamp();
                modification.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                modification.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                TransactionItem? transaction_item = await DatabaseHelper.getSingleTransaction(list
                    .elementAt(selected_index!).transaction_id);

                modification.transaction = transaction_item!;

                await FireBaseUtils.deleteBirdsDetails(modification);

              }
            }
          }else {
            int birds_to_delete = list
                .elementAt(selected_index!)
                .item_count;
            Flock? flock = await DatabaseHelper
                .getSingleFlock(list
                .elementAt(selected_index!)
                .f_id);
            int current_birds = flock!.active_bird_count!;

            if (list
                .elementAt(selected_index!)
                .item_type == "Addition")
              current_birds = current_birds - birds_to_delete;
            else
              current_birds = current_birds + birds_to_delete;

            await DatabaseHelper.updateFlockBirds(
                current_birds, list
                .elementAt(selected_index!)
                .f_id);

            if(Utils.isMultiUSer){
              Flock? flock = await DatabaseHelper.getSingleFlock(list
                  .elementAt(selected_index!)
                  .f_id);
              flock!.active_bird_count = current_birds;
              await FireBaseUtils.updateFlock(flock);

              list.elementAt(selected_index!).f_sync_id = getFlockSyncID(list
                  .elementAt(selected_index!).f_id);
              list.elementAt(selected_index!).sync_status = SyncStatus.DELETED;
              BirdsModification modification = BirdsModification(flockDetail: list
                  .elementAt(selected_index!));

              modification.last_modified = Utils.getTimeStamp();
              modification.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
              modification.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

              await FireBaseUtils.deleteBirdsDetails(modification);

            }
          }

        }
        DatabaseHelper.deleteItemWithFlockID("Flock_Detail", selected_id!);
        list.removeAt(selected_index!);
        Utils.showToast("RECORD_DELETED");
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