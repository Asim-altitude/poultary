import 'dart:io';

import 'package:csv/csv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/birds_report_screen.dart';
import 'package:poultary/eggs_report_screen.dart';
import 'package:poultary/farm_setup_screen.dart';
import 'package:poultary/financial_report_screen.dart';
import 'package:poultary/model/farm_item.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/pdf/pdf_viewer_screen.dart';
import 'package:poultary/pdf/production_pdf.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'database/databse_helper.dart';
import 'model/egg_item.dart';

class ProductionReportScreen extends StatefulWidget {
  const ProductionReportScreen({super.key});

  @override
  State<ProductionReportScreen> createState() => _ProductionReportScreenState();
}

class _ProductionReportScreenState extends State<ProductionReportScreen> {
  DateTime startDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime endDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(const Duration(days: 6));
  int totalDays = 0;

  List<bool>? _dailyExpanded;
  late List<bool> _monthlyExpanded;
  DateTimeRange? selectedDateRange;

   late BannerAd _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;
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

      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;

      });
      totalDays = endDate.difference(startDate).inDays + 1;

      getAllData();

    }
  }

  @override
  void dispose() {
    try{
      _bannerAd.dispose();
      _myNativeAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  Widget _buildWhiteCardVertical(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(label.tr(), style: const TextStyle(fontSize: 14,color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue())),
        ],
      ),
    );
  }

  Widget _buildWhiteCard(String label, String value, IconData icon, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16,),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Utils.getThemeColorBlue()).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor ?? Utils.getThemeColorBlue()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Utils.getThemeColorBlue(),
                    ),
                  ),
                )

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8),
      child: Text(title.tr(), style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFilters();
    if(Utils.isShowAdd){
      _loadBannerAd();
      _loadNativeAds();
    }
    AnalyticsUtil.logScreenView(screenName: "production_report_screen");
  }
  _loadNativeAds(){
    _myNativeAd = NativeAd(
      adUnitId: Utils.NativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium, // or medium
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

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
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

  String getDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  num gross_income=0,total_expense=0,profit=0,total_feed_consumption=0;
  int total_eggs_collected = 0, total_eggs_reduced = 0,total_eggs =0
  ,total_birds_added=0,total_birds_reduced=0,mortality=0,culling=0,mortality_culling=0;

  List<TransactionItem> transactions =[];
  List<Eggs> eggsList = [];
  List<Flock_Detail> birdsInfoList = [];
  List<Feeding> feedList = [];

  Map<String, Map<String, dynamic>>? dailyBreakDown;
  List<MonthlyBreakdownData>? monthlyBreakDown;

  bool isLoading = false;
  Future<void> getAllData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      totalDays = calculateTotalDays(str_date, end_date);
    });

    if(str_date.startsWith("1950")){
      str_date = "";
      end_date = "";
    }

    try {
      gross_income = await DatabaseHelper.getTransactionsTotal(
          -1, "Income", str_date, end_date);

      total_expense = await DatabaseHelper.getTransactionsTotal(
          -1, "Expense", str_date, end_date);

      profit = gross_income - total_expense;

      total_eggs_collected =
      await DatabaseHelper.getEggCalculations(-1, 1, str_date, end_date);

      total_eggs_reduced =
      await DatabaseHelper.getEggCalculations(-1, 0, str_date, end_date);

      total_eggs = total_eggs_collected - total_eggs_reduced;

      total_birds_added = await DatabaseHelper.getBirdsCalculations(
          -1, "Addition", str_date, end_date);

      total_birds_reduced = await DatabaseHelper.getBirdsCalculations(
          -1, "Reduction", str_date, end_date);

      /*mortality = await DatabaseHelper.getFlockMortalityCount(-1);
      culling = await DatabaseHelper.getFlockCullingCount(-1);
*/
     try {
       mortality =
       await DatabaseHelper.getFlockReductionCount(flockId: -1, reason: "MORTALITY", str_date: str_date, end_date: end_date);
       culling =
       await DatabaseHelper.getFlockReductionCount(flockId: -1, reason: "CULLING", str_date: str_date, end_date: end_date);

     }
     catch(ex){
       print(ex);
     }

      total_feed_consumption =
      await DatabaseHelper.getTotalFeedConsumption(
          -1, str_date, end_date);

      total_feed_consumption =
          num.parse(total_feed_consumption.toStringAsFixed(2));

      birdsInfoList =
      await DatabaseHelper.getFilteredFlockDetails(
          -1, "All", str_date, end_date);

      eggsList =
      await DatabaseHelper.getFilteredEggs(
          -1, "All", str_date, end_date);

      transactions =
      await DatabaseHelper.getReportFilteredTransactions(
          -1, "All", str_date, end_date);

      feedList =
      await DatabaseHelper.getFilteredFeedingWithSort(
          -1, "All", str_date, end_date, "DESC");

      try {

        dailyBreakDown = generateDailyBreakdown(
          startDate: str_date,
          endDate: end_date,
          transactions: transactions,
          feedings: feedList,
          eggsList: eggsList,
          flockDetails: birdsInfoList,
        );
      }
      catch(ex){
        print(ex);
      }


      monthlyBreakDown = generateMonthlyBreakdown(
        flockDetails: birdsInfoList,
        eggs: eggsList,
        feedings: feedList,
        transactions: transactions,
      );

      _dailyExpanded =
          List.generate(dailyBreakDown!.length, (index) => index == 0);

      _monthlyExpanded =
          List.generate(monthlyBreakDown!.length, (index) => index == 0);

    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  int calculateTotalDays(String str_date, String end_date) {
    final DateTime start = DateTime.parse(str_date);
    final DateTime end = DateTime.parse(end_date);

    return end.difference(start).inDays + 1; // +1 to include both dates
  }


  List<MonthlyBreakdownData> generateMonthlyBreakdown({
    required List<Flock_Detail> flockDetails,
    required List<Eggs> eggs,
    required List<Feeding> feedings,
    required List<TransactionItem> transactions,
  })
  {
    final Map<String, MonthlyBreakdownData> monthlyData = {};

    String getMonth(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}";

    // ---------------- FLOCK DETAILS ----------------
    for (final f in flockDetails) {
      final date = DateTime.tryParse(f.acqusition_date);
      if (date == null) continue;

      final key = getMonth(date);
      final data = monthlyData.putIfAbsent(key, () => _emptyMonth(key));

      // ✅ FIX: use item_type
      if (f.item_type == 'Addition') {
        data.birdsAdded += f.item_count;
      } else if (f.item_type == 'Reduction') {
        data.birdsReduced += f.item_count;

        // ✅ FIX: uppercase comparison
        if (f.reason == 'MORTALITY') {
          data.mortality += f.item_count;
        } else if (f.reason == 'CULLING') {
          data.culling += f.item_count;
        }
      }
    }

    // ---------------- EGGS ----------------
    for (final e in eggs) {
      final date = DateTime.tryParse(e.date ?? '');
      if (date == null) continue;

      final key = getMonth(date);
      final data = monthlyData.putIfAbsent(key, () => _emptyMonth(key));

      if (e.isCollection == 1) {
        data.totalEggs += e.total_eggs;
      } else {
        data.totalEggs -= e.total_eggs;
      }
    }

    // ---------------- FEED ----------------
    for (final f in feedings) {
      final date = DateTime.tryParse(f.date ?? '');
      if (date == null) continue;

      final key = getMonth(date);
      final data = monthlyData.putIfAbsent(key, () => _emptyMonth(key));

      data.totalFeedKg += double.tryParse(f.quantity ?? '0') ?? 0;
    }

    // ---------------- TRANSACTIONS ----------------
    for (final t in transactions) {
      final date = DateTime.tryParse(t.date);
      if (date == null) continue;

      final key = getMonth(date);
      final data = monthlyData.putIfAbsent(key, () => _emptyMonth(key));

      final amount = double.tryParse(t.amount) ?? 0;
      if (t.type == 'Income') {
        data.income += amount;
      } else if (t.type == 'Expense') {
        data.expense += amount;
      }
    }

    // ---------------- SORT ----------------
    final result = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return result.map((e) => e.value).toList();
  }

  MonthlyBreakdownData _emptyMonth(String key) {
    return MonthlyBreakdownData(
      month: key,
      birdsAdded: 0,
      birdsReduced: 0,
      mortality: 0,
      culling: 0,
      totalEggs: 0,
      totalFeedKg: 0.0,
      income: 0.0,
      expense: 0.0,
    );
  }


  Map<String, Map<String, dynamic>> generateDailyBreakdown({
    required String startDate, // yyyy-MM-dd
    required String endDate,   // yyyy-MM-dd
    required List<TransactionItem> transactions,
    required List<Feeding> feedings,
    required List<Eggs> eggsList,
    required List<Flock_Detail> flockDetails,
  })
  {
    final Map<String, Map<String, dynamic>> breakdown = {};


    // ---------- helpers ----------
    String normalize(String? date) {
      if (date == null) return "";
      final parsed = DateTime.tryParse(date);
      if (parsed == null) return "";
      return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
    }

    void ensureDate(String date) {
      breakdown.putIfAbsent(date, () => {
        'birdsAdded': 0,
        'birdsReduced': 0,
        'mortality': 0,
        'culling': 0,
        'eggs': 0,
        'feed': 0.0,
        'income': 0.0,
        'expense': 0.0,
      });
    }

    void add(String date, String key, num value) {
      if (date.isEmpty) return;
      ensureDate(date);
      breakdown[date]![key] += value;
    }

    // ---------- 1️⃣ Pre-fill full date range ----------
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final d = start.add(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      ensureDate(key);
    }

    // ---------- 2️⃣ Flock details ----------
    for (var f in flockDetails) {
      final date = normalize(f.acqusition_date);

      if (f.item_type == "Addition") {
        add(date, 'birdsAdded', f.item_count);
      } else if (f.item_type == "Reduction") {
        add(date, 'birdsReduced', f.item_count);

        if (f.reason == "MORTALITY") {
          add(date, 'mortality', f.item_count);
        } else if (f.reason == "CULLING") {
          add(date, 'culling', f.item_count);
        }
      }
    }

    // ---------- 3️⃣ Eggs ----------
    for (var e in eggsList) {
      final date = normalize(e.date);

      if (e.isCollection == 1) {
        add(date, 'eggs', e.total_eggs);
      } else if (e.isCollection == 0) {
        add(date, 'eggs', -e.total_eggs);
      }
    }

    // ---------- 4️⃣ Feed ----------
    for (var f in feedings) {
      final date = normalize(f.date);
      final qty = double.tryParse(f.quantity ?? "0") ?? 0;
      add(date, 'feed', qty);
    }

    // ---------- 5️⃣ Transactions ----------
    for (var t in transactions) {
      final date = normalize(t.date);
      final amt = double.tryParse(t.amount) ?? 0;

      if (t.type == "Income") {
        add(date, 'income', amt);
      } else if (t.type == "Expense") {
        add(date, 'expense', amt);
      }
    }

    // ---------- 6️⃣ Sort by date ----------
    final sortedKeys = breakdown.keys.toList()..sort();

    return {
      for (final k in sortedKeys) k: breakdown[k]!,
    };
  }


  void showFarmSetupDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.orange,
              ),
              SizedBox(height: 15),
              Text(
                "Farm Setup Date Missing",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text("The daily and monthly production breakdowns depend on this date, ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  FarmSetupScreen()),);

                    var inputFormat = DateFormat('yyyy-MM-dd');
                    List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();
                    FarmSetup farmInfo = farmSetup[0];
                    str_date = farmInfo.date;
                    end_date = inputFormat.format(DateTime.now());

                    pdf_formatted_date_filter = 'ALL_TIME'.tr();
                    getAllData();// Navigate to Farm Setup Screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Set Up Farm Now",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {

    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('Production Report'.tr(),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),),
          backgroundColor: Utils.getThemeColorBlue(),
          foregroundColor: Colors.white, // keeps title and back button white
          actions: [
            // Excel Icon (keeps its own color)
            if(!Platform.isIOS)
            Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: null), // reset inherited white
              ),
              child: IconButton(
                icon: Image.asset(
                  'assets/excel_icon.png',
                  width: 26,
                  height: 26,
                ),
                tooltip: 'Export Excel',
                onPressed: () async {
                  Utils.setupInvoiceInitials(
                    "Production Report".tr(),
                    DateFormat("yyyy MMM dd").format(startDate) +
                        " - " +
                        DateFormat("yyyy MMM dd").format(endDate),
                  );

                  await generateProductionReportExcel(
                    flockName: 'My Flock',
                    totalBirdsAdded: total_birds_added,
                    totalBirdsReduced: total_birds_reduced,
                    mortality: mortality,
                    culling: culling,
                    totalEggsCollected: total_eggs_collected,
                    totalEggsReduced: total_eggs_reduced,
                    grossIncome: gross_income,
                    totalExpense: total_expense,
                    profit: profit,
                    totalFeedUsed: total_feed_consumption,
                    dailyBreakdown: dailyBreakDown ?? {},
                    monthlyBreakdown: monthlyBreakDown!,
                  );
                },
              ),
            ),

            // PDF icon (white)
            IconButton(
              icon: Image.asset(
            'assets/pdf_icon.png',
            width: 20,
            height: 20,
            ),
              tooltip: 'Export PDF',
              onPressed: () async {
                AnalyticsUtil.logButtonClick(buttonName: "pdf", screen: "production_report");


                Utils.setupInvoiceInitials(
                  "Production Report".tr(),
                  DateFormat("yyyy MMM dd").format(startDate) +
                      " - " +
                      DateFormat("yyyy MMM dd").format(endDate),
                );

                final pdfBytes = await generateProductionReportPdf(
                  flockName: 'My Flock',
                  totalBirdsAdded: total_birds_added,
                  totalBirdsReduced: total_birds_reduced,
                  mortality: mortality,
                  culling: culling,
                  totalEggsCollected: total_eggs_collected,
                  totalEggsReduced: total_eggs_reduced,
                  grossIncome: gross_income,
                  totalExpense: total_expense,
                  profit: profit,
                  totalFeedUsed: total_feed_consumption,
                  dailyBreakdown: dailyBreakDown ?? {},
                  monthlyBreakdown: monthlyBreakDown!,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductionReportViewer(pdfData: pdfBytes),
                  ),
                );
              },
            ),
          ],
        ),

        body: Column(children: [
         if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),

        Expanded(child:
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 12,right: 12,top: 0,bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             /* Center(
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),*/
              InkWell(
                onTap: () {
                  openDatePicker();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 45,
                  margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                  padding: EdgeInsets.symmetric(horizontal: 12),
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
              ),
              SizedBox(height: 10,),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),

        GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  BirdsReportsScreen()),);
                },
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child:  Column(
                    children: [
                      _sectionTitle('BIRDS_SUMMARY'),
                      Row(
                        children: [

                          Expanded(child: _buildWhiteCard('Birds Added', '$total_birds_added', Icons.add_circle, iconColor: Colors.green)),

                          Expanded(child: _buildWhiteCard('Birds Reduced', '$total_birds_reduced', Icons.remove_circle, iconColor: Colors.orange)),
                        ],
                      ),

                      _buildWhiteCard('MORTALITY'.tr()+ "/"+ "CULLING".tr(), '${mortality+culling}', Icons.warning_amber, iconColor: Colors.red),
                      const SizedBox(height: 10),

                      Container(
                        width: 260,
                        height: 260,
                        child: SfCircularChart(
                          title: ChartTitle(text: 'BIRDS_SUMMARY'.tr()),
                          legend: Legend(isVisible: true, position: LegendPosition.bottom),
                          series: <CircularSeries>[
                            PieSeries<_ChartData, String>(
                              dataSource: [
                                _ChartData('Added'.tr(), total_birds_added.toDouble(), Colors.green),
                                _ChartData('Reduced'.tr(), total_birds_reduced.toDouble(), Colors.orange),
                                _ChartData('MORTALITY'.tr(), mortality.toDouble() + culling.toDouble(), Colors.red),
                              ],
                              pointColorMapper: (_ChartData data, _) => data.color,
                              xValueMapper: (_ChartData data, _) => data.label.tr(),
                              yValueMapper: (_ChartData data, _) => data.value,
                              dataLabelSettings: const DataLabelSettings(isVisible: true),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                ),
              ),

              SizedBox(height: 10,),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  EggsReportsScreen()),);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _sectionTitle('EGGS_SUMMARY'),
                      _buildWhiteCard('eggs collected', '$total_eggs_collected', Icons.egg, iconColor: Colors.purple),
                      _buildWhiteCard('Reduced Eggs', '$total_eggs_reduced', Icons.restaurant, iconColor: Colors.brown),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 260,
                        child: SfCircularChart(
                          title: ChartTitle(text: 'EGGS_SUMMARY'.tr()),
                          legend: Legend(isVisible: true, position: LegendPosition.bottom),
                          series: <CircularSeries>[
                            PieSeries<_ChartData, String>(
                              dataSource: [
                                _ChartData('COLLECTION'.tr(), total_eggs_collected.toDouble(), Colors.purple),
                                _ChartData('Consumption'.tr(), total_eggs_reduced.toDouble(), Colors.brown),
                              ],
                              pointColorMapper: (_ChartData data, _) => data.color,
                              xValueMapper: (_ChartData data, _) => data.label,
                              yValueMapper: (_ChartData data, _) => data.value,
                              dataLabelSettings: const DataLabelSettings(isVisible: true),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isNativeAdLoaded && _myNativeAd != null)
                Container(
                  height: 350,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AdWidget(ad: _myNativeAd),
                ),

              SizedBox(height: 10,),

              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  FinanceReportsScreen()),);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _sectionTitle('HEADING_DASHBOARD'),
                      _buildWhiteCard('Income'.tr()+' (' + Utils.currency + ')', '$gross_income', Icons.trending_up, iconColor: Colors.green),
                      _buildWhiteCard('Expenses'.tr()+' (' + Utils.currency + ')', '$total_expense', Icons.trending_down, iconColor: Colors.red),
                      _buildWhiteCard('NET_PROFIT'.tr()+' (' + Utils.currency + ')', '$profit', Icons.attach_money, iconColor: Colors.blueAccent),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 260,
                        child: SfCircularChart(
                          title: ChartTitle(text: 'HEADING_DASHBOARD'.tr()),
                          legend: Legend(isVisible: true, position: LegendPosition.bottom),
                          series: <CircularSeries>[
                            PieSeries<_ChartData, String>(
                              dataSource: [
                                _ChartData('Income'.tr(), gross_income.toDouble(), Colors.green),
                                _ChartData('Expense'.tr(), total_expense.toDouble(), Colors.red),
                              ],
                              pointColorMapper: (_ChartData data, _) => data.color,
                              xValueMapper: (_ChartData data, _) => data.label,
                              yValueMapper: (_ChartData data, _) => data.value,
                              dataLabelSettings: const DataLabelSettings(isVisible: true),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10,),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),

                child: Column(
                  children: [
                    _sectionTitle('FEED_CONSUMPTION'),
                    _buildWhiteCard('FEED_CONSUMPTION'.tr()+' (' + Utils.selected_unit + ')', '$total_feed_consumption', Icons.rice_bowl, iconColor: Colors.teal),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Center(child: buildToggle()),
              ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),

                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: _selectedView == 'Daily'
                      ? buildDailyBreakdownList()
                      : buildMonthlyBreakdownList(monthlyBreakDown ?? []),
                ),


            ],
          ),
        ),
        ),
      ],),
    );
  }
  String _selectedView = 'Daily'; // or 'Monthly'

  Widget buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        segments:  [
          ButtonSegment(
            value: 'Daily',
            label: Text('Daily'.tr()),
          ),
          ButtonSegment(
            value: 'Monthly',
            label: Text('Monthly'.tr()),
          ),
        ],
        selected: {_selectedView},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedView = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Utils.getThemeColorBlue(); // Selected segment background color
            }
            return Colors.white; // Unselected segment background
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white; // Selected text color
            }
            return Utils.getThemeColorBlue(); // Unselected text color
          }),
          side: MaterialStateProperty.all(
             BorderSide(color: Utils.getThemeColorBlue()),
          ),
        ),
      ),
    );
  }
  double widthScreen = 0;
  double heightScreen = 0;
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
  String str_date = '',end_date = '';
  Future<void> getData(String filter) async {
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

      List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();
      FarmSetup farmInfo = farmSetup[0];
      if(farmInfo.date.toLowerCase() == "date"){
        showFarmSetupDialog(context);
        return;
      }else{
        str_date = farmInfo.date;
      }

      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      end_date = inputFormat.format(DateTime.now());
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'ALL_TIME'.tr();
      getAllData();
    }else if (filter == 'DATE_RANGE'){
      _pickDateRange();
    }


  }

  List<Widget> buildDailyBreakdownList() {
    if (dailyBreakDown == null || dailyBreakDown!.isEmpty) {
      return [];
    }

    final dates = dailyBreakDown!.keys.toList()..sort();

    return List.generate(dates.length, (index) {
      final dateKey = dates[index];
      final date = DateTime.parse(dateKey);

      bool isExpanded = _dailyExpanded?[index] ?? false;

      final data = dailyBreakDown![dateKey]!;

      return Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _dailyExpanded![index] = !_dailyExpanded![index];
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat("yyyy MMM dd").format(date),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        " (${DateFormat.EEEE().format(date).tr()})",
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWhiteCard('Birds Added', '${data['birdsAdded']}', Icons.add_circle, iconColor: Colors.green),
                  _buildWhiteCard(
                    'Birds Reduced',
                    '${data['birdsReduced']}',
                    Icons.remove_circle,
                    iconColor: Colors.orange,
                  ),
                  _buildWhiteCard('MORTALITY'.tr()+ "/"+ "CULLING".tr(), '${data['mortality']+data['culling']}', Icons.warning_amber, iconColor: Colors.red),

                  Row(
                    children: [
                      Expanded(child: _buildWhiteCardVertical('Eggs', '${data['eggs']}')),
                      const SizedBox(width: 5),
                      Expanded(child: _buildWhiteCardVertical('Feed', '${data['feed']} ${Utils.selected_unit.tr()}')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildWhiteCard('Income', Utils.currency + '${data['income']}', Icons.trending_up, iconColor: Colors.green)),
                      const SizedBox(width: 5),
                      Expanded(child: _buildWhiteCard('Expense', Utils.currency + '${data['expense']}', Icons.trending_down, iconColor: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  List<Widget> buildMonthlyBreakdownList(List<MonthlyBreakdownData> monthlySummary) {
    return List.generate(monthlySummary.length, (index) {
      final data = monthlySummary[index];
      final isExpanded = _monthlyExpanded[index]; // This must be a List<bool>

      final monthFormatted = DateFormat("MMMM yyyy").format(DateTime.parse("${data.month}-01"));

      return Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _monthlyExpanded[index] = !_monthlyExpanded[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthFormatted,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWhiteCard('Birds Added', '${data.birdsAdded}', Icons.add_circle_outline, iconColor: Colors.green),
                  _buildWhiteCard('Birds Reduced', '${data.birdsReduced}', Icons.remove_circle_outline, iconColor: Colors.orange),
                  Row(
                    children: [

                      Expanded(child: _buildWhiteCard('MORTALITY', '${data.mortality}', Icons.warning_amber_rounded, iconColor: Colors.red)),
                      const SizedBox(width: 5),
                      Expanded(child: _buildWhiteCard('CULLING', '${data.culling}', Icons.cancel, iconColor: Colors.redAccent)),
                    ],
                  ),

                  Row(
                    children: [
                      Flexible(child: _buildWhiteCard('Eggs', '${data.totalEggs}', Icons.egg, iconColor: Colors.deepOrange)),
                      const SizedBox(width: 5),
                      Flexible(child: _buildWhiteCard('Feed', '${data.totalFeedKg}', Icons.grain, iconColor: Colors.brown)),
                    ],
                  ),
                  Row(
                    children: [
                     
                      Expanded(child: _buildWhiteCard('Income', Utils.currency+'${data.income}', Icons.trending_up, iconColor: Colors.green)),
                      const SizedBox(height: 5),
                     
                      Expanded(child: _buildWhiteCard('Expense', Utils.currency+'${data.expense}', Icons.trending_down, iconColor: Colors.redAccent)),
                    ],
                  ),
              
                ],
              ),
            ),
        ],
      );
    });
  }



  Future<void> generateProductionReportExcel({
    required String flockName,
    required int totalBirdsAdded,
    required int totalBirdsReduced,
    required int mortality,
    required int culling,
    required int totalEggsCollected,
    required int totalEggsReduced,
    required num grossIncome,
    required num totalExpense,
    required num profit,
    required num totalFeedUsed,
    required Map<String, Map<String, dynamic>> dailyBreakdown,
    required List<MonthlyBreakdownData> monthlyBreakdown,
  }) async {
    var excel = Excel.createExcel();
    var sheet = excel['Production Report'.tr()];

    // ==== Define Styles ====
    var titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString("#1F4E78"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var sectionTitleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#BDD7EE"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#B7DEE8"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var numberStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);

    int row = 0;

    // ==== Report Title ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Production Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = titleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));

    row += 2;

    // ==== Summary Section ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("SUMMARY".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
    row++;

    // Birds Summary
    sheet.appendRow([
      TextCellValue("Birds Added".tr()),
      TextCellValue("Birds Reduced".tr()),
      TextCellValue("MORTALITY".tr()),
      TextCellValue("CULLING".tr()),
    ]);
    for (int i = 0; i < 4; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }
    row++;

    sheet.appendRow([
      TextCellValue(totalBirdsAdded.toString()),
      TextCellValue(totalBirdsReduced.toString()),
      TextCellValue(mortality.toString()),
      TextCellValue(culling.toString()),
    ]);
    for (int i = 0; i < 4; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = numberStyle;
    }

    row += 2;

    // Eggs Summary
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("EGGS_SUMMARY".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    row++;

    sheet.appendRow([
      TextCellValue("TOTAL_ADDED".tr()),
      TextCellValue("TOTAL_REDUCED".tr()),
    ]);
    for (int i = 0; i < 2; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }
    row++;

    sheet.appendRow([
      TextCellValue(totalEggsCollected.toString()),
      TextCellValue(totalEggsReduced.toString()),
    ]);
    for (int i = 0; i < 2; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = numberStyle;
    }

    row += 2;

    // Feed Summary
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Feed Stock Summary".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    row++;

    sheet.appendRow([
      TextCellValue("Total Feed Used".tr()),
    ]);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = headerStyle;
    row++;

    sheet.appendRow([
      TextCellValue(totalFeedUsed.toString()),
    ]);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = numberStyle;

    row += 2;

    // Finance Summary
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("HEADING_DASHBOARD".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    row++;

    sheet.appendRow([
      TextCellValue("Income".tr()+"(${Utils.currency})"),
      TextCellValue("Expense".tr()+"(${Utils.currency})"),
      TextCellValue("Profit".tr()+"(${Utils.currency})"),
    ]);
    for (int i = 0; i < 3; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }
    row++;

    sheet.appendRow([
      TextCellValue(grossIncome.toString()),
      TextCellValue(totalExpense.toString()),
      TextCellValue(profit.toString()),
    ]);
    for (int i = 0; i < 3; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = numberStyle;
    }

    row += 2;

    // ==== Daily Breakdown ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Daily Breakdown".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
    row++;

    // Dynamic Daily Headers
    List<String> dailyHeaders = [
      "Date".tr(),
      "Birds Added".tr(),
      "Birds Reduced".tr(),
      "MORTALITY".tr(),
      "CULLING".tr(),
      "Eggs".tr(),
      "FEED_CONSUMPTION".tr(),
      "Income".tr()+"(${Utils.currency})",
      "Expense".tr()+"(${Utils.currency})",
    ];

    for (int i = 0; i < dailyHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(dailyHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    dailyBreakdown.forEach((date, data) {
      sheet.appendRow([
        TextCellValue(date),
        TextCellValue(data["birdsAdded"].toString()),
        TextCellValue(data["birdsReduced"].toString()),
        TextCellValue(data["mortality"].toString()),
        TextCellValue(data["culling"].toString()),
        TextCellValue(data["eggs"].toString()),
        TextCellValue(data["feedUsed"].toString()),
        TextCellValue(data["income"].toString()),
        TextCellValue(data["expense"].toString()),
      ]);
      row++;
    });

    row += 2;

    // ==== Monthly Breakdown ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Monthly Breakdown".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
    row++;

    List<String> monthlyHeaders =
    [
      "Month".tr(),
      "Birds Added".tr(),
      "Birds Reduced".tr(),
      "MORTALITY".tr(),
      "CULLING".tr(),
      "Total Eggs".tr(),
      "Feed (kg)".tr(),
      "Income".tr()+"(${Utils.currency})",
      "Expense".tr()+"(${Utils.currency})",
    ];

    for(int i = 0; i < monthlyHeaders.length; i++)
    {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = TextCellValue(monthlyHeaders[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).cellStyle = headerStyle;
    }

    row++;

    for (var m in monthlyBreakdown)
    {
      sheet.appendRow([
        TextCellValue(m.month),
        TextCellValue(m.birdsAdded.toString()),
        TextCellValue(m.birdsReduced.toString()),
        TextCellValue(m.mortality.toString()),
        TextCellValue(m.culling.toString()),
        TextCellValue(m.totalEggs.toString()),
        TextCellValue(m.totalFeedKg.toString()),
        TextCellValue(m.income.toString()),
        TextCellValue(m.expense.toString()),
      ]);
      row++;
    }

    // === Auto-adjust column widths ===
    for (var table in excel.tables.keys)
    {
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
        sheet.setColumnWidth(col, (maxLength * 1.2).clamp(12, 35));
      }
    }

    saveAndShareExcel(excel);
  }

  Future<void> saveAndShareExcel(Excel excel) async {
    final downloadsDir = Directory("/storage/emulated/0/Download");
    String formattedDate = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
    String filePath = "${downloadsDir.path}/production_report_$formattedDate.xlsx";

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved to Downloads: egg_report_$formattedDate.xlsx");

    // ✅ Share/Open the file safely
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Production report exported successfully!",
    );
  }


}

class MonthlyBreakdownData {
   String month; // e.g. "2025-05"
   int birdsAdded;
   int birdsReduced;
   int mortality;
   int culling;
   int totalEggs;
   double totalFeedKg;
   double income;
   double expense;

  MonthlyBreakdownData({
    required this.month,
    required this.birdsAdded,
    required this.birdsReduced,
    required this.mortality,
    required this.culling,
    required this.totalEggs,
    required this.totalFeedKg,
    required this.income,
    required this.expense,
  });
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
