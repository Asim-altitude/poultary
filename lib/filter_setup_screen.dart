import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'consume_store.dart';
class FilterSetupScreen extends StatefulWidget {
  bool inStart;
  FilterSetupScreen({Key? key,required this.inStart}) : super(key: key);

  @override
  _FilterSetupScreen createState() => _FilterSetupScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FilterSetupScreen extends State<FilterSetupScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;
  late BannerAd _bannerAd;
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



  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  int _dashboard_filter = 0;
  int _reports_filter = 0;
  int _others_filter = 0;

  @override
  void initState() {
    super.initState();

    getFilters();

    setUpInitial();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
  }

  setUpInitial() async {
    bool isInApp = await SessionManager.getInApp();
    if(isInApp){
      Utils.isShowAdd = false;
    }
    else{
      Utils.isShowAdd = true;
    }
  }


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
              "All Data Filters".tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
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
      body:SafeArea(

          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getScreenBackground
              (),
            child: Column(children: [
               if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),
              Expanded(child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:  [

                      Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),

                        ), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 1), // changes position of shadow
                                ),
                              ],
                              color: Colors.white,
                              //  border: Border.all(color: Colors.blueAccent,width: 1.0)
                            ),
                            margin: EdgeInsets.only(left: 12,right: 12,top: 5,bottom: 5),
                            child: Container(
                              height: 90,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white, //(x,y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Row(
                                        children: [

                                          Icon(Icons.filter_list,color: Utils.getThemeColorBlue(),),
                                          SizedBox(width: 4,),
                                          Text('Dashboard Filter'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Utils.getThemeColorBlue()),),

                                        ],
                                      )),
                                  getDashDropDownList(),
                                  //Text(filterList.elementAt(_dashboard_filter).tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),),


                                ],),),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 1), // changes position of shadow
                                ),
                              ],
                              color: Colors.white,
                              // border: Border.all(color: Colors.blueAccent,width: 1.0)
                            ),
                            margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                            child: Container(
                              height: 85,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white, //(x,y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Row(
                                        children: [

                                          Icon(Icons.filter_list,color: Utils.getThemeColorBlue(),),
                                          SizedBox(width: 4,),
                                          Text('Reports Filter'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Utils.getThemeColorBlue()),),

                                        ],
                                      )),
                                  getReportDropDownList(),
                                  //Text(filterList.elementAt(_reports_filter).tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),),

                                ],),),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 1), // changes position of shadow
                                ),
                              ],
                              color: Colors.white,
                              //  border: Border.all(color: Colors.blueAccent,width: 1.0)
                            ),
                            margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                            child: Container(
                              height: 85,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white, //(x,y)
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Row(
                                        children: [

                                          Icon(Icons.filter_list,color: Utils.getThemeColorBlue(),),
                                          SizedBox(width: 4,),
                                          Text('All Other Filters'.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Utils.getThemeColorBlue()),),

                                        ],
                                      )),
                                  // Text(filterList.elementAt(_others_filter).tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),),
                                  getOtherDropDownList(),
                                ],),),
                          ),
                          SizedBox(height: 4,),

                        ],
                      ),),
                    ]
                ),))
            ],),),),);
  }

  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String dash_filter_name = 'LAST6_MONTHS'.tr();
  String report_filter_name = 'LAST6_MONTHS'.tr();
  String other_filter_name = 'THIS_MONTH'.tr();

   void getFilters() async {

    _dashboard_filter = (await SessionManager.getDashboardFilter())!;
    _reports_filter = (await SessionManager.getReportFilter())!;
    _others_filter = (await SessionManager.getOtherFilter())!;

    dash_filter_name = filterList.elementAt(_dashboard_filter);
    report_filter_name = filterList.elementAt(_reports_filter);
    other_filter_name = filterList.elementAt(_others_filter);

    setState(() {

    });

   }

  Widget getDashDropDownList() {
    return Container(
      width: widthScreen/2,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: dash_filter_name,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            dash_filter_name = newValue!;
            _dashboard_filter = filterList.indexOf(dash_filter_name);
            SessionManager.updateFilterValue(SessionManager.dash_filter, _dashboard_filter);
          });
        },
        items: filterList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,

            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget getReportDropDownList() {
    return Container(
      width: widthScreen/2,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: report_filter_name,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            report_filter_name = newValue!;
            _reports_filter = filterList.indexOf(report_filter_name);
            SessionManager.updateFilterValue(SessionManager.report_filter, _reports_filter);
          });
        },
        items: filterList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,

            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget getOtherDropDownList() {
    return Container(
      width: widthScreen/2,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: other_filter_name,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            other_filter_name = newValue!;
            _others_filter = filterList.indexOf(other_filter_name);
            SessionManager.updateFilterValue(SessionManager.other_filter, _others_filter);
          });
        },
        items: filterList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,

            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


}

