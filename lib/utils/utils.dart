import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/languages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/model/custom_category_data.dart';
import 'package:poultary/utils/session_manager.dart';
import '../CAS_Ads.dart';
import 'package:uuid/uuid.dart';
import '../birds_report_screen.dart';
import '../custom_category_report.dart';
import '../database/databse_helper.dart';
import '../eggs_report_screen.dart';
import '../financial_report_screen.dart';
import '../health_report_screen.dart';
import '../model/bird_item.dart';
import '../model/bird_model.dart';
import '../model/bird_product.dart';
import '../model/custom_category.dart';
import '../model/egg_item.dart';
import '../model/egg_report_item.dart';
import '../model/farm_item.dart';
import '../model/feed_item.dart';
import '../model/feed_report_item.dart';
import '../model/feedflock_report_item.dart';
import '../model/finance_report_item.dart';
import '../model/finance_summary_flock.dart';
import '../model/flock.dart';
import '../model/flock_detail.dart';
import '../model/flock_report_item.dart';
import '../model/health_report_item.dart';
import '../model/med_vac_item.dart';
import '../model/transaction_item.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


class Utils {
  static const String APPLICATION_ID = "BirdDiary";
  static const String APPLICATION_VERSION = "1.0.0";
  static final String BASE_URL = "";
  static bool isDebug = true;
  static double WIDTH_SCREEN = 0;
  static double HEIGHT_SCREEN = 0;
  static double _standardWidth = 414;
  static double _standardheight = 736;
  static final bool ISTESTACCOUNT = false;
  static late bool isShowAdd = true;
  static late bool iShowInterStitial = false;

  static final String appIdIOS     = "ca-app-pub-2367135251513556~6965974738";
  static final String appIdAndroid = "ca-app-pub-2367135251513556~8724531818";
  static var box;


  static final String testIOS     = "ca-app-pub-3940256099942544~1458002511";
  static final String testAndroid = "ca-app-pub-3940256099942544~3347511713";

  static String currency = "\$";

  //static final totalSecondsInDay = 5;
  static final totalSecondsInDay = 86400;

  static Flock? selected_flock;
  static Eggs? selected_egg_collection;
  static Flock_Detail? selected_flock_collection;
  static List<Flock_Detail>? flock_details;
  static List<EggReductionSummary>? eggReductionSummary;
  static List<FlockIncomeExpense>? flockfinanceList;
  static List<VaccinationGrouped>? groupedList;
  static List<FinancialItem>? incomeItems;
  static List<FinancialItem>? expenseItems;
  static List<FlockQuantity>? flockQuantity;
  static List<ReductionByReason>? reductionByReason;
  static List<CustomCategoryData>? categoryDataList;

  static Feeding? selected_feeding;
  static int selected_category = -1;
  static String selected_category_name = "";
  static TransactionItem? selected_transaction;
  static Vaccination_Medication? selected_med;
  static String vaccine_medicine = "All Medications/Vaccinations";
  static String INVOICE_LOGO_STR = "";
  static String INVOICE_HEADING = "";
  static String INVOICE_SUB_HEADING = "";
  static String INVOICE_DATE = "";

  static String TOTAL_BIRDS_ADDED = "0";
  static String TOTAL_BIRDS_REDUCED = "0";
  static String TOTAL_ACTIVE_BIRDS = "0";

  static String TOTAL_EGG_COLLECTED = "100";
  static String TOTAL_EGG_REDUCED = "20";
  static String EGG_RESERVE = "80";
  static String GOOD_EGGS = "80";
  static String BAD_EGGS = "80";

  static String TOTAL_INCOME = "0";
  static String TOTAL_EXPENSE = "0";
  static String NET_INCOME = "0";

  static String TOTAL_MEDICATIONS = "0";
  static String TOTAL_VACCINATIONS = "0";
  static String applied_filter = "";
  static String TOTAL_CONSUMPTION = "0";

