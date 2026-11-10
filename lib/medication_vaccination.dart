import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_vac_med.dart';
import 'package:poultary/multiuser/model/multi_health_record.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'add_multi_vac_med.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/med_vac_item.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/RefreshMixin.dart';

class MedicationVaccinationScreen extends StatefulWidget {
  const MedicationVaccinationScreen({Key? key}) : super(key: key);

  @override
  _MedicationVaccinationScreen createState() => _MedicationVaccinationScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _MedicationVaccinationScreen extends State<MedicationVaccinationScreen> with SingleTickerProviderStateMixin, RefreshMixin{

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.HEALTH) {
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
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,

      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _heightBanner = 60;
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _heightBanner = 0;
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }
  int _other_filter = 2;
  void getFilters() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++) {
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

  bool isVaccine = false;
  @override
  void initState() {
    super.initState();

    if (Utils.vaccine_medicine.toLowerCase().contains("medication")) {
      isVaccine = false;
    }else{
      isVaccine = true;
    }

    getFilters();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

    AnalyticsUtil.logScreenView(screenName: "all_health_screen");
  }

  bool no_colection = true;
  List<Vaccination_Medication> vac_med_list = [], tempList = [];
  List<String> flock_name = [];
  void getvaccMedList() async {

    await DatabaseHelper.instance.database;

    tempList = await DatabaseHelper.getAllVaccinationMedications();
    vac_med_list = tempList.reversed.toList();
    feed_total = vac_med_list.length;

    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = "Health";

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
          height: 65, // Slightly increased height for better touch area
          width: widthScreen,
          padding: EdgeInsets.symmetric(horizontal: 10), // Added padding for better spacing
          child: Row(
            children: [
              /// 🟢 Vaccination Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_health"))
                    {
                      Utils.showMissingPermissionDialog(context, "add_health");
                      return;
                    }

                    Utils.vaccine_medicine = "Vaccination";
                    // addNewVacMad();

                    showTreatmentTypeBottomSheet(context, onSingleMedicineTap: () {
                      addNewVacMad();
                    }, onMultiMedicineTap: () {
                      addMultiNewVacMad();
                    });

                  },
                  borderRadius: BorderRadius.circular(10), // Rounded ripple effect
                  child: Container(
                    height: 55, // Increased height for a more premium feel
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade900.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 28), // Slightly smaller icon
                        SizedBox(width: 6), // Space between icon and text
                        Text(
                          'Vaccination'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10), // Space between buttons

              /// 🔹 Medication Button
              Expanded(
                child: InkWell(

                  onTap: () {

                    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_health"))
                    {
                      Utils.showMissingPermissionDialog(context, "add_health");
                      return;
                    }

                    Utils.vaccine_medicine = "Medication";
                    // addNewVacMad();

                    showTreatmentTypeBottomSheet(context, onSingleMedicineTap: () {
                      addNewVacMad();
                    }, onMultiMedicineTap: () {
                      addMultiNewVacMad();
                    });
                  },

                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'Medication'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
      body:SafeArea(
        top: false,
        child: Container(
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
                                          setState(() {
                                            _purposeselectedValue = newValue!;
                                            getFlockID();
                                            getFilteredTransactions(str_date, end_date);
                                          });
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
                                        buildFilterButton('Medication', 2, Colors.green),
                                        buildFilterButton('Vaccination', 3, Colors.red),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "${vac_med_list.length} ${'records'.tr()}",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (vac_med_list.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) => _buildHealthCard(index),
                          childCount: vac_med_list.length,
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Utils.getCustomEmptyMessage("assets/p_health.png", "No vaccination/medication added"),
                      ),

                    SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],)),),);
  }

  // ═══════════════ UI HELPERS (redesign – display only) ═══════════════

  int _cardKey(int index) => vac_med_list[index].id ?? -(index + 1);

  Widget _buildSummaryCard() {
    int vaccinations = 0, medications = 0;
    DateTime? lastDate;
    String? lastRaw;
    for (final v in vac_med_list) {
      if (v.type == 'Vaccination') {
        vaccinations++;
      } else {
        medications++;
      }
      final d = DateTime.tryParse(v.date ?? '');
      if (d != null && (lastDate == null || d.isAfter(lastDate))) {
        lastDate = d;
        lastRaw = v.date;
      }
    }
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
                  "Health Records".tr().toUpperCase(),
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
                "${vac_med_list.length}",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.1),
              ),
              SizedBox(width: 8),
              Text("Treatments".tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
          SizedBox(height: 12),
          Row(
            children: [
              _summaryStat("Vaccination".tr(), "$vaccinations", Colors.red.shade700, false),
              _summaryStat("Medication".tr(), "$medications", Colors.green.shade700, true),
              _summaryStat("Last treated".tr(),
                  lastRaw == null ? "-" : Utils.getFormattedDate(lastRaw), Colors.black87, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color valueColor, bool leftBorder) {
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
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

  Widget _buildHealthCard(int index) {
    final Vaccination_Medication item = vac_med_list[index];
    final bool isVaccine = item.type == 'Vaccination';
    final bool isMulti = item.medicine == "";
    final Color accent = isVaccine ? Colors.red.shade700 : Colors.green.shade700;
    final int key = _cardKey(index);
    final bool expanded = _expandedIds.contains(key);
    final String title = isMulti ? "Multi-Medicine Treatment".tr() : "${item.medicine!.tr()}";
    final String flockName = (item.f_name ?? '').tr();
    final String dateText = Utils.getFormattedDate(item.date.toString());
    final String note = item.short_note ?? '';

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
                    child: Icon(isVaccine ? Icons.vaccines : Icons.medication, color: accent, size: 21),
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
                          "$flockName · $dateText",
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (isVaccine ? 'Vaccination' : 'Medication').tr(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${item.bird_count ?? 0} Birds'.tr(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
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
                      _detailCell("Flock".tr(), flockName),
                      _detailCell("Birds".tr(), '${item.bird_count ?? 0}'),
                      if (!isMulti)
                        _detailCell("Dose".tr(), "${item.quantity} ${item.unit}".tr()),
                      if (!isMulti)
                        _detailCell("Disease".tr(), item.disease ?? ''),
                      _detailCell(isVaccine ? 'Vac by: '.tr() : 'Med by: '.tr(), item.doctor_name ?? ''),
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
                  if (isMulti)
                    viewAllTreatmentsButton(() {
                      showMedicineDetailsBottomSheet(item.id!);
                    }),
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

  Widget viewAllTreatmentsButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 10),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Utils.getThemeColorBlue(), // Your app theme color
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.10),
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined,
                color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              "View All Treatments".tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMedicineDetailsBottomSheet(int usageId) async {
    final items = await DatabaseHelper.getMedicineItemsByUsage(usageId);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SizedBox(height: 12),
                Text(
                  "Treatment Medicine Details".tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 14),

                items.isEmpty
                    ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No Medicines Found".tr(),
                      style: TextStyle(fontSize: 15)),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final med = items[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Utils.getThemeColorBlue(), width: 0.7),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.medication_rounded,
                              size: 26, color: Utils.getThemeColorBlue()),
                          SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.medicineName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Disease".tr()+": ${med.diseaseName}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Qty + Unit
                          Text(
                            "${med.quantity} ${med.unit}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
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

  void showTreatmentTypeBottomSheet(
      BuildContext context, {
        required VoidCallback onSingleMedicineTap,
        required VoidCallback onMultiMedicineTap,
      })
  {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined, color: Colors.blue,),
                  title:  Text("Single Medicine Treatment".tr(), style: TextStyle(fontWeight: FontWeight.w600),),
                  subtitle:  Text("Record a treatment with one medicine only".tr()),
                  onTap: () {
                    Navigator.pop(context);
                    onSingleMedicineTap();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.medication_liquid_outlined, color: Colors.blue,),
                  title:  Text("Multi-Medicine Treatment".tr(), style: TextStyle(fontWeight: FontWeight.w600),),
                  subtitle:  Text("Record treatment with multiple medicines".tr()),
                  onTap: () {
                    Navigator.pop(context);
                    onMultiMedicineTap();
                  },
                ),
              ],
            ),
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

  Future<void> addMultiNewVacMad() async {
    var str = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewMultiVaccineMedicine()),
    );

    getFilteredTransactions(str_date, end_date);
  }
  Future<void> addNewVacMad() async {
    var str = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewVaccineMedicine()),
    );

    getFilteredTransactions(str_date, end_date);
  }

  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];


  int isCollection = 1;
  int selected = 1;

  // UI-only: which cards are expanded (keyed by record id)
  final Set<int> _expandedIds = {};
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

    tempList = await DatabaseHelper.getFilteredMedicationWithSort(f_id,filter_name,st,end,sortSelected);
    vac_med_list = tempList.reversed.toList();
    setState(() {

    });

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
        ),


      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 2){

          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_health"))
          {
            Utils.showMissingPermissionDialog(context, "edit_health");
            return;
          }

          if(vac_med_list.elementAt(selected_index!).type == 'Medication') {
            Utils.vaccine_medicine = "Medication";
            if(vac_med_list.elementAt(selected_index!).disease==""){
              var str = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NewMultiVaccineMedicine(
                          vaccination_medication: vac_med_list.elementAt(
                              selected_index!),)),
              );
            }else {
              var str = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NewVaccineMedicine(
                          vaccination_medication: vac_med_list.elementAt(
                              selected_index!),)),
              );
            }

            getFilteredTransactions(str_date, end_date);
          }else{
            Utils.vaccine_medicine = "Vaccination";
            if(vac_med_list.elementAt(selected_index!).disease==""){
              var str = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NewMultiVaccineMedicine(
                          vaccination_medication: vac_med_list.elementAt(
                              selected_index!),)),
              );
            }else {
              var str = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NewVaccineMedicine(
                          vaccination_medication: vac_med_list.elementAt(
                              selected_index!),)),
              );
            }
            getFilteredTransactions(str_date, end_date);
          }
        }
        else if(value == 1){
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_health"))
          {
            Utils.showMissingPermissionDialog(context, "delete_health");
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
        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_health")){
          if(vac_med_list.elementAt(selected_index!).medicine== ""){
            MultiHealthRecord multiHealthRecord = MultiHealthRecord();
            Vaccination_Medication vaccination_medication = vac_med_list.elementAt(selected_index!);
            vaccination_medication.f_sync_id = getFlockSyncID(vaccination_medication.f_id!);
            multiHealthRecord.record = vaccination_medication;
            multiHealthRecord.usageItems = await DatabaseHelper.getMedicineItemsByUsage(vac_med_list.elementAt(selected_index!).id!);
            await FireBaseUtils.deleteMultiHealthRecord(multiHealthRecord);
          }else {
            await FireBaseUtils.deleteHealthRecord(vac_med_list.elementAt(selected_index!));
          }
        }

        DatabaseHelper.deleteItem("Vaccination_Medication", selected_id!);
        vac_med_list.removeAt(selected_index!);
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

  String? getFlockSyncID(int f_id) {

    String? selected_id = "unknown";
    for(int i=0;i<flocks.length;i++){
      if(f_id == flocks.elementAt(i).f_id){
        selected_id = flocks.elementAt(i).sync_id;
        break;
      }
    }

    return selected_id;
  }

  String sortSelected = "DESC"; // Default label
  String sortOption = "Date (new)";
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