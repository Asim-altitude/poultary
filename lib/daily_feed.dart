import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/feed_report_screen.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auto_feed_management.dart';
import 'database/databse_helper.dart';
import 'farm_routine/farm_routine_screen.dart';
import 'farm_routine/routine_prefs.dart';
import 'model/flock.dart';
import 'multiuser/utils/RefreshMixin.dart';

class DailyFeedScreen extends StatefulWidget {
  const DailyFeedScreen({Key? key}) : super(key: key);

  @override
  _DailyFeedScreen createState() => _DailyFeedScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _DailyFeedScreen extends State<DailyFeedScreen> with SingleTickerProviderStateMixin, RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.FEEDING) {
        getData(date_filter_name);
      }
    }
    catch(ex){
      print(ex);
    }
  }

  double widthScreen = 0;
  double heightScreen = 0;

  bool isAutoFeedEnabled = false;
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

    if(Utils.selected_flock != null)
      _purposeselectedValue = Utils.selected_flock!.f_name;
    else {
      _purposeselectedValue = _purposeList[0];
      Utils.selected_flock = flocks[0];
    }
    f_id = getFlockID();

    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

    getData(date_filter_name);

  }

  Future<void> _addManualFeedingRecord() async {
    // Check if automatic feed management is turned on
    if (isAutoFeedEnabled) {
      // Show bottom dialog asking for confirmation
      bool? shouldProceed = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Automatic Feed Enabled".tr(), style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,color: Utils.getThemeColorBlue()),),
                SizedBox(height: 20,),
                Text(
                  'auto_feed_msg'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false); // User cancels
                      },
                      child: Text("CANCEL".tr(), style: TextStyle(color: Colors.grey),),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        addNewCollection();// User proceeds
                      },
                      child: Text("Still Proceed".tr()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      // If user cancels, return early
      if (shouldProceed == false) {
        return;
      }
    }else{
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>  NewFeeding()),
      );

      try{
        bool isFirst = true;//await DatabaseHelper.isFirstRecord("Feeding");
        if(isFirst) {
          _statuses  = await _prefs.loadAllStatuses(_routineOrder);
          bool complete = _statuses["Feed"] ?? false;
          if(!complete) {
            _showFeedRoutineSuggestionDialog();
          }
        }
      }
      catch(ex){
        print(ex);
      }

      getFilteredTransactions(str_date, end_date);
    }

    // Proceed with adding the manual feeding record
    // Your logic for adding manual feeding record here
    print("Adding manual feeding record...");

  }


  @override
  void initState() {
    super.initState();
    getFilters();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

    AnalyticsUtil.logScreenView(screenName: "daily_feed_screen");
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
  List<Feeding> feedings = [], tempFeed = [];
  List<String> flock_name = [];
  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    tempFeed = await DatabaseHelper.getAllFeedings();
    feedings = tempFeed.reversed.toList();
    feed_total = feedings.length;

    setState(() {

    });

  }

  int feed_total = 0;

  // UI-only: which cards are expanded (keyed by record id)
  final Set<int> _expandedIds = {};

  String applied_filter_name = "All Feedings";

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
        child: InkWell(
            onTap: () {
              if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_feed"))
              {
                Utils.showMissingPermissionDialog(context, "add_feed");
                return;
              }

              _addManualFeedingRecord();
            },
            child: Container(
              height: 50,
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Utils.getThemeColorBlue(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'NEW_FEEDING'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )

        ),
      ),
      body:SafeArea(
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
                        // ── Dropdowns + hidden auto-feed entry (original code, unchanged) ──
                        Center(
                          child: Container(
                            padding: EdgeInsets.only(top: 10),
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
                                        getFlockID();
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
                        ),    /*Container(
                height: 50,
                width: widthScreen ,
                margin: EdgeInsets.only(left: 25,right: 25,bottom: 5),
                child: Row(children: [

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 1;
                        filter_name ='All';
                        getFilteredTransactions(str_date, end_date);
                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected == 1 ? Utils.getThemeColorBlue() : Colors.transparent,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)
                              ,bottomLeft: Radius.circular(10)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('All', style: TextStyle(
                            color: selected==1 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 2;
                        isCollection = 1;
                        filter_name ='Medication';
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==2 ? Utils.getThemeColorBlue() : Colors.transparent,


                          border: Border.all(
                            color: Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('Medication', style: TextStyle(
                            color: selected==2 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selected = 3;
                        filter_name ='Vaccination';
                        isCollection = 0;
                        getFilteredTransactions(str_date, end_date);

                      },
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected==3 ? Utils.getThemeColorBlue() : Colors.transparent,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(10)
                              ,bottomRight: Radius.circular(10)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        child: Text('Vaccination', style: TextStyle(
                            color: selected==3 ? Colors.white : Utils.getThemeColorBlue(), fontSize: 14),),
                      ),
                    ),
                  ),
                ],),
              )*/
                        Visibility(
                          visible: false,
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>  AutomaticFeedManagementScreen()),
                              );

                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

                              setState(() {

                              });

                            },
                            child: Container(height: 60,
                              width: widthScreen,
                              margin: EdgeInsets.all(10.0),
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(0, 1), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text('Automatic Feed Management'.tr(), style: TextStyle(color: Utils.getThemeColorBlue(), fontSize: 15, fontWeight: FontWeight.w600),)),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Utils.getThemeColorBlue(), size: 30,)
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── NEW: Summary card ──
                        InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FeedReportsScreen()),
                              );
                            },
                            child: _buildSummaryCard()),

                        // ── NEW: list header ──
                        Padding(
                          padding: EdgeInsets.fromLTRB(14, 8, 14, 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Feeding History".tr(),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                              Text("${feedings.length} ${'records'.tr()}",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (feedings.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) => _buildFeedCard(index),
                        childCount: feedings.length,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Utils.getCustomEmptyMessage("assets/pfeed.png", "NO_FFEDING"),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],),),),);
  }

  // ═══════════════ UI HELPERS (redesign – display only) ═══════════════

  int _cardKey(int index) => feedings[index].id ?? -(index + 1);

  String _fmtQty(double v) => NumberFormat('#,##0.##').format(v);

  Widget _buildSummaryCard() {
    double total = 0;
    int count = feedings.length;
    DateTime? lastFed;
    String? lastFedRaw;
    for (final f in feedings) {
      total += double.tryParse((f.quantity ?? '').trim()) ?? 0;
      final d = DateTime.tryParse(f.date ?? '');
      if (d != null && (lastFed == null || d.isAfter(lastFed))) {
        lastFed = d;
        lastFedRaw = f.date;
      }
    }
    final double avg = count == 0 ? 0 : total / count;
    final String unit = Utils.selected_unit.tr();
    final String periodLabel = date_filter_name == 'DATE_RANGE'
        ? '$str_date  →  $end_date'
        : date_filter_name.tr();

    return Container(
      margin: EdgeInsets.fromLTRB(10, 10, 10, 4),
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
                  "Feed Consumed".tr().toUpperCase(),
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
                _fmtQty(total),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.1),
              ),
              SizedBox(width: 8),
              Text(unit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
          SizedBox(height: 12),
          Row(
            children: [
             /* _summaryStat("Feedings".tr(), "$count", false),*/
              _summaryStat("Avg / feeding".tr(), "${_fmtQty(avg)} $unit", true),
              _summaryStat("Last fed".tr(),
                  lastFedRaw == null ? "-" : Utils.getFormattedDate(lastFedRaw), true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, bool leftBorder) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: leftBorder ? 12 : 0),
        decoration: leftBorder
            ? BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.25))))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
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

  Widget _buildFeedCard(int index) {
    final Feeding item = feedings[index];
    final int key = _cardKey(index);
    final bool expanded = _expandedIds.contains(key);
    final String feedName = (item.feed_name ?? '').tr();
    final String flockName = item.f_name.tr();
    final String note = item.short_note ?? '';
    final String dateText = Utils.getFormattedDate(item.date.toString());
    final String qty = "${item.quantity} ${Utils.selected_unit.tr()}";

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
                      color: Colors.orange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.restaurant, color: Colors.orange.shade800, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "$flockName · $dateText",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    qty,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
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
                      _detailCell("Flock".tr(), flockName),
                      _detailCell("Feed".tr(), feedName),
                      _detailCell("Consumption".tr(), qty),
                      _detailCell("Date".tr(), dateText),
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

  final _prefs = RoutinePrefs.instance;
  static const _routineOrder = ['Egg', 'Feed', 'Health'];
  Map<String, bool>    _statuses   = {for (final t in _routineOrder) t: false};

  Future<void> addNewCollection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewFeeding()),
    );

    try{
      bool isFirst = await DatabaseHelper.isFirstRecord("Feeding");
      if(isFirst) {
        _statuses  = await _prefs.loadAllStatuses(_routineOrder);
        bool complete = _statuses["Feed"] ?? false;
        if(!complete) {
          _showFeedRoutineSuggestionDialog();
        }
      }
    }
    catch(ex){
      print(ex);
    }

    getFilteredTransactions(str_date, end_date);
  }


  void _showFeedRoutineSuggestionDialog() {
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
              const Text("🌾", style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),

              Text(
                "feed_routine_dialog_title".tr(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                "feed_routine_dialog_body".tr(),
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
                    Navigator.pop(context); // close dialog first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmRoutineScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "feed_routine_dialog_setup".tr(),
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
                    side: const BorderSide(color: Colors.green, width: 2),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "feed_routine_dialog_later".tr(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 💡 Hint
              Text(
                "feed_routine_dialog_hint".tr(),
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
          setState(() {
            _purposeselectedValue = newValue!;
            getFlockID();
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

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;

    feedings = await DatabaseHelper.getFilteredFeedingWithSort(f_id,filter_name,st,end,sortSelected);
    //feedings = tempFeed.reversed.toList();
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

  int? selected_id = 0;
  int? selected_index = 0;
  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      color: Colors.white,
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
        ),


      ],
      elevation: 8.0,
    ).then((value) async{
      if (value != null) {
        if(value == 2){
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_feed"))
          {
            Utils.showMissingPermissionDialog(context, "edit_feed");
            return;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewFeeding(feeding: feedings.elementAt(selected_index!),)),
          );

          getFilteredTransactions(str_date, end_date);
        }
        else if(value == 1){
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_feed"))
          {
            Utils.showMissingPermissionDialog(context, "delete_feed");
            return;
          }

          showAlertDialog(context);
        }else {
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
        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_feed")){
          await FireBaseUtils.deleteFeedingRecord(feedings.elementAt(selected_index!));
        }

        DatabaseHelper.deleteItem("Feeding", selected_id!);
        feedings.removeAt(selected_index!);
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