import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'multiuser/model/sub_category_fb.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class SubCategoryScreen extends StatefulWidget {
  const SubCategoryScreen({Key? key}) : super(key: key);

  @override
  _SubCategoryScreen createState() => _SubCategoryScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SubCategoryScreen extends State<SubCategoryScreen> with SingleTickerProviderStateMixin, RefreshMixin {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.SUB_CATEGORY) {
        getSubCategoriesList();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  double widthScreen = 0;
  double heightScreen = 0;

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

  @override
  void initState() {
    super.initState();

    getSubCategoriesList();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

  }


  List<SubItem> categoryList = [];
  void getSubCategoriesList() async {

    await DatabaseHelper.instance.database;

    categoryList = await DatabaseHelper.getSubCategoryList(Utils.selected_category);

    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = Utils.selected_category_name;

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
      appBar: AppBar(
        title: Text(
          applied_filter_name.tr(),
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

      bottomNavigationBar: BottomAppBar(
    color: Colors.transparent,
    child: Container(
    height: 60,
    width: widthScreen,
    child: InkWell(
      onTap: () async {

        if (Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_settings")) {
          Utils.showMissingPermissionDialog(context, "edit_settings");
          return;
        }

        openPopup();
      },
      child: Container(
        width: widthScreen,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Utils.getThemeColorBlue(),
          borderRadius: const BorderRadius.all(
              Radius.circular(6.0)),
          border: Border.all(
            color:  Utils.getThemeColorBlue(),
            width: 2.0,
          ),
        ),
        margin: EdgeInsets.only(left: 0, right: 0),
        child: Text(
          "ADD_NEW".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    ),
    ),
    elevation: 0,
    ),
      body:SafeArea(
          child:Container(
          width: widthScreen,
          height: heightScreen ,

          color: Utils.getScreenBackground(),
            child:Column(children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),
              Expanded(child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:  [


                      SizedBox(height: 10,),
                      Container(
                        height: heightScreen - 220,
                        width: widthScreen,
                        child: ListView.builder(
                            controller: _controller,
                            itemCount: categoryList.length,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(3)),

                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey,width: 1.0)
                                ),
                                margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                                child: Row(
                                  children: [
                                    Row( children: [
                                      Column( children: [
                                        Container(

                                            width: (widthScreen - widthScreen/4)+6,
                                            margin: EdgeInsets.all(4) , padding: EdgeInsets.all(10), child: Text(categoryList.elementAt(index).name!.tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 18, color: Colors.black),)),
                                        // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                      ],),

                                    ]),
                                    Visibility(
                                      visible: categoryList.length==1? false : true,
                                      child: InkWell(
                                          onTap: () {
                                            showAlertDialog(context,index);
                                          },child: Container(width: 40,height: 40,child: Icon(Icons.cancel, color: Colors.red,),)),
                                    )
                                  ],
                                ),
                              );

                            }),
                      )

                    ]
                ),))
            ],),),),);
  }

  showAlertDialog(BuildContext context, int index) {

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

        if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_category")){
          Utils.showMissingPermissionDialog(context, "delete_category");
          return;
        }

        SubItem subItem = categoryList.elementAt(index);
        DatabaseHelper.deleteSubItem(subItem);

        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_category")){
          subItem.syncStatus = SyncStatus.DELETED;
          subItem.modified_by = Utils.currentUser!.email;
          subItem.last_modified = Utils.getTimeStamp();
          subItem.farm_id = Utils.currentUser!.farmId;
          await FireBaseUtils.updateSubCategory(subItem);
        }

        getSubCategoriesList();
        Navigator.pop(context);
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

  void openPopup() {

    final nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("New ".tr()+Utils.selected_category_name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Name'.tr(),
                      ),
                    ),

                    InkWell(
                      onTap: () async {
                        print(nameController.text);

                        if(!nameController.text.isEmpty){
                          SubItem subItem = SubItem(c_id: Utils.selected_category, name: nameController.text,
                            sync_id: Utils.getUniueId(),
                            syncStatus: SyncStatus.SYNCED,
                            last_modified: Utils.getTimeStamp(),
                            farm_id: Utils.currentUser != null? Utils.currentUser!.farmId : '',
                            modified_by: Utils.currentUser != null? Utils.currentUser!.email : '',);
                          await DatabaseHelper.insertNewSubItem(subItem);
                          getSubCategoriesList();

                          if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_category")){
                            await FireBaseUtils.addSubCategory(subItem);
                          }

                          Navigator.pop(context);
                          _scrollDown();
                        }


                      },
                      child: Container(
                        width: widthScreen,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Utils.getThemeColorBlue(),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(50.0)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        margin: EdgeInsets.all( 20),
                        child: Text(
                          "CONFIRM".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
        });
  }

  final ScrollController _controller = ScrollController();

// This is what you're looking for!
  void _scrollDown() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

}