  static String SELECTED_FLOCK = "";
  static int SELECTED_FLOCK_ID = -1;

  static List<Flock_Report_Item> flock_report_list = [];
  static List<Egg_Report_Item> egg_report_list = [];
  static List<Feed_Report_Item> feed_report_list = [];
  static List<FeedFlock_Report_Item> feed_flock_report_list = [];
  static List<Finance_Report_Item> finance_report_list = [];

  static List<Health_Report_Item> vaccine_report_list = [];
  static List<Health_Report_Item> medication_report_list = [];
  static BannerAd? _bannerAd ;
  static bool _isBannerAdReady = false;
  static InterstitialAd? _interstitialAd;
  static List<BirdModel> products = [];
  static bool isShowProducts = false;

  // static MediationManager? manager;
  // static CASBannerView? view;


  static bool direction = true;

 static Future<bool> getDirection() async{

   String? language = await SessionManager.getSelectedLanguage();


   if(language =="en"){
     return true;
   }
   else if(language =="ar"){
     return false;
   }
   else if(language =="ru"){
     return true;
   }
   else if(language =="fa"){
     return false;
   }
   else if(language =="de"){
     return true;
   }
   else if(language =="ja"){
     return true;
   }
   else if(language =="ko"){
     return true;
   }
   else if(language =="pt"){
     return true;
   }
   else if(language =="tr"){
     return true;
   }
   else if(language =="fr"){
     return true;
   }
   else if(language =="id"){
     return true;
   }
   else if(language =="hi"){
     return true;
   }
   else if(language =="es"){
     return true;
   }
   else if(language =="zh"){
     return true;
   }
   else if(language =="uk"){
     return true;
   }
   else if(language =="pl"){
     return true;
   }
   else if(language =="bn"){
     return true;
   }
   else if(language =="te"){
     return true;
   }
   else if(language =="ta"){
     return true;
   }
   else if(language =="ur"){
     return false;
   }

   return true;
 }

  static Future<String> getPdfregularFont() async{

   String language = await SessionManager.getSelectedLanguage();

    if(language =="en"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="ar"){
      return "assets/font/arabic_regular.ttf";
    }
    else if(language =="ru"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="fa"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="de"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="ja"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="ko"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="pt"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="tr"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="fr"){
      return "assets/font/persian2.ttf";
    }
    else if(language =="id"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="hi"){
      return "assets/font/Hind-Regular.ttf";
    }
    else if(language =="es"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="zh"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="uk"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="pl"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="bn"){
      return "assets/font/NotoSansBengali.ttf";
    }
    else if(language =="te"){
      return "assets/font/NotoSerifTelugu.ttf";
    }
    else if(language =="ta"){
      return "assets/font/NotoSansTamil.ttf";
    }
    else if(language =="ur"){
      return "assets/font/NotoSansArabic.ttf";
    }else{
      return "assets/font/Roboto-Regular.ttf";
    }


  }

  static Future<String> getPdfBoldFont() async{
    String language = await SessionManager.getSelectedLanguage();

    if(language =="en"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="ar"){
      return "assets/font/arbic_bold.ttf";
    }
    else if(language =="ru"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="fa"){
      return "assets/font/persian2.ttf";
    }
    else if(language =="de"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="ja"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="ko"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="pt"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="tr"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="fr"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="id"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="hi"){
      return "assets/font/Hind-Bold.ttf";
    }
    else if(language =="es"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="zh"){
      return "assets/font/Roboto-Regular.ttf";
    }
    else if(language =="uk"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="pl"){
      return "assets/font/Roboto-Bold.ttf";
    }
    else if(language =="bn"){
      return "assets/font/NotoSansBengali.ttf";
    }
    else if(language =="te"){
      return "assets/font/NotoSerifTelugu.ttf";
    }
    else if(language =="ta"){
      return "assets/font/NotoSansTamil.ttf";
    }
    else if(language =="ur"){
      return "assets/font/NotoSansArabic.ttf";
    } else{
      return "assets/font/Roboto-Bold.ttf";
    }


  }

