import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/model/egg_income.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/multiuser/model/egg_record.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'farm_routine/farm_routine_screen.dart';
import 'farm_routine/routine_prefs.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';
import 'package:url_launcher/url_launcher.dart';

import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';


class EggCollectionScreen extends StatefulWidget {
  const EggCollectionScreen({Key? key}) : super(key: key);

  @override
  _EggCollectionScreen createState() => _EggCollectionScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _EggCollectionScreen extends State<EggCollectionScreen> with SingleTickerProviderStateMixin, RefreshMixin{

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.EGGS ) {
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

    trayEnabled = await SessionManager.getBool(SessionManager.tray_enabled);
    traySize = await SessionManager.getInt(SessionManager.tray_size);

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    if(Utils.selected_flock != null)
      _purposeselectedValue = Utils.selected_flock!.f_name;
    else {
      _purposeselectedValue = _purposeList[0];
      Utils.selected_flock = flocks[0];
    }

    f_id = getFlockID();
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);
    getData(date_filter_name);

  }


  @override
  void initState() {
    super.initState();
    getFilters();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
    AnalyticsUtil.logScreenView(screenName: "eggs_screen");
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
  List<Eggs> eggs = [], tempList = [];
  List<String> flock_name = [];

  bool trayEnabled = false;
  int traySize = 30;

  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    tempList = await DatabaseHelper.getEggsCollections();
    eggs = tempList.reversed.toList();
    egg_total = eggs.length;

    setState(() {

    });

  }

  int egg_total = 0;

  // UI-only: which cards are expanded (keyed by record id)
  final Set<int> _expandedIds = {};

  String applied_filter_name = "ALL_COLLECTION";

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
          height: 60,
          width: widthScreen,
          child: Row(
            children: [
              /// 🟢 Collect Button
              Expanded(
                child: InkWell(
                  onTap: addNewCollection,
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.white.withOpacity(0.3),
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'COLLECT'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// 🔴 Reduce Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    reduceCollection(null);
                  },
                  /* onTap: () {
                    showModifyCollectedEggsDialog(context);
                  },*/
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.white.withOpacity(0.3),
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.red.shade600, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red.shade600, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'REDUCE'.tr(),
                          style: TextStyle(color: Colors.red.shade600, fontSize: 16, fontWeight: FontWeight.bold),
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
                                      buildFilterButton('Collection', 2, Colors.green),
                                      buildFilterButton('Reduction', 3, Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "${eggs.length} ${'records'.tr()}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (eggs.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) => _buildEggCard(index),
                        childCount: eggs.length,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Utils.getCustomEmptyMessage("assets/egg_collect.png", "No Egg Collections Added"),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],),),),);
  }

  // ═══════════════ UI HELPERS (redesign – display only) ═══════════════

  int _cardKey(int index) => eggs[index].id ?? -(index + 1);

  /// Reads "84.28%" from the auto-generated note (e.g. "production is 84.28%")
  String? _extractProduction(String? note) {
    if (note == null) return null;
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(note);
    return m == null ? null : '${m.group(1)}%';
  }

  Widget _buildSummaryCard() {
    int collected = 0, reduced = 0, good = 0, bad = 0;
    final Set<String> days = {};
    for (final e in eggs) {
      if (e.isCollection == 1) {
        collected += e.total_eggs;
        good += e.good_eggs;
        bad += e.bad_eggs;
        days.add(e.date ?? '');
      } else {
        reduced += e.total_eggs;
      }
    }
    final int net = collected - reduced;
    final int avgPerDay = days.isEmpty ? 0 : (collected / days.length).round();
    final double goodFraction = (good + bad) == 0 ? 1.0 : good / (good + bad);
    final nf = NumberFormat.decimalPattern();
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
                  "TOTAL".tr()+" "+"eggs collected".tr().toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.blueGrey),
                ),
              ),
              SizedBox(width: 8),
              Text(
                periodLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                nf.format(collected),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.1),
              ),
              SizedBox(width: 8),
              Text("Eggs".tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          if (trayEnabled)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                "${Utils.getEggTrays(collected, traySize)} ${'trays'.tr()} + ${Utils.getRemaining(collected, traySize)} ${'Eggs'.tr()}",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goodFraction,
              minHeight: 8,
              backgroundColor: Colors.orange.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${nf.format(good)} ${'Good Eggs'.tr()}",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
              Text("${nf.format(bad)} ${'Bad Eggs'.tr()}",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
          SizedBox(height: 12),
          Row(
            children: [
              _summaryStat("Reduced".tr(), nf.format(reduced), Colors.red.shade700),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.25)),
              _summaryStat("Net".tr(), nf.format(net), Colors.black87),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.25)),
              _summaryStat("Avg / day".tr(), nf.format(avgPerDay), Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _detailCell(String label, String value, {Color? valueColor}) {
    final double cellWidth = (widthScreen - 20 - 24 - 12) / 2;
    return SizedBox(
      width: cellWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildEggCard(int index) {
    final Eggs e = eggs[index];
    final bool isCollect = e.isCollection == 1;
    final Color accent = isCollect ? Colors.green.shade700 : Colors.red.shade700;
    final int key = _cardKey(index);
    final bool expanded = _expandedIds.contains(key);
    final String? production = isCollect ? _extractProduction(e.short_note) : null;
    final String note = e.short_note ?? '';
    final String reason = e.reduction_reason ?? '';
    final nf = NumberFormat.decimalPattern();
    final String subtitle = isCollect
        ? "${e.f_name ?? ''} · ${'Collected'.tr()}"
        : "${e.f_name ?? ''} · ${reason.isNotEmpty ? reason.tr() : 'Reduced'.tr()}";

    final double? amountVal =
    double.tryParse((e.sale_amount ?? '').replaceAll(',', ''));
    final bool hasAmount = !isCollect && amountVal != null && amountVal > 0;
    final String amountText = hasAmount ? nf.format(amountVal) : '';

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
                    child: Icon(isCollect ? Icons.add : Icons.remove, color: accent, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utils.getFormattedDate(e.date.toString()),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
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
                        "${isCollect ? '' : '-'}${nf.format(e.total_eggs)}",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isCollect ? Colors.black87 : Colors.red.shade700),
                      ),
                      if (hasAmount)
                        Container(
                          margin: EdgeInsets.only(top: 3),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                           Utils.currency+amountText, // add your currency symbol here if you have one, e.g. "${Utils.currencySymbol} $amountText"
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      /*if (production != null)
                        Container(
                          margin: EdgeInsets.only(top: 3),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(production,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
                        ),*/
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
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      if (trayEnabled)
                        _detailCell("Good trays".tr(), "${Utils.getEggTrays(e.good_eggs, traySize)}", valueColor: Colors.green.shade700),
                      if (trayEnabled)
                        _detailCell("Bad trays".tr(), "${Utils.getEggTrays(e.bad_eggs, traySize)}", valueColor: Colors.orange.shade800),
                      _detailCell("Good Eggs".tr(),
                          trayEnabled ? "${Utils.getRemaining(e.good_eggs, traySize)}" : "${e.good_eggs}",
                          valueColor: Colors.green.shade700),
                      _detailCell("Bad Eggs".tr(),
                          trayEnabled ? "${Utils.getRemaining(e.bad_eggs, traySize)}" : "${e.bad_eggs}",
                          valueColor: Colors.orange.shade800),
                      _detailCell("Color".tr(), (e.egg_color ?? '').tr()),
                    ],
                  ),
                  if (!isCollect && reason.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Utils.getThemeColorBlue(),
                              ),
                            ),
                          ),
                          /*if (hasAmount)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4),
                                Text(
                                  Utils.currency+amountText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),*/
                        ],
                      ),
                    ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(note,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      if (isCollect)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showHatchBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(0, 44),
                              backgroundColor: Colors.orange.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.egg, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Hatch These Eggs".tr(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ],
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
                            Eggs item = e;
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
                      SizedBox(width: 8),
                      GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          selected_id = e.id;
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


  void _showHatchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align details to left
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Centered App Icon & Title
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/hatching_icon.png', // Ensure the file is in assets folder
                      height: 80,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Egg Hatching".tr(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),
              // Left-aligned details
              Text(
                "hatch_msg".tr(),
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("✅ Multi-batch Egg Tracking".tr(), style: TextStyle(fontWeight: FontWeight.w700),),
                  Text("✅ Track Remaining Days".tr(),  style: TextStyle(fontWeight: FontWeight.w700)),
                  Text("✅ Customizable Notifications".tr(),  style: TextStyle(fontWeight: FontWeight.w700)),
                  Text("✅ Manage Egg Incubator".tr(),  style: TextStyle(fontWeight: FontWeight.w700)),
                  Text("✅ View Hatch History".tr(),  style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: 20),

              // Buttons (Right-aligned)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CANCEL".tr(),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openHatchingApp();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      backgroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      "Continue to Hatching App".tr(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  void _openHatchingApp() async {
    Uri _urlAppLink = Uri.parse('');
    if (Platform.isAndroid) {
      _urlAppLink = Uri.parse('https://play.google.com/store/apps/details?id=com.zaheer.hatchingbird');
      final Uri appUrl = Uri.parse("market://details?id=com.zaheer.hatchingbird");

      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl);
      } else {
        await launchUrl(_urlAppLink);
      }
    } else if (Platform.isIOS) {
      _urlAppLink = Uri.parse('https://apps.apple.com/us/app/egg-hatching-manager/id1637798439');
    }

    if (await canLaunchUrl(_urlAppLink)) {
      await launchUrl(_urlAppLink,mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $_urlAppLink';
    }
  }

  /// Function to Build Filter Buttons (compact segmented style - logic unchanged)
  Widget buildFilterButton(String label, int index, Color color) {
    bool isSelected = selected == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if(label=="Collection")
              filter_name = "1";
            else if(label=="Reduction")
              filter_name ="0";
            else
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

  final _prefs = RoutinePrefs.instance;
  static const _routineOrder = ['Egg', 'Feed', 'Health'];
  Map<String, bool>    _statuses   = {for (final t in _routineOrder) t: false};
  Future<void> addNewCollection() async {
    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_eggs"))
    {
      Utils.showMissingPermissionDialog(context, "add_eggs");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewEggCollection(isCollection: true,eggs: null, reason: null,)),
    );


    try{
      bool isFirst = true;//await DatabaseHelper.isFirstRecord("Eggs");
      if(isFirst) {
        _statuses  = await _prefs.loadAllStatuses(_routineOrder);
        bool complete = _statuses["Egg"] ?? false;
        if(!complete) {
          _showEggRoutineSuggestionDialog();
        }
      }
    }
    catch(ex){
      print(ex);
    }

    print("Flock ID $result");
    getData(date_filter_name);


    //checkReminderScheduling(result.toString());

  }

  Future<void> reduceCollection(String? reason) async{
    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_eggs"))
    {
      Utils.showMissingPermissionDialog(context, "add_eggs");
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewEggCollection(isCollection: false, eggs: null, reason: reason,)),
    );
    print(result);
    getData(date_filter_name);
  }

  void _showEggRoutineSuggestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🥚", style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),

              Text(
                "egg_routine_dialog_title".tr(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                "egg_routine_dialog_body".tr(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ✅ Setup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmRoutineScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    "egg_routine_dialog_setup".tr(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⏳ Do Later Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    "egg_routine_dialog_later".tr(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 💡 Hint Text
              Text(
                "egg_routine_dialog_hint".tr(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  /*void showModifyCollectedEggsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make the background transparent
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modify Collected Eggs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Option 1 - Sell Eggs
              ListTile(
                leading: Icon(
                  Icons.attach_money,
                  color: Utils.getThemeColorBlue(),
                ),
                title: Text('Egg Sale'.tr()),
                onTap: () async {
                  // Handle Sell Eggs
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewIncome(
                        transactionItem: null,
                        selectedExpenseType: null,
                        selectedIncomeType: "Egg Sale",
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),

              // Option 2 - Personal Use
              ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: Colors.pink,
                ),
                title: Text('PERSONAL_USE'.tr()),
                onTap: () {
                  reduceCollection('PERSONAL_USE');
                  // Handle Personal Use

                },
              ),

              // Option 3 - Lost
              ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
                title: Text('LOST'.tr()),
                onTap: () {
                  reduceCollection('LOST');
                  // Handle Lost

                },
              ),

              // Option 4 - Other (Custom Option)
              ListTile(
                leading: Icon(
                  Icons.more_horiz,
                  color: Colors.blue,
                ),
                title: Text('OTHER'.tr()),
                onTap: () {
                  reduceCollection(null);
                  // Handle Custom Option

                },
              ),
            ],
          ),
        );
      },
    );
  }
*/


  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];


  int isCollection = 1;
  int selected = 1;
  int f_id = -1;


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
          getFlockID();
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
            title: Text('Date Filter'),
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

    eggs = await DatabaseHelper.getFilteredEggsWithSort(f_id, filter_name, st, end, sortSelected);
    //eggs = tempList.reversed.toList();

    setState(() {

    });

  }

  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
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
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            "DELETE_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        )
      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 2){
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_eggs"))
          {
            Utils.showMissingPermissionDialog(context, "edit_eggs");
            return;
          }

          if(eggs.elementAt(selected_index!).isCollection == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  NewEggCollection(isCollection: true,eggs: eggs.elementAt(selected_index!), reason: null,)),
            );

            getFilteredTransactions(str_date, end_date);
            //getEggCollectionList();
          }else{
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  NewEggCollection(isCollection: false,eggs: eggs.elementAt(selected_index!), reason: null,)),
            );
            //getEggCollectionList();
            getFilteredTransactions(str_date, end_date);
          }
        }
        else if(value == 1){
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_eggs"))
          {
            Utils.showMissingPermissionDialog(context, "delete_eggs");
            return;
          }

          showAlertDialog(context);
        }
        else
        {
          print(value);
        }
      }
    });
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

        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_eggs")){

          EggTransaction? eggTransaction = await DatabaseHelper.getByEggItemId(eggs.elementAt(selected_index!).id!);
          if(eggTransaction!= null) {
            TransactionItem? transactionItem = await DatabaseHelper.getSingleTransaction(
                eggTransaction.transactionId.toString());

            transactionItem!.sync_status = SyncStatus.DELETED;
            EggRecord eggRecord = EggRecord(eggs: eggs.elementAt(selected_index!), transaction: transactionItem,
              sync_id: eggs.elementAt(selected_index!).sync_id,
              sync_status: SyncStatus.DELETED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
            );

            eggRecord.sync_status = SyncStatus.DELETED;
            eggRecord.eggs.sync_status = SyncStatus.DELETED;


            await FireBaseUtils.updateEggRecord(eggRecord);
          }else{
            EggRecord eggRecord = EggRecord(eggs: eggs.elementAt(selected_index!),
              sync_id: eggs.elementAt(selected_index!).sync_id,
              sync_status: SyncStatus.DELETED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',);
            eggRecord.sync_status = SyncStatus.DELETED;
            eggRecord.eggs.sync_status = SyncStatus.DELETED;


            await FireBaseUtils.updateEggRecord(eggRecord);
          }

        }

        EggTransaction? eggTransaction = await DatabaseHelper.getByEggItemId(selected_id!);
        if(eggTransaction!= null) {
          DatabaseHelper.deleteItem("Transactions", eggTransaction.transactionId);
          DatabaseHelper.deleteByEggItemId(selected_id!);
        }
        DatabaseHelper.deleteItem("Eggs", selected_id!);
        eggs.removeAt(selected_index!);
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

