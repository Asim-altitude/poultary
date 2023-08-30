import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../database/databse_helper.dart';
import '../model/egg_item.dart';
import '../model/farm_item.dart';
import '../model/feed_item.dart';
import '../model/flock.dart';
import '../model/flock_detail.dart';
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
  static final bool ISTESTACCOUNT = true;
  static late bool isShowAdd = false;
  static final String appIdIOS     = "ca-app-pub-2367135251513556~4114934168";
  static final String appIdAndroid = "ca-app-pub-2367135251513556~7089416015";
  static var box;


  static final String testIOS     = "ca-app-pub-3940256099942544~1458002511";
  static final String testAndroid = "ca-app-pub-3940256099942544~3347511713";

  static String currency = "USD";

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


  static setupInvoiceInitials(String invoiceHeading,String date) async {
    await DatabaseHelper.instance.database;

    List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();

    Utils.INVOICE_LOGO_STR = farmSetup
        .elementAt(0)
        .image;
    Utils.INVOICE_HEADING = invoiceHeading;
    Utils.INVOICE_DATE = date;

    print(date);
    print(invoiceHeading);
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
        return 'ca-app-pub-2367135251513556/9916542295';
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
        return 'ca-app-pub-2367135251513556/3351133949';
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




}