  static List<Currency> getMissingCurrency() {
    List<Currency> missingCurrencies = [
      Currency(
        code: "IRR",
        name: "Iranian Rial",
        symbol: "﷼",
        flag: "IRR",
        decimalDigits: 0,
        number: 364,
        namePlural: "Iranian rials",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: true,
        symbolOnLeft: false,
      ),
      Currency(
        code: "XCD",
        name: "East Caribbean Dollar",
        symbol: "\$",
        flag: "XCD",
        decimalDigits: 2,
        number: 951,
        namePlural: "East Caribbean dollars",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "KMF",
        name: "Comorian Franc",
        symbol: "CF",
        flag: "KMF",
        decimalDigits: 0,
        number: 174,
        namePlural: "Comorian francs",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "LSL",
        name: "Lesotho Loti",
        symbol: "L",
        flag: "LSL",
        decimalDigits: 2,
        number: 426,
        namePlural: "Lesotho lotis",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "MRU",
        name: "Mauritanian Ouguiya",
        symbol: "UM",
        flag: "MRU",
        decimalDigits: 2,
        number: 929,
        namePlural: "Mauritanian ouguiyas",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "SLL",
        name: "Sierra Leonean Leone",
        symbol: "Le",
        flag: "SLL",
        decimalDigits: 2,
        number: 694,
        namePlural: "Sierra Leonean leones",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "STN",
        name: "São Tomé and Príncipe Dobra",
        symbol: "Db",
        flag: "STN",
        decimalDigits: 2,
        number: 930,
        namePlural: "São Tomé and Príncipe dobras",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "SSP",
        name: "South Sudanese Pound",
        symbol: "£",
        flag: "SSP",
        decimalDigits: 2,
        number: 728,
        namePlural: "South Sudanese pounds",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "VES",
        name: "Venezuelan Bolívar Soberano",
        symbol: "Bs.",
        flag: "VES",
        decimalDigits: 2,
        number: 928,
        namePlural: "Venezuelan bolívars soberanos",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: false,
        symbolOnLeft: true,
      ),
      Currency(
        code: "GNF",
        name: "Guinean Franc",
        symbol: "FG",
        flag: "GNF",
        decimalDigits: 0, // GNF has no decimal units
        number: 324, // ISO 4217 currency code number for GNF
        namePlural: "Guinean francs",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: true,
        symbolOnLeft: false,
      ),

    ];


    return missingCurrencies;
  }

