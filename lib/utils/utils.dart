import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/languages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/model/custom_category_data.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncManager.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../birds_report_screen.dart';
import '../custom_category_report.dart';
import '../database/databse_helper.dart';
import '../eggs_report_screen.dart';
import '../financial_report_screen.dart';
import '../health_report_screen.dart';
import '../model/bird_model.dart';
import '../model/category_item.dart';
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
import '../model/notification_suggestions.dart';
import '../model/recurrence_type.dart';
import '../model/schedule_notification.dart';
import '../model/transaction_item.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/src/widgets/image.dart';

import '../multiuser/model/egg_record.dart';
import '../multiuser/model/flockfb.dart';
import '../multiuser/model/role_permissions.dart';
import '../multiuser/model/user.dart';

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
  static late bool isShowAdd = true;
  static late bool iShowInterStitial = false;

  static bool shouldBackup = false;

  static final String ProxyAPI = "https://photogallerytv.com/Api/proxy.php?url=";

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

  static MultiUser? currentUser = null;
  static String selected_unit = "KG";

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

  // Replace with your actual Play Store and App Store links


  static bool isMultiUSer = false;
  static bool isSyncDone = false;
  static bool isTrialActive = false;
  // static MediationManager? manager;
  // static CASBannerView? view;

  static bool isUSerActive = false;
  static RoleWithPermissions? rolePerms = null;

  static bool direction = true;


  static void shareApp() {
    final String androidLink = "https://play.google.com/store/apps/details?id=com.zaheer.poultry";
    final String iosLink = "https://apps.apple.com/app/id6469481170";

    final String link = Platform.isAndroid ? androidLink : iosLink;
    Share.share("Easy Poultry & Chicken manager: $link");
  }


  static Future<void> generateDatabaseTables() async {
    try
    {
      await DatabaseHelper.addEggColorColumn();
      await DatabaseHelper.addFlockInfoColumn();
      await DatabaseHelper.addQuantityColumnMedicine();
      await DatabaseHelper.addUnitColumnMedicine();
      await DatabaseHelper.createFeedStockHistoryTable();
      await DatabaseHelper.createMedicineStockHistoryTable();
      await DatabaseHelper.createVaccineStockHistoryTable();
      await DatabaseHelper.createSaleContractorTable();
      await DatabaseHelper.createFeedIngridentTable();
      await DatabaseHelper.createFeedBatchTable();
      await DatabaseHelper.createFeedBatchItemTable();
      await DatabaseHelper.createWeightRecordTableIfNotExists();
      await DatabaseHelper.createScheduledNotificationsTable();
      await DatabaseHelper.createStockExpenseJunction();
      await DatabaseHelper.createEggTransactionJunction();
      await DatabaseHelper.createSyncFailedTable();
      await DatabaseHelper.addColumnIfNotExists("Transactions", "unit_price", "REAL", 0);
      await addNewColumn();
      await addMissingCategories();
      // await createMissingEggsRecords();
    }
    catch(ex){
      print(ex);
    }
  }

  static Future<void> addMissingCategories() async{

    //Medicine Category
    CategoryItem categoryItem = CategoryItem(id: null, name: "Medicine");
    CategoryItem categoryItem1 = CategoryItem(id: null, name: "Vaccine");

    List<String> commonMedicines = [
      "Amprolium",
      "Tylosin",
      "Doxycycline",
      "Enrofloxacin",
      "Neomycin",
      "Sulfaquinoxaline",
      "Furazolidone",
      "Flubendazole",
      "Ivermectin",
      "Gentamycin",
      "Ketoprofen",
      "Multivitamins",
      "Lincomycin",
      "Oxytetracycline",
      "Copper Sulfate",
      "Probiotics",
    ];

    List<String> commonVaccines = [
      "Newcastle",
      "Gumboro",
      "Marek’s",
      "Fowl Pox",
      "Avian Influenza",
      "Salmonella",
      "Bronchitis",
      "Fowl Cholera",
      "Mycoplasma",
      "EDS",
      "Coryza",
      "Reovirus",
      "E. coli",
      "Coccidiosis",
    ];
    int? medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(categoryItem);

    for(int i=0;i<commonMedicines.length;i++){
      await DatabaseHelper.addSubcategoryIfNotExists(medicineCategoryID!, commonMedicines[i]);
      print(commonMedicines[i]);
    }

    int? vaccineCategoryID  = await DatabaseHelper.addCategoryIfNotExists(categoryItem1);

    for(int i=0;i<commonVaccines.length;i++){
      await DatabaseHelper.addSubcategoryIfNotExists(vaccineCategoryID!, commonVaccines[i]);
      print(commonVaccines[i]);
    }

  }


  static Future<void> addNewColumn() async {
    try{
      int c = await DatabaseHelper.addColumnInFlockDetail();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int c = await DatabaseHelper.addColumnInFTransactions();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int? c = await DatabaseHelper.updateLinkedFlocketailNullValue();
      print("Flock Details Update Info $c");

      int? t = await DatabaseHelper.updateLinkedTransactionNullValue();
      print("Transactions Update Info $t");
    }catch(ex){
      print(ex);
    }
  }


  static void showSyncInfo(BuildContext context, String updatedAt, String updatedBy) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// **Header Row (Icon + Title)**
              Row(
                children: [
                  Icon(Icons.sync, size: 28, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    "Sync Information".tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// **Updated At Row**
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${"Updated At".tr()}: ",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          TextSpan(
                            text: updatedAt,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// **Updated By Row**
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${"Updated By".tr()}: ",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          TextSpan(
                            text: updatedBy,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// **Close Button**
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  label: Text(
                    "Close".tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  static DateTime getTimeStamp() {
    return DateTime.now();
  }

  static void showLoading() {
    EasyLoading.show(status: 'Saving...'.tr(),
      dismissOnTap: true,);
  }

 /* static void showLoading() {
    EasyLoading.show(
      status: 'Saving...'.tr(),
      dismissOnTap: false,
    );

    Future.delayed(Duration(seconds: 10), () {
      EasyLoading.instance.indicatorWidget = Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => EasyLoading.dismiss(),
              child: Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ),
        ],
      );

      // refresh loading with new widget
      EasyLoading.show(status: 'Saving...'.tr());
    });
  }*/


  static void hideLoading() {
    EasyLoading.showSuccess('DONE'.tr()+" ✅");
  }

  static void showError(){
    EasyLoading.showError('Failed...'.tr());
  }

  static bool hasFeaturePermission(String permission)
  {
    if(Utils.currentUser!.role.toLowerCase() == "admin")
      return true;

    if(!Utils.isUSerActive) {
      Utils.showToast("Your Account is Banned. Contact Admin".tr());
      return false;
    }

    try {
      bool hasPermission = rolePerms?.permissions.contains(permission) ?? false;
      return hasPermission;
    }
    catch(ex){
      return false;
    }

  }


  static Future<void> logoutUser() async {
   /* await SessionManager.setBoolValue(SessionManager.loggedIn, false);
    await SessionManager.setBoolValue(SessionManager.isAdmin, false);
    await SessionManager.setBoolValue('db_initialized_${Utils.currentUser!.farmId}', false);*/
    await SessionManager.clearPrefs();
    await SessionManager.setValue("farmID", Utils.currentUser!.farmId);
    await SessionManager.setBoolValue(SessionManager.loggedOut, true);
    await SessionManager.setupComplete();
    /*  await SessionManager.clearUserObject();
    await SessionManager.setLastSyncTime(FireBaseUtils.USERS, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.FEEDING, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.HEALTH, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.BIRDS, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.EGGS, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.FINANCE, null);
    await  SessionManager.setLastSyncTime(FireBaseUtils.FLOCK_DETAILS, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.FLOCK_IMAGES, null);
    await  SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY_DATA, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY, null);
    await  SessionManager.setLastSyncTime(FireBaseUtils.FEED_STOCK_HISTORY, null);
    await  SessionManager.setLastSyncTime(FireBaseUtils.MEDICINE_STOCK_HISTORY, null);

    await SessionManager.setLastSyncTime(FireBaseUtils.VACCINE_STOCK_HISTORY, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.FEED_INGRIDIENT, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.FEED_BATCH, null);

    await SessionManager.setLastSyncTime(FireBaseUtils.SUB_CATEGORY, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.WEIGHT_RECORD, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.SALE_CONTRACTOR, null);

    await SessionManager.setLastSyncTime(FireBaseUtils.TRANSACTIONS, null);
    await SessionManager.setLastSyncTime(FireBaseUtils.EGG_TRANSACTIONS, null);*/
    SyncManager().stopAllListening();
  }


  static String displayLangCode(language) {
    if (language.name.contains("Chinese")) return "zh";
    return language.isoCode.split("_").first; // takes 'zh_Hans' → 'zh'
  }


  static void showMissingPermissionDialog(BuildContext context, String permissionKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
               Text(
                "Access Denied".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
               Text(
                "You do not have permission for this feature.".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(
                      permissionKey,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child:  Text("Close".tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  static Future<void> retryFailedSyncs() async {
    final db = await DatabaseHelper.instance.database;
    final items = await db?.query('SyncQueue');

    for (final item in items!) {
      final type = item['type'] as String;
      final payload = jsonDecode(item['payload'] as String);

      try {
        if (type == 'egg') {
          final record = EggRecord.fromJson(payload);
          await FirebaseFirestore.instance
              .collection(FireBaseUtils.EGGS)
              .doc(record.sync_id!)
              .set(record.toJson());
        } else if (type == 'flock') {
          final record = FlockFB.fromJson(payload);
          await FirebaseFirestore.instance
              .collection(FireBaseUtils.FLOCKS)
              .doc(record.flock.sync_id!)
              .set(record.toJson());
        }

        // Success, remove from queue
        await db?.delete('SyncQueue', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        // Increment retry count and save error
        await db?.update(
          'SyncQueue',
          {
            'retry_count': (item['retry_count'] as int) + 1,
            'last_error': e.toString(),
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }


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

  static void shareSubUserCredentials({
    required String name,
    required String email,
    required String password,
    required String farmID,
  }) {
    String storeLink = "";

    if (Platform.isAndroid) {
      storeLink = "${"https://play.google.com/store/apps/details?id=com.zaheer.poultry"}";
    } else if (Platform.isIOS) {
      storeLink = "${"https://apps.apple.com/pk/app/easy-poultry-chicken-manager/id6469481170"}";
    }

    final message = '''
${"sub_user_share_title".tr()}

${"Farm ID".tr()}: $farmID
👤 ${"sub_user_name".tr()}: $name
📧 ${"sub_user_email".tr()}: $email
🔑 ${"sub_user_password".tr()}: $password

${"sub_user_note".tr()}

📱 ${"get_app_here".tr()}:
$storeLink
''';

    Share.share(message);
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

  static int getAgeIndays(String dob) {
    try {
      DateTime birthDate = DateFormat("yyyy-MM-dd").parse(dob);
      DateTime today = DateTime.now();

      Duration ageDuration = today.difference(birthDate);
      int totalDays = ageDuration.inDays;


      return totalDays;


    } catch (e) {
      print("Error parsing DOB: $e");
      return 0; // Return '-' if error
    }
  }
  static String getAnimalAgeWeeks(String dob) {
    try {
      DateTime birthDate = DateFormat("yyyy-MM-dd").parse(dob);
      DateTime today = DateTime.now();

      Duration ageDuration = today.difference(birthDate);
      int totalDays = ageDuration.inDays;

      int weeks = totalDays ~/ 7;
      int days = totalDays % 7;

      // Example: "12 weeks 3 days"
      if (weeks == 0) {
        return "$days " + "days".tr();
      } else if (days == 0) {
        return "$weeks " + "weeks".tr();
      } else {
        return "$weeks " + "weeks".tr() + " $days " + "days".tr();
      }
    } catch (e) {
      print("Error parsing DOB: $e");
      return "-"; // Return '-' if error
    }
  }


  static String getAnimalAge(String dob) {
    try {
      DateTime birthDate = DateFormat("yyyy-MM-dd").parse(dob);
      DateTime today = DateTime.now();

      Duration ageDuration = today.difference(birthDate);
      int totalDays = ageDuration.inDays;
      /*int years = totalDays ~/ 365;
      int remainingDays = totalDays % 365;
      int months = remainingDays ~/ 30;
      int days = remainingDays % 30;*/


      return totalDays.toString() +" "+ "days".tr().toString();

      /*if (totalDays < 30) {
        return "$totalDays "+ "days".tr(); // Show only days if less than a month
      } else if (years > 0 && months == 0) {
        return "$years "+ "years".tr()+" $days "+ "days".tr(); // Show days if 0 months
      } else if (years > 0) {
        return "$years "+ "years".tr()+" $months "+"months".tr();
      } else {
        return "$months "+ "months".tr()+" $days "+ "days".tr();
      }*/
    } catch (e) {
      print("Error parsing DOB: $e");
      return "-"; // Return '-' if error
    }
  }

  List<SuggestedNotification> allSuggestedNotifications = [
    // **Chicken**
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 1,
      title: 'Vaccination',
      description: 'Vaccinate for Marek’s Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 7,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 21,
      title: 'Vaccination',
      description: 'Vaccinate for Fowl Pox',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 42,
      title: 'Vaccination',
      description: 'Vaccinate for IBD/Gumboro',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 15,
      title: 'Feeding',
      description: 'Introduce Grower Feed',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 56,
      title: 'Laying',
      description: 'Start laying eggs – check for eggs',
      category: 'Laying',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 7,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Chicken',
      triggerDay: 30,
      title: 'Health Check',
      description: 'Monthly health check',
      category: 'Health Check',
    ),

    // **Duck**
    SuggestedNotification(
      birdType: 'Duck',
      triggerDay: 7,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Duck',
      triggerDay: 30,
      title: 'Feeding',
      description: 'Introduce Grit for digestion',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Duck',
      triggerDay: 90,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Duck',
      triggerDay: 180,
      title: 'Laying',
      description: 'Check for laying readiness',
      category: 'Laying',
    ),
    SuggestedNotification(
      birdType: 'Duck',
      triggerDay: 30,
      title: 'General Care',
      description: 'Clean water containers',
      category: 'General Care',
    ),

    // **Turkey**
    SuggestedNotification(
      birdType: 'Turkey',
      triggerDay: 30,
      title: 'Vaccination',
      description: 'Vaccinate for Fowl Pox',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Turkey',
      triggerDay: 45,
      title: 'Feeding',
      description: 'Introduce Grower Feed',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Turkey',
      triggerDay: 7,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Turkey',
      triggerDay: 60,
      title: 'General Care',
      description: 'Clean water containers',
      category: 'General Care',
    ),
    SuggestedNotification(
      birdType: 'Turkey',
      triggerDay: 150,
      title: 'Laying',
      description: 'Monitor egg-laying readiness',
      category: 'Laying',
    ),

    // **Peacock**
    SuggestedNotification(
      birdType: 'Peacock',
      triggerDay: 30,
      title: 'Health Check',
      description: 'Check for physical health',
      category: 'Health Check',
    ),
    SuggestedNotification(
      birdType: 'Peacock',
      triggerDay: 7,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Peacock',
      triggerDay: 45,
      title: 'Feeding',
      description: 'Introduce special diet for growth',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Peacock',
      triggerDay: 120,
      title: 'Laying',
      description: 'Egg-laying readiness check',
      category: 'Laying',

    ),

    // **Bob White Quail**
    SuggestedNotification(
      birdType: 'Bob white quail',
      triggerDay: 7,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Bob white quail',
      triggerDay: 21,
      title: 'Feeding',
      description: 'Feed high-protein diet',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Bob white quail',
      triggerDay: 14,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),

    // **Guinea Fowl**
    SuggestedNotification(
      birdType: 'Guinea',
      triggerDay: 7,
      title: 'Vaccination',
      description: 'Vaccinate for Fowl Pox',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Guinea',
      triggerDay: 15,
      title: 'Feeding',
      description: 'Introduce Grower Feed',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Guinea',
      triggerDay: 30,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Guinea',
      triggerDay: 60,
      title: 'Laying',
      description: 'Check for egg-laying readiness',
      category: 'Laying',
    ),

    // **Goose**
    SuggestedNotification(
      birdType: 'Goose',
      triggerDay: 15,
      title: 'Feeding',
      description: 'Introduce Grower Feed',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Goose',
      triggerDay: 30,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Goose',
      triggerDay: 7,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
    SuggestedNotification(
      birdType: 'Goose',
      triggerDay: 180,
      title: 'Laying',
      description: 'Check for breeding readiness',
      category: 'Laying',
    ),

    // **Pigeon**
    SuggestedNotification(
      birdType: 'Pigeon',
      triggerDay: 7,
      title: 'Vaccination',
      description: 'Vaccinate for Pigeon Paramyxovirus',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Pigeon',
      triggerDay: 15,
      title: 'Feeding',
      description: 'Provide special diet for growth',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Pigeon',
      triggerDay: 30,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),

    // **Canary**
    SuggestedNotification(
      birdType: 'Canary',
      triggerDay: 7,
      title: 'Feeding',
      description: 'Provide special diet for growth',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Canary',
      triggerDay: 30,
      title: 'Vaccination',
      description: 'Vaccinate for respiratory diseases',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Canary',
      triggerDay: 7,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),

    // **Finch**
    SuggestedNotification(
      birdType: 'Finch',
      triggerDay: 7,
      title: 'Health Check',
      description: 'Check for signs of stress or disease',
      category: 'Health Check',
    ),
    SuggestedNotification(
      birdType: 'Finch',
      triggerDay: 15,
      title: 'Feeding',
      description: 'Provide calcium supplements',
      category: 'Feeding',
    ),

    // **Ostrich**
    SuggestedNotification(
      birdType: 'Ostrich',
      triggerDay: 90,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Ostrich',
      triggerDay: 120,
      title: 'Feeding',
      description: 'Introduce Grower Feed',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Ostrich',
      triggerDay: 30,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),

    // **Rhea**
    SuggestedNotification(
      birdType: 'Rhea',
      triggerDay: 90,
      title: 'Vaccination',
      description: 'Vaccinate for Newcastle Disease',
      category: 'Vaccination',
    ),
    SuggestedNotification(
      birdType: 'Rhea',
      triggerDay: 180,
      title: 'Feeding',
      description: 'Provide protein supplements',
      category: 'Feeding',
    ),
    SuggestedNotification(
      birdType: 'Rhea',
      triggerDay: 30,
      title: 'Weight Check',
      description: 'Weekly weight check',
      category: 'Weight Check',
    ),
  ];

  void checkScheduledNotifications() async {
    initNotification();
    final List<PendingNotificationRequest> pendingNotificationRequests =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print('Scheduled notifications count: ${pendingNotificationRequests.length}');
    for (var notification in pendingNotificationRequests) {
      print(
          'ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}, Payload: ${notification.payload}');
    }
  }


  List<SuggestedNotification> getSuggestedNotifications({
    required String birdType,
    required int ageInDays,
  }) {
    return allSuggestedNotifications
        .where((notif) =>
    (notif.birdType.toLowerCase() == birdType.toLowerCase() || notif.birdType.toLowerCase() == 'other') &&
        notif.triggerDay >= ageInDays)
        .toList();
  }

  List<ScheduledNotification> generateRecurringNotifications({
    required String birdType,
    required int flockId,
    required String title,
    required String description,
    required DateTime startDate,
    required RecurrenceType recurrence,
  }) {
    final List<ScheduledNotification> scheduled = [];
    Duration interval;

    switch (recurrence) {
      case RecurrenceType.once:
        interval = Duration.zero;
        break;
      case RecurrenceType.weekly:
        interval = const Duration(days: 7);
        break;
      case RecurrenceType.every15Days:
        interval = const Duration(days: 15);
        break;
      case RecurrenceType.monthly:
        interval = const Duration(days: 30);
        break;
    }

    for (int i = 0; i < (recurrence == RecurrenceType.once ? 1 : 6); i++) {
      final scheduledAt = startDate.add(interval * i);
      scheduled.add(ScheduledNotification(
        id: DateTime.now().millisecondsSinceEpoch + i, // use proper ID generator
        birdType: birdType,
        flockId: flockId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        recurrence: recurrence,
      ));
    }

    return scheduled;
  }


  /// Returns number of full trays
  static int getEggTrays(int total, int traySize) {
   print("TRAY FUNCTION TOTAL $total TRAY $traySize");
    if (traySize <= 0 || total <= 0) return 0;
    return total ~/ traySize;
  }

  /// Returns number of loose eggs after filling trays
  static int getRemaining(int total, int traySize) {
    print("REMAINING FUNCTION TOTAL $total TRAY $traySize");
    if (traySize <= 0 || total <= 0) return 0;
    return total % traySize;
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
   modifyBirds.cIcon = "assets/flock_icon.png";

   CustomCategory eggCollection = CustomCategory(name:"EGG_COLLECTION", itemtype: "Default", cat_type: "EGG_COLLECTION".tr(), unit: "num", enabled: 1, icon: Icons.add);
   eggCollection.cIcon = "assets/egg.png";

   CustomCategory feeding = CustomCategory(name:"DAILY_FEEDING", itemtype: "Default", cat_type: "Feed Consumption".tr(), unit: "kg", enabled: 1, icon: Icons.add);
   feeding.cIcon = "assets/feed.png";

   CustomCategory health = CustomCategory(name:"BIRDS_HEALTH", itemtype: "Default", cat_type: "Medical".tr(), unit: "num", enabled: 1, icon: Icons.add);
   health.cIcon = "assets/health.png";

   CustomCategory finance = CustomCategory(name:"INCOME_EXPENSE", itemtype: "Default", cat_type: "Finance".tr(), unit: "currency", enabled: 1, icon: Icons.add);
   finance.cIcon = "assets/finance_icon.png";

   defaultCategories.add(modifyBirds);
   defaultCategories.add(eggCollection);
   defaultCategories.add(feeding);
   defaultCategories.add(health);
   defaultCategories.add(finance);

   return defaultCategories;

  }

  static String getUniueId() {
    final uuid = Uuid();

    return uuid.v4();
  }


  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


  static Future<void> setupAds() async
  {

    bool isInApp = await SessionManager.getInApp();
    if (isInApp || (Utils.isMultiUSer && !Utils.isTrialActive))
    {
      Utils.isShowAdd = false;
      hideBanner();
    }
    else
    {
      Utils.isShowAdd = true;
      inititalize();
    }
    Utils.isShowAdd = false;

  }


  static void showFloatingMessage(BuildContext context, GlobalKey key, String text) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + renderBox.size.height + 5, // below widget
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  static int backup_changes = 12;

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
    for(int i=0;i<list.length;i++) {
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




  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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

  static String getFlagEmoji(String countryCode) {
    return countryCode.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }


  static void showToast(String msg)
  {
    if(Utils.isMultiUSer && (msg.toLowerCase() == "done" || msg.toLowerCase() == "successful") )
      return;

    Fluttertoast.showToast(
        msg: msg.tr(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0 );
  }

  static Color getThemeColorBlue2() {
    Color themeColor = Color.fromRGBO(2, 86, 185, 1);
    return themeColor;
  }

  static Color getThemeColorBlue() {
    Color themeColor = Color.fromRGBO(2, 83, 179, 1);
    return themeColor;
  }

  static Widget getAdBar() {
    if(isShowAdd) {
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

  static Widget getDistanceBar() {
    if(isShowAdd) {
      return Container(width: WIDTH_SCREEN,height: 60,
        child:_isBannerAdReady?Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 60.0 ,
            width: Utils.WIDTH_SCREEN,
          ),
        ): Container(),
      );
    }
    return Container(width: WIDTH_SCREEN,height: 0,);
  }

  static getSelectedLanguage() async {

    String? language = await SessionManager.getSelectedLanguage();
    if(language == "" || language == "en")
    {
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
    else if(language =="it"){
      return Languages.italian;
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
    else if(language.isoCode =="it"){
      languageName = "it";
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
  static Future<File> convertToJPGFileIfRequiredWithCompression(File file,
      {int maxSizeKB = 500}) async {
    print("Original file path: ${file.path}");

    int originalSize = await file.length();
    print("Original size: ${originalSize / 1024} KB");

    int quality = 95; // start high
    Uint8List? imageBytes;
    File? compressedFile;

    do {
      imageBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: 1920,   // optional resize for huge images
        minHeight: 1920,
      );

      String newFilePath = await generateRandomFileName();
      compressedFile = await File(newFilePath).writeAsBytes(imageBytes!,
          flush: true, mode: FileMode.write);

      int newSize = await compressedFile.length();
      print("Compressed with quality=$quality => ${newSize / 1024} KB");

      // reduce quality gradually if still larger than target
      quality -= 5;

      if (quality < 30) break; // avoid going too low (bad quality)

    } while ((await compressedFile.length()) > maxSizeKB * 1024);

    return compressedFile!;
  }


  //LOCAL NOTIFICATION

  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static Future<void> showNotification(int id, String title, String body, int time) async {
    int notificationId = generateRandomNumber();

    try{
      initNotification();
      tz.initializeTimeZones();

      await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

          // Type of time interpretation
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,);

    }catch(ex){
      pushInexactNotification(notificationId,title,body,time);

    }
  }
  static pushInexactNotification(int notificationId,String title,String body,int time) async {
    try{
      await initNotification();
      tz.initializeTimeZones();


      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Type of time interpretation
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,);

    }catch(ex){

    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    initNotification();
    tz.initializeTimeZones();

    try{
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('main_channel', 'Main Channel',
            channelDescription: "kelsey",
            importance: Importance.max,
            priority: Priority.max,

          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }catch(ex){
      scheduleInexactNotification(id: id, title: title, body: body, scheduledDate: scheduledDate);
    }
  }
  static scheduleInexactNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    initNotification();
    tz.initializeTimeZones();

    try{
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('main_channel', 'Main Channel',
            channelDescription: "kelsey",
            importance: Importance.max,
            priority: Priority.max,

          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
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

  Future<void> cancelAndRemoveNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await DatabaseHelper.deleteNotification(id);
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
  static Widget showBannerAd1(BannerAd bannerAds,bool isBannerAdReadyOr){
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
          height: 60.0,
          width: Utils.WIDTH_SCREEN,
          child: isBannerAdReadyOr
              ? AdWidget(ad: bannerAds)
              : Container(
            decoration: BoxDecoration(

              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                "Advertisement".tr(),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          )
      ),
    );

  }
  static Widget showBannerAd(BannerAd? bannerAds, bool isBannerAdReadyOr) {
    if(!Utils.isShowAdd) return SizedBox();
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 60.0,
        width: Utils.WIDTH_SCREEN,
        child: (bannerAds != null && isBannerAdReadyOr)
            ? AdWidget(ad: bannerAds)
            : Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Text(
              "Advertisement".tr(),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

}