/*Future<void> checkReminderScheduling(String flockId) async {

    // Check if reminder is already set up
    final reminderService = ReminderSchedulerService();
    final hasReminder = await reminderService.hasActiveReminder(
      flockId,
      'egg_collection',
    );

    if (!hasReminder) {
      // Show reminder setup dialog
      await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReminderFrequencySetup(
        reminderType: ReminderType.eggCollection,
        onComplete: (frequency, times, customDays) async {
          await _scheduleReminders(frequency, times, customDays,flockId);
        },
        onSkip: () {
          // User skipped
        },
      ),
      );
    }
  }


  Future<void> _scheduleReminders(
      ReminderFrequency frequency,
      List<TimeOfDay>? times,
      List<int>? customDays,
      String flockId
      ) async
  {
    if (times == null || times.isEmpty) return;

    final reminderService = ReminderSchedulerService();

    try {
      // Initialize the notification service
      await reminderService.initialize();

      // Request notification permissions
      final hasPermission = await reminderService.requestPermissions();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required for reminders. Please enable it in settings.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Convert ReminderFrequency enum to string
      final frequencyString = _frequencyToString(frequency);

      // Schedule the reminders
      await reminderService.scheduleReminders(
        flockId: flockId, // Your flock ID
        reminderType: 'egg_collection', // or 'feed_consumption'
        frequency: frequencyString,
        times: times,
        customDays: customDays,
      );

      print('✅ Reminders scheduled successfully!');

    } catch (e) {
      print('❌ Error scheduling reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reminder: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

// Helper function to convert enum to string
  String _frequencyToString(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'daily';
      case ReminderFrequency.twiceDaily:
        return 'twice_daily';
      case ReminderFrequency.threeTimesWeek:
        return 'three_times_week';
      case ReminderFrequency.fourTimesWeek:
        return 'four_times_week';
      case ReminderFrequency.weekly:
        return 'weekly';
      case ReminderFrequency.custom:
        return 'custom';
      default:
        return 'daily';
    }
  }*/

}