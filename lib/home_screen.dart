import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_flocks.dart';
import 'package:poultary/add_income.dart';
import 'package:poultary/all_events.dart';
import 'package:poultary/auto_feed_management.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/daily_feed.dart';
import 'package:poultary/dashboard.dart';
import 'package:poultary/egg_collection.dart';
import 'package:poultary/farm_routine/farm_routine_screen.dart';
import 'package:poultary/feed_batch_screen.dart';
import 'package:poultary/manage_flock_screen.dart';
import 'package:poultary/medication_vaccination.dart';
import 'package:poultary/multiuser/classes/all_flocks_screen.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:poultary/product_screen.dart';
import 'package:poultary/sale_contractor_screen.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/stock/egg_stock_screen.dart';
import 'package:poultary/stock/medicine_stock_screen.dart';
import 'package:poultary/stock/screens/general_stock_screen.dart';
import 'package:poultary/stock/stock_screen.dart';
import 'package:poultary/stock/tools_assets/screens/tools_assets_screen.dart';
import 'package:poultary/stock/vaccine_stock_screen.dart';
import 'package:poultary/task_calender/recurring_tasks/task_calendar_screen.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/poultry_command_center.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'add_birds.dart';
import 'add_eggs.dart';
import 'add_expense.dart';
import 'add_feeding.dart';
import 'database/databse_helper.dart';
import 'model/category_item.dart';
import 'model/egg_income.dart';
import 'model/egg_item.dart';
import 'model/transaction_item.dart';
import 'multiuser/classes/AdminProfile.dart';
import 'multiuser/classes/NetworkAcceessNotifier.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/SyncManager.dart';
import 'stock/main_inventory_screen.dart';
import 'model/farm_item.dart';
import 'model/flock.dart';
import 'new_reporting_Screen.dart';

