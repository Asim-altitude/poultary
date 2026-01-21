import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/egg_report_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'model/egg_income.dart';
import 'model/egg_item.dart';
import 'model/eggs_chart_data.dart';
import 'model/flock.dart';
import 'model/transaction_item.dart';

class EggsReportsScreen extends StatefulWidget {
  const EggsReportsScreen({Key? key}) : super(key: key);

  @override
  _EggsReportsScreen createState() => _EggsReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _EggsReportsScreen extends State<EggsReportsScreen> with SingleTickerProviderStateMixin {

  double widthScreen = 0;
  double heightScreen = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;
  @override
  void dispose() {
    super.dispose();
    try{
      _bannerAd.dispose();
      _myNativeAd.dispose();

    }catch(ex){

    }
  }

  int _reports_filter = 2;

  void getFilters() async {
    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }

  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    try {
      //date_filter_name = Utils.applied_filter;
      _zoomPanBehavior = ZoomPanBehavior(
          enableDoubleTapZooming: true,
          enablePinching: true,
          // Enables the selection zooming
          enableSelectionZooming: true,
          selectionRectBorderColor: Colors.red,
          selectionRectBorderWidth: 1,
          selectionRectColor: Colors.grey
      );
      getFilters();
      getList();
    }
    catch (ex) {
      print(ex);
    }
    if(Utils.isShowAdd){
      _loadBannerAd();
      _loadNativeAds();

    }

    AnalyticsUtil.logScreenView(screenName: "egg_report_screen");
  }
  _loadNativeAds(){
    _myNativeAd = NativeAd(
      adUnitId: Utils.NativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // or medium
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => _isNativeAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed: $error');
        },
      ),
    );


    _myNativeAd.load();

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
  List<Eggs_Chart_Item> collectionList = [],
      reductionList = [];
  List<Eggs> eggs = [];
  List<String> flock_name = [];

  int egg_total = 0;


  int total_eggs_collected = 0;
  int total_eggs_reduced = 0;
  int total_eggs = 0;
  int remainingEggs = 0;

  void clearValues() {
    total_eggs_collected = 0;
    total_eggs_reduced = 0;
    total_eggs = 0;
    eggs = [];
  }

  List<TransactionItem> eggSales = [];
  void getAllData() async {
    await DatabaseHelper.instance.database;

    clearValues();

    total_eggs_collected =
    await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);

    total_eggs_reduced =
    await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);

    remainingEggs = total_eggs_collected - total_eggs_reduced;

    eggSales = await DatabaseHelper.getEggSaleTransactionsFiltered(str_date, end_date, f_id);

    collectionList =
    await DatabaseHelper.getEggsReportData(str_date, end_date, 1,f_id);

    reductionList =
    await DatabaseHelper.getEggsReportData(str_date, end_date, 0,f_id);

    int reduced_eggs = 0;
    for(int i=0;i<eggSales.length;i++){
      TransactionItem item = eggSales[i];
     // print(item.toLocalFBJson());
      //print(item.date);
      EggTransaction? eggTransaction = await DatabaseHelper.getEggsByTransactionItemId(item.id!);
      if(eggTransaction == null) {
        reduced_eggs += int.parse(item.how_many);
        int index_e = isSameDateExists(reductionList,item.date);
        if(index_e != -1){
          reductionList[index_e].total = reductionList[index_e].total! + int.parse(item.how_many);
        }else {
          Eggs_Chart_Item eggs_chart_item = Eggs_Chart_Item(
              date: item.date, total: int.parse(item.how_many));
          reductionList.add(eggs_chart_item);
        }
      }
    }

    for (int i = 0; i < reductionList.length; i++) {
      print(reductionList.elementAt(i).date);

      reductionList
          .elementAt(i)
          .date = Utils.getFormattedDate(reductionList
          .elementAt(i)
          .date).substring(0, Utils
          .getFormattedDate(reductionList
          .elementAt(i)
          .date)
          .length - 4);
    }

    for (int j = 0; j < collectionList.length; j++) {
      collectionList
          .elementAt(j)
          .date = Utils.getFormattedDate(collectionList
          .elementAt(j)
          .date).substring(0, Utils
          .getFormattedDate(collectionList
          .elementAt(j)
          .date)
          .length - 4);
    }

    total_eggs_reduced += reduced_eggs;
    total_eggs = total_eggs_collected - total_eggs_reduced;


    getFilteredEggsCollections(str_date, end_date, reduced_eggs, eggSales);

    setState(() {

    });
  }

  List<FlockEggSummary> flockEggSummary = [];
  List<EggReductionSummary> eggReductionSummary = [];

  int good_eggs = 0,
      bad_eggs = 0;

  void getFilteredEggsCollections(String st, String end, int reduced_eggs, List<TransactionItem> eggSales) async {
    await DatabaseHelper.instance.database;

    eggs = await DatabaseHelper.getFilteredEggs(f_id, "All", st, end);

    good_eggs = eggs
        .where((item) => item.isCollection == 1)
        .fold(0, (sum, item) => sum + item.good_eggs);

    bad_eggs = eggs
        .where((item) => item.isCollection == 1)
        .fold(0, (sum, item) => sum + item.bad_eggs);

    flockEggSummary = getFlockWiseEggSummary(eggs, str_date, end_date);
    eggReductionSummary = getEggReductionSummary(eggs, str_date, end_date);

    if(reduced_eggs > 0)
      updateReductionSummary(reduced_eggs);

    /*if(eggSales.length > 0)
      updateFlockSummary(eggSales);
*/
    Utils.eggReductionSummary = eggReductionSummary;

    setState(() {

    });
  }


  @override
  Widget build(BuildContext context) {
    double safeAreaHeight = MediaQuery
        .of(context)
        .padding
        .top;
    double safeAreaHeightBottom = MediaQuery
        .of(context)
        .padding
        .bottom;
    widthScreen =
        MediaQuery
            .of(context)
            .size
            .width; // because of default padding
    heightScreen = MediaQuery
        .of(context)
        .size
        .height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery
        .of(context)
        .size
        .height - (safeAreaHeight + safeAreaHeightBottom);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "EGGS_REPORT".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),

        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        elevation: 8,
        automaticallyImplyLeading: true,
        actions: [
          if(!Platform.isIOS)

            InkWell(
              onTap: () async {
                AnalyticsUtil.logButtonClick(buttonName: "excel", screen: "eggs_report");

                Utils.setupInvoiceInitials("EGGS_REPORT".tr(), pdf_formatted_date_filter);
                await prepareListData();

                generateEggSummaryExcel(Utils.egg_report_list, Utils.eggReductionSummary!);
              },
              child: Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(right: 10),
                child: Image.asset('assets/excel_icon.png'),
              ),
            ),
          InkWell(
            onTap: () {
              AnalyticsUtil.logButtonClick(buttonName: "pdf", screen: "eggs_report");

              Utils.setupInvoiceInitials("EGGS_REPORT".tr(),
                  pdf_formatted_date_filter);
              prepareListData();

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PDFScreen(item: 1,)),
              );
            },
            child: Container(
              width: 22,
              height: 22,
              margin: EdgeInsets.only(right: 10),
              child: Image.asset('assets/pdf_icon.png'),
            ),
          )
        ],
      ),
      body: SafeArea(
        top: false,

        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
          child: Column(children: [
            Utils.showBannerAd(_bannerAd, _isBannerAdReady),
            Expanded(child: SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    /*ClipRRect(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0)),
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
                          Expanded(
                            child: Container(
                                margin: EdgeInsets.only(left: 5),
                                child: Text(
                                  "EGGS_REPORT".tr(),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                )),
                          ),
                          if(!Platform.isIOS)

                            InkWell(
                            onTap: () async {
                              Utils.setupInvoiceInitials("EGGS_REPORT".tr(), pdf_formatted_date_filter);
                              await prepareListData();

                              generateEggSummaryExcel(Utils.egg_report_list, Utils.eggReductionSummary!);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: EdgeInsets.only(right: 10),
                              child: Image.asset('assets/excel_icon.png'),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Utils.setupInvoiceInitials("EGGS_REPORT".tr(),
                                  pdf_formatted_date_filter);
                              prepareListData();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PDFScreen(item: 1,)),
                              );
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              margin: EdgeInsets.only(right: 10),
                              child: Image.asset('assets/pdf_icon.png'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),*/

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(left: 10),
                            margin: EdgeInsets.only(left: 10,right: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: getDropDownList(),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            openDatePicker();
                          },
                          borderRadius: BorderRadius.circular(8), // Adds ripple effect with rounded edges
                          child: Container(
                            height: 45,
                            margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, color: Utils.getThemeColorBlue(), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  date_filter_name.tr(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(), size: 20),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),

                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Chart Section
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.all(10),
                            child: SfCartesianChart(
                              primaryXAxis: CategoryAxis(),
                              zoomPanBehavior: _zoomPanBehavior,
                              title: ChartTitle(text: date_filter_name.tr()),
                              legend: Legend(isVisible: true,
                                  position: LegendPosition.bottom),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              series: <CartesianSeries<Eggs_Chart_Item, String>>[
                                ColumnSeries(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  color: Colors.green,
                                  name: 'Collections'.tr(),
                                  dataSource: collectionList,
                                  xValueMapper: (Eggs_Chart_Item item, _) =>
                                  item.date,
                                  yValueMapper: (Eggs_Chart_Item item, _) =>
                                  item.total,
                                ),
                                ColumnSeries(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  color: Colors.red,
                                  name: 'Reductions'.tr(),
                                  dataSource: reductionList,
                                  xValueMapper: (Eggs_Chart_Item item, _) =>
                                  item.date,
                                  yValueMapper: (Eggs_Chart_Item item, _) =>
                                  item.total,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 📌 Summary Section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(
                                        "Summary & Analytics".tr(),
                                        style: TextStyle(fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Divider(),
                                  SizedBox(height: 8),


                                  Column(
                                    children: [
                                      SummaryRow(
                                        title: 'Total Collected'.tr(),
                                        value: '$total_eggs_collected',
                                        icon: Icons.egg,
                                        color: Colors.green,
                                        percentage: "100%",
                                        isBold: true,
                                      ),

                                      SummaryRow(
                                        title: 'Good Eggs'.tr(),
                                        value: '$good_eggs',
                                        icon: Icons.check_circle,
                                        color: Colors.blue,
                                        percentage: percent(good_eggs, total_eggs_collected),
                                      ),

                                      SummaryRow(
                                        title: 'Bad Eggs'.tr(),
                                        value: '$bad_eggs',
                                        icon: Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        percentage: percent(bad_eggs, total_eggs_collected),
                                      ),

                                      const Divider(),

                                      SummaryRow(
                                        title: 'Total Used'.tr(),
                                        value: '-$total_eggs_reduced',
                                        icon: Icons.remove_circle,
                                        color: Colors.red,
                                        percentage: percent(total_eggs_reduced, total_eggs_collected),
                                      ),

                                      SummaryRow(
                                        title: 'Remaining Eggs'.tr(),
                                        value: '${total_eggs_collected - total_eggs_reduced}',
                                        icon: Icons.egg_alt,
                                        color: (total_eggs_collected - total_eggs_reduced) >= 0 ? Colors.black : Colors.red,
                                        percentage: percent((total_eggs_collected - total_eggs_reduced), total_eggs_collected),
                                        isBold: true,
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 16),
                                  if (_isNativeAdLoaded && _myNativeAd != null)
                                    Container(
                                      height: 90,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: AdWidget(ad: _myNativeAd),
                                    ),


                                  Divider(),

                                  // 🐔 Flock-wise Summary Section
                                  Text(
                                    "By Flock".tr(),
                                    style: TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),

                                  // 🏷️ Flock List
                                  Column(
                                    children: flockEggSummary.map((flock) =>
                                        _buildFlockRow(flock, total_eggs_collected)).toList(),
                                  ),
                                  SizedBox(height: 8),
                                  buildEggReductionList(eggReductionSummary)
                                ],
                              ),
                            ),
                          )

                        ],
                      ),
                    )

                  ]
              ),))
          ],),),),);
  }

  String percent(num part, num total) {
    if (total <= 0) return "0%";
    return "${((part / total) * 100).toStringAsFixed(1)}%";
  }


  Widget buildEggReductionList(List<EggReductionSummary> reductionList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Egg Usage (Reductions)".tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...reductionList.map((reduction) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(Icons.remove_circle, color: Colors.red),
            title: Text(
              reduction.reason.tr(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "-${reduction.totalReduced}",
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        )),
      ],
    );
  }


  Widget _buildFlockRow(
      FlockEggSummary flock,
      int totalEggsCollected,
      ) {
    final double percent = totalEggsCollected == 0
        ? 0
        : (flock.totalEggs / totalEggsCollected);
    final int percentValue = (percent * 100).round();

    // Dynamic color
    Color progressColor;
    if (percent >= 0.7) {
      progressColor = Colors.green.shade400;
    } else if (percent >= 0.4) {
      progressColor = Colors.orange.shade400;
    } else {
      progressColor = Colors.red.shade400;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Egg Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                  ),
                  child: const Icon(Icons.egg, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),

                // Flock Name
                Expanded(
                  child: Text(
                    flock.fName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$percentValue%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Egg Stats
            Row(
              children: [
                _buildEggInfo("Good", flock.goodEggs, Colors.green),
                const SizedBox(width: 10),
                _buildEggInfo("Bad", flock.badEggs, Colors.orange),
                const SizedBox(width: 10),
                _buildEggInfo("Total", flock.totalEggs, Colors.blue),
              ],
            ),

            const SizedBox(height: 8),

            // Animated Progress Bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: percent),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // Subtitle
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$percentValue% of total collected eggs",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



// 🎨 Helper for Colored Egg Info
  Widget _buildEggInfo(String label, int count, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        SizedBox(width: 4),
        Text(
          "$label: $count",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }


  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

  void getList() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0, Flock(f_id: -1,
        f_name: 'Farm Wide'.tr(),
        bird_count: 0,
        purpose: '',
        acqusition_date: '',
        acqusition_type: '',
        notes: '',
        icon: '',
        active_bird_count: 0,
        active: 1,
        flock_new: 1));

    for (int i = 0; i < flocks.length; i++) {
      _purposeList.add(flocks
          .elementAt(i)
          .f_name);
    }

    _purposeselectedValue = _purposeList[0];

    setState(() {

    });
  }

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
            getAllData();
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


  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(
                bcontext, widthScreen - 40, widthScreen),
          );
        });
  }


  Widget setupAlertDialoadContainer(BuildContext bcontext, double width,
      double height) {
    return Container(
      height: filterList.length * 55, // Change as per your requirement
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

              Navigator.pop(bcontext);
              getData(date_filter_name);

            },
            child: ListTile(
              title: Text(filterList.elementAt(index).tr()),
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

      pdf_formatted_date_filter = 'TODAY'.tr()+" ("+Utils.getFormattedDate(str_date)+")";

      getAllData();
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";
      getAllData();
    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'THIS_MONTH'.tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'ALL_TIME';
      getAllData();
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
      date_filter_name = Utils.getFormattedDate(str_date) +" | "+Utils.getFormattedDate(end_date);
      print(str_date+" "+end_date);
      getAllData();

    }
  }

  int getFlockID() {
    for (int i = 0; i < flocks.length; i++) {
      if (_purposeselectedValue == flocks
          .elementAt(i)
          .f_name) {
        f_id = flocks
            .elementAt(i)
            .f_id;
        break;
      }
    }

    return f_id;
  }

  Future<void> prepareListData() async {
    int collected = 0,
        reduced = 0,
        reserve = 0,
        t_good_eggs,
        t_bad_eggs;

    Utils.egg_report_list.clear();
    Utils.TOTAL_EGG_COLLECTED = total_eggs_collected.toString();
    Utils.TOTAL_EGG_REDUCED = total_eggs_reduced.toString();
    Utils.EGG_RESERVE = total_eggs.toString();
    Utils.GOOD_EGGS = good_eggs.toString();
    Utils.BAD_EGGS = bad_eggs.toString();


    if (f_id == -1) {
      for (int i = 0; i < flocks.length; i++) {
        collected = await DatabaseHelper.getUniqueEggCalculations(flocks
            .elementAt(i)
            .f_id, 1, str_date, end_date);
        reduced = await DatabaseHelper.getUniqueEggCalculations(flocks
            .elementAt(i)
            .f_id, 0, str_date, end_date);

        reduced += getFromSales(flocks
            .elementAt(i)
            .f_id);

        t_good_eggs =
        await DatabaseHelper.getUniqueEggCalculationsGoodBad(flocks
            .elementAt(i)
            .f_id, 1, str_date, end_date);
        t_bad_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(flocks
            .elementAt(i)
            .f_id, 0, str_date, end_date);

        reserve = collected - reduced;

        Egg_Report_Item item = Egg_Report_Item(f_name: flocks
            .elementAt(i)
            .f_name,
            collected: collected,
            reduced: reduced,
            reserve: reserve);
        item.good_eggs = t_good_eggs;
        item.bad_eggs = t_bad_eggs;
        Utils.egg_report_list.add(item);
      }
    } else {
      collected =
      await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);
      reduced =
      await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);
      t_good_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(
          f_id, 1, str_date, end_date);
      t_bad_eggs = await DatabaseHelper.getUniqueEggCalculationsGoodBad(
          f_id, 0, str_date, end_date);

      reduced += getFromSales(f_id);

      reserve = collected - reduced;

      Flock? flock = await getSelectedFlock();

      Egg_Report_Item item = Egg_Report_Item(f_name: flock!.f_name,
          collected: collected,
          reduced: reduced,
          reserve: reserve);
      item.good_eggs = t_good_eggs;
      item.bad_eggs = t_bad_eggs;
      Utils.egg_report_list.add(item);
    }
  }


