import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/dashboard.dart';
import 'package:poultary/product_screen.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database/databse_helper.dart';
import 'model/category_item.dart';
import 'multiuser/classes/NetworkAcceessNotifier.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/SyncManager.dart';
import 'stock/main_inventory_screen.dart';
import 'model/farm_item.dart';
import 'model/flock.dart';
import 'new_reporting_Screen.dart';

final ValueNotifier<DateTime?> syncTimeNotifier = ValueNotifier(null);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreen createState() => _HomeScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _HomeScreen extends State<HomeScreen> {

  double widthScreen = 0;
  double heightScreen = 0;

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

    if(Utils.isMultiUSer){
      // Delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _networkNotifier.initialize(context);
      });
    }
  }



  void addEggColorColumn() async {
    DatabaseHelper.instance.database;

    print("DONE");
  }



  bool no_flock = true;
  List<Flock> flocks = [];
  void getList() async {

   Database? db =  await DatabaseHelper.instance.database;

   try {
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
     await addNewColumn();
     await addMissingCategories();
   }
   catch(ex){
     print(ex);
   }

   try {
     List<String> tables = [
       'Flock',
       'Flock_Image',
       'Eggs',
       'Feeding',
       'Transactions',
       'Vaccination_Medication',
       'Category_Detail',
       'EggTransaction',
       'FeedBatch',
       'FeedBatchItem',
       'FeedIngredient',
       'FeedStockHistory',
       'Flock_Detail',
       'MedicineStockHistory',
       'SaleContractor',
       'ScheduledNotification',
       'VaccineStockHistory',
       'WeightRecord',
       'StockExpense',
       'CustomCategory',
       'CustomCategoryData',

     ]; // Add your actual table names

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

  Future<void> addMissingCategories() async{

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

  Future<void> addNewColumn() async {
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
      child: ReportListScreen(),
    ),
    Center(
      child: ManageInventoryScreen(),
    ),
    Center(
      child: SettingsScreen(),
    ),
    Center(
      child: ProductScreen(),
    ),
    // Center(
    //   child: ProductScreen(),
    // ),

  ];

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
           bottomNavigationBar: ClipRRect(
             borderRadius: BorderRadius.only(
               topLeft: Radius.circular(12),
               topRight: Radius.circular(12),
             ),
             child: BottomNavigationBar(
               type: BottomNavigationBarType.fixed,
               currentIndex: _selectedTab,
               onTap: (index) => _changeTab(index),
               selectedItemColor: Colors.white,
               unselectedItemColor: Colors.white70,
               backgroundColor: Utils.getThemeColorBlue(),
               items: [
                 BottomNavigationBarItem(icon: Icon(Icons.home), label: "DASHBOARD".tr()),
                 BottomNavigationBarItem(icon: Icon(Icons.area_chart), label: "REPORTS".tr()),
                 BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Stock".tr()),
                 BottomNavigationBarItem(icon: Icon(Icons.settings), label: "SETTINGS".tr()),
                 BottomNavigationBarItem(icon: Icon(Icons.egg_outlined), label: "Poultry".tr()),

               ],
             ),
           ),
      body: _pages[_selectedTab])); /*SafeArea(
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
      }
    }
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
    SyncManager().startCustomCategoryDataListening(farmId, lastSyncTime);
    SyncManager().startFeedBatchFBListening(farmId, lastSyncTime);
    SyncManager().startFeedStockFBListening(farmId, lastSyncTime);
    SyncManager().startMedicineStockFBListening(farmId, lastSyncTime);
    SyncManager().startVaccineStockFBListening(farmId, lastSyncTime);


  }

}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);
  final String xData;
  final num yData;
  final String? text;
}