final ValueNotifier<DateTime?> syncTimeNotifier = ValueNotifier(null);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreen createState() => _HomeScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _HomeScreen extends State<HomeScreen> {

  double widthScreen = 0;
  double heightScreen = 0;

  void _showCommandCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: _buildBottomSheet(),
        );
      },
    );
  }

  void _showGlobalBackupPrompt(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                "backup_title".tr(), // e.g. "Backup Recommended"
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Main message
              Text(
                "backup_message".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Hint
              Text(
                "backup_hint".tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Later".tr()), // "Later"
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminProfileScreen(users: Utils.currentUser!)),
                        );
                        // Trigger backup logic here
                      },
                      child: Text(
                        "backup_now".tr(), // "Backup Now"
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    if (Utils.isMultiUSer) {
      _networkNotifier.dispose();
    }
    super.dispose();
  }
  final _networkNotifier = NetworkSnackNotifier();


  @override
  void initState() {
    super.initState();

    getDirection();
    getList();
    getCurrency();
   // addEggColorColumn();

    Utils.setupAds();
    if(Utils.isMultiUSer)
    {
      // Delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _networkNotifier.initialize(context);
        //scheduleBackupPrompt(synclastSyncTime!);
       /* Future.delayed(const Duration(seconds: 10), () {
          _showGlobalBackupPrompt(context);
        });*/
      });
    }

    AnalyticsUtil.logScreenView(screenName: "home_screen");
    AnalyticsUtil.logAppOpen();
  }


  /*void scheduleBackupPrompt(DateTime lastBackupDate) {
    final now = DateTime.now();
    final difference = now.difference(lastBackupDate);

    if (difference.inDays >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 20), () {
          final ctx = navigatorKey.currentState?.overlay?.context;
          if (ctx != null) {
            _showGlobalBackupPrompt(ctx);
          }
        });
      });
    }
  }
*/

  void addEggColorColumn() async {
    DatabaseHelper.instance.database;

    print("DONE");
  }



  bool no_flock = true;
  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    await Utils.generateDatabaseTables();

   try {
     List<String> tables = Utils.getTAllables(); // Add your actual table names

     for (final table in tables) {
       await DatabaseHelper.instance.addSyncColumnsToTable(table);
       await DatabaseHelper.instance.assignSyncIds(table);
     }

     await SessionManager.setBoolValue(SessionManager.table_created, true);
     print('TABLE CREATION DONE');
   }
   catch(ex){
     print(ex);
   }


   try {
     Utils.selected_unit = await SessionManager.getUnit();

     flocks = await DatabaseHelper.getFlocks();

     if (flocks.length == 0) {
       no_flock = true;
       print('No Flocks');
     }

     flock_total = flocks.length;
   }
   catch(ex){
     print(ex);
   }

   try
   {
     if(Utils.isMultiUSer) {
      // NetworkSnackNotifier().initialize(context);
       setupDataListners();
     }
   }
   catch(ex){
     print(ex);
   }

    setState(() {

    });

  }

  Future<void> addSyncColumnsToTable(Database _database, String tableName) async {
    final columns = await _getTableColumns(_database, tableName);

    try{
      Future<void> addColumn(String name, String type) async {
        if (!columns.contains(name)) {
          await _database?.execute('ALTER TABLE $tableName ADD COLUMN $name $type');
        }
      }

      await addColumn('sync_id', 'TEXT');
      await addColumn('sync_status', 'TEXT');
      await addColumn('last_modified', 'INTEGER');
      await addColumn('modified_by', 'TEXT');
      await addColumn('farm_id', 'TEXT');
    }
    catch(ex){
      print(ex);
    }

    print("Colums ADDED");
  }

  Future<void> assignSyncIds(Database _database, String tableName) async {
    final uuid = Uuid();

    try {
      final List<Map<String, Object?>>? rows = await _database?.query(
        tableName,
        where: 'sync_id IS NULL OR sync_id = ""',
      );

      for (final row in rows!) {
        final id = row['id']; // assuming each row has an `id` column
        final newSyncId = uuid.v4();
        await _database?.update(
          tableName,
          {'sync_id': newSyncId},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    catch(ex){
      print(ex);
    }

    print("IDS Assigned");
  }

// Helper: Get column names for a table
  Future<List<String>> _getTableColumns(Database _database,String tableName) async {
    final result = await _database?.rawQuery('PRAGMA table_info($tableName)');
    return result!.map((row) => row['name'] as String).toList();
  }



  bool direction = true;

  List<_PieData> _piData =[];

  int flock_total = 0;
  int _selectedTab = 0;

  _changeTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  List _pages = [
    Center(
      child: DashboardScreen(syncTimeNotifier: syncTimeNotifier),
    ),
    Center(
      child: ReportListScreen(showBack: false,),
    ),
    Center(
      child: ManageInventoryScreen(),
    ),
    Center(
      child: SettingsScreen(showBack: false,),
    ),
    Center(
      child: ProductScreen(),
    ),
    // Center(
    //   child: ProductScreen(),
    // ),

  ];

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => _changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4,
        color: Utils.getThemeColorBlue(),
        child: SizedBox(
          height: 45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              _navItem(Icons.home, "DASHBOARD".tr(), 0),
              _navItem(Icons.bar_chart_rounded, "REPORTS".tr(), 1),

              const SizedBox(width: 72), // MUST match FAB size

              _navItem(Icons.inventory, "All".tr()+" "+"Stock".tr(), 2),
              _navItem(Icons.settings, "SETTINGS".tr(), 3),
            //  _navItem(Icons.help, "Poultry".tr(), 4),
            ],
          ),
        ),
      ),
    );
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


       return Scaffold(
         // Circular Floating Action Button
          /* floatingActionButton: FloatingActionButton(
             onPressed: () {
               print("Plus Button Clicked");
               // Add action here (e.g., open add item screen)
             },
             backgroundColor: Colors.blueAccent, // Change to match your theme
             child: Icon(Icons.add, size: 32, color: Colors.white),
             elevation: 6,
             shape: CircleBorder(), // Ensures it's always circular
           ),
           floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
       */
           floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
           floatingActionButton: SizedBox(
             width: 64,
             height: 64,
             child: FloatingActionButton(
               onPressed: _showCommandCenter,
               elevation: 8,
               backgroundColor: Colors.transparent,
               shape: const CircleBorder(),
               child: Ink(
                 decoration: const BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [
                       Color(0xFFFF9800),
                       Color(0xFFF57C00),
                       Color(0xFFE65100),
                     ],
                   ),
                 ),
                 child: const Center(
                   child: Icon(
                     Icons.electric_bolt,
                     color: Colors.white,
                     size: 30,
                   ),
                 ),
               ),
             ),
           ),


           bottomNavigationBar:
           _buildBottomBar(),
           body: _pages[_selectedTab]); /*SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
            child:Center(

            child: SingleChildScrollView(

            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Container(
                  margin: EdgeInsets.only(left: 10,top: 20),
                  child: Text(
                    "All FLocks( $flock_total)",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  )),
              InkWell(
                onTap: () async {
                 await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ADDFlockScreen()),
                  );

                 getList();

                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Add New Flock", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),

              Container(
                height: heightScreen/2,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: flocks.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return  InkWell(
                        onTap: () async{
                          Utils.selected_flock = flocks.elementAt(index);
                         await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SingleFlockScreen()),
                        );

                        getList();

                        },
                        child: Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 3,
                          child: Container(
                            height: 130,
                            *//*decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Colors.black,
                                width: 1.0,
                              ),
                            ),*//*
                            child: Row( children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  margin: EdgeInsets.all(10),
                                  child: Column( children: [
                                    Container(margin: EdgeInsets.all(5), child: Text(flocks.elementAt(index).f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
                                    Container(margin: EdgeInsets.all(0), child: Text(flocks.elementAt(index).acqusition_type, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                                    Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),

                                  ],),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(5),
                                    height: 80, width: 80,
                                    child: Image.asset(flocks.elementAt(index).icon, fit: BoxFit.contain,),),
                                  Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: Row(
                                      children: [
                                        Container( margin: EdgeInsets.only(right: 5), child: Text(flocks.elementAt(index).active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
                                        Text("Birds", style: TextStyle(color: Colors.black, fontSize: 16),)
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            ]),
                          ),
                        ),
                      );

                    }),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoryScreen()),
                  );
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Category Set up", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReportsScreen()),
                  );
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(margin: EdgeInsets.only(right: 15, top: 20), child: Text("Reports", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),))),
              ),
              *//*Center(
                    child: SfCircularChart(
                        title: ChartTitle(text: 'Income/Expense'),
                        legend: Legend(isVisible: true),
                        series: <PieSeries<_PieData, String>>[
                          PieSeries<_PieData, String>(
                              explode: false,
                              explodeIndex: 0,
                              dataSource: _piData,
                              xValueMapper: (_PieData data, _) => data.xData,
                              yValueMapper: (_PieData data, _) => data.yData,
                              dataLabelMapper: (_PieData data, _) => data.text,
                              dataLabelSettings: DataLabelSettings(isVisible: true)),
                        ]
                    )
                ),*//*


                   *//* Text(
              "Main Menu",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  color: Utils.getThemeColorBlue(),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold
              ),
            ),
                    SizedBox(width: widthScreen, height: 50,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 4),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: const BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 30),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/image.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Inventory",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Inventory()),
                          );
                        }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Profit/Loss",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiRepeatScreen()),
                    );*//**//*
                  }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Medication",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiScreen()),
                    );*//**//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Feeding",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//**//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Form Setup",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//**//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//**//*
                  }),*//*
                  ]
      ),),
        ),),),),);*/
  }

  void getCurrency() async{
    try {
      await DatabaseHelper.instance.database;

      List<FarmSetup> farmSetup = await DatabaseHelper.getFarmInfo();
      Utils.currency = farmSetup
          .elementAt(0)
          .currency;

    }
    catch(ex){
      print(ex);
    }

  }

  Future<void> getDirection() async {
    direction = await Utils.getDirection();
  }


  Future<void> setupDataListners() async {

    final docRef = FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP)
        .doc(Utils.currentUser!.farmId);
    final docSnapshot = await docRef.get();
    final DateTime lastBackupDate;
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final Timestamp? lastTimestamp = data?['timestamp'];

      print("DB BACKUP "+lastTimestamp.toString());
      if (lastTimestamp != null) {
        lastBackupDate = lastTimestamp.toDate();
        synclastSyncTime = lastBackupDate;

        SyncManager().setSyncTimeNotifier(syncTimeNotifier);
       // getFlocksFromFirebase(Utils.currentUser!.farmId, lastBackupDate);
        SyncManager().startAllListeners(Utils.currentUser!.farmId, lastBackupDate);


        try {
          final DateTime now = DateTime.now();
          final Duration difference = now.difference(lastBackupDate);
          if (difference.inDays >= 2) {
            print("BACKUP NEEDED");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(seconds: 30), () async {
                // final ctx = navigatorKey.currentState?.overlay?.context;
               DateTime? bckupTime = (await SessionManager.getLastBackupTime())!;
               if(bckupTime == null){
                 _showGlobalBackupPrompt(context);
               }
               else {
                 final DateTime now = DateTime.now();
                 final Duration difference = now.difference(bckupTime);
                 if(difference.inDays >= 2){
                   _showGlobalBackupPrompt(context);
                 }
               }
              });
            });
          }
        }
        catch(ex){
          print(ex);
        }
      }
    }
  }

  void _retryShowBackupPrompt() {
    Future.delayed(const Duration(seconds: 2), () {
      final ctx = navigatorKey.currentState?.overlay?.context;
      if (ctx != null) {
        _showGlobalBackupPrompt(ctx);
      } else {
        print("Failed again, giving up.");
      }
    });
  }



  DateTime? synclastSyncTime = null;


  void listenToFlocks(String farmId, DateTime? lastSyncTime) async {

    SyncManager().stopAllListening();
    // 🔹 Real-time listener (new changes only)
    SyncManager().startFockListening(farmId, lastSyncTime);
    SyncManager().startFinanceListening(farmId, lastSyncTime);
    SyncManager().startBirdModificationListening(farmId, lastSyncTime);
    SyncManager().startEggRecordListening(farmId, lastSyncTime);
    SyncManager().startFeedingListening(farmId, lastSyncTime);
    SyncManager().startCustomCategoryListening(farmId, lastSyncTime);
    SyncManager().startFeedIngredientListening(farmId, lastSyncTime);
    SyncManager().startHealthListening(farmId, lastSyncTime);
    SyncManager().startMultiHealthListening(farmId, lastSyncTime);
    SyncManager().startCustomCategoryDataListening(farmId, lastSyncTime);
    SyncManager().startFeedBatchFBListening(farmId, lastSyncTime);
    SyncManager().startFeedStockFBListening(farmId, lastSyncTime);
    SyncManager().startMedicineStockFBListening(farmId, lastSyncTime);
    SyncManager().startVaccineStockFBListening(farmId, lastSyncTime);


  }

  Future<void> createMissingEggsRecords() async {
    var eggSales = await DatabaseHelper.getEggSaleTransactions();
    print("EGG_SALES ${eggSales.length}");
    for(int i=0;i<eggSales.length;i++)
    {
      try {
        print("INDEX $i");
        TransactionItem item = eggSales[i];
        print("TRANSACTION_ID ${item.id}");
        EggTransaction? eggTransaction = await DatabaseHelper
            .getEggsByTransactionItemId(item.id!);
        if (eggTransaction == null) {
          print("NO_EGG_RECORD ${item.how_many} ${item.date} ${item.f_name}");
          Eggs eggs = Eggs(
              f_id: item.f_id!,
              f_name: item.f_name,
              image: "image",
              good_eggs: int.parse(item.how_many),
              bad_eggs: 0,
              egg_color: "white",
              total_eggs: int.parse(item.how_many),
              date: item.date,
              short_note: item.short_note,
              isCollection: 0,
              reduction_reason: "Sold",
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.PENDING,
              modified_by: Utils.isMultiUSer? Utils.currentUser!.email : '',
              last_modified: Utils.getTimeStamp(),
            farm_id: Utils.isMultiUSer? Utils.currentUser!.farmId : ''
          );
          int? egg_id = await DatabaseHelper.insertEggCollection(eggs);
          EggTransaction eggTransaction1 = EggTransaction(eggItemId: egg_id!,
              transactionId: item.id!,
              syncId: Utils.getUniueId(),
              syncStatus: eggs.sync_status!,
              lastModified: eggs.last_modified!,
              modifiedBy: eggs.modified_by!,
              farmId: Utils.isMultiUSer? Utils.currentUser!.farmId : '');
          await DatabaseHelper.insertEggJunction(eggTransaction1);
          print("EggTransaction ${eggTransaction1.eggItemId} ${eggTransaction1
              .transactionId}");
        } else {
          print("FOUND_EGG_RECORD ${eggTransaction.eggItemId} ${item
              .how_many} ${item.date} ${item.f_name}");
          print("EggTransaction ${eggTransaction.eggItemId} ${eggTransaction
              .transactionId}");
        }
      }
      catch(ex){
        print("ERROR $ex");
      }
    }
  }


  int _selectedIndex = 0;
  bool _sheetOpen = false;
  Section? _expandedSection;
  String _searchQuery = "";
  final List<String> _pinnedIds = [/*"feedstock", "medstock", "vaccstock"*/];
  String? _toastMessage;

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _togglePin(String id, StateSetter setModalState) {
    setModalState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
      } else {
        _pinnedIds.insert(0, id);
      }
    });
  }


  List<Map<String, dynamic>> _getSearchResults() {
    if (_searchQuery.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (var section in sections) {
      if(section.title.tr().toLowerCase().contains(_searchQuery.toLowerCase())){
        results.add({'section': section, 'feature': section.title});
      /*for (var feature in section.features) {
        *//*if (feature.label.toLowerCase().contains(_searchQuery.toLowerCase())) {
          results.add({'section': section, 'feature': feature});
        }else*//* if(section.title.toLowerCase().contains(_searchQuery.toLowerCase())){
          results.add({'section': section, 'feature': section.title});
        }*/
      }
    }
    return results;
  }

  List<Section> _getSortedSections() {
    final pinned = sections.where((s) => _pinnedIds.contains(s.id)).toList();
    final unpinned = sections.where((s) => !_pinnedIds.contains(s.id)).toList();
    final stockUnpinned = unpinned.where((s) => s.tier == "stock").toList();
    final coreUnpinned = unpinned.where((s) => s.tier == "core").toList();
    return [...pinned, ...stockUnpinned, ...coreUnpinned];
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem("🏠", "nav_home".tr(), 0),
              _buildNavItem("📊", "nav_reports".tr(), 1),
              const SizedBox(width: 56), // Space for center button
              _buildNavItem("🔔", "nav_alerts".tr(), 3),
              _buildNavItem("👤", "nav_profile".tr(), 4),
            ],
          ),
          Positioned(
            top: -22,
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 28,
            child: GestureDetector(
              onTap: () => setState(() => _sheetOpen = !_sheetOpen),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.42),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("⚡", style: TextStyle(fontSize: 23)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    
    return StatefulBuilder(builder: (context, setState)
    {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 40,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 9),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _expandedSection?.title ?? "label_command_center".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _expandedSection != null
                            ? "${_expandedSection!.features.length} features"
                            : "label_log_track_manage".tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() {
                          _sheetOpen = false;
                          _expandedSection = null;
                          _searchQuery = "";
                          Navigator.pop(context);
                        }),
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "✕",
                          style: TextStyle(fontSize: 14, color: Color(
                              0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _expandedSection != null
                  ? _buildExpandedView(setState)
                  : _buildMainContent(setState),
            ),
          ],
        ),
      );
    });

  }

  Widget _buildMainContent(StateSetter setModalState) {
    final searchResults = _getSearchResults();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          _buildSearchBar(setModalState),
          const SizedBox(height: 10),

          if (_searchQuery.isNotEmpty)
            _buildSearchResults(searchResults,setState)
          else
            ...[
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Color(0xFFEEF2F7)),
              ),
              const SizedBox(height: 12),
              _buildDataActions(),
              /*const SizedBox(height: 12),

              // Recent Activity
              _buildRecentActivity(),*/
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Color(0xFFEEF2F7)),
              ),
              const SizedBox(height: 4),

              // Sections
              _buildSections(setModalState),
            ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF16A34A)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          children: [
            const Opacity(
              opacity: 0.4,
              child: Text("🔍", style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) => setModalState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "search_placeholder".tr(),
                  hintStyle: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13.5),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                    fontSize: 13.5, color: Color(0xFF1E293B)),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setModalState(() => _searchQuery = ""),
                child: const Opacity(
                  opacity: 0.35,
                  child: Text("✕", style: TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "label_quick_actions".tr(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          // First row (4 actions)
          Row(
            children: quickActions.sublist(0, 4).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Second row (4 actions)
          Row(
            children: quickActions.sublist(4, 8).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),

        ],
      ),
    );
  }

  Widget _buildDataActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "label_date_actions".tr(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          // Second row (4 actions)
          Row(
            children: quickActions.sublist(8, 10).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),const SizedBox(height: 8),
          // Second row (4 actions)
          Row(
            children: quickActions.sublist(10, 12).map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildQuickActionButton(action),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(QuickAction action) {
    return GestureDetector(
      onTap: () => {
        if(action.id == "qa1"){
       Navigator.push(
      context,
      CupertinoPageRoute(
          builder: (context) =>  NewEggCollection(isCollection: true, eggs: null, reason: '',)),)
        }else if(action.id == "qa2"){
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) =>  NewEggCollection(isCollection: false, eggs: null, reason: 'SOLD',)),)
        } else if(action.id == "qa3"){
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  NewIncome(transactionItem: null, selectedIncomeType: null, selectedExpenseType: null,)),
          )
        }else if(action.id == "qa4"){
      Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewExpense(transactionItem: null,)),
    )
        }else if(action.id == "qa5"){
      Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: false,flock_detail: null, reason: 'MORTALITY',)),
    )
        }else if(action.id == "qa6"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  NewBirdsCollection(isCollection: false,flock_detail: null, reason: 'CULLING',)),
          )

        }else if(action.id == "qa7"){
      Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewFeeding()),
    )
        }else if(action.id == "qa8"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  ADDFlockScreen(isStart: false,)),
          )
        }else if(action.id == "qa9"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  AllFlocksScreen()),
          )
        }else if(action.id == "qa10"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  EggCollectionScreen()),
          )
        }else if(action.id == "qa11"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  TransactionsScreen()),
          )
        }else if(action.id == "qa12"){

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  DailyFeedScreen()),
          )
        }



        //_showToast("toast_action_opened".tr(args: [action.label]))
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8ECF0), width: 1.5),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.16),
                border: Border.all(
                    color: action.color.withOpacity(0.28), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(action.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              action.label.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "label_recent_activity".tr(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          ...recentActivity.map((item) => _buildRecentActivityItem(item)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(RecentActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              border: Border.all(color: item.color.withOpacity(0.22), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  "${item.batch} · ${item.time}",
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showToast("toast_repeating".tr(
                args: [item.action.split('—')[0].trim()])),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text("↻",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections(StateSetter setModalState) {
    final sortedSections = _getSortedSections();
    final pinned = sortedSections.where((s) => _pinnedIds.contains(s.id))
        .toList();
    final stockUnpinned = sortedSections
        .where((s) => !_pinnedIds.contains(s.id) && s.tier == "stock")
        .toList();
    final coreUnpinned = sortedSections
        .where((s) => !_pinnedIds.contains(s.id) && s.tier == "core")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinned.isNotEmpty) ...[
          _buildTierLabel("label_pinned".tr(), pinned.length),
          ...pinned.map((s) => _buildSectionCard(s, setModalState)),
        ],
        if (stockUnpinned.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTierLabel("label_stocks".tr(), stockUnpinned.length),
          ...stockUnpinned.map((s) => _buildSectionCard(s, setModalState)),
        ],
        if (coreUnpinned.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTierLabel("label_features".tr(), coreUnpinned.length),
          ...coreUnpinned.map((s) => _buildSectionCard(s, setModalState)),
        ],
      ],
    );
  }

  Widget _buildTierLabel(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.9,
            ),
          ),
          Text(
            "$count sections",
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Section section, StateSetter setModalState) {
    final isPinned = _pinnedIds.contains(section.id);


    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (section.isExpandable) {
          setModalState(() => _expandedSection = section);
        } else {
          Navigator.pop(context); // close bottom sheet safely
          section.onTap?.call(context); // ✅ valid context
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isPinned
                ? section.color.withOpacity(0.3)
                : const Color(0xFFE8ECF0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.14),
                border: Border.all(
                  color: section.color.withOpacity(0.28),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(section.icon, style: const TextStyle(fontSize: 19)),
              ),
            ),

            const SizedBox(width: 10),

            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        section.title.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 5),
                        const Text("📌", style: TextStyle(fontSize: 9)),
                      ],
                    ],
                  ),

                  if (section.isExpandable)
                    Text(
                      "${section.features.length} features",
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                    )
                  else
                   SizedBox.shrink()
                ],
              ),
            ),

            // Chevron for expandable sections
            if (section.isExpandable)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF94A3B8),
              ),

            const SizedBox(width: 6),

            // Pin button (isolated tap)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _togglePin(section.id, setModalState);
              },
              child: Opacity(
                opacity: isPinned ? 0.9 : 0.25,
                child: const Text("📌", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results, StateSetter setState) {
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Text("🔍", style: TextStyle(fontSize: 36)),
              SizedBox(height: 10),
              Text(
                "search_no_results".tr(),
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "search_results_count".tr(args: [results.length.toString()]) +
                (results.length != 1 ? "S" : ""),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...results.map((r) => _buildSearchResultItem(r,setState)),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result, StateSetter setModalState) {
    final section = result['section'] as Section;
    final feature = result['feature'] as String;

    return GestureDetector(
      onTap: () {
        section.onTap?.call(context);
      }
          /*setModalState(() {
            _expandedSection = section;
            _searchQuery = "";
          })*/,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(section.icon, style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title.tr(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "label_in".tr() + " ${section.title.tr()}",
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            /*if (section.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: section.urgent
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  section.badge!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: section.urgent
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(StateSetter modalSetState) {
    final section = _expandedSection!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => modalSetState(() {
              _expandedSection = null;
            }),
            child: Row(
              children: [
                Text("←", style: TextStyle(fontSize: 14)),
                SizedBox(width: 5),
                Text(
                  "label_back".tr(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Section header
          Container(
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.06),
              border: Border.all(
                  color: section.color.withOpacity(0.18), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.18),
                    border: Border.all(
                        color: section.color.withOpacity(0.35), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                        section.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (section.badge != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: section.urgent
                                ? const Color(0xFFFEF2F2)
                                : section.color.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            section.badge!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: section.urgent
                                  ? const Color(0xFFDC2626)
                                  : section.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Features
          ...section.features
              .asMap()
              .entries
              .map((entry) {
            final i = entry.key;
            final feature = entry.value;
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 220 + (i * 60)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: feature.urgent
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFEEF2F7),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: section.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                            feature.icon, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (feature.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: feature.urgent
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          feature.badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: feature.urgent
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void openFeedStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeedStockScreen()),);
  }
}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);
  final String xData;
  final num yData;
  final String? text;
}


class QuickAction {
  final String id;
  final String icon;
  final String label;
  final Color color;

  QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class RecentActivityItem {
  final String id;
  final String icon;
  final String action;
  final String time;
  final Color color;
  final String batch;

  RecentActivityItem({
    required this.id,
    required this.icon,
    required this.action,
    required this.time,
    required this.color,
    required this.batch,
  });
}

class Feature {
  final String id;
  final String icon;
  final String label;
  final String? badge;
  final bool urgent;

  Feature({
    required this.id,
    required this.icon,
    required this.label,
    this.badge,
    this.urgent = false,
  });
}

class Section {
  final String id;
  final String icon;
  final String title;
  final Color color;
  final String tier;

  final String? badge;
  final bool urgent;

  final List<Feature> features;

  /// Context-aware tap
  final void Function(BuildContext context)? onTap;

  bool get isExpandable => features.isNotEmpty;

  const Section({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.tier,
    this.badge,
    this.urgent = false,
    this.features = const [],
    this.onTap,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

final List<QuickAction> quickActions = [
  QuickAction(id: "qa8", icon: "🐔", label: "NEW_FLOCK", color: const Color(0xFF0EA5E9)),
  QuickAction(id: "qa1", icon: "🥚", label: "quick_action_collect_eggs", color: const Color(0xFFF59E0B)),
  QuickAction(id: "qa2", icon: "💵", label: "quick_action_sell_eggs", color: const Color(0xFF10B981)),
  QuickAction(id: "qa3", icon: "💰", label: "quick_action_add_income", color: const Color(0xFF3B82F6)),
  QuickAction(id: "qa4", icon: "💸", label: "quick_action_add_expense", color: const Color(0xFFEF4444)),
  QuickAction(id: "qa5", icon: "💀", label: "quick_action_mortality", color: const Color(0xFF6B7280)),
  QuickAction(id: "qa6", icon: "🔪", label: "quick_action_culling", color: const Color(0xFF9333EA)),
  QuickAction(id: "qa7", icon: "🌾", label: "quick_action_feed_usage", color: const Color(0xFF16A34A)),

  QuickAction(id: "qa9", icon: "🐔", label: "ALL_FLOCKS", color: const Color(0xFFEF4444)),
  QuickAction(id: "qa10", icon: "🥚", label: "EGG_COLLECTION", color: const Color(0xFF6B7280)),
  QuickAction(id: "qa11", icon: "💰", label: "INCOME_EXPENSE", color: const Color(0xFF9333EA)),
  QuickAction(id: "qa12", icon: "🌾", label: "DAILY_FEEDING", color: const Color(0xFF16A34A)),

];

final List<RecentActivityItem> recentActivity = [
  RecentActivityItem(
    id: "r1",
    icon: "🥚",
    action: "recent_activity_collected_eggs".tr(),
    time: "recent_activity_time_10min".tr(),
    color: const Color(0xFFF59E0B),
    batch: "recent_activity_batch_a".tr(),
  ),
  RecentActivityItem(
    id: "r2",
    icon: "🍗",
    action: "recent_activity_feed_logged".tr(),
    time: "recent_activity_time_1hr".tr(),
    color: const Color(0xFF16A34A),
    batch: "recent_activity_flock_1".tr(),
  ),
  RecentActivityItem(
    id: "r3",
    icon: "💵",
    action: "recent_activity_sold_eggs".tr(),
    time: "recent_activity_time_2hrs".tr(),
    color: const Color(0xFF10B981),
    batch: "recent_activity_retail".tr(),
  ),
  RecentActivityItem(
    id: "r4",
    icon: "💀",
    action: "recent_activity_mortality".tr(),
    time: "recent_activity_time_yesterday".tr(),
    color: const Color(0xFF6B7280),
    batch: "recent_activity_flock_2".tr(),
  ),
  RecentActivityItem(
    id: "r5",
    icon: "📥",
    action: "recent_activity_income_added".tr(),
    time: "recent_activity_time_yesterday".tr(),
    color: const Color(0xFF3B82F6),
    batch: "recent_activity_sales".tr(),
  ),
];

final List<Section> sections = [
  // STOCKS
  Section(
    id: "feedstock",
    icon: "🌾",
    title: "section_feed_stock",
    color: const Color(0xFF16A34A),
    tier: "stock",
    badge: "section_feed_stock_badge".tr(),
    urgent: true,
    features: [],
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FeedStockScreen()),
      );
    },
  ),
  Section(
    id: "medstock",
    icon: "💊",
    title: "section_medicine_stock",
    color: const Color(0xFFEF4444),
    tier: "stock",
    badge: "section_medicine_stock_badge".tr(),
    urgent: true,
    features: [],
    onTap: (context) async {
      CategoryItem item = CategoryItem(id: null, name: "Medicine");
      int? medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);

       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicineStockScreen(id: medicineCategoryID!),
        ),
      );
    },
  ),
  Section(
    id: "vaccstock",
    icon: "💉",
    title: "section_vaccine_stock",
    color: const Color(0xFF8B5CF6),
    tier: "stock",
    badge: "section_vaccine_stock_badge".tr(),
    urgent: true,
    /*features: [
      Feature(id: "vs1", icon: "💉", label: "feature_available_vaccines".tr(), badge: "feature_available_vaccines_badge".tr()),
      Feature(id: "vs2", icon: "📅", label: "feature_upcoming_schedules".tr(), badge: "feature_upcoming_schedules_badge".tr(), urgent: true),
      Feature(id: "vs3", icon: "📊", label: "feature_vaccination_history".tr()),
      Feature(id: "vs4", icon: "🛒", label: "feature_reorder_purchase".tr()),
    ],*/
    features: [],
    onTap: (context) async {
      CategoryItem item = CategoryItem(id: null, name: "Vaccine");
      int? vaccineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VaccineStockScreen(id: vaccineCategoryID!),
        ),
      );
    },
  ),
  Section(
    id: "eggstock",
    icon: "🥚",
    title: "section_egg_stock",
    color: const Color(0xFFF59E0B),
    tier: "stock",
    badge: "section_egg_stock_badge".tr(),
    features: [],
    onTap: (context) {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EggStockScreen()),
      );
    }
    /*features: [
      Feature(id: "es1", icon: "📦", label: "feature_current_egg_inventory".tr(), badge: "feature_current_egg_inventory_badge".tr()),
      Feature(id: "es2", icon: "📈", label: "feature_daily_collection_log".tr()),
      Feature(id: "es3", icon: "💵", label: "feature_sales_history".tr()),
      Feature(id: "es4", icon: "🏷️", label: "feature_grading_sorting".tr()),
    ],*/
  ),
  Section(
    id: "tools",
    icon: "🔧",
    title: "section_farm_tools_assets",
    color: const Color(0xFF78716C),
    tier: "stock",
    badge: "section_farm_tools_assets_badge".tr(),
    urgent: true,
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ToolsAssetsScreen()),
        );
      }
    /*features: [
      Feature(id: "ft1", icon: "📋", label: "feature_asset_registry".tr(), badge: "feature_asset_registry_badge".tr()),
      Feature(id: "ft2", icon: "🔧", label: "feature_maintenance_tracker".tr(), badge: "feature_maintenance_tracker_badge".tr(), urgent: true),
      Feature(id: "ft3", icon: "📅", label: "feature_service_schedule".tr()),
      Feature(id: "ft4", icon: "📊", label: "feature_depreciation_log".tr()),
    ],*/
  ),
  Section(
    id: "genstock",
    icon: "📦",
    title: "section_general_stock",
    color: const Color(0xFF0EA5E9),
    tier: "stock",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GeneralStockScreen()),
        );
      }
  ),
  // CORE FEATURES
  Section(
      id: "farm_routine",
      icon: "⏰",
      title: "FARM_ROUTINE",
      color: const Color(0xFFD93756),
      tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FarmRoutineScreen()),
        );
      }
  ),
  Section(
    id: "flock",
    icon: "🐔",
    title: "FLOCK_MANAGMENT",
    color: const Color(0xFFD97706),
    tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageFlockScreen()),
        );
      }
  ),
  Section(
    id: "category",
    icon: "📝",
    title: "CATEGORY_MANAGMENT",
    color: const Color(0xFFEF4444),
    tier: "core",
    badge: "".tr(),
    urgent: true,
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryScreen()),
        );
      }
  ),
  Section(
    id: "feed_batch",
    icon: "🌾",
    title: "Feed Batches",
    color: const Color(0xFF10B981),
    tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedBatchScreen()),
        );
      }
    /*features: [
      Feature(id: "fn1", icon: "📊", label: "feature_income_expenses".tr()),
      Feature(id: "fn2", icon: "💵", label: "feature_sales_records".tr()),
      Feature(id: "fn3", icon: "📈", label: "feature_profit_loss".tr()),
      Feature(id: "fn4", icon: "📆", label: "feature_monthly_summary".tr()),
    ],*/
  ),
  /*Section(
    id: "env",
    icon: "🏠",
    title: "section_environment".tr(),
    color: const Color(0xFF06B6D4),
    tier: "core",
    features: [
      Feature(id: "ev1", icon: "🌡️", label: "feature_temperature".tr()),
      Feature(id: "ev2", icon: "💨", label: "feature_ventilation".tr()),
      Feature(id: "ev3", icon: "💡", label: "feature_lighting_schedule".tr()),
      Feature(id: "ev4", icon: "🌧️", label: "feature_weather_alerts".tr()),
    ],
  ),*/
  Section(
    id: "task_calender",
    icon: "📅",
    title: "task_calendar",
    color: const Color(0xFF16A34A),
    tier: "core",
    badge: "task_calendar_badge".tr(),
    urgent: true,
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskCalendarScreen()),
        );
      }
    /*features: [
      Feature(id: "fd1", icon: "📅", label: "feature_feed_schedule".tr(), badge: "feature_feed_schedule_badge".tr(), urgent: true),
      Feature(id: "fd2", icon: "📊", label: "feature_nutrition_tracker".tr()),
      Feature(id: "fd3", icon: "💧", label: "feature_water_management".tr()),
      Feature(id: "fd4", icon: "📈", label: "feature_feed_cost_analysis".tr()),
    ],*/
  ),
  Section(
    id: "reminders",
    icon: "⏰",
    title: "Reminders",
    color: const Color(0xFF8B5CF6),
    tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  AllEventsScreen()),
        );
      }
    /*features: [
      Feature(id: "rp1", icon: "📈", label: "feature_daily_summary".tr()),
      Feature(id: "rp2", icon: "📉", label: "feature_weekly_report".tr()),
      Feature(id: "rp3", icon: "📆", label: "feature_monthly_analytics".tr()),
      Feature(id: "rp4", icon: "📤", label: "feature_export_data".tr()),
    ],*/
  ),
  Section(
      id: "auto_feed",
      icon: "🔄",
      title: "AUTO_FEED_MANAGMENT",
      color: const Color(0xFF8B5CF6),
      tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  AutomaticFeedManagementScreen()),
        );
      }
    /*features: [
      Feature(id: "rp1", icon: "📈", label: "feature_daily_summary".tr()),
      Feature(id: "rp2", icon: "📉", label: "feature_weekly_report".tr()),
      Feature(id: "rp3", icon: "📆", label: "feature_monthly_analytics".tr()),
      Feature(id: "rp4", icon: "📤", label: "feature_export_data".tr()),
    ],*/
  ),
  Section(
      id: "sale_contractor",
      icon: "🤝",
      title: "Sale Contractors",
      color: const Color(0xFF8B5CF6),
      tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  SaleContractorScreen()),
        );
      }
    /*features: [
      Feature(id: "rp1", icon: "📈", label: "feature_daily_summary".tr()),
      Feature(id: "rp2", icon: "📉", label: "feature_weekly_report".tr()),
      Feature(id: "rp3", icon: "📆", label: "feature_monthly_analytics".tr()),
      Feature(id: "rp4", icon: "📤", label: "feature_export_data".tr()),
    ],*/
  ),
  Section(
      id: "settings",
      icon: "⚙️",
      title: "Settings",
      color: const Color(0xFF8B5CF6),
      tier: "core",
      features: [],
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  SettingsScreen(showBack: true,)),
        );
      }
    /*features: [
      Feature(id: "rp1", icon: "📈", label: "feature_daily_summary".tr()),
      Feature(id: "rp2", icon: "📉", label: "feature_weekly_report".tr()),
      Feature(id: "rp3", icon: "📆", label: "feature_monthly_analytics".tr()),
      Feature(id: "rp4", icon: "📤", label: "feature_export_data".tr()),
    ],*/
  ),
];