// Call this function after you have all summary values & lists
 /* Future<void> generateEggSummaryExcel(
      List<Egg_Report_Item> flockReport,
      List<EggReductionSummary> reductions) async
  {

    var excel = Excel.createExcel();

    /// ---- Sheet 1: Overall Summary ----
    Sheet summarySheet = excel['Egg Summary'];
    summarySheet.appendRow(
        [TextCellValue("Total Collected"), TextCellValue("Total Reduced"), TextCellValue("Egg Reserve"),TextCellValue("Good Eggs"), TextCellValue("Bad Eggs")]);
    summarySheet.appendRow(
        [TextCellValue(Utils.TOTAL_EGG_COLLECTED), TextCellValue(Utils.TOTAL_EGG_REDUCED), TextCellValue(Utils.EGG_RESERVE), TextCellValue(Utils.GOOD_EGGS), TextCellValue(Utils.BAD_EGGS)]);

    /// ---- Sheet 2: Flock Report ----
    Sheet flockSheet = excel['Flock Report'];
    flockSheet.appendRow(
        [
          TextCellValue("Flock Name"),
          TextCellValue("Collected"),
          TextCellValue("Reduced"),
          TextCellValue("Reserve"),
          TextCellValue("Good Eggs"),
          TextCellValue("Bad Eggs"),
        ]
    );

    for (var item in flockReport) {
      flockSheet.appendRow([
        TextCellValue(item.f_name),
        IntCellValue(item.collected ?? 0),
        IntCellValue(item.reduced ?? 0),
        IntCellValue(item.reserve ?? 0),
        IntCellValue(item.good_eggs ?? 0),
        IntCellValue(item.bad_eggs),
      ]);

    }

    /// ---- Sheet 3: Reduction Reasons ----
    Sheet reductionSheet = excel['Reduction Reasons'];
    reductionSheet.appendRow([
      TextCellValue("Reason"),
      TextCellValue("Total Reduced"),
    ]);


    for (var reason in reductions) {
      reductionSheet.appendRow([TextCellValue(reason.reason), IntCellValue(reason.totalReduced)]);
    }

    /// ---- Save File ----
    final directory = await getApplicationDocumentsDirectory();
    String formattedDate = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
// Example: 20251006_1345
    String filePath = "${directory.path}/egg_report_$formattedDate.xlsx";

    final downloadsDir = Directory("/storage/emulated/0/Download");
    String path = "${downloadsDir.path}/egg_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";
    File(path)..createSync(recursive: true)..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved in Downloads");
   *//* File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);*//*

    print("Excel report saved: $filePath");
  }*/
  Future<void> generateEggSummaryExcel(
      List<Egg_Report_Item> flockReport,
      List<EggReductionSummary> reductions) async
  {
    var excel = Excel.createExcel();
    var sheet = excel['Egg Report'.tr()];

    // ==== Define Styles ====
    var headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#B7DEE8"),
      // light blue header
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString("#1F4E78"),
      // dark blue title bar
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var sectionTitleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#BDD7EE"),
      // section background
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    int row = 0;

    // ==== Report Title ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("EGGS_REPORT".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = titleStyle;

    // Merge title across columns (0–5)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));

    row += 2;

    // ==== Summary Section ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("SUMMARY".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));

    row++;

    // Header Row
    List<String> summaryHeaders = [
      "Total Collected".tr(),
      "Total Reduced".tr(),
      "Reserve Eggs".tr(),
      "Good Eggs".tr(),
      "Bad Eggs".tr(),
    ];
    for (int i = 0; i < summaryHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(summaryHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    // Data Row
    List<String> summaryValues = [
      Utils.TOTAL_EGG_COLLECTED,
      Utils.TOTAL_EGG_REDUCED,
      Utils.EGG_RESERVE,
      Utils.GOOD_EGGS,
      Utils.BAD_EGGS,
    ];
    for (int i = 0; i < summaryValues.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(summaryValues[i]);
    }

    row += 2;

    // ==== Flock Report ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("FLOCK_REPORT".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));

    row++;

    List<String> flockHeaders = [
      "Flock Name".tr(),
      "Total Collected".tr(),
      "TOTAL_REDUCED".tr(),
      "Reserve Eggs".tr(),
      "Good Eggs".tr(),
      "Bad Eggs".tr(),
    ];
    for (int i = 0; i < flockHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(flockHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var item in flockReport) {
      sheet.appendRow([
        TextCellValue(item.f_name),
        IntCellValue(item.collected ?? 0),
        IntCellValue(item.reduced ?? 0),
        IntCellValue(item.reserve ?? 0),
        IntCellValue(item.good_eggs ?? 0),
        IntCellValue(item.bad_eggs),
      ]);
    }

    row += flockReport.length + 2;

    // ==== Reduction Summary ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("REDUCTIONS_1".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));

    row++;

    List<String> reductionHeaders = [
      "REDUCTIONS_1".tr(),
      "Total Reduced".tr(),
    ];
    for (int i = 0; i < reductionHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(reductionHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var r in reductions) {
      sheet.appendRow([
        TextCellValue(r.reason.tr()),
        IntCellValue(r.totalReduced),
      ]);
    }


    // === Auto-adjust column widths ===
    for (var table in excel.tables.keys) {
      var sheet = excel[table];
      for (int col = 0; col < sheet.maxColumns; col++) {
        double maxLength = 0;
        for (int row = 0; row < sheet.maxRows; row++) {
          var cellValue = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value;
          if (cellValue != null) {
            var text = cellValue.toString();
            if (text.length > maxLength) {
              maxLength = text.length.toDouble();
            }
          }
        }
        // adjust column width based on max text length
        sheet.setColumnWidth(
            col, (maxLength * 1.2).clamp(12, 35)); // min 12, max 35
      }
    }

    saveAndShareExcel(excel);
  }


  Future<void> saveAndShareExcel(Excel excel) async {
    final downloadsDir = Directory("/storage/emulated/0/Download");
    String formattedDate = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
    String filePath = "${downloadsDir.path}/egg_report_$formattedDate.xlsx";

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved to Downloads: egg_report_$formattedDate.xlsx");

    // ✅ Share/Open the file safely
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Egg report exported successfully!",
    );
  }


/*
  Future<void> saveEggReportMobile(List<int> bytes) async {
    final params = SaveFileDialogParams(
      data: bytes,
      fileName: "egg_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx",
    );

    final filePath = await FlutterFileDialog.saveFile(params: params);
    if (filePath != null) {
      print("Excel report saved at: $filePath");
    } else {
      print("User canceled saving.");
    }
  }*/
  Future<Flock?> getSelectedFlock() async {
    Flock? flock = null;

    for (int i = 0; i < flocks.length; i++) {
      if (f_id == flocks
          .elementAt(i)
          .f_id) {
        flock = flocks.elementAt(i);
        break;
      }
    }

    return flock;
  }

  List<FlockEggSummary> getFlockWiseEggSummary(List<Eggs> eggsList,
      String startDate, String endDate) {
    Map<String, FlockEggSummary> summaryMap = {};

    for (var egg in eggsList) {
      if (egg.date != null &&
          egg.isCollection == 1) { // ✅ Filter by type "Addition"
        DateTime eggDate = DateTime.parse(egg.date!);
        DateTime start = DateTime.parse(startDate);
        DateTime end = DateTime.parse(endDate);

        if (eggDate.isAfter(start.subtract(Duration(days: 1))) &&
            eggDate.isBefore(end.add(Duration(days: 1)))) {
          if (!summaryMap.containsKey(egg.f_name)) {
            summaryMap[egg.f_name!] = FlockEggSummary(
                fName: egg.f_name!, goodEggs: 0, badEggs: 0, totalEggs: 0);
          }
          summaryMap[egg.f_name]!.goodEggs += egg.good_eggs;
          summaryMap[egg.f_name]!.badEggs += egg.bad_eggs;
          summaryMap[egg.f_name]!.totalEggs += egg.total_eggs;
        }
      }
    }

    return summaryMap.values.toList();
  }

  List<EggReductionSummary> getEggReductionSummary(List<Eggs> eggsList,
      String str, String endDate) {
    Map<String, int> reductionMap = {};

    for (var egg in eggsList) {
      if (egg.isCollection == 0) {
        DateTime eggDate = DateTime.parse(egg.date!);
        DateTime start = DateTime.parse(str);
        DateTime end = DateTime.parse(endDate);

        if (eggDate.isAfter(start.subtract(Duration(days: 1))) &&
            eggDate.isBefore(end.add(Duration(days: 1)))) {
          String reason = egg.reduction_reason ?? "Unknown";
          reductionMap[reason] = (reductionMap[reason] ?? 0) + egg.total_eggs;
        }
      }
    }

      return reductionMap.entries
          .map((entry) =>
          EggReductionSummary(reason: entry.key, totalReduced: entry.value))
          .toList();
  }

  int isSameDateExists(List<Eggs_Chart_Item> reductionList, String date) {
    int index = -1;
    for(int i=0;i<reductionList.length;i++){
      if(reductionList[i].date == date){
        index = i;
        break;
      }
    }
    return index;
  }

  void updateReductionSummary(int reduced_eggs) {
    for(int i=0;i<eggReductionSummary.length;i++){
      if(eggReductionSummary[i].reason.toLowerCase() == "egg sale" || eggReductionSummary[i].reason.toLowerCase() == "sold"){
        eggReductionSummary[i].totalReduced = eggReductionSummary[i].totalReduced + reduced_eggs;
        break;
      }else{
        EggReductionSummary eggSummaryItem = EggReductionSummary(reason: "Egg Sale", totalReduced: reduced_eggs);
        eggReductionSummary.add(eggSummaryItem);
        break;
      }
    }
  }

  void updateFlockSummary(List<TransactionItem> eggSales) {

    for(int i=0;i<flockEggSummary.length;i++)
    {
      String f_name = flockEggSummary[i].fName;

      for(int j=0; j<eggSales.length; j++){
        if(eggSales[j].f_name == f_name)
        {
          flockEggSummary[i].totalEggs += int.parse(eggSales[j].how_many);
          flockEggSummary[i].goodEggs += int.parse(eggSales[j].how_many);
          break;
        }
      }

    }
  }

  int getFromSales(int f_id) {
    int n = 0;
    for(int i=0;i<eggSales.length;i++)
      {
        if(eggSales[i].f_id==f_id)
        {
          n = n + int.parse(eggSales[i].how_many);
        }
      }
    return n;
  }

}

// 📌 Model for Flock-wise summary
class FlockEggSummary {
   String fName;
   int goodEggs;
   int badEggs;
   int totalEggs;

  FlockEggSummary({required this.fName, required this.goodEggs, required this.badEggs, required this.totalEggs});
}

// 📌 Summary Row Widget
class SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isBold;
  final String? percentage; // 👈 new

  const SummaryRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isBold = false,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (percentage != null)
                Text(
                  percentage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class EggReductionSummary {
  String reason;
  int totalReduced;

  EggReductionSummary({required this.reason, required this.totalReduced});
}

