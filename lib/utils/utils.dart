import 'dart:ffi';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/languages.dart';
import 'package:poultary/utils/session_manager.dart';
import '../CAS_Ads.dart';
import '../database/databse_helper.dart';
import '../model/egg_item.dart';
import '../model/egg_report_item.dart';
import '../model/farm_item.dart';
import '../model/feed_item.dart';
import '../model/feed_report_item.dart';
import '../model/feedflock_report_item.dart';
import '../model/finance_report_item.dart';
import '../model/flock.dart';
import '../model/flock_detail.dart';
import '../model/flock_report_item.dart';
import '../model/health_report_item.dart';
import '../model/med_vac_item.dart';
import '../model/transaction_item.dart';


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

  static final String appIdIOS     = "ca-app-pub-2367135251513556~4114934168";
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
  static Feeding? selected_feeding;
  static int selected_category = -1;
  static String selected_category_name = "";
  static TransactionItem? selected_transaction;
  static Vaccination_Medication? selected_med;
  static String vaccine_medicine = "All Medications/Vaccinations";
  static String INVOICE_LOGO_STR = "";
  static String INVOICE_HEADING = "";
  static String INVOICE_DATE = "";

  static String TOTAL_BIRDS_ADDED = "0";
  static String TOTAL_BIRDS_REDUCED = "0";
  static String TOTAL_ACTIVE_BIRDS = "0";

  static String TOTAL_EGG_COLLECTED = "100";
  static String TOTAL_EGG_REDUCED = "20";
  static String EGG_RESERVE = "80";

  static String TOTAL_INCOME = "0";
  static String TOTAL_EXPENSE = "0";
  static String NET_INCOME = "0";

  static String TOTAL_MEDICATIONS = "0";
  static String TOTAL_VACCINATIONS = "0";
  static String applied_filter = "";

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

  // static MediationManager? manager;
  // static CASBannerView? view;

  static setupInvoiceInitials(String invoiceHeading,String date) async {
    await DatabaseHelper.instance.database;

    List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();

    Utils.INVOICE_LOGO_STR = farmSetup
        .elementAt(0)
        .image;
    Utils.INVOICE_HEADING = farmSetup
        .elementAt(0).name;
    Utils.INVOICE_DATE = date;

    print(date);
    print(invoiceHeading);
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

    Utils.isShowAdd = false;
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

      Future.delayed(const Duration(seconds: 5), () {
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
            Future.delayed(Duration(seconds: 1), () {
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
        return 'ca-app-pub-2367135251513556/6925764489';
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
        return 'ca-app-pub-2367135251513556/1481866110';
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

    if (date.toLowerCase().contains("date")){
      return date;
    }

    var inputFormat = DateFormat('yyyy-MM-dd');
    var inputDate = inputFormat.parse(date); // <-- dd/MM 24H format

    var outputFormat = DateFormat('dd MMM yyyy');
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

  static Color getThemeColorBlue() {
    Color themeColor = Color.fromRGBO(2, 83, 179, 1);
    return themeColor;
  }
  static Widget getAdBar(){
    if(isShowAdd){
      return Container(width: WIDTH_SCREEN,height: 60,
        child:_isBannerAdReady?Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 60.0 ,
            width: Utils.WIDTH_SCREEN,
            child: AdWidget(ad: _bannerAd!),
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
    return Languages.english;
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

    print(language.isoCode);
    EasyLocalization.of(context)?.setLocale(Locale(languageName));
    await SessionManager.setSelectedLanguage(languageName);
  }





}
