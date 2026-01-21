import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:language_picker/languages.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/all_events.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/sale_contractor_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/support_screen.dart';
import 'package:poultary/utils/about.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/premium_subscription_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auto_feed_management.dart';
import 'backup_screen.dart';
import 'database/databse_helper.dart';
import 'farm_setup_screen.dart';
import 'feed_batch_screen.dart';
import 'filter_setup_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'consume_store.dart';
import 'manage_flock_screen.dart';
import 'multiuser/classes/AdminProfile.dart';
import 'multiuser/classes/AuthGate.dart';
import 'multiuser/model/user.dart';
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
  bool isTrayEnabled = false;
  int traySize = 30;
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
    isTrayEnabled = await SessionManager.getBool(SessionManager.tray_enabled);
    traySize = await SessionManager.getInt(SessionManager.tray_size);

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


    AnalyticsUtil.logScreenView(screenName: "settings_screen");
  }

  MultiUser? admin = null;
  List<MultiUser> users = [];
  bool loggedIn = false;
  setUpInitial() async {

    bool isInApp = await SessionManager.getInApp();
    if(isInApp){
      Utils.isShowAdd = false;
    }
    else{
      Utils.isShowAdd = true;
    }

    loadUsers();
  }

  Future<void> loadUsers() async {
    loggedIn = await SessionManager.getBool(SessionManager.loggedIn);
    try
    {
      users = await DatabaseHelper.getAllUsers();
    }
    catch(ex){
      print(ex);
    }

    setState(() {

    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 8,
        automaticallyImplyLeading: (Utils.isMultiUSer && Utils.currentUser!.role.toLowerCase() != "admin")? true : false,
      ),
      body:SafeArea(
        top: false,
        child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Colors.white,
            // color: Utils.getScreenBackground(),
            child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [

              Utils.getDistanceBar(),

              // Farm & Inventory Section
              // Farm & Inventory Section
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Farm & Inventory'),
                      _buildSettingsTile(
                        context,
                        icon: Icons.account_balance,
                        title: 'FARM_MANAGMENT'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmSetupScreen())),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.manage_history_outlined,
                        title: 'FLOCK_MANAGMENT'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFlockScreen())),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.category,
                        title: 'CATEGORY_MANAGMENT'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen())),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.dataset,
                        title: 'Feed Batches'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeedBatchScreen())),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Reminders & Automation'),
                      _buildSettingsTile(
                        context,
                        icon: Icons.notifications_active,
                        title: 'Schedule Reminders'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllEventsScreen())),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.auto_mode,
                        title: 'Auto Feed Management'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AutomaticFeedManagementScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Eggs in tray'.tr(), style: Theme.of(context).textTheme.titleMedium),
                          Switch(
                            value: isTrayEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                isTrayEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (isTrayEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: traySize.toString(),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // Only allow digits (integers)
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Tray size',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (value) {
                                    traySize = int.tryParse(value) ?? traySize;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  if(traySize > 0) {
                                    SessionManager.setInt(traySize);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          'Tray size set to $traySize')),
                                    );
                                  }else{
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          'Tray size invalid')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Icon(Icons.save),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Business & Sales
              (Utils.isMultiUSer && Utils.currentUser!.role.toLowerCase() != 'admin')?
              SizedBox.shrink()
                  : Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Business & Sales'),
                      Visibility(
                        visible: true,
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.supervised_user_circle_sharp,
                          title: 'Users & Roles'.tr(),
                          onTap: ()  async {
                            if(Utils.isMultiUSer && Utils.currentUser!.role.toLowerCase() != 'admin')
                              {
                                Utils.showToast("Only Admin can use this feature.".tr());

                              }
                            else
                              {
                                bool hasIntroduced = await SessionManager.getBool("farm_intro");
                                if(!hasIntroduced){
                                  SessionManager.setBoolValue("farm_intro", true);
                                  showFarmAccountIntro(context);
                                }else{
                                //  SessionManager.setBoolValue("farm_intro", false);

                                  await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) =>
                                      !loggedIn
                                          ? AuthGate(isStart: false,)
                                          : AdminProfileScreen(users: Utils.currentUser!,)));
                                  loadUsers();
                                }

                               /* */
                              }
                          }
                        ),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.group_add,
                        title: 'Sale Contractors'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleContractorScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              // Tools & Data
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Tools & Data'),
                      _buildSettingsTile(
                        context,
                        icon: Icons.filter_alt_rounded,
                        title: 'All Data Filters'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilterSetupScreen(inStart: false))),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.backup,
                        title: 'BACK_UP_RESTORE_MESSAGE'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackupRestoreScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              // Help & Support
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Help & Support'),
                      _buildSettingsTile(
                        context,
                        icon: Icons.contact_support,
                        title: 'Contact & Support'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactSupportScreen())),
                      ), _buildSettingsTile(
                        context,
                        icon: Icons.rate_review,
                        title: 'Rate Us'.tr(),
                        onTap: () {
                          rateUs();
                        }
                      ), _buildSettingsTile(
                        context,
                        icon: Icons.share,
                        title: 'Share App'.tr(),
                        onTap: () {
                          Utils.shareApp();
                        }), _buildSettingsTile(
                        context,
                        icon: Icons.account_balance_outlined,
                        title: 'About App'.tr(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutAppPage())),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20,),
                if(Utils.isShowAdd)
                  _buildPremiumUpgradeTile(context),

                /* /// **Support Section Card**
                     Container(
                       margin: EdgeInsets.all(10),
                       padding: EdgeInsets.all(5),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(15),
                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           _buildSectionTitle('Contact & Support'),

                           /// **WhatsApp Group & Channel Cards**
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               /// **WhatsApp Group - Ask a Question**
                               Expanded(
                                 child: InkWell(
                                   onTap: _launchUrl,
                                   child: Container(
                                     height: 150, // Slightly increased height to prevent text overflow
                                     padding: EdgeInsets.all(14),
                                     margin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(12),
                                       gradient: LinearGradient(
                                         colors: [Colors.green.shade700, Colors.green.shade500],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       ),
                                       boxShadow: [
                                         BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                       ],
                                     ),
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         /// **WhatsApp Icon**
                                         CircleAvatar(
                                           backgroundColor: Colors.white.withOpacity(0.2),
                                           radius: 25,
                                           child: Icon(MdiIcons.whatsapp, color: Colors.white, size: 30),
                                         ),
                                         SizedBox(height: 8),

                                         /// **Group Title**
                                         Flexible(
                                           child: Text(
                                             "Ask a Question".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                             maxLines: 1, // Ensures text does not overflow
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),

                                         /// **Subtitle**
                                         Flexible(
                                           child: Text(
                                             "WhatsApp Group".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 13, color: Colors.white70),
                                             maxLines: 2, // Allows wrapping
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),

                               /// **Spacing Between Cards**
                               SizedBox(width: 10),

                               /// **WhatsApp Channel - Easy Farming Community**
                               Expanded(
                                 child: InkWell(
                                   onTap: _launchUrl2,
                                   child: Container(
                                     height: 150, // Same increased height
                                     padding: EdgeInsets.all(14),
                                     margin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(12),
                                       gradient: LinearGradient(
                                         colors: [Colors.blue.shade700, Colors.blue.shade500],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       ),
                                       boxShadow: [
                                         BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                       ],
                                     ),
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         /// **WhatsApp Channel Icon**
                                         CircleAvatar(
                                           backgroundColor: Colors.white.withOpacity(0.2),
                                           radius: 25,
                                           child: Icon(MdiIcons.whatsapp, color: Colors.white, size: 30),
                                         ),
                                         SizedBox(height: 8),

                                         /// **Channel Title**
                                         Flexible(
                                           child: Text(
                                             "Tips & Updates".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),

                                         /// **Subtitle**
                                         Flexible(
                                           child: Text(
                                             "WhatsApp Channel".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 13, color: Colors.white70),
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),


                         ],
                       ),
                     ),*/


                /*   InkWell(
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
    */


                /*Container(width: Utils.WIDTH_SCREEN,
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


             /* SizedBox(height: 5,),
              Container(

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
                     _buildSectionTitle('Settings'.tr()),
                     _buildSettingsTile(
                       context,
                       icon: Icons.notifications_active,
                       title: 'Schedule Reminders'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                               builder: (context) => const AllEventsScreen()),
                         );
                       },
                     ),
                     _buildSettingsTile(
                       context,
                       icon: Icons.account_balance,
                       title: 'Farm Management'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                               builder: (context) => const FarmSetupScreen()),
                         );
                       },
                     ),
                     _buildSettingsTile(
                       context,
                       icon: Icons.category,
                       title: 'Category Management'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                               builder: (context) => const CategoryScreen()),

                         );
                       },
                     ),
                     _buildSettingsTile(
                       context,
                       icon: Icons.auto_mode,
                       title: 'Auto Feed Management'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                               builder: (context) =>  AutomaticFeedManagementScreen()),
                         );
                       },
                     ),

                     _buildSettingsTile(
                       context,
                       icon: Icons.filter_alt_rounded,
                       title: 'All Data Filters'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                               builder: (context) =>  FilterSetupScreen(inStart: false,)),
                         );
                       },
                     ),

                     _buildSettingsTile(
                       context,
                       icon: Icons.backup,
                       title: 'Backup & Restore'.tr(),
                       onTap: () {
                           Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BackupRestoreScreen()),
                      );
                       },
                     ),

                     _buildSettingsTile(
                       context,
                       icon: Icons.support,
                       title: 'Contact & Support'.tr(),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => ContactSupportScreen()),
                         );
                       },
                     ),

                     SizedBox(height: 20,),
                     if(true)
                       _buildPremiumUpgradeTile(context),

                    *//* /// **Support Section Card**
                     Container(
                       margin: EdgeInsets.all(10),
                       padding: EdgeInsets.all(5),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(15),
                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           _buildSectionTitle('Contact & Support'),

                           /// **WhatsApp Group & Channel Cards**
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               /// **WhatsApp Group - Ask a Question**
                               Expanded(
                                 child: InkWell(
                                   onTap: _launchUrl,
                                   child: Container(
                                     height: 150, // Slightly increased height to prevent text overflow
                                     padding: EdgeInsets.all(14),
                                     margin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(12),
                                       gradient: LinearGradient(
                                         colors: [Colors.green.shade700, Colors.green.shade500],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       ),
                                       boxShadow: [
                                         BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                       ],
                                     ),
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         /// **WhatsApp Icon**
                                         CircleAvatar(
                                           backgroundColor: Colors.white.withOpacity(0.2),
                                           radius: 25,
                                           child: Icon(MdiIcons.whatsapp, color: Colors.white, size: 30),
                                         ),
                                         SizedBox(height: 8),

                                         /// **Group Title**
                                         Flexible(
                                           child: Text(
                                             "Ask a Question".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                             maxLines: 1, // Ensures text does not overflow
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),

                                         /// **Subtitle**
                                         Flexible(
                                           child: Text(
                                             "WhatsApp Group".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 13, color: Colors.white70),
                                             maxLines: 2, // Allows wrapping
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),

                               /// **Spacing Between Cards**
                               SizedBox(width: 10),

                               /// **WhatsApp Channel - Easy Farming Community**
                               Expanded(
                                 child: InkWell(
                                   onTap: _launchUrl2,
                                   child: Container(
                                     height: 150, // Same increased height
                                     padding: EdgeInsets.all(14),
                                     margin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(12),
                                       gradient: LinearGradient(
                                         colors: [Colors.blue.shade700, Colors.blue.shade500],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       ),
                                       boxShadow: [
                                         BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                       ],
                                     ),
                                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         /// **WhatsApp Channel Icon**
                                         CircleAvatar(
                                           backgroundColor: Colors.white.withOpacity(0.2),
                                           radius: 25,
                                           child: Icon(MdiIcons.whatsapp, color: Colors.white, size: 30),
                                         ),
                                         SizedBox(height: 8),

                                         /// **Channel Title**
                                         Flexible(
                                           child: Text(
                                             "Tips & Updates".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),

                                         /// **Subtitle**
                                         Flexible(
                                           child: Text(
                                             "WhatsApp Channel".tr(),
                                             textAlign: TextAlign.center,
                                             style: TextStyle(fontSize: 13, color: Colors.white70),
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),


                         ],
                       ),
                     ),*//*


                     *//*   InkWell(
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
    *//*


                    *//*Container(width: Utils.WIDTH_SCREEN,
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
                    ),*//*




                     *//* InkWell(
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
                  ),*//*
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

                  *//*Padding(
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
                  ),*//*
                ],
              ),),*/


      ),),),),);
  }

 /* void _showPremiumDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85, // more compact
          child: Column(
            children: [
              /// **Gradient Header**
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Utils.getThemeColorBlue(), Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      "assets/premium_icon.png",
                      width: 90,
                      height: 90,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "✨ " + "Unlock Premium".tr() + " ✨",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Get the best experience with exclusive features".tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              /// **Features**
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    SizedBox(height: 10,),
                    _buildFeatureItem(Icons.group, "Multi-User Access".tr() + "(10 "+"Max".tr()+")",
                        "Add multiple users with individual logins".tr()),
                    Divider(color: Colors.grey.shade300,),
                    _buildFeatureItem(Icons.admin_panel_settings, "Role-Based Permissions".tr(),
                        "Assign custom roles & control access".tr()),
                    Divider(color: Colors.grey.shade300,),
                    _buildFeatureItem(Icons.block, "No Ads".tr(),
                        "Enjoy a distraction-free experience".tr()),
                    Divider(color: Colors.grey.shade300,),
                    _buildFeatureItem(Icons.cloud_upload, "Cloud Sync".tr(),
                        "Back up & access your data across devices".tr()),
                    Divider(color: Colors.grey.shade300,),
                    _buildFeatureItem(Icons.update, "Real-Time Updates".tr(),
                        "Instant sync for all users".tr()),
                    Divider(color: Colors.grey.shade300,),
                    _buildFeatureItem(Icons.support, "Premium Support".tr(), "Priority Customer Care".tr()),
                  ],
                ),
              ),

              /// **Upgrade Button with Gradient**
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color.fromRGBO(2, 83, 179, 1), Colors.green], // green shades
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    onPressed: () {
                      PurchaseParam purchaseParam = PurchaseParam(productDetails: _products[0]);
                      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _products.isNotEmpty ? _products[0].price : "Loading...".tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                         Text(
                          "6 month plan".tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              TextButton(
                onPressed: () {
                  _inAppPurchase.restorePurchases();
                  Navigator.pop(context);
                },
                child: Text(
                  'RESTORE_PREMIUM'.tr(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
*/


  Future<void> rateUs() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      print("Review Available ");
      // Show native in-app review dialog (if supported)
      await inAppReview.requestReview();

    } else {
      print("Review Not Available ");
      // Fallback: Open store listing directly
      await inAppReview.openStoreListing(
        appStoreId: '6469481170', // iOS App ID
        microsoftStoreId: null,
        // For Android, no ID is required as it uses packageName automatically
      );
    }
  }

  void _showPremiumDialog(BuildContext context) {
    int selectedPlan = 0; // 0 = Ads Removal, 1 = Premium Subscription

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return FractionallySizedBox(
                heightFactor: 0.85,
                child: Column(
                  children: [
                    /// **Header**
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                  child: Icon(Icons.cancel_outlined, size: 30, color: Colors.white))),
          
                          Icon(Icons.workspace_premium, size: 70, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            "Upgrade Your Plan".tr(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Upgrade to unlock more features".tr(),
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
          
                    const SizedBox(height: 10),
          
                    /// Features Checklist
                    Expanded(
                      child: ListView(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          _buildFeatureItem(
                              "No Ads".tr(),
                              "Enjoy distraction-free experience".tr(),
                              included: true,
                              alwaysIncluded: true,
                          duration: "Lifetime"),
                          _buildFeatureItem(
                              "Priority Support".tr(),
                              "Get quick responses".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "Lifetime".tr()),
                          _buildFeatureItem(
                              "Reports".tr(),
                              "Access detailed analytics".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "Lifetime".tr()),
                          _buildFeatureItem(
                              "Cloud Sync".tr(),
                              "Access your data anywhere".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "6 months".tr()),
                          _buildFeatureItem(
                              "Multi-User Access".tr(),
                              "Add multiple users".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "6 months".tr()),
                          _buildFeatureItem(
                              "Role-Based Permissions".tr(),
                              "Control access levels".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "6 months".tr()),
          
                          _buildFeatureItem(
                              "Other Features".tr(),
                              "All other features are completely free".tr(),
                              included: true,
                              alwaysIncluded: true,
                              duration: "Lifetime".tr()),
          
                        ],
                      ),
                    ),
          
                    /// Plan Selection (Horizontal)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
          
                          /*_buildPlanOption(
                            title: "Ads Removal".tr(),
                            price: _products.isNotEmpty ? _products[0].price : "Loading...",
                            duration: "Lifetime",
                            selected: selectedPlan == 0,
                            onTap: () => setState(() => selectedPlan = 0),
                          ),*/
          
                          /*const SizedBox(width: 8),
                          _buildPlanOption(
                            title: "Premium".tr(),
                            price: _products.isNotEmpty ? "${_products[0].price}" : "Loading...",
                            duration: "6 months",
                            selected: selectedPlan == 0,
                            onTap: () => setState(() => selectedPlan = 0),
                          ),*/
                        ],
                      ),
                    ),
          
                    /// Purchase Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF2196F3)], // Green to Blue
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28), // More round
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0, // Remove default elevation (handled by boxShadow)
                              backgroundColor: Colors.transparent, // Use gradient instead
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              if(selectedPlan == 0) {
                                final PurchaseParam purchaseParam =
                                PurchaseParam(
                                    productDetails: _products[0]);
                                _inAppPurchase.buyNonConsumable(
                                    purchaseParam: purchaseParam);
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              "upgrade".tr()+"(${_products[0].price})",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
          
                    /// Restore
                    TextButton(
                      onPressed: () {
                        _inAppPurchase.restorePurchases();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Restore Premium'.tr(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Feature Row with check or cross + duration display
  Widget _buildFeatureItem(
      String title,
      String subtitle, {
        bool included = false,
        bool alwaysIncluded = false,
        String? duration, // <-- New optional parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included || alwaysIncluded ? Icons.check_circle : Icons.cancel,
            color: duration?.toLowerCase() == "lifetime" ? Colors.green :  Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 10,),
                    if (duration != null) // Show duration if provided
                      Text(
                        "($duration)",
                        style:  TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: duration.toLowerCase() == "lifetime" ? Colors.green :  Colors.orange,),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Horizontal Plan Option Card
  Widget _buildPlanOption(
      {required String title,
        required String price,
        required String duration,
        required bool selected,
        required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? Colors.blue : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: selected?  Colors.blue: Colors.grey),

              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500)),
              const SizedBox(height: 4),
              Text(price,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blue : Colors.grey.shade700)),
              Text(duration,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.blue : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }



  /*void _showPremiumDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allow full-screen scroll
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // 60% of screen height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Utils.getThemeColorBlue(), Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      "assets/premium_icon.png",
                      width: 70,
                      height: 70,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "✨" + "Unlock Premium Features".tr() + "✨",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              /// Scrollable Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
// _buildFeatureItem(Icons.group, "Multi-User Access".tr(), "Add multiple users to your farm with individual logins".tr()),
// _buildFeatureItem(Icons.admin_panel_settings, "Role-Based Permissions".tr(), "Assign custom roles and control access per user".tr()),
_buildFeatureItem(Icons.block, "No Ads".tr(), "Enjoy an ad-free experience".tr()),
_buildFeatureItem(Icons.cloud_upload, "Cloud Sync".tr(),
"Automatically back up your data and access it across devices".tr()),
// _buildFeatureItem(Icons.update, "Real-Time Updates".tr(),
// "See changes from all users instantly with sync-enabled collaboration".tr()),
                        SizedBox(height: 20),

                        /// Buy Premium Button
                        ElevatedButton.icon(
                          icon: Icon(Icons.shopping_cart, size: 24),
                          label: Text('Upgrade to Premium'.tr(),
                              style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            PurchaseParam purchaseParam =
                            PurchaseParam(productDetails: _products[0]);
                            _inAppPurchase
                                .buyNonConsumable(purchaseParam: purchaseParam);
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(height: 10),

                        /// Restore Purchase
                        TextButton(
                          onPressed: () {
                            _inAppPurchase.restorePurchases();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'RESTORE_PREMIUM'.tr(),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
*/

  void showFarmAccountIntro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(Icons.account_tree, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "farm_account_title".tr(),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Intro
              Text(
                "farm_account_intro".tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              SizedBox(height: 20),

              // Benefits
              Row(
                children: [
                  Icon(Icons.group, color: Colors.blue, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_users".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.orange, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_roles".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.manage_accounts, color: Colors.teal, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_manage".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.sync, color: Colors.purple, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_sync".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.backup, color: Colors.indigo, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_backup".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.redAccent, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "farm_account_benefit_subscription".tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("CANCEL".tr()),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(
                            builder: (_) =>
                            !loggedIn
                                ? AuthGate(isStart: false,)
                                : AdminProfileScreen(users: Utils.currentUser!,)));
                        // Continue logic here
                      },
                      child: Text("continue".tr(), style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }



  /*/// Feature Item Widget (icon + text)
  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
*/
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Text(
        title.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }


  Widget _buildPremiumUpgradeTile(BuildContext context) {
    return
      
      SafeArea(
        child: GestureDetector(
        onTap: () {
              _showPremiumDialog(context);

        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Utils.getThemeColorBlue(), Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              /// **Premium Icon**
              Image.asset("assets/premium_icon.png", width: 40, height: 40, color: Colors.orange),
        
              /// **Text Section**
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// **Main Title**
                      Text(
                        'Upgrade to Premium'.tr(),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
        
                      /// **Subtitle for Price**
                      Text(
                        _products.isNotEmpty ? "Only".tr()+" ${_products[0].price}" : "Loading Price".tr(),
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
        
              /// **Forward Arrow**
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
            ),
      );
  }
  /// **Section Title**
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  /// **Card-Based Settings Tile**
  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                /// **Leading Icon**
                CircleAvatar(
                  backgroundColor: Colors.blueAccent.withOpacity(0.15),
                  radius: 20,
                  child: Icon(icon, color: Colors.blueAccent, size: 20),
                ),
                SizedBox(width: 10),

                /// **Title**
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),

                /// **Forward Arrow**
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
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
    }else {
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
    //_kProductIds.add(premiumPoultry);
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

    for (var product in productDetailResponse.productDetails) {
      print('ID: ${product.id}');
      print('Title: ${product.title}');
      print('Description: ${product.description}');
      print('Price: ${product.price}');
      print('Currency Code: ${product.currencyCode}');
      print('Raw Price: ${product.rawPrice}');
      print('--------------------------------');
    }


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

