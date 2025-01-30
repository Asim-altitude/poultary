import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/model/egg_item.dart';
import 'package:poultary/model/flock.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';

import '../model/bird_item.dart';
import '../model/category_item.dart';
import '../model/eggs_chart_data.dart';
import '../model/farm_item.dart';
import '../model/feed_item.dart';
import '../model/feed_report_item.dart';
import '../model/feed_summary.dart';
import '../model/feedflock_report_item.dart';
import '../model/finance_chart_data.dart';
import '../model/flock_detail.dart';
import '../model/flock_image.dart';
import '../model/health_chart_data.dart';
import '../model/transaction_item.dart';
import '../model/used_item.dart';
class DatabaseHelper  {
  static const _databaseName = "assets/poultary.db";

  static const user_table = 'user';

  static final DatabaseHelper _db = DatabaseHelper._internal();

  DatabaseHelper._internal();
  static DatabaseHelper get instance => _db;
  static Database? _database;

  Future<Database?> get database async {
    if(_database != null) {
      return _database;
    }
    _database = await _init();
    return _database;

  }
  Future<Database> _init() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, _databaseName);

    // Check if the database exists
    var exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
        print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "poultary.db"));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);

    } else {
        print("Opening existing database");
    }
// open the database
    return await openDatabase(path, readOnly: false);
  }
  static getFilePathDB() async {
    // File result = await _db.dBToCopy();
    // print("lllllllllllllllllll ${result.absolute.path}");
    //
    // Directory documentsDirectory =
    // Directory("storage/emulated/0/Download/");
    File abcd = await _db.dBToCopy();

    String recoveryPath =
        "${abcd.absolute.path}/assets/poultary.db";

    String newPath = recoveryPath;
    print('Path:${newPath}');
    File file = new File(recoveryPath);


    return file;
  }
  static importDataBaseFile (BuildContext context) async {
    File abcd = await _db.dBToCopy();

    bool? clear = await FilePicker.platform.clearTemporaryFiles();
    print(clear);
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(

    );
    String recoveryPath =
        "${abcd.absolute.path}/assets/poultary.db";
    String newPath = "${result?.files.single.path}";
    if(newPath.contains(".db")){
      File backupFile = File(newPath);
      backupFile.copy(recoveryPath);
      Alert(
        context: context,
        type: AlertType.success,
        title: "RESTORE_SUCCESSFUL".tr(),
        desc: "RESTORE_SUCCESSFUL_DESC".tr(),
        buttons: [
          DialogButton(
            child: Text(
              "OK".tr(),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
            width: 120,
          )
        ],
      ).show();
    }
    else{
      Alert(
        context: context,
        type: AlertType.error,
        title: "BACKUP_FAILED".tr(),
        desc: "BACKUP_FAILED_DESC1".tr() + "BACKUP_FAILED_DESC2".tr() + "BACKUP_FAILED_DESC3".tr(),
        buttons: [
          DialogButton(
            child: Text(
              "OK".tr(),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
            width: 120,
          )
        ],
      ).show();
    }

  }
  Future<File> dBToCopy() async {
    final db = await instance.database;
    final dbPath = await getDatabasesPath();
    var afile = File(dbPath);
    return afile;
  }
  static Future<int?>  insertFlock(Flock flock) async {

    int count = await getFlocksNamesCount(flock.f_name);
    if(count>0){
      flock.f_name = "${flock.f_name} (${(count+1)})";
    }
     return await _database?.insert(
      'Flock',
      flock.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }


  static Future<void> addEggColorColumn() async {
    try {
      // Check if the 'egg_color' column exists
      final tableInfo = await _database?.rawQuery("PRAGMA table_info(eggs)");
      final hasColumn = tableInfo?.any((column) => column['name'] == 'egg_color');

      if (!hasColumn!) {
        // Add the column if it doesn't exist
        await _database?.execute("ALTER TABLE eggs ADD COLUMN egg_color TEXT DEFAULT 'white'");
        // Update existing rows to have 'white' as default (optional since DEFAULT handles it)
        await _database?.rawUpdate("UPDATE eggs SET egg_color = 'white' WHERE egg_color IS NULL");
        print("COLOR COLUMN ADDED");
      }
    } catch (e) {
      print("Error adding 'egg_color' column: $e");
    }
  }


  static Future<int?>  insertFlockImages(Flock_Image image) async {

    return await _database?.insert(
      'Flock_Image',
      image.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<dynamic> addColumnInFTransactions() async {
    var count = await _database?.execute("ALTER TABLE Transactions ADD "
        "COLUMN flock_update_id TEXT;");
    // print(await _database?.query(TableName));
    return count;
  }

  static Future<dynamic> addColumnInFlockDetail() async {
     var count = await _database?.execute("ALTER TABLE Flock_Detail ADD "
        "COLUMN transaction_id TEXT;");
   // print(await _database?.query(TableName));
    return count;
  }

  static Future<List<CategoryItem>>  getCategoryItem() async {
    var result = await _database?.rawQuery("SELECT * FROM Category");
    List<CategoryItem> _categoryList = [];
    CategoryItem category;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            category = CategoryItem.fromJson(json);
            _categoryList.add(category);
            print(_categoryList);
          }
        }

        Map<String, dynamic> json = result[0];
        category = CategoryItem.fromJson(json);
      }
    }
    return _categoryList;
  }

  static Future<List<FarmSetup>>  getFarmInfo() async {
    var result = await _database?.rawQuery("SELECT * FROM FarmSetup");
    List<FarmSetup> _birdList = [];
    FarmSetup bird;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            bird = FarmSetup.fromJson(json);
            _birdList.add(bird);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        bird = FarmSetup.fromJson(json);
      }
    }
    return _birdList;
  }

  static Future<List<Bird>>  getBirds() async {
    var result = await _database?.rawQuery("SELECT * FROM Bird");
    List<Bird> _birdList = [];
    Bird bird;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            bird = Bird.fromJson(json);
            _birdList.add(bird);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        bird = Bird.fromJson(json);
      }
    }
    return _birdList;
  }

  static Future<int?> insertNewTransaction(TransactionItem transaction) async{
    return await _database?.insert(
      'Transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }



  static Future<int?> insertNewFeeding(Feeding feeding) async {

    return await _database?.insert(
      'Feeding',
      feeding.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  // Function to get the latest feeding record date
  static Future<Map<String, dynamic>?> queryLatestFeedingRecord() async {
    List<Map<String, dynamic>>? result = await _database?.query(
      'Feeding',
      columns: ['feeding_date'],
      orderBy: 'feeding_date DESC',
      limit: 1,
    );

    print('FEEDING_DATE $result');
    // Check if the result is not null and contains data
    if (result != null && result.isNotEmpty) {
      return result.first;
    }

    return null;
  }


  static Future<int?> insertEggCollection(Eggs eggs) async {

    return await _database?.insert(
      'Eggs',
      eggs.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<int?> insertNewSubItem(SubItem subitem) async {

    return await _database?.insert(
      'Category_Detail',
      subitem.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<int?> insertFlockDetail(Flock_Detail flock_detail) async {

    return await _database?.insert(
      'Flock_Detail',
      flock_detail.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<Flock_Detail?> getSingleFlockDetails(int f_detail_id) async {

    final map = await _database?.rawQuery(
        "SELECT * FROM Flock_Detail WHERE f_detail_id = ?",[f_detail_id]
    );

    if (map!.isNotEmpty) {
      return Flock_Detail.fromJson(map.first);
    } else {
      return null;
    }
  }

  static Future<Flock?> getSingleFlock(int f_id) async {

    final map = await _database?.rawQuery("SELECT * FROM Flock WHERE f_id = $f_id");

    if (map!.isNotEmpty) {
      return Flock.fromJson(map.first);
    } else {
      return null;
    }
  }

  static Future<int?> updateLinkedFlocketailNullValue() async {

    return await _database?.rawUpdate(
        "UPDATE Flock_Detail SET transaction_id = '-1' WHERE transaction_id = 'NULL';");
  }

  static Future<int?> updateLinkedTransactionNullValue() async {

    return await _database?.rawUpdate(
        "UPDATE Transactions SET flock_update_id = '-1' WHERE flock_update_id = 'NULL';");
  }

  static Future<int?> updateLinkedFlockDetail(String f_detail_id, String transaction_id,) async {

    return await _database?.rawUpdate(
        "UPDATE Flock_Detail SET transaction_id = '$transaction_id' WHERE f_detail_id = $f_detail_id;");
  }

  static Future<int?> updateLinkedTransaction(String id, String f_detail_id,) async {

    return await _database?.rawUpdate(
        "UPDATE Transactions SET flock_update_id = '$f_detail_id' WHERE id = $id;");
  }

  static Future<int?> updateFlock(Flock_Detail? flock_detail) async {

    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "Flock_Detail",
        flock_detail!.toJson(),
        where: 'f_detail_id= ?',
        whereArgs: [flock_detail.f_detail_id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int?> updateEggCollection(Eggs eggs) async {

    // get a reference to the database
    // because this is an expensive operation we use async and await

    // row to update


    // We'll update the first row just as an example
    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "Eggs",
        eggs.toJson(),
        where: 'id= ?',
        whereArgs: [eggs.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int?> updateTransaction(TransactionItem transactionItem) async {

    // get a reference to the database
    // because this is an expensive operation we use async and await

    // row to update


    // We'll update the first row just as an example
    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "Transactions",
        transactionItem.toJson(),
        where: 'id = ?',
        whereArgs: [transactionItem.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int?> updateFeeding(Feeding feeding) async {

    // get a reference to the database
    // because this is an expensive operation we use async and await

    // row to update


    // We'll update the first row just as an example
    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "Feeding",
        feeding.toJson(),
        where: 'id= ?',
        whereArgs: [feeding.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int?> updateHealth(Vaccination_Medication vaccination_medication) async {

    // get a reference to the database
    // because this is an expensive operation we use async and await

    // row to update


    // We'll update the first row just as an example
    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "Vaccination_Medication",
        vaccination_medication.toJson(),
        where: 'id= ?',
        whereArgs: [vaccination_medication.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }


  static Future<int?> insertMedVac(Vaccination_Medication vaccination_medication) async {

    return await _database?.insert(
      'Vaccination_Medication',
      vaccination_medication.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<List<Vaccination_Medication>>  getMedVacByFlock(int id) async {
    var result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication where f_id = $id");
    List<Vaccination_Medication> _List = [];
    Vaccination_Medication flock_detail;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock_detail = Vaccination_Medication.fromJson(json);
            _List.add(flock_detail);
            print(_List);
          }
        }
        Map<String, dynamic> json = result[0];
        flock_detail = Vaccination_Medication.fromJson(json);
      }
    }
    return _List;
  }

  static Future<List<Feeding>>  getFeedingsByFlock(int id) async {
    var result = await _database?.rawQuery("SELECT * FROM Feeding where f_id = $id");
    List<Feeding> _List = [];
    Feeding flock_detail;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock_detail = Feeding.fromJson(json);
            _List.add(flock_detail);
            print(_List);
          }
        }
        Map<String, dynamic> json = result[0];
        flock_detail = Feeding.fromJson(json);
      }
    }
    return _List;
  }



  static Future<List<TransactionItem>>  getTransactionByFlock(int id) async {
    var result = await _database?.rawQuery("SELECT * FROM Transactions where f_id = $id");
    List<TransactionItem> _List = [];
    TransactionItem flock_detail;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock_detail = TransactionItem.fromJson(json);
            _List.add(flock_detail);
            print(_List);
          }
        }

        Map<String, dynamic> json = result[0];
        flock_detail = TransactionItem.fromJson(json);
      }
    }
    return _List;
  }

  static Future<List<Flock_Detail>>  getFlockDetailsByFlock(int id) async {
    var result = await _database?.rawQuery("SELECT * FROM Flock_Detail where f_id = $id");
    List<Flock_Detail> _List = [];
    Flock_Detail flock_detail;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock_detail = Flock_Detail.fromJson(json);
            _List.add(flock_detail);
            print(_List);
          }
        }

        Map<String, dynamic> json = result[0];
        flock_detail = Flock_Detail.fromJson(json);
      }
    }
    return _List;
  }

  static Future<List<Flock_Detail>>  getFlockDetails() async {
    var result = await _database?.rawQuery("SELECT * FROM Flock_Detail");
    List<Flock_Detail> _List = [];
    Flock_Detail flock_detail;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock_detail = Flock_Detail.fromJson(json);
            _List.add(flock_detail);
            print(_List);
          }
        }

        Map<String, dynamic> json = result[0];
        flock_detail = Flock_Detail.fromJson(json);
      }
    }
    return _List;
  }

  static Future<List<Eggs>>  getEggsCollections() async {
    var result = await _database?.rawQuery("SELECT * FROM Eggs");
    List<Eggs> _eggList = [];
    Eggs eggs;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            eggs = Eggs.fromJson(json);
            _eggList.add(eggs);
            print(_eggList);
          }
        }

        Map<String, dynamic> json = result[0];
        eggs = Eggs.fromJson(json);
      }
    }
    return _eggList;
  }

  static Future<List<Eggs>>  getFilteredEggs(int f_id,String type,String str_date, String end_date) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where collection_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Eggs");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where isCollection = $type");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where isCollection = $type and collection_date BETWEEN  '$str_date' and '$end_date'");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where f_id = $f_id and collection_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Eggs where f_id = $f_id");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where f_id = $f_id and isCollection = $type");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Eggs where f_id = $f_id and isCollection = $type and collection_date BETWEEN '$str_date' and '$end_date'");
      }
    }

    print(result);
    List<Eggs> _transactionList = [];
    Eggs _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = Eggs.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = Eggs.fromJson(json);
      }
    }
    return _transactionList;
  }


  static Future<List<Flock_Detail>>  getFilteredFlockDetails(int f_id,String type,String str_date, String end_date) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where acqusition_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Flock_Detail");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where item_type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN  '$str_date' and '$end_date'");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and acqusition_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Flock_Detail where f_id = $f_id");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and item_type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and item_type = '$type' and acqusition_date BETWEEN  '$str_date' and '$end_date'");
      }
    }

    print(result);
    List<Flock_Detail> _transactionList = [];
    Flock_Detail _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = Flock_Detail.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = Flock_Detail.fromJson(json);
      }
    }
    return _transactionList;
  }

  static Future<List<Vaccination_Medication>>  getFilteredMedication(int f_id,String type,String str_date, String end_date) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where type = '$type' and date BETWEEN  '$str_date' and '$end_date'");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication where f_id = $f_id");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and type = '$type' and date BETWEEN  '$str_date' and '$end_date'");
      }
    }

    print(result);
    List<Vaccination_Medication> _transactionList = [];
    Vaccination_Medication _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = Vaccination_Medication.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = Vaccination_Medication.fromJson(json);
      }
    }
    return _transactionList;
  }

  static Future<List<Feeding>>  getFilteredFeeding(int f_id,String type,String str_date, String end_date) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where feeding_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Feeding");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding ");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where and feeding_date BETWEEN  '$str_date' and '$end_date'");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id and feeding_date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Feeding where f_id = $f_id");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id ");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id  and feeding_date BETWEEN  '$str_date' and '$end_date'");
      }
    }

    print(result);
    List<Feeding> _transactionList = [];
    Feeding _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = Feeding.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = Feeding.fromJson(json);
      }
    }
    return _transactionList;
  }
  static Future<List<Feeding>> getAllMostUsedFeeds(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id==-1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC");
      print("SELECT * from Feeding where feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC");
    }else if(f_id!=-1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where f_id='$f_id' ORDER BY quantity ASC");
      print("SELECT * from Feeding where f_id='$f_id' ORDER BY quantity ASC");
    }else if(f_id!=-1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where f_id='$f_id' and feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC");
      print("SELECT * from Feeding where f_id='$f_id' and feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC");
    }else if (f_id==-1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT * from Feeding ORDER BY quantity ASC ");
      print("SELECT * from Feeding ORDER BY quantity ASC ");
    }

    List<Feeding> _feedList = [];
    Feeding feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            feed = Feeding.fromJson(json);
            feed.quantity = feed.quantity!.replaceAll(",", ".");
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Feeding.fromJson(json);
      }
    }
    return _feedList;

  }

  static Future<List<FeedSummary>> getMyMostUsedFeeds(int f_id, String str_date, String end_date) async {
    var result;

    // Case 1: No flock ID and date range provided
    if (f_id == -1 && !str_date.isEmpty && !end_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE feeding_date BETWEEN '$str_date' AND '$end_date' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC"
      );
     // print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE feeding_date BETWEEN '$str_date' AND '$end_date' GROUP BY feed_name ORDER BY total_quantity");

      // Case 2: Flock ID provided but no date range
    } else if (f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE f_id = '$f_id' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC"
      );
     // print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE f_id = '$f_id' GROUP BY feed_name ORDER BY total_quantity");

      // Case 3: Both flock ID and date range provided
    } else if (f_id != -1 && !str_date.isEmpty && !end_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE f_id = '$f_id' AND feeding_date BETWEEN '$str_date' AND '$end_date' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC"
      );
     // print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE f_id = '$f_id' AND feeding_date BETWEEN '$str_date' AND '$end_date' GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");

      // Case 4: No flock ID and no date range (global query)
    } else if (f_id == -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC"
      );
     // print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");
    }

    List<FeedSummary> _feedList = [];
    if (result != null && result.isNotEmpty) {
      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> json = result[i];
        FeedSummary feedSummary = FeedSummary.fromMap(json);
        _feedList.add(feedSummary);
      }
    }

    return _feedList;
  }


  static Future<List<FeedSummary>> getMyTopMostUsedFeeds(int f_id, String str_date, String end_date) async {
    var result;

    // Case 1: No flock ID and date range provided
    if (f_id == -1 && !str_date.isEmpty && !end_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE feeding_date BETWEEN '$str_date' AND '$end_date' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC LIMIT 3"
      );
      print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE feeding_date BETWEEN '$str_date' AND '$end_date' GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");

      // Case 2: Flock ID provided but no date range
    } else if (f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE f_id = '$f_id' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC LIMIT 3"
      );
      print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE f_id = '$f_id' GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");

      // Case 3: Both flock ID and date range provided
    } else if (f_id != -1 && !str_date.isEmpty && !end_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "WHERE f_id = '$f_id' AND feeding_date BETWEEN '$str_date' AND '$end_date' "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC LIMIT 3"
      );
      print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding WHERE f_id = '$f_id' AND feeding_date BETWEEN '$str_date' AND '$end_date' GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");

      // Case 4: No flock ID and no date range (global query)
    } else if (f_id == -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding "
              "GROUP BY feed_name "
              "ORDER BY total_quantity DESC LIMIT 3"
      );
      print("SELECT feed_name, SUM(quantity) AS total_quantity FROM Feeding GROUP BY feed_name ORDER BY total_quantity DESC LIMIT 3");
    }

    List<FeedSummary> _feedList = [];
    if (result != null && result.isNotEmpty) {
      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> json = result[i];
        FeedSummary feedSummary = FeedSummary.fromMap(json);
        _feedList.add(feedSummary);
      }
    }

    return _feedList;
  }


  static Future<List<Feeding>> getTopMostUsedFeeds(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id==-1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC LIMIT 3");
      print("SELECT * from Feeding where feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC LIMIT 3");
    }else if(f_id!=-1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where f_id='$f_id' ORDER BY quantity ASC LIMIT 3");
      print("SELECT * from Feeding where f_id='$f_id' ORDER BY quantity ASC LIMIT 3");
    }else if(f_id!=-1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT * from Feeding where f_id='$f_id' and feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC LIMIT 3");
      print("SELECT * from Feeding where f_id='$f_id' and feeding_date BETWEEN '$str_date'and '$end_date' ORDER BY quantity ASC LIMIT 3");
    }else if (f_id==-1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT * from Feeding ORDER BY quantity ASC LIMIT 3");
      print("SELECT * from Feeding ORDER BY quantity ASC LIMIT 3");
    }

    List<Feeding> _feedList = [];
    Feeding feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            feed = Feeding.fromJson(json);
            feed.quantity = feed.quantity!.replaceAll(",", ".");
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Feeding.fromJson(json);
      }
    }
    return _feedList;

  }

  static Future<num> getTotalFeedConsumption(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id == -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(quantity) FROM Feeding where feeding_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(quantity) FROM Feeding where feeding_date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id!=-1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT sum(quantity) FROM Feeding where f_id = $f_id ");
      print("SELECT sum(quantity) FROM Feeding where f_id = $f_id ");
    }
    else if (f_id!=-1 && !str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT sum(quantity) FROM Feeding where f_id = $f_id and feeding_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(quantity) FROM Feeding where f_id = $f_id and feeding_date BETWEEN '$str_date'and '$end_date'");
    }else if (f_id==-1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT sum(quantity) FROM Feeding");
      print("SELECT sum(quantity) FROM Feeding");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return num.parse(map.values.first.toString().replaceAll(",", "."));

  }

  // INCOME/EXPENSE

  static Future<double> getTransactionsTotal(int f_id, String type, String str_date, String end_date) async {

    var result;

    if(type.isEmpty){
      type = "type = 'Income' or type='Expense'";
    }else{
      type = "type = '$type'";
    }
    if(f_id == -1) {
      result = await _database?.rawQuery(
          "SELECT sum(CAST(REPLACE(amount,',','.') as REAL)) FROM Transactions where $type and date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1) {
      result = await _database?.rawQuery(
          "SELECT sum(CAST(REPLACE(amount,',','.') as REAL)) FROM Transactions where $type and f_id = $f_id and date BETWEEN '$str_date'and '$end_date' ");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return double.parse(map.values.first.toString().replaceAll(",", "."));

  }


  //HEALTH

  static Future<int> getHealthTotal(int f_id, String type, String str_date, String end_date) async {

    var result;

    if(type.isEmpty){
      type = "type = 'Vaccination' or type='Medication'";
    }else{
      type = "type = '$type'";
    }
    if(f_id == -1) {
      result = await _database?.rawQuery(
          "SELECT count(*) FROM Vaccination_Medication where $type and date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1) {
      result = await _database?.rawQuery(
          "SELECT count(*) FROM Vaccination_Medication where $type and f_id = $f_id ");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString().replaceAll(",", "."));

  }

  static Future<List<BirdUsage>> getBirdUSage(int f_id) async {

    var result = null;
    List<BirdUsage> _transactionList = [];
    try {
      result = await _database?.rawQuery(
          "select reason,sum(item_count) from Flock_Detail where item_type = 'Reduction' and f_id = $f_id GROUP BY reason ");

      BirdUsage _transaction;
      if (result != null) {
        if (result.isNotEmpty) {
          if (result.isNotEmpty) {
            for (int i = 0; i < result.length; i ++) {
              Map<String, dynamic> json = result[i];

              _transaction = BirdUsage.fromJson(json);
              _transactionList.add(_transaction);
              print(_transactionList);
            }
          }

          Map<String, dynamic> json = result[0];
          _transaction = BirdUsage.fromJson(json);
        }
      }
    }
    catch(ex){
      print("USAGE $ex");

    }
    return _transactionList;
  }

  static Future<int> getAllFlockBirdsCount(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id == -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(active_bird_count) FROM Flock where acqusition_date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT active_bird_count FROM Flock where f_id = $f_id ");

    }else if(f_id != -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT active_bird_count FROM Flock where f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date' ");

    }else if (f_id == -1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT sum(active_bird_count) FROM Flock");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString());

  }

  static Future<int> getAllFlockInitialBirdsCount(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id == -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Flock where acqusition_date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT bird_count FROM Flock where f_id = $f_id ");

    }else if(f_id != -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT bird_count FROM Flock where f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date' ");

    }else if (f_id == -1 && str_date.isEmpty){
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Flock");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString());

  }

  static Future<int> getBirdsCalculations(int f_id, String type,String str_date, String end_date) async {

    var result;

    if(f_id==-1) {
      result = await _database?.rawQuery(
          "SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN '$str_date'and '$end_date'");
    }else if (f_id!=-1){
      result = await _database?.rawQuery(
          "SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date'");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString());

  }

  static Future<int> getUniqueEggCalculations(int f_id,int type,String str_date, String end_date) async {

    var result;

    result = await _database?.rawQuery(
        "SELECT sum(total_eggs) FROM Eggs where isCollection = $type and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");
    print("SELECT sum(total_eggs) FROM Eggs where isCollection = $type and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");


    Map<String,dynamic> map = result![0];
    print(map.values.first);
    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString());

  }


  static Future<int> getEggCalculations(int f_id,int type,String str_date, String end_date) async {

    var result;

    if(f_id==-1) {
      result = await _database?.rawQuery(
          "SELECT sum(total_eggs) FROM Eggs where isCollection = $type and collection_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(total_eggs) FROM Eggs where isCollection = $type and collection_date BETWEEN '$str_date'and '$end_date'");
    }else if (f_id!=-1){
      result = await _database?.rawQuery(
          "SELECT sum(total_eggs) FROM Eggs where isCollection = $type and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");
      print("SELECT sum(total_eggs) FROM Eggs where isCollection = $type and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);
    if(map.values.first.toString().toLowerCase() == 'null')
        return 0;
    else
        return int.parse(map.values.first.toString());

  }

  static Future<TransactionItem?> getSingleTransaction(String id) async {

    final map = await _database?.rawQuery(
        "SELECT * FROM Transactions where id = ?",[id]
    );

    if (map!.isNotEmpty) {
      return TransactionItem.fromJson(map.first);
    } else {
      return null;
    }
  }

  /*static Future<List<TransactionItem>> getSingleTransaction(String id) async{
    var result = null;
    result = await _database?.rawQuery(
        "SELECT * FROM Transactions where id = '$id'");

    print(result);
    List<TransactionItem> _transactionList = [];
    TransactionItem _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = TransactionItem.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = TransactionItem.fromJson(json);
      }
    }
    return _transactionList;

  }
*/
  static Future<List<TransactionItem>>  getReportFilteredTransactions(int f_id,String type,String str_date,String end_date) async {

    var result = null;

    if (f_id == -1) {
      result = await _database?.rawQuery(
          "SELECT * FROM Transactions where date BETWEEN '$str_date' and '$end_date'");
    } else if(f_id!= -1) {
      result = await _database?.rawQuery(
          "SELECT * FROM Transactions where f_id = $f_id and date BETWEEN  '$str_date' and '$end_date'");
    }

    print(result);
    List<TransactionItem> _transactionList = [];
    TransactionItem _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = TransactionItem.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = TransactionItem.fromJson(json);
      }
    }
    return _transactionList;
  }


  static Future<List<TransactionItem>>  getFilteredTransactions(int f_id,String type,String str_date, String end_date) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Transactions");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where type = '$type' and date BETWEEN  '$str_date' and '$end_date'");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and date BETWEEN '$str_date' and '$end_date'");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Transactions where f_id = $f_id");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and type = '$type'");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and type = '$type' and date BETWEEN  '$str_date' and '$end_date'");
      }
    }

    print(result);
    List<TransactionItem> _transactionList = [];
    TransactionItem _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = TransactionItem.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = TransactionItem.fromJson(json);
      }
    }
    return _transactionList;
  }

  static Future<List<TransactionItem>>  getAllTransactions() async {
    var result = await _database?.rawQuery("SELECT * FROM Transactions");
    List<TransactionItem> _transactionList = [];
    TransactionItem _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = TransactionItem.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }
        Map<String, dynamic> json = result[0];
        _transaction = TransactionItem.fromJson(json);
      }
    }
    return _transactionList;
  }

  static Future<List<TransactionItem>>  getAllIncomes() async {
    var result = await _database?.rawQuery("SELECT * FROM Transactions where type = 'Income'");
    List<TransactionItem> _transactionList = [];
    TransactionItem _transaction;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            _transaction = TransactionItem.fromJson(json);
            _transactionList.add(_transaction);
            print(_transactionList);
          }
        }

        Map<String, dynamic> json = result[0];
        _transaction = TransactionItem.fromJson(json);
      }
    }
    return _transactionList;
  }


  static Future<List<Feed_Report_Item>>  getAllFeedingsReport(String strDate,String endDate) async {
    var result = await _database?.rawQuery("SELECT feed_name,sum(quantity) FROM Feeding WHERE feeding_date >= '$strDate' and feeding_date <= '$endDate' GROUP BY feed_name");
    List<Feed_Report_Item> _feedList = [];
    Feed_Report_Item feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            feed = Feed_Report_Item.fromJson(json);
            feed.consumption = num.parse(feed.consumption!.toStringAsFixed(2));

            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Feed_Report_Item.fromJson(json);
      }
    }

    print(_feedList);
    return _feedList;
  }

  //FFUNC
  static Future<List<Health_Chart_Item>>  getHealthReportData(String strDate,String endDate, String itype) async {
    var result = await _database?.rawQuery("SELECT date, count(id) FROM Vaccination_Medication WHERE date >= '$strDate' and date <= '$endDate' and type = '$itype'  GROUP BY date");
    List<Health_Chart_Item> _feedList = [];
    Health_Chart_Item feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++) {
            Map<String, dynamic> json = result[i];

            feed = Health_Chart_Item.fromJson(json);
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Health_Chart_Item.fromJson(json);
      }
    }

    print(_feedList);
    return _feedList;
  }


  //FFUNC
  static Future<List<Eggs_Chart_Item>>  getEggsReportData(String strDate,String endDate, int itype) async {
    var result = await _database?.rawQuery("SELECT collection_date,sum(total_eggs) FROM Eggs WHERE collection_date >= '$strDate' and collection_date <= '$endDate' and isCollection = '$itype'  GROUP BY collection_date");
    List<Eggs_Chart_Item> _feedList = [];
    Eggs_Chart_Item feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++) {
            Map<String, dynamic> json = result[i];

            feed = Eggs_Chart_Item.fromJson(json);
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Eggs_Chart_Item.fromJson(json);
      }
    }

    print(_feedList);
    return _feedList;
  }

  //FFUNC
  static Future<List<Finance_Chart_Item>>  getFinanceChartData(String strDate,String endDate, String itype) async {
    var result = await _database?.rawQuery("SELECT type,date,sum(CAST(REPLACE(amount,',','.') as REAL)) FROM Transactions WHERE date >= '$strDate' and date <= '$endDate' and type = '$itype'  GROUP BY date");
    List<Finance_Chart_Item> _feedList = [];
    Finance_Chart_Item feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          String date ="", type="", amount="";
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];
            print(json);
            result[i].forEach((index, value) {
              print("$index - $value");
              if(index.toString()=="date")
                date = value.toString();
              else if(index.toString()=="type")
                type = value.toString();
              else
                amount = value.toString();
            });
            feed = Finance_Chart_Item(date: date, type: type, amount: double.parse(amount));
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Finance_Chart_Item.fromJson(json);
      }
    }

    print(_feedList);
    return _feedList;
  }


  static Future<List<FeedFlock_Report_Item>>  getAllFeedingsReportByFlock(String strDate,String endDate) async {
    var result = await _database?.rawQuery("SELECT f_name,sum(quantity) FROM Feeding WHERE feeding_date >= '$strDate' and feeding_date <= '$endDate' GROUP BY f_name");
    List<FeedFlock_Report_Item> _feedList = [];
    FeedFlock_Report_Item feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];
            feed = FeedFlock_Report_Item.fromJson(json);
            feed.consumption = num.parse(feed.consumption!.toStringAsFixed(2));
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = FeedFlock_Report_Item.fromJson(json);
      }
    }

    print(_feedList);
    return _feedList;
  }


  static Future<List<Feeding>>  getAllFeedings() async {
    var result = await _database?.rawQuery("SELECT * FROM Feeding");
    List<Feeding> _feedList = [];
    Feeding feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            feed = Feeding.fromJson(json);
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = Feeding.fromJson(json);
      }
    }
    return _feedList;
  }


  static Future<List<Vaccination_Medication>>  getAllVaccinationMedications() async {
    var result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication");
    List<Vaccination_Medication> _medList = [];
    Vaccination_Medication medi;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            medi = Vaccination_Medication.fromJson(json);
            _medList.add(medi);
            print(_medList);
          }
        }

        Map<String, dynamic> json = result[0];
        medi = Vaccination_Medication.fromJson(json);
      }
    }
    return _medList;
  }


  static Future<List<SubItem>>  getSubCategoryList(int i) async {
    var result = await _database?.rawQuery("SELECT * FROM Category_Detail where c_id = $i");
    List<SubItem> _feedList = [];
    SubItem feed;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            feed = SubItem.fromJson(json);
            _feedList.add(feed);
            print(_feedList);
          }
        }

        Map<String, dynamic> json = result[0];
        feed = SubItem.fromJson(json);
      }
    }
    return _feedList;
  }

  static Future<String> getFlockName(int id) async {

    var result = await _database?.rawQuery("SELECT f_name FROM Flock where f_id = $id");

    return result![0].toString();

   }

  static Future<int> getFlockActiveBirds(int id) async {

    print(id);
    var result = await _database?.rawQuery("SELECT active_bird_count FROM Flock where f_id = $id");

    print(result![0]);
    return int.parse(result![0].toString());

  }

  static Future<List<Flock>>  getFlocks() async {
    var result = await _database?.rawQuery("SELECT * FROM Flock where active = 1");
    List<Flock> _birdList = [];
    Flock flock;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock = Flock.fromJson(json);
            _birdList.add(flock);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        flock = Flock.fromJson(json);
      }
    }
    return _birdList;
  }

  static Future<int>  getFlocksNamesCount(String name) async {
    int index = 0;
    var result = await _database?.rawQuery("SELECT * FROM Flock where active = 1 AND f_name = '${name}'");
    List<Flock> _birdList = [];
    Flock flock;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock = Flock.fromJson(json);
            if(flock.f_name == name){
              index++;
            }

          }
        }

      }
    }
    return index;
  }

  static Future<List<Flock>>  getAllFlocks() async {
    var result = await _database?.rawQuery("SELECT * FROM Flock");
    List<Flock> _birdList = [];
    Flock flock;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock = Flock.fromJson(json);
            _birdList.add(flock);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        flock = Flock.fromJson(json);
      }
    }
    return _birdList;
  }

  static Future<int>  deleteSubItem(SubItem subItem) async {
    var result = await _database?.rawQuery("DELETE FROM Category_Detail WHERE id = '${subItem.id}'");
    return 1;
  }

  static Future<int>  deleteItem(String table, int id) async {
    var result = await _database?.rawQuery("DELETE FROM $table WHERE id = $id");

    return 1;
  }

  static Future<int>  deleteItemWithFlockID(String table, int id) async {
    var result = await _database?.rawQuery("DELETE FROM $table WHERE f_id = $id");

    return 1;
  }

  static Future<int>  updateFlockStatus (int active, int id) async {
    var result = await _database?.rawUpdate("UPDATE Flock SET active = '${active}' WHERE f_id = ${id}");
    return 1;
  }

  static Future<int>  updateFlockName (String name, int id) async {
    var result = await _database?.rawUpdate("UPDATE Flock SET f_name = '$name' WHERE f_id = ${id}");
    return 1;
  }

  static Future<int>  deleteFlock (Flock flock) async {
    var result = await _database?.rawQuery("DELETE FROM Flock WHERE f_id = '${flock.f_id}'");
    return 1;
  }

  static Future<int>  deleteFlockDetails (int id) async {
    var result = await _database?.rawQuery("DELETE FROM Flock_Detail WHERE f_id = $id");
    return 1;
  }

  static Future<int>  updateFlockBirds (int count, int id) async {
    var result = await _database?.rawUpdate("UPDATE Flock SET active_bird_count = '${count}' WHERE f_id = ${id}");
    return 1;
  }

  static Future<int>  updateCurrency(String currency) async {
    var result = await _database?.rawUpdate("UPDATE FarmSetup SET currency = '${currency}' WHERE id = 1");
    return 1;
  }

  static Future<int>  updateFarmSetup (FarmSetup? farmSetup) async {
    var result = await _database?.rawUpdate("UPDATE FarmSetup SET name = '${farmSetup!.name}'"
        ",image = '${farmSetup!.image}'"
        ",modified = 1,date = '${farmSetup!.date}',location = '${farmSetup!.location}'"
        "  WHERE id = 1");
    return 1;
  }

  static Future<Flock> findFlock(int id) async {

    var result =  await _database?.query('Flock', where: "f_id = ?", whereArgs: [id], limit: 1);
    Map<String, dynamic> json = result![0];

    Flock flock =  Flock.fromJson(json);
    print(flock);

    return flock;
  }

  static Future<List<Flock_Image>> getFlockImage(int f_id) async {
    var result = await _database?.rawQuery("SELECT * FROM Flock_Image where f_id = $f_id");
    List<Flock_Image> _birdList = [];
    Flock_Image flock;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            flock = Flock_Image.fromJson(json);
            _birdList.add(flock);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        flock = Flock_Image.fromJson(json);
      }
    }
    return _birdList;
  }
}