  static double roundTo2Decimal(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static setupInvoiceInitials(String invoiceHeading, String date) async {
    await DatabaseHelper.instance.database;
    Utils.INVOICE_DATE = date;
    List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();
    print('NAME '+farmSetup.elementAt(0).name);
    print("LOCATION "+farmSetup.elementAt(0).location);
    print("IMAGE "+farmSetup.elementAt(0).image);
    print("DATE "+farmSetup.elementAt(0).date);

    Utils.INVOICE_LOGO_STR = farmSetup
        .elementAt(0)
        .image;
    Utils.INVOICE_HEADING = farmSetup
        .elementAt(0).name;

    print(date);
    print(invoiceHeading);
  }

  static List<CustomCategory> getDefaultFlockCatgories() {
   List<CustomCategory> defaultCategories = [];
   CustomCategory modifyBirds = CustomCategory(name:"Modify Birds", itemtype: "Default", cat_type: "Birds FLock", unit: "num", enabled: 1, icon: Icons.add);
   modifyBirds.cIcon = "assets/birds.png";

   CustomCategory eggCollection = CustomCategory(name:"EGG_COLLECTION", itemtype: "Default", cat_type: "EGG_COLLECTION".tr(), unit: "num", enabled: 1, icon: Icons.add);
   eggCollection.cIcon = "assets/egg.png";

   CustomCategory feeding = CustomCategory(name:"DAILY_FEEDING", itemtype: "Default", cat_type: "Feed Consumption".tr(), unit: "kg", enabled: 1, icon: Icons.add);
   feeding.cIcon = "assets/feed.png";

   CustomCategory health = CustomCategory(name:"BIRDS_HEALTH", itemtype: "Default", cat_type: "Medical".tr(), unit: "num", enabled: 1, icon: Icons.add);
   health.cIcon = "assets/health.png";

   CustomCategory finance = CustomCategory(name:"INCOME_EXPENSE", itemtype: "Default", cat_type: "Finance".tr(), unit: "currency", enabled: 1, icon: Icons.add);
   finance.cIcon = "assets/income.png";

   defaultCategories.add(modifyBirds);
   defaultCategories.add(eggCollection);
   defaultCategories.add(feeding);
   defaultCategories.add(health);
   defaultCategories.add(finance);

   return defaultCategories;

  }

  static Future<void> setupAds() async {
    bool isInApp = await SessionManager.getInApp();
    if(isInApp){
      Utils.isShowAdd = false;
      hideBanner();
    }
    else{
      Utils.isShowAdd = true;
      inititalize();
    }

  }
  static Future<void> inititalize() async {
    // CAS.setDebugMode(true);

    // CAS.setFlutterVersion("3.10.3");
    //
    // ManagerBuilder builder = CAS.buildManager();
    // builder.withInitializationListener(new InitializationListenerWrapper());
    // // builder.withTestMode(true);
    // // CAS.addTestDeviceId("5BC971590B20B4500231D53345928594");
    // builder.withCasId("com.zaheer.poultry");
    //
    // builder.withConsentFlow(CAS.buildConsentFlow().withDismissListener(new DismissListenerWrapper()));
    // builder.withAdTypes(
    //     AdTypeFlags.Interstitial | AdTypeFlags.Banner );
    // manager = builder.initialize();
    //
    // CAS.validateIntegration();
    if(Utils.isShowAdd){
      createBanner();
    }
  }
  static Future<void> showInterstitial() async {
    if(Utils.isShowAdd){

      Future.delayed(const Duration(seconds: 0), () {
        if(iShowInterStitial){
          iShowInterStitial = false;
          _createInterstitialAd();
          // manager?.showInterstitial(new InterstitialListenerWrapper());
        }
        else{
          iShowInterStitial = true;
        }
      });
    }
  }
  static void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Utils.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _interstitialAd!.setImmersiveMode(true);
            Future.delayed(Duration(seconds: 0), () {
              _interstitialAd!.show();
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
          },
        ));
  }
   static Future<void> createBanner() async {
      _bannerAd = BannerAd(
        adUnitId: Utils.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
              _isBannerAdReady = true;
          },
          onAdFailedToLoad: (ad, err) {
            print('Failed to load a banner ad: ${err.message}');
            _isBannerAdReady = false;
            ad.dispose();
          },
        ),
      );

      _bannerAd?.load();

    // view = manager?.getAdView(AdSize.Adaptive);
    // view?.setAdListener(new AdaptiveBannerListener());
    // view?.setBannerPosition(AdPosition.TopCenter);
    // view?.showBanner();
  }
  static Future<void> hideBanner() async {
    // view?.hideBanner();
  }

  static bool checkIfContains(List<String> list ,String unit) {
    bool contains = false;
    for(int i=0;i<list.length;i++){
      if(unit == list[i])
      {
        contains = true;
        break;
      }
    }

    return contains;
  }

  static double getWidthResized(double input) {
    double tempVar = 0;
    tempVar = (WIDTH_SCREEN / _standardWidth) * input;
    tempVar = WIDTH_SCREEN - tempVar;
    tempVar = WIDTH_SCREEN - tempVar;
    if(isDebug){
     // print('Resized Val $tempVar');
    }
    return tempVar;
  }

  static Color getScreenBackground(){
   return Color(0xFFF0F0F3);
  }

  static Future onSelectNotification(String? payload) async {
    // showDialog(
    //   context: context,
    //   builder: (_) {
    //     updateData();
    //     // var collection = FirebaseFirestore.instance.collection('Users');
    //     // await collection
    //     //     .doc(DateTime.now().millisecondsSinceEpoch.toString()) // <-- Doc ID where data should be updated.
    //     //     .set(user);
    //     return  AlertDialog(
    //       title: Text("PayLoad"),
    //       content: Text("Payload : $payload"),
    //     );
    //   },
    // );
  }





  static Color getSciFiThemeColor(){
    return const Color.fromRGBO(255, 255, 255, 1);
  }
  static Color getSciFiThemeColorHalf(){
    return const Color.fromRGBO(242, 242, 242, 1);
  }
  static Color getThemeColor(){
    return const Color.fromRGBO(255, 255, 255, 1);
  }

  static double getHeightResized(double input) {
    double tempVar = 0;
    tempVar = (HEIGHT_SCREEN / _standardheight) * input;
    tempVar = HEIGHT_SCREEN - tempVar;
    tempVar = HEIGHT_SCREEN - tempVar;
    if(isDebug){
      //print('Resized Val $tempVar');
    }
    return tempVar;
  }



  static String get bannerAdUnitId {
    if (ISTESTACCOUNT) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      } else {
        throw new UnsupportedError('Unsupported platform');
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2367135251513556/4686866841';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2367135251513556/3026729721';
      } else {
        throw new UnsupportedError('Unsupported platform');
      }
    }
  }

  static String get interstitialAdUnitId {
    if (ISTESTACCOUNT) {
      if (Platform.isAndroid) {
        return "ca-app-pub-3940256099942544/1033173712";
      } else if (Platform.isIOS) {
        return "ca-app-pub-3940256099942544/4411468910";
      } else {
        throw new UnsupportedError("Unsupported platform");
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2367135251513556/5356132442';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2367135251513556/3625162389';
      } else {
        throw new UnsupportedError('Unsupported platform');
      }
    }
  }

  static String get rewardedAdUnitId {
    if (ISTESTACCOUNT) {
      if (Platform.isAndroid) {
        return "ca-app-pub-3940256099942544/5354046379";
      } else if (Platform.isIOS) {
        return "ca-app-pub-3940256099942544/6978759866";
      } else {
        throw new UnsupportedError("Unsupported platform");
      }
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2367135251513556/2933923124';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-2367135251513556/4974477114';
      } else {
        throw new UnsupportedError('Unsupported platform');
      }
    }
  }
  static int getDayDifferenceBetweenDates(String selectedDate){
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    var diff = currentTime - int.parse(selectedDate);
    var day = (diff/86400000);
    // var day = (diff/60000);

    var dayInt = day.floor();
    return dayInt;
  }
  static int getDayRemaining(String total, int difference){
    int tot = int.parse(total);
    int dayRem = (tot-difference);
    if(dayRem<1){
      dayRem = 0;
    }
    return dayRem;
  }
  static double getPercentage(String total, int difference){
    int tot = int.parse(total);
    // double remaining = (tot-difference).toDouble();

    double d = (difference/tot).toDouble();
    if(d>1.0){
      d = 1.0;
    }
    return d;
  }

  static String getFormattedDate(String date){

   try {
     if (date.toLowerCase().contains("date")) {
       return "Choose date".tr();
     }

     var inputFormat = DateFormat('yyyy-MM-dd');
     var inputDate = inputFormat.parse(date); // <-- dd/MM 24H format

     var outputFormat = DateFormat('dd MMM yyyy');
     var outputDate = outputFormat.format(inputDate);
     return outputDate;
   }
   catch(ex){
     print(ex);
     return date;
   }
  }

  static String getReminderFormattedDate(String date){

    if (date.toLowerCase().contains("date")){
      return "Choose date".tr();
    }

    if (date.toLowerCase().contains("am") || date.toLowerCase().contains("pm")){
      return date;
    }

    var inputFormat = DateFormat('yyyy-MM-dd hh:mm');
    var inputDate = inputFormat.parse(date); // <-- dd/MM 24H format

    var outputFormat = DateFormat('dd MMM yyyy - hh:mm a');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

  static void showToast(String msg){
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static Color getThemeColorBlue2() {
    Color themeColor = Color.fromRGBO(2, 86, 185, 1);
    return themeColor;
  }

  static Color getThemeColorBlue() {
    Color themeColor = Color.fromRGBO(2, 83, 179, 1);
    return themeColor;
  }
  static Widget getAdBar(){
    if(isShowAdd){
      return Container(width: WIDTH_SCREEN,height: 60,
        color: Colors.white,
        child:_isBannerAdReady?Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 60.0 ,
            width: Utils.WIDTH_SCREEN,
            child: new AdWidget(ad: _bannerAd!),
          ),
        ):Container(),
      );

    }
    return Container(width: WIDTH_SCREEN,height: 0,);
  }
  static Widget getDistanceBar(){
    if(isShowAdd){
      return Container(width: WIDTH_SCREEN,height: 60,
        child:_isBannerAdReady?Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 60.0 ,
            width: Utils.WIDTH_SCREEN,
          ),
        ):Container(),
      );

    }
    return Container(width: WIDTH_SCREEN,height: 0,);
  }
  static getSelectedLanguage() async {

    String? language = await SessionManager.getSelectedLanguage();
    if(language == "" || language == "en"){
      return Languages.english;
    }
    else if(language == "ar"){
      return Languages.arabic;
    }
    else if(language == "ar"){
      return Languages.arabic;
    }
    else if(language == "ru"){
      return Languages.russian;
    }
    else if(language == "fa"){
      return Languages.persian;
    }
    else if(language == "de"){
      return Languages.german;
    }
    else if(language == "ja"){
      return Languages.japanese;
    }
    else if(language == "ko"){
      return Languages.korean;
    }
    else if(language == "pt"){
      return Languages.portuguese;
    }
    else if(language == "tr"){
      return Languages.turkish;
    }
    else if(language =="fr"){
      return Languages.french;
    }
    else if(language =="id"){
      return Languages.indonesian;
    }
    else if(language =="hi"){
      return Languages.hindi;
    }
    else if(language =="es"){
      return Languages.spanish;
    }
    else if(language =="zh_Hans" || language =="zh"){
      return Languages.chineseSimplified;
    }
    else if(language =="uk"){
      return Languages.ukrainian;
    }
    else if(language =="pl"){
      return Languages.polish;
    }
    else if(language =="bn"){
      return Languages.bengali;
    }
    else if(language =="te"){
      return Languages.telugu;
    }
    else if(language =="ta"){
      return Languages.tamil;
    }
    else if(language =="ur"){
      return Languages.urdu;
    }
    else if(language =="el"){
      return Languages.greek;
    }
    return Languages.english;
  }

  static Future<bool> checkAppLaunch() async{

   return SessionManager.getAppLaunch();

  }

  static setupCompleted() async{

   SessionManager.setupComplete();
  }

  static Widget getCustomEmptyMessage(String imageName, String message) {
   return  Center(
     child: Container(
       margin: EdgeInsets.only(top: 50),
       child: Column(
         children: [
           Image.asset(imageName, width: 100, height: 100,),
           SizedBox(height: 10,),
           Text(message.tr(), style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),),
         ],
       ),
     ),
   );
  }

  static setSelectedLanguage(Language language,BuildContext context) async {

    String languageName = "";
    if(language.isoCode =="en"){
      languageName = "en";
    }
    else if(language.isoCode =="ar"){
      languageName = "ar";
    }
    else if(language.isoCode =="ru"){
      languageName = "ru";
    }
    else if(language.isoCode =="fa"){
      languageName = "fa";
    }
    else if(language.isoCode =="de"){
      languageName = "de";
    }
    else if(language.isoCode =="ja"){
      languageName = "ja";
    }
    else if(language.isoCode =="ko"){
      languageName = "ko";
    }
    else if(language.isoCode =="pt"){
      languageName = "pt";
    }
    else if(language.isoCode =="tr"){
      languageName = "tr";
    }
    else if(language.isoCode =="fr"){
      languageName = "fr";
    }
    else if(language.isoCode =="id"){
      languageName = "id";
    }
    else if(language.isoCode =="hi"){
      languageName = "hi";
    }
    else if(language.isoCode =="es"){
      languageName = "es";
    }
    else if(language.isoCode =="zh_Hans"){
      languageName = "zh";
    }
    else if(language.isoCode =="uk"){
      languageName = "uk";
    }
    else if(language.isoCode =="pl"){
      languageName = "pl";
    }
    else if(language.isoCode =="bn"){
      languageName = "bn";
    }
    else if(language.isoCode =="te"){
      languageName = "te";
    }
    else if(language.isoCode =="ta"){
      languageName = "ta";
    }
    else if(language.isoCode =="ur"){
      languageName = "ur";
    }
    else if(language.isoCode =="el"){
      languageName = "el";
    }

    print(language.isoCode);
    EasyLocalization.of(context)?.setLocale(Locale(languageName));
    await SessionManager.setSelectedLanguage(languageName);
  }

  // COMPRESS IMAGE

  static Future<String> generateRandomFileName() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    if (Platform.isAndroid) {
      //Exposing the database
      //we cannot do that for iPhone
      appDocDir = (await getExternalStorageDirectory())!;
    }

    String appDocPath = appDocDir.path;
    var uuid = Uuid();
    return "$appDocPath/resumeapp-${uuid.v1()}.jpg";
  }
  static Future<File> convertToJPGFileIfRequiredWithCompression(
      File file) async {
    print(file.path);
    print("converting file");

    int fileSize = await file.length();
    int quality = 10;


    print( "convertToJPGFileIfRequiredWithCompression => ${quality}");

    Uint8List? image = await FlutterImageCompress.compressWithFile(file.path,
        format: CompressFormat.jpeg, quality: quality);
    String newfilePath = file.path.toLowerCase();
    newfilePath = await generateRandomFileName();
    print("path is now => ${newfilePath}");
    final fileToWrite = File(newfilePath);

    print("going to write file");

    int length = await file.length();

    print("file lenght before conversion = ${length}");

    File fileToReturn = await fileToWrite.writeAsBytes(image!,
        flush: true, mode: FileMode.write);

    length = await fileToReturn.length();

    return fileToReturn;
  }


  //LOCAL NOTIFICATION

  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static Future<void> showNotification(int id, String title, String body, int time) async {

    try{
      initNotification();
      tz.initializeTimeZones();
      print("Notification Pressed");

      await flutterLocalNotificationsPlugin.zonedSchedule(
          generateRandomNumber(),
          title,
          body,
          tz.TZDateTime.now(tz.local).add(Duration(seconds: time)),
          const NotificationDetails(
            // Android details
            android: AndroidNotificationDetails('main_channel', 'Main Channel',
              channelDescription: "kelsey",
              importance: Importance.max,
              priority: Priority.max,

            ),
            // iOS details
            iOS: DarwinNotificationDetails(
              sound: 'default.wav',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          // Type of time interpretation
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          androidAllowWhileIdle: true);

    }catch(ex){

    }
  }

  static initNotification(){
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = new DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android:initializationSettingsAndroid, iOS:initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Click Notification Event Here

      },
    );
    flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((value) {
      // Click Notification Event Here
    });
  }

  static int generateRandomNumber(){
    int max = 327641;
    int min = 10;
    Random rnd = new Random();
    int r = min + rnd.nextInt(max - min);
    return r;
  }

  static Future<bool> isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
          false;

      return granted;
    }
    return false;
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
      await androidImplementation?.requestNotificationsPermission();

    }
  }

}
