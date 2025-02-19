import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auto_egg_collection.dart';
import 'auto_feed_management.dart';
import 'database/databse_helper.dart';
import 'farm_setup_screen.dart';
import 'filter_setup_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'consume_store.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreen createState() => _SettingsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SettingsScreen extends State<SettingsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  String adRemovalID = "removeadspoultry";
  final bool _kAutoConsume = Platform.isIOS || true;
  List<String> _kProductIds = <String>[
  ];

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  List<String> _consumables = <String>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  final supportedLanguages = [
    Languages.english,
    Languages.arabic,
    Languages.russian,
    Languages.persian,
    Languages.german,
    Languages.japanese,
    Languages.korean,
    Languages.portuguese,
    Languages.turkish,
    Languages.french,
    Languages.indonesian,
    Languages.hindi,
    Languages.spanish,
    Languages.chineseSimplified,
    Languages.ukrainian,
    Languages.polish,
    Languages.bengali,
    Languages.telugu,
    Languages.tamil,
    Languages.greek

  ];
  late Language _selectedCupertinoLanguage;
  bool isGetLanguage = false;
  final Uri _url = Uri.parse('https://chat.whatsapp.com/DT7MfbSM53G8MYoe4ufmsU');
  final Uri _url2 = Uri.parse('https://whatsapp.com/channel/0029Vb358El3gvWaZBGYBU28');

  getLanguage() async {
    _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
    setState(() {
      isGetLanguage = true;

    });

  }
  Widget _buildDropdownItem(Language language) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 8.0,
        ),
        if(language.isoCode !="pt" && language.isoCode !="zh_Hans")
          Text("${language.name} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="pt")
          Text("${'Portuguese'} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="zh_Hans")
          Text("${'Chinese'} (zh)",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
      ],
    );
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();

  }

  @override
  void initState() {
    loadInAppData();
    beforeInit();
    super.initState();
    setUpInitial();
    Utils.setupAds();
    getLanguage();
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
  shareFiles() async {
    File newPath = await DatabaseHelper.getFilePathDB();
    XFile file = new XFile(newPath.path);

    final result = await Share.shareXFiles([file], text: 'BACKUP'.tr());

    if (result.status == ShareResultStatus.success) {
      print('Backup completed');
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
    return SafeArea(child: Scaffold(
      body:SafeArea(
        top: false,
        child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Colors.white,
            // color: Utils.getScreenBackground(),
            child:SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [

              Utils.getDistanceBar(),
              // ClipRRect(
              //   borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
              //   child: Container(
              //     decoration: BoxDecoration(
              //        boxShadow: [
              //         BoxShadow(
              //           color: Utils.getThemeColorBlue(), //(x,y)
              //         ),
              //       ],
              //     ),
              //     child: Row(
              //       children: [
              //         Container(
              //           alignment: Alignment.center,
              //           width: 52,
              //           height: 52,
              //           child: Icon(Icons.settings,
              //               color: Colors.white),
              //         ),
              //         Container(
              //
              //             child: Text(
              //               'SETTINGS'.tr(),
              //               textAlign: TextAlign.start,
              //               style: TextStyle(
              //                   color: Colors.white,
              //                   fontSize: 18,
              //                   fontWeight: FontWeight.bold),
              //             )),
              //
              //       ],
              //     ),
              //   ),
              // ),
              // if(isGetLanguage)
              //   Visibility(
              //     visible: false,
              //     child: Container(
              //       decoration: BoxDecoration(
              //           borderRadius: BorderRadius.all(Radius.circular(3)),
              //           color: Colors.white,
              //           border: Border.all(color: Colors.blueAccent,width: 1.0)
              //       ),
              //       height: 60,
              //       margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
              //
              //       child:
              //
              //       Column(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           Container(height: 20,
              //
              //             color: Colors.white,
              //             child: Align(
              //               alignment: Alignment.center,
              //               child:Text("Language".tr(),
              //                 textAlign: TextAlign.center,
              //                 style: new TextStyle(
              //                   fontSize: 13.0,
              //                   fontWeight: FontWeight.normal,
              //                   color: Colors.black54,
              //
              //                 ),
              //               ),),
              //           ),
              //
              //           Container(
              //             width: Utils.getWidthResized(200),height:24,color: Colors.white,
              //             child: LanguagePickerDropdown(
              //               initialValue: _selectedCupertinoLanguage,
              //               itemBuilder: _buildDropdownItem,
              //               languages: supportedLanguages,
              //               onValuePicked: (Language language) {
              //                 _selectedCupertinoLanguage = language;
              //                 // Utils.showToast(language.isoCode);
              //                 Utils.setSelectedLanguage(_selectedCupertinoLanguage,context);
              //               },
              //             ),
              //           ),
              //
              //         ],)
              //
              //       ,),
              //   ),

              SizedBox(height: 12,),
              Container(
                  padding: EdgeInsets.all(0),
                  margin: EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                    color: Colors.white,
                    boxShadow: [

                    ],
                  ), child: Column(
                children: [
                  // Align(
                  //   alignment: Alignment.center,
                  //   child:
                  //   Text('Basic Settings'.tr(),style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                  // ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FarmSetupScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),

                        color: Colors.white,
                         border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 5,bottom: 8),
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
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

                                    SizedBox(width: 2,),
                                    Icon(Icons.account_balance_rounded,color: Utils.getThemeColorBlue(),size: 20,),
                                    SizedBox(width: 8,),
                                    Text('FARM_MANAGMENT'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CategoryScreen()),

                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),

                          color: Colors.white,
                          border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                      child: Container(
                        height: 48,
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

                                    SizedBox(width: 2,),

                                    Icon(Icons.account_tree,color: Utils.getThemeColorBlue(),size: 20,),
                                    SizedBox(width: 8,),
                                    Text('CATEGORY_MANAGMENT'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  AutomaticFeedManagementScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),

                          color: Colors.white,
                          border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 5,bottom: 8),
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(),
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
                                    SizedBox(width: 2,),
                                    Image.asset("assets/auto_feed_icon.png", color: Utils.getThemeColorBlue(), width: 20, height: 20,),
                                    SizedBox(width: 8,),
                                    Text('AUTO_FEED_MANAGMENT'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),
                          ],),),
                    ),
                  ),

                  /*InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  AutomaticEggCollectionScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),

                          color: Colors.white,
                          border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 5,bottom: 8),
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
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

                                    SizedBox(width: 2,),
                                    Image.asset("assets/eggs_tray.png", color: Utils.getThemeColorBlue(), width: 20, height: 20,),
                                    SizedBox(width: 8,),
                                    Text('AUTO_EGG_MANAGMENT'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),*/
                 /* InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ManageFlockScreen()),

                      );
                    },
                    child: Container(
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
                        height: 52,
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

                                    Icon(Icons.group_work_outlined,color: Utils.getThemeColorBlue(),),
                                    SizedBox(width: 4,),
                                    Text('FLOCK_MANAGMENT'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),*/
                  // SizedBox(height: 4,),
                  // InkWell(
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //           builder: (context) => const AllEventsScreen()),
                  //
                  //     );
                  //   },
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.all(Radius.circular(3)),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.grey.withOpacity(0.5),
                  //           spreadRadius: 2,
                  //           blurRadius: 2,
                  //           offset: Offset(0, 1), // changes position of shadow
                  //         ),
                  //       ],
                  //       color: Colors.white,
                  //       //  border: Border.all(color: Colors.blueAccent,width: 1.0)
                  //     ),
                  //     margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                  //     child: Container(
                  //       height: 52,
                  //       padding: EdgeInsets.all(10),
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.all(Radius.circular(5)),
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: Colors.white, //(x,y)
                  //           ),
                  //         ],
                  //       ),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.center,
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //
                  //         children: [
                  //           Align(
                  //               alignment: Alignment.topLeft,
                  //               child: Row(
                  //                 children: [
                  //
                  //                   Icon(Icons.notification_add,color: Utils.getThemeColorBlue(),),
                  //                   SizedBox(width: 4,),
                  //                   Text('Events'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                  //                 ],
                  //               )),
                  //
                  //         ],),),
                  //   ),
                  // ),
                  SizedBox(height: 0,),
                  InkWell(
                    onTap: ()
                    {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  FilterSetupScreen(inStart: false,)),

                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),

                          color: Colors.white,
                          border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                      child: Container(
                        height: 52,
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
                                    SizedBox(width: 2,),
                                    Icon(Icons.filter_list,color: Utils.getThemeColorBlue(),size: 20,),
                                    SizedBox(width: 8,),
                                    Text('All Data Filters'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),
                  /*Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Us',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: Icon(Icons.chat, color: Colors.green),
                          title: Text('Contact via WhatsApp'),
                          subtitle: Text('Chat with us directly on WhatsApp'),
                          trailing: Icon(Icons.arrow_forward, color: Colors.green),
                          onTap: () => _openWhatsApp(whatsappNumber),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.group, color: Colors.blue),
                          title: Text('Join Our WhatsApp Channel'),
                          subtitle: Text('Stay updated with our latest news and updates'),
                          trailing: Icon(Icons.arrow_forward, color: Colors.blue),
                          onTap: () => _openWhatsAppChannel(whatsappChannelLink),
                        ),
                      ],
                    ),
                  ),*/
                ],
              ),),


              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    color: Colors.white,
                  boxShadow: [
                    ]
                ),
                child: Column(children: [
                Align(
                  alignment: Alignment.center,
                  child:
                  Text('BACK_UP_RESTORE_MESSAGE'.tr(),style: TextStyle(fontSize: 20,fontFamily: 'Roboto', fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                ),
                SizedBox(height: 4,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [


                  InkWell(
                    onTap: () {
                      shareFiles();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        boxShadow: [

                        ],
                        color: Colors.white,
                        border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.all(10),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white, //(x,y)
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  children: [

                                    Icon(Icons.backup,color: Utils.getThemeColorBlue(),size: 25,),
                                    Text("BACKUP".tr(),style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await DatabaseHelper.importDataBaseFile(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                          boxShadow: [

                          ],
                          color: Colors.white,
                          border: Border.all(color: Utils.getThemeColorBlue(),width: 0.5)
                      ),
                      margin: EdgeInsets.all(10),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white, //(x,y)
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  children: [

                                    Icon(Icons.restore,color: Utils.getThemeColorBlue(),size: 25,),
                                    Text("RESTORE".tr(),style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),

                ],),


              ],),),

              if(Utils.isShowAdd)
              Container(width: Utils.WIDTH_SCREEN,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(6)),

                    color: Utils.getThemeColorBlue(),
                    border: Border.all(color: Colors.blueAccent,width: 1.0)
                ),
                margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                padding: EdgeInsets.only(left: 0,right: 0,top: 10,bottom: 10),

                child: Column(
                children: [
                  Text('ADS_REMOVAL'.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Align(
                      alignment: Alignment.center,
                      child:Text("ONLY_FOR".tr(),
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.white70,
                            fontFamily: 'PTSANS'
                        ),
                      ),),
                    if(_products!=null && _products.length>0)
                      Align(
                        alignment: Alignment.center,
                        child:Text(" ${_products[0].price.toString()}",
                          textAlign: TextAlign.center,
                          style: new TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.white70,
                              fontFamily: 'PTSANS'
                          ),
                        ),),
                  ],),
                  SizedBox(height: 8,),
                  InkWell(
                    onTap: () {
                      PurchaseParam purchaseParam = PurchaseParam(productDetails: _products[0]);
                      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6)),

                          color: Color.fromRGBO(255, 255, 255, 0.5),
                          border: Border.all(color: Colors.transparent,width: 0.0)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 0,bottom: 0),
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.5),

                          borderRadius: BorderRadius.all(Radius.circular(5)),


                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  children: [

                                    SizedBox(width: 4,),
                                    Icon(Icons.remove_circle_outline,color: Utils.getThemeColorBlue(),size: 24,),
                                    SizedBox(width: 6,),
                                    Text('REMOVE_ADS'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),
                  SizedBox(height: 10,),
                  InkWell(
                    onTap: () {
                      _inAppPurchase.restorePurchases();

                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),

                          color: Color.fromRGBO(255, 255, 255, 0.5),
                          border: Border.all(color: Colors.transparent,width: 0.0)
                      ),
                      margin: EdgeInsets.only(left: 12,right: 12,top: 0,bottom: 0),
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.5),


                          borderRadius: BorderRadius.all(Radius.circular(6)),


                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  children: [

                                    SizedBox(width: 4,),
                                    Icon(Icons.settings_backup_restore,color: Utils.getThemeColorBlue(),size: 25,),
                                    SizedBox(width: 8,),
                                    Text('RESTORE_PREMIUM'.tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                  ],
                                )),

                          ],),),
                    ),
                  ),

                ],
              ),
              ),

              Padding(padding: EdgeInsets.only(left: 16,right: 12,top: 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:Text("Contact Us".tr(),
                    textAlign: TextAlign.left,
                    style: new TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),),),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  InkWell(
                    onTap: (){
                      _launchUrl();
                    },
                    child:Container(width: Utils.WIDTH_SCREEN/2-20,height: 100,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          boxShadow: [
                            new BoxShadow(
                              color: Color.fromRGBO(240, 240, 240, 1),
                              blurRadius: 2.0,
                            ),
                          ],
                          borderRadius: const BorderRadius.all(
                              Radius.circular(8.0)),
                          border: Border.all(
                            color:  Color.fromRGBO(125, 125, 125, 0.5),
                            width: 0.0,
                          ),
                        ),
                        child:Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(MdiIcons.whatsapp,color: Colors.black54,size: 34,),
                            Padding(padding: EdgeInsets.only(left: 8,right: 8,bottom: 0,top: 4),
                              child: Align(
                                alignment: Alignment.center,
                                child:Text("Ask a question on Whatsapp".tr(),
                                  textAlign: TextAlign.center,
                                  style: new TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black54,
                                      fontFamily: 'PTSans'
                                  ),
                                ),),),


                          ],)

                    ),),
                  Container(width: 14,height: 120,),
                  InkWell(
                    onTap: (){
                      _launchUrl2();
                    },
                    child:Container(width: Utils.WIDTH_SCREEN/2-20,height: 100,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          boxShadow: [
                            new BoxShadow(
                              color: Color.fromRGBO(240, 240, 240, 1),
                              blurRadius: 2.0,
                            ),
                          ],
                          borderRadius: const BorderRadius.all(
                              Radius.circular(8.0)),
                          border: Border.all(
                            color:  Color.fromRGBO(125, 125, 125, 0.5),
                            width: 0.0,
                          ),
                        ),
                        child:Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(MdiIcons.whatsapp,color: Colors.green,size: 40,),
                            Padding(padding: EdgeInsets.only(left: 8,right: 8,bottom: 0,top: 4),
                              child: Align(
                                alignment: Alignment.center,
                                child:Text("For daily updates, join".tr(),
                                  textAlign: TextAlign.center,
                                  style: new TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black54,
                                      fontFamily: 'PTSans'
                                  ),
                                ),),),
                            Padding(padding: EdgeInsets.only(left: 0,right: 0,bottom: 0),
                              child: Align(
                                alignment: Alignment.center,
                                child:Text("Easy Farming Community".tr(),
                                  textAlign: TextAlign.center,
                                  style: new TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.green,
                                      fontFamily: 'PTSans'
                                  ),
                                ),),),


                          ],)

                    ),),

                ],),
              Padding(padding: EdgeInsets.only(left: 16,right: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:Text("NOTE_DETAIL".tr(),
                    textAlign: TextAlign.left,
                    style: new TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),),),

            ]
      ),),),),),);
  }

  void addNewCollection(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewFeeding()),
    );
  }
  showInAppDialog(BuildContext context, String message) {

    // set up the button
    Widget okButton = TextButton(
      child: Container(height: Utils.getHeightResized(44),width: Utils.WIDTH_SCREEN-Utils.getWidthResized(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(Utils.getHeightResized(4))),
          color:Utils.getSciFiThemeColor(),

        ),
        child:Align(
          alignment: Alignment.center,
          child:Text("PURCHASE NOW",
            textAlign: TextAlign.center,
            style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontFamily: 'PTSans'
            ),
          ),),
      ),
      onPressed: () {
        Navigator.of(context).pop();
        PurchaseParam purchaseParam = PurchaseParam(productDetails: _products[0]);

        _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);


      },
    );
    Widget restoreButton = TextButton(
      child:
      Container(height: Utils.getHeightResized(44),width: Utils.WIDTH_SCREEN-Utils.getWidthResized(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(Utils.getHeightResized(4))),
          color:Utils.getSciFiThemeColor(),

        ),
        child:Align(
          alignment: Alignment.center,
          child:Text("RESTORE_PREMIUM".tr(),
            textAlign: TextAlign.center,
            style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontFamily: 'PTSans'
            ),
          ),),
      ),

      onPressed: () {
        Navigator.of(context).pop();
        _inAppPurchase.restorePurchases();

      },
    );
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr(),
        style: new TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
            color: Colors.black,
            fontFamily: 'PTSans'
        ),
      ),
      onPressed: () {
        Navigator.of(context).pop();

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Align(
        alignment: Alignment.center,
        child:Text("APP_NAME",
          textAlign: TextAlign.center,
          style: new TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'PTSans'
          ),
        ),),
      backgroundColor: Colors.pink,
      content: Text(message,
        style: new TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            fontFamily: 'PTSans'
        ),),
      actions: [
        okButton,
        restoreButton,
        cancelButton
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
  callRemoveAdsFunction(){
    showInAppDialog(context,"PURCHASE_ONE_TIME".tr());

  }
  Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _consumables = consumables;
    });
  }
  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  Future<void> _launchUrl() async {

    if (!await launchUrl(
      _url,
      mode: LaunchMode.externalApplication, // Ensures opening in the app
    )) {
      throw 'Could not launch $_url2';
    }
  }
  Future<void> _launchUrl2() async {
    if (!await launchUrl(
      _url2,
      mode: LaunchMode.externalApplication, // Ensures opening in the app
    )) {
      throw 'Could not launch $_url2';
    }
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    print("Payment successfull");


    // IMPORTANT!! Always verify purchase details before delivering the product.
    if (purchaseDetails.productID == adRemovalID) {
      await ConsumableStore.save(purchaseDetails.purchaseID!);
      final List<String> consumables = await ConsumableStore.load();
      await SessionManager.setInApp(true);
      Utils.isShowAdd = false;
      Utils.setupAds();
      setState(() {
        _purchasePending = false;
        _consumables = consumables;
      });
    } else {
      setState(() {
        _purchases.add(purchaseDetails);
        _purchasePending = false;
      });
    }
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
  }
  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (Platform.isAndroid) {
          if (!_kAutoConsume && purchaseDetails.productID == adRemovalID) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
            _inAppPurchase.getPlatformAddition<
                InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }


  final String whatsappNumber = '+1234567890';
  final String whatsappChannelLink = 'https://chat.whatsapp.com/exampleChannelLink';

  void _openWhatsApp(String number) async {
    final whatsappUrl = 'https://wa.me/$number';
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      throw 'Could not launch $whatsappUrl';
    }
  }

  void _openWhatsAppChannel(String channelLink) async {
    if (await canLaunch(channelLink)) {
      await launch(channelLink);
    } else {
      throw 'Could not launch $channelLink';
    }
  }

  Future<void> confirmPriceChange(BuildContext context) async {
    // if (Platform.isAndroid) {
    //   final InAppPurchaseAndroidPlatformAddition androidAddition =
    //   _inAppPurchase
    //       .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    //   final BillingResultWrapper priceChangeConfirmationResult =
    //   await androidAddition.launchPriceChangeConfirmationFlow(
    //     sku: 'purchaseId',
    //   );
    //   if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
    //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //       content: Text('Price change accepted'),
    //     ));
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       content: Text(
    //         priceChangeConfirmationResult.debugMessage ??
    //             'Price change failed with code ${priceChangeConfirmationResult.responseCode}',
    //       ),
    //     ));
    //   }
    // }
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition =
      _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }
  GooglePlayPurchaseDetails? _getOldSubscription(
      ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    // This is just to demonstrate a subscription upgrade or downgrade.
    // This method assumes that you have only 2 subscriptions under a group, 'subscription_silver' & 'subscription_gold'.
    // The 'subscription_silver' subscription can be upgraded to 'subscription_gold' and
    // the 'subscription_gold' subscription can be downgraded to 'subscription_silver'.
    // Please remember to replace the logic of finding the old subscription Id as per your app.
    // The old subscription is only required on Android since Apple handles this internally
    // by using the subscription group feature in iTunesConnect.
    GooglePlayPurchaseDetails? oldSubscription;
    if (productDetails.id == adRemovalID &&
        purchases[adRemovalID] != null) {
      oldSubscription =
      purchases[adRemovalID]! as GooglePlayPurchaseDetails;
    }
    return oldSubscription;
  }
  loadInAppData(){
    _kProductIds.add(adRemovalID);
  }
  beforeInit(){
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        }, onDone: () {
          _subscription.cancel();
        }, onError: (Object error) {
          // handle error here.
        });
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _notFoundIds = <String>[];
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
      _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }
}
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

