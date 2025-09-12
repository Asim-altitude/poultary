import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/language_picker_dropdown.dart';
import 'package:language_picker/languages.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:poultary/eggs_report_screen.dart';
import 'package:poultary/feed_report_screen.dart';
import 'package:poultary/health_report_screen.dart';
import 'package:poultary/multiuser/classes/AdminProfile.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'financial_report_screen.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';
import 'multiuser/api/server_apis.dart';
import 'multiuser/classes/AuthGate.dart';
import 'multiuser/model/flockfb.dart';
import 'multiuser/model/user.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncManager.dart';
import 'multiuser/utils/SyncStatus.dart';
import 'multiuser/utils/SyncStatusManager.dart';

ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.syncTimeNotifier, Key? key}) : super(key: key);
  final ValueNotifier<DateTime?> syncTimeNotifier;

  @override
  _DashboardScreen createState() => _DashboardScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _DashboardScreen extends State<DashboardScreen> with RefreshMixin {
  final GlobalKey profileKey = GlobalKey();


  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.FLOCKS || event == FireBaseUtils.FINANCE ||
          event == FireBaseUtils.EGGS || event == FireBaseUtils.FEEDING) {
        getList();
      }
    }
    catch(ex){
      print(ex);
    }
  }


  late SyncManager syncManager;
  bool isSyncing = true;
  int completed = 0;
  int total = 16;

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
    Languages.italian,
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
  double widthScreen = 0;
  double heightScreen = 0;
  late Language _selectedCupertinoLanguage;
  bool isGetLanguage = false;
  getLanguage() async {
    _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
    setState(() {
      isGetLanguage = true;

    });

  }

  Widget _buildDropdownItem(Language language) {
    return Container(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 8.0,
          ),
          if(language.isoCode !="pt" && language.isoCode !="zh_Hans")
            Text("${language.name} (${language.isoCode})",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
          if(language.isoCode =="pt")
            Text("${'Portuguese'} (${language.isoCode})",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
          if(language.isoCode =="zh_Hans")
            Text("${'Chinese'} (zh)",
              style: new TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'PTSans'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

  }

  Map<String, double> dataMap = {"Income".tr(): 0,
    "Expense".tr(): 0};



  @override
  void initState() {
    super.initState();

    getFilters();
    getList();
    getLanguage();
    Utils.setupAds();

    checkMultiUSer();

    // Utils.showInterstitial();
  }

  /*Future<void> getFlocksFromFirebase(String farmId, DateTime? lastSyncTime) async {


    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FLOCKS);

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FLOCKS)
          .where('farm_id', isEqualTo: farmId);

      if (lastTime != null) {
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastTime),
        );
      }else{
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastSyncTime!),
        );
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("📭 No flocks found for farm: $farmId");
        // ✅ Start image/follow-up listeners anyway
      //  SyncManager().startAllListeners(farmId, lastSyncTime);
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        FlockFB? flockFB = FlockFB.fromJson(data);
        print("📥 Syncing FLOCK: ${flockFB.flock.f_name}");

        if (flockFB.last_modified!.isAfter(lastSyncTime!)) {
          lastSyncTime = flockFB.last_modified;
        }

        bool isAlreadyAdded = await DatabaseHelper.checkFlockBySyncID(flockFB.flock.sync_id!);
        if (isAlreadyAdded) {
          if (flockFB.flock.sync_status == SyncStatus.UPDATED || flockFB.flock.sync_status == SyncStatus.SYNCED) {
            await DatabaseHelper.updateFlockInfoBySyncID(flockFB.flock);
            Flock? flock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await listenToFlockImages(flock!, flock.farm_id ?? "");
          } else if (flockFB.flock.sync_status == SyncStatus.DELETED) {
            await DatabaseHelper.deleteFlockAndRelatedInfoSyncID(flockFB.flock.sync_id!);
          }
        } else {
          if (flockFB.flock.sync_status != SyncStatus.DELETED) {
            int? f_id = await DatabaseHelper.insertFlock(flockFB.flock);

            if (flockFB.transaction != null) {
              flockFB.transaction!.f_id = f_id!;
              int? tr_id = await DatabaseHelper.insertNewTransaction(flockFB.transaction!);
              flockFB.flockDetail!.transaction_id = tr_id.toString();
              flockFB.flockDetail!.f_id = f_id;
              int? f_detail_id = await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
              await DatabaseHelper.updateLinkedTransaction(tr_id!.toString(), f_detail_id!.toString());
            } else {
              flockFB.flockDetail!.transaction_id = "-1";
              flockFB.flockDetail!.f_id = f_id!;
              await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
            }

            Flock? insertedFlock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await listenToFlockImages(insertedFlock!, flockFB.flock.farm_id ?? "");
          }
        }
      }

      getList();

      SessionManager.setLastSyncTime(FireBaseUtils.FLOCKS, lastSyncTime!);

      // ✅ Start real-time sync listener after initial fetch
     // SyncManager().startAllListeners(farmId, lastSyncTime);

    } catch (e) {
      print("❌ Error in getFlocksFromFirebase: $e");
    //  SyncManager().startAllListeners(farmId, lastSyncTime);

    }
  }
*/
  Future<void> listenToFlockImages(Flock flock, String farmId) async {
    final query = FirebaseFirestore.instance
        .collection(FireBaseUtils.FLOCK_IMAGES)
        .where('farm_id', isEqualTo: farmId)
        .where('f_sync_id', isEqualTo: flock.sync_id); // Use correct field name

    final snapshot = await query.get();

    if(!snapshot.docs.isEmpty){
      List<Flock_Image> images = await DatabaseHelper.getFlockImage(flock.f_id);
      for(var image in images) {
        int result =  await DatabaseHelper.deleteItem("Flock_Image", image.id!);
        print("DELETED $result");
      }
    }

    print("DOC LENGTH ${snapshot.docs.length} Flock ${flock.f_name}");

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic>? imageUrls = data['image_urls'];

      if (imageUrls != null && imageUrls.isNotEmpty) {
        List<String> urls = imageUrls.cast<String>();

        print("🖼️ Flock Image URLs: $urls");
        if (imageUrls != null) {
          for (String url in urls) {
            print("DOWNLOADING URL $url");
            final base64 = await FlockImageUploader().downloadImageAsBase64(url);

            if (base64 != null) {
              Flock_Image image = Flock_Image(
                  f_id: flock.f_id, image: base64,
                  sync_id: Utils.getUniueId(),
                  sync_status: SyncStatus.SYNCED,
                  last_modified: flock.last_modified,
                  modified_by: flock.modified_by,
                  farm_id: flock.farm_id);

              await DatabaseHelper.insertFlockImages(image);
              print("SAVED URL $url for Flock ${flock.f_name}");
            }
          }
        }

        // TODO: Save URLs to SQLite or use them as needed
      } else {
        print("⚠️ No images found for flock: ${data['f_sync_id']}");
      }
    }


  }

  Future<void> checkMultiUSer() async {
    try {
      if (Utils.isMultiUSer) {

      MultiUser? user = await SessionManager.getUserFromPrefs();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool initialized = prefs.getBool('db_initialized_${user!.farmId}') ?? false;
      //final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FLOCKS);

      widget.syncTimeNotifier.addListener(() {
        final syncTime = widget.syncTimeNotifier.value;
        if (syncTime != null) {
         // getFlocksFromFirebase(user.farmId, syncTime); // or startSyncListeners(syncTime)
          getList();
        }
      });


      syncManager = SyncManager();
      syncManager.init(
        totalListeners: total,
        onAllComplete: () {
          setState(() {
            isSyncing = false;
            Utils.isSyncDone = true;
            /*if (Utils.backup_changes >= 10) {
              Utils.showFloatingMessage(context, profileKey, "${Utils.backup_changes}"+"Changes".tr()+" "+"Backup Recommended".tr());

            }*/
          });
        },
        onProgress: (c, t) {
          setState(() {
            completed = c;
          });
        },
      );

        if (initialized) {
          print("Database already initialized for farm ${user.farmId}");
        //  getFlocksFromFirebase(user.farmId, lastSyncTime);
          return;
        }


        /*final latestBackupUrl = await getLatestBackupUrlFromFirestore(
            user.farmId);
        if (latestBackupUrl != null) {
          showBackupFoundDialog(context, () {
            fetchAndInitializeDatabaseWithProgress(user!.farmId);
          });
        }*/
      }
    }
    catch(ex){
      print(ex);
    }
  }


  void showBackupFoundDialog(BuildContext context, VoidCallback onRestore) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.backup, size: 60, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                "Backup Found",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "We found a backup for your farm data.\nWould you like to restore it?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                      },
                      icon: Icon(Icons.cancel),
                      label: Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRestore(); // perform restore action
                      },
                      icon: Icon(Icons.restore),
                      label: Text("Restore"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  void addEggColorColumn() async{
    DatabaseHelper.instance.database;
    await DatabaseHelper.addEggColorColumn();
    print("DONE");
  }
  int _dashboard_filter = 2;
  void getFilters() async {

    _dashboard_filter = (await SessionManager.getDashboardFilter())!;
    date_filter_name = filterList.elementAt(_dashboard_filter);
    addEggColorColumn();

  }

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
                            AuthGate(isStart: false,)));
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


  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,Utils.WIDTH_SCREEN - 40, widthScreen),
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
              getFilteredData(date_filter_name);

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
  void getFilteredData(String filter){
    int index = 0;


    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
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
      getFilteredTransactions(str_date, end_date);

    }
  }


  void getFilteredTransactions(String st,String end) async {
    print("DATE"+st+end);

    await DatabaseHelper.instance.database;
    getFinanceData();
    total_eggs_collected = await DatabaseHelper.getEggCalculations(-1, 1, str_date, end_date);
    total_feed_consumption = await DatabaseHelper.getTotalFeedConsumption(-1, str_date, end_date);
    int vac_count = await DatabaseHelper.getHealthTotal(-1, "Vaccination", str_date, end_date);
    int med_count = await DatabaseHelper.getHealthTotal(-1, "Medication", str_date, end_date);
    treatmentCount = vac_count + med_count;
    total_feed_consumption = num.parse(total_feed_consumption.toStringAsFixed(2));

    _piData = [
      PieData("Income".tr(), gross_income, Colors.green),
      PieData("Expense".tr(), total_expense, Colors.red),
    ];

    setState(() {

    });

  }

  void getFinanceData() async {

    await DatabaseHelper.instance.database;

    gross_income = await DatabaseHelper.getTransactionsTotal(-1, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(-1, "Expense", str_date, end_date);

    net_income = gross_income - total_expense;

    gross_income = num.parse(gross_income.toStringAsFixed(2));
    total_expense = num.parse(total_expense.toStringAsFixed(2));
    net_income = num.parse(net_income.toStringAsFixed(2));

    dataMap = { "Income".tr(): gross_income.toDouble(),
      "Expense".tr(): total_expense.toDouble(),};

    setState(() {

    });
  }

  bool no_flock = true;
  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getFlocks();
    for(int i=0; i < flocks.length;i++){
      print(flocks.elementAt(i).toJson());
    }
    if(flocks.length == 0)
    {
      no_flock = true;
      print("NO_FLOCKS".tr());
      Utils.showToast("Please add new flock to continue.".tr());

    }/*else{
      bool isShow = await SessionManager.isShowWhatsNewDialog();
      if(isShow &)
        _showFeatureDialog();
    }*/

    flock_total = flocks.length;

    getFilteredData(date_filter_name);

    setState(() {

    });


  }

  List<PieData> _piData =[];

  int flock_total = 0;


  num gross_income = 0;
  num total_expense = 0;
  num net_income = 0;
  int total_eggs_collected = 0;
  num total_feed_consumption = 0;
  int treatmentCount =0;

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.blue, // same as appbar color
      statusBarIconBrightness: Brightness.light, // for Android (light = white icons)
      statusBarBrightness: Brightness.dark, // for iOS (dark = white text)
    ));

    double widthScreen = MediaQuery.of(context).size.width;
    Color backgroundColor = Color(0xFFF0F0F3);
    Color shadowColor = Utils.getThemeColorBlue();
    Color lightShadowColor = Colors.white;
    Color primaryTextColor = Colors.black87;

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

    return SafeArea(child: Scaffold(

      body:  SafeArea(
        top: false,
          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
            child:SingleChildScrollView(
            child: Column(
            children:  [
              // Utils.getDistanceBar(),
              // Show sync status at top
              /*(Utils.isMultiUSer && !Utils.isSyncDone)? Padding(
                padding: const EdgeInsets.all(0.0),
                child: SyncStatusWidget(
                  isSyncing: isSyncing,
                  completed: completed,
                  total: total,
                ),
              ) : SizedBox.shrink(),*/
              ClipRRect(
            child: Container(
              width: widthScreen,
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  // 🌍 Language Picker (Left Side)
                  if (isGetLanguage)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  color: Colors.white,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: supportedLanguages.length,
                                    itemBuilder: (context, index) {
                                      final language = supportedLanguages[index];
                                      return ListTile(
                                        title: Text("${language.name} (${language.isoCode})"),
                                        onTap: () {
                                          setState(() {
                                            _selectedCupertinoLanguage = language;
                                          });
                                          Utils.setSelectedLanguage(language, context);
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 45,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.language, size: 20, color: Colors.black.withOpacity(0.8)),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedCupertinoLanguage.name.toLowerCase().contains("chinese")
                                        ? "Chinese"
                                        : _selectedCupertinoLanguage.name,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "(${Utils.displayLangCode(_selectedCupertinoLanguage)})",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),


                  SizedBox(width: 8),

                  Expanded(
                    child: GestureDetector(
                      onTap: openDatePicker,
                      child: Container(
                        height: 45,
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Colors.black.withOpacity(0.8)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                date_filter_name.tr(),
                                style: TextStyle(fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'PTSans'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: 24, color: Colors.black.withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                Utils.isMultiUSer?
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminProfileScreen(users: Utils.currentUser!)),
                    );
                  },
                  child: Container(
                    key: profileKey,
                    padding: EdgeInsets.all(2), // Thickness of the border
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white, // Border color
                        width: 2, // Border width
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,

                      backgroundImage: (Utils.currentUser!.image != null && Utils.currentUser!.image.isNotEmpty)
                          ? NetworkImage(Utils.ProxyAPI+Utils.currentUser!.image)
                          : null,
                      child: (Utils.currentUser!.image == null || Utils.currentUser!.image.isEmpty)
                          ? Icon(Icons.person, size: 25, color: Colors.white)
                          : null,
                    ),
                  ))
                : Visibility(
                      visible: true,
                      child: InkWell(
                                        onTap: () async {
                       bool loggedIn = await SessionManager.getBool(SessionManager.loggedIn);

                       if(loggedIn){
                         await Navigator.push(context, MaterialPageRoute(
                             builder: (_) =>
                             AdminProfileScreen(users: Utils.currentUser!,)));
                       }else {
                         showFarmAccountIntro(context);
                       }
                                          // SessionManager.setBoolValue("farm_intro", true);

                     /* bool hasIntroduced = await SessionManager.getBool("farm_intro");
                      if(!hasIntroduced){
                        SessionManager.setBoolValue("farm_intro", true);
                        showFarmAccountIntro(context);
                      }else{
                        //  SessionManager.setBoolValue("farm_intro", false);
                       bool loggedIn = await SessionManager.getBool(SessionManager.loggedIn);
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) =>
                            !loggedIn
                                ? AuthGate(isStart: false,)
                                : AdminProfileScreen(users: Utils.currentUser!,)));
                      
                      }*/
                                        },
                        child: CircleAvatar(
                        radius: 22, // Size of the circle
                        backgroundColor: Colors.white, // White background
                        child: Icon(
                          Icons.person,
                          size: 25, // Icon size inside
                          color: Colors.black, // Icon color
                        ),
                                          ),
                      ),
                    )

                ],
              ),
            ),
          ),
              Column(
                children: [

                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // Financial Overview (Pie Chart + Info)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Pie Chart (Left Side)
                              InkWell(
                                onTap: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FinanceReportsScreen()),
                                  );
                                },
                                child: Container(
                                  width: widthScreen / 2,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                        offset: Offset(3, 5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                    ),
                                  ),
                                  child: _piData.isNotEmpty
                                ? Padding(
                                padding: EdgeInsets.all(1.0),
                      child: SfCircularChart(
                        legend: Legend(
                          isVisible: true,
                          textStyle: TextStyle(fontSize: 11, color: Colors.black),
                          padding: 2,
                        ),
                        series: <CircularSeries>[
                          PieSeries<PieData, String>(
                            dataSource: _piData,
                            xValueMapper: (PieData data, _) => data.label,
                            yValueMapper: (PieData data, _) => data.value,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            pointColorMapper: (PieData data, _) => data.color,
                          ),
                        ],
                      ),
                    )
                : Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 40, color: Colors.blueGrey),
              SizedBox(height: 8),
              Text(
                'No data available'.tr(),
                style: TextStyle(color: Colors.blueGrey, fontSize: 14),
              ),
            ],
          ),
      ),
                                ),
                              ),


                              // Financial Summary (Right Side)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height:4),

                                    getFinanceCard(Icons.arrow_upward, "Income", "${Utils.currency} $gross_income", Colors.green.shade300, FinanceReportsScreen(), context,0),
                                    getFinanceCard(Icons.arrow_downward, "Expense", "${Utils.currency} $total_expense", Colors.red, FinanceReportsScreen(), context,1),
                                    getFinanceCard(Icons.monetization_on, "NET_PROFIT", net_income >= 0 ? "${Utils.currency} $net_income" : "-${Utils.currency} ${-net_income}", net_income >= 0 ? Colors.white : Colors.white, FinanceReportsScreen(), context,2),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 5,),
                          // Egg Collection, Feed Consumption, Treatment Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(child: getSummaryCard(Icons.egg, "Eggs", "$total_eggs_collected", Colors.white, EggsReportsScreen(), context)),
                              Expanded(child: getSummaryCard(Icons.food_bank, "Feed", "$total_feed_consumption"+ Utils.selected_unit.tr(), Colors.white, FeedReportsScreen(), context)),
                              Expanded(child: getSummaryCard(Icons.medical_information, "Health", "$treatmentCount", Colors.white, HealthReportScreen(), context)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                 /* Container(
                    height: 50,
                    padding: EdgeInsets.all(10),
                    child: ValueListenableBuilder<int>(
                      valueListenable: SyncManager.activeListeners,
                      builder: (context, value, child) {
                        if (value > 0) {
                          return Text(
                            "Syncing".tr()+"...",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),*/
                  Container(
                    margin: EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      color: backgroundColor,
                    ),
                    child: Column(
                      children: [
                        // Title Section
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "ALL_FLOCKS".tr(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "(${flocks.length})",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Floating Action Button
                              flocks.isNotEmpty
                                  ? Align(
                                alignment: Alignment.centerRight,
                                child: FloatingActionButton(
                                  backgroundColor: backgroundColor,
                                  elevation: 4,
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (context) => const ADDFlockScreen()),
                                    );
                                    getList();
                                    getFilteredData(date_filter_name);
                                  },
                                  child: Icon(Icons.add, color: primaryTextColor, size: 28),
                                ),
                              )
                                  : SizedBox(),
                            ],
                          ),
                        ),

                        SizedBox(height: 8),

                        // Flock List with Neumorphic Effect
                        flocks.isNotEmpty
                            ? ListView.builder(
                          itemCount: flocks.length,
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () async {
                                  Utils.selected_flock = flocks[index];
                                  await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => const SingleFlockScreen()),
                                  );
                                  getList();
                                  getFilteredData(date_filter_name);
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: backgroundColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey,
                                        offset: Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: lightShadowColor,
                                        offset: Offset(-4, -4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Flock Icon
                                      Container(
                                        margin: EdgeInsets.all(5),
                                        height: 70,
                                        width: 70,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          flocks[index].icon.replaceAll("jpeg", "png"),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(width: 12),

                                      // Flock Info (Expanded to take available space)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              flocks[index].f_name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              flocks[index].acqusition_type.tr(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              Utils.getFormattedDate(flocks[index].acqusition_date),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Bird Count + Arrow in a Column
                                      Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: shadowColor,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4,
                                                ),
                                                BoxShadow(
                                                  color: lightShadowColor,
                                                  offset: Offset(-2, -2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              flocks[index].active_bird_count.toString(),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "BIRDS".tr(),
                                            style: TextStyle(
                                              color: primaryTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),


                                    ],
                                  ),
                                )

                            );
                          },
                        )
                            : // Empty State UI
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "NO_FLOCKS".tr(),
                              style: TextStyle(fontSize: 16, color: primaryTextColor),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => const ADDFlockScreen()),
                                );
                                getList();
                                getFilteredData(date_filter_name);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: backgroundColor,
                                shadowColor: shadowColor,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              icon: Icon(Icons.add, color: primaryTextColor),
                              label: Text(
                                "NEW_FLOCK".tr(),
                                style: TextStyle(fontSize: 16, color: primaryTextColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),

    ]))))));
  }

  Widget buildDateFilterWidget(String selectedFilter, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Opens the dialog on click
      child: Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 22),
              SizedBox(width: 8),
              Text(
                selectedFilter,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_drop_down, color: Colors.blue.shade600, size: 24), // Dropdown Indicator
            ],
          ),
        ),
      ),
    );
  }


  // Finance Info Card (Income, Expense, Net Profit)
  Widget getFinanceCard(IconData icon, String title, String amount, Color color, Widget nextScreen, BuildContext context,int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(

        decoration: BoxDecoration(
          color: index == 0
              ? Colors.green.shade50
              : index == 1
              ? Colors.red.shade50
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: index == 0
                ? Colors.green.shade300
                : index == 1
                ? Colors.red.shade300
                : Colors.blue.shade300,
          ),
        ),
        margin: EdgeInsets.only(left:5,right:5,top:0,bottom:5),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 5),
              Expanded( // Makes sure content can flex to fit available space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: index == 0
                              ? Colors.green[900]
                              : index == 1
                              ? Colors.red[900]
                              : Colors.blue[900],
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            title.tr(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: index == 0
                                  ? Colors.green[900]
                                  : index == 1
                                  ? Colors.red[900]
                                  : Colors.blue[900],
                            ),
                          ),
                        ),

                      ],
                    ),
                    SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        amount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: index == 0
                              ? Colors.green[900]
                              : index == 1
                              ? Colors.red[900]
                              : Colors.blue[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Summary Card (Eggs, Feed, Treatments)
  Widget getSummaryCard(IconData icon, String title, String value, Color color,Widget nextScreen, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      },
      child: Container(
        margin: EdgeInsets.only(left: 3,right: 3),
        padding: EdgeInsets.symmetric(vertical: 5,horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700], // Lighter gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
          ],

        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                SizedBox(width: 3),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child:
                  Text(title.tr(),
                    textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500, color: Colors.white70)),),

              ],
            ),
              SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }


  Widget getDashboardDataBox(Color color, String title, String data, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: color,

      ),
       padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
         
            Icon(icon, color: iconColor,),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white70),)
          ],),

          Container(
              margin: EdgeInsets.only(top: 5),
              child: Text(Utils.currency+data, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),))
        ],
      ),
    );
  }


  Widget getCustomDataBox(Color color, String title, String data, String imageSource,String ext) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: color,
      ),
      padding: EdgeInsets.only(top: 12,bottom: 12,left: 5,right: 5),
      margin: EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,


            children: [

            imageSource == ''? SizedBox(width: 0,height: 0,) :  Image.asset(imageSource, width: 40, height: 40,),

            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),)
          ],),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(data, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),)),
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(ext, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),)),
            ],
          )
        ],
      ),
    );
  }


  void showWhatsNewDialog() {

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              controller: ModalScrollController.of(context),
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's New".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Utils.getThemeColorBlue(),
                      ),
                    ),
                    SizedBox(height: 5,),

                    Text(
                      'Some key changes made in this update'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    SizedBox(height: 20,),
                    Text(
                      'Birds'.tr()+' '+'ADITION_RDCTIN'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5,),
                    Text(
                      'graph1'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      'Income'.tr()+'/'+'Expense'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'graph2'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    InkWell(
                      onTap: (){
                        SessionManager.setWhatsNewDialog(false);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: widthScreen,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Utils.getThemeColorBlue(),
                          borderRadius: const BorderRadius.all(
                              Radius.circular(10.0)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 2.0,
                          ),
                        ),
                        margin: EdgeInsets.all( 20),
                        child: Text(
                          "DONE".tr(),
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
            );
          },
        );
      },
    );
  }

  void _showFeatureDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                'New Feature: Automatic Feed Management!'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
               Text(
                'feature_msg'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Utils.getThemeColorBlue(), // Button color for "Activate Now"
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // Padding for a better look
                    ),
                    onPressed: () {
                      // Navigate to the settings screen or activate the feature
                      SessionManager.setWhatsNewDialog(false);
                      Navigator.pop(context); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  SettingsScreen()),
                      ); // Example route
                    },
                    child:  Text('Activate Now'.tr(), style: TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Button color for "Not Now"
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // Padding for a better look
                    ),
                    onPressed: () {
                      // Close the dialog and save the preference
                      SessionManager.setWhatsNewDialog(false);
                      Navigator.pop(context);
                    },
                    child:  Text('Not Now'.tr(), style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  bool downloadingDB = false;
  Future<void> fetchAndInitializeDatabaseWithProgress(String farmId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool initialized = prefs.getBool('db_initialized_$farmId') ?? false;

    if (initialized) {
      print("Database already initialized for farm $farmId");
      return;
    }

    downloadingDB = true;
    try {
      final latestBackupUrl = await getLatestBackupUrlFromFirestore(farmId);

      print("BACKUP_URL $latestBackupUrl");
      final uri = Uri.parse(latestBackupUrl);
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception("Failed to download DB file");
      }
      File abcd = await DatabaseHelper.instance.dBToCopy();

      // Prepare file path
      String recoveryPath =
          "${abcd.absolute.path}/assets/poultary.db";
      final file = File(recoveryPath);
      final sink = file.openWrite();

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      // Listen to stream and write to file while updating progress
      await response.stream.listen(
            (chunk) {
          bytesReceived += chunk.length;
          sink.add(chunk);
          if (contentLength > 0) {
            downloadProgress.value = bytesReceived / contentLength;
          }
        },
        onDone: () async {
          await sink.close();
          await prefs.setBool('db_initialized_$farmId', true);
          downloadProgress.value = 1.0;
          print("Database download complete.");
          downloadingDB = false;
          Utils.showToast("RESTORE_SUCCESSFUL".tr());

        },
        onError: (e) {
          sink.close();
          Utils.showToast("BACKUP_FAILED".tr());

          throw Exception("Download failed: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      Utils.showToast("BACKUP_FAILED".tr());

      print("Error during DB download: $e");
      rethrow;
    }
  }

  Future<String> getLatestBackupUrlFromFirestore(String farmId) async {
    final doc = await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).get();
    return doc.data()?['last_backup_url'] ?? '';
  }

}



class PieData {
  final String label;
final num value;
final Color color;

PieData(this.label, this.value, this.color);
}

class FinanceData {
  final String month;
  final num income;
  final num expense;

  FinanceData(this.month, this.income, this.expense);
}

