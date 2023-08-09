import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:poultary/model/egg_item.dart';
import 'package:poultary/model/flock.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';

import '../model/bird_item.dart';
import '../model/category_item.dart';
import '../model/feed_item.dart';
import '../model/flock_detail.dart';
import '../model/flock_image.dart';
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
  static Future<int?>  insertFlock(Flock flock) async {

     return await _database?.insert(
      'Flock',
      flock.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  static Future<int?>  insertFlockImages(Flock_Image image) async {

    return await _database?.insert(
      'Flock_Image',
      image.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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

  static Future<int?> insertMedVac(Vaccination_Medication vaccination_medication) async {

    return await _database?.insert(
      'Vaccination_Medication',
      vaccination_medication.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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
  static Future<List<Feeding>> getAllMostUsedFeeds(int f_id, String type,String str_date, String end_date) async {

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

  static Future<int> getTotalFeedConsumption(int f_id,String str_date, String end_date) async {

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
      return int.parse(map.values.first.toString());

  }

  // INCOME/EXPENSE

  static Future<int> getTransactionsTotal(int f_id, String type, String str_date, String end_date) async {

    var result;

    if(type.isEmpty){
      type = "type = 'Income' or type='Expense'";
    }else{
      type = "type = '$type'";
    }
    if(f_id == -1) {
      result = await _database?.rawQuery(
          "SELECT sum(amount) FROM Transactions where $type and date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1) {
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Transactions where $type and f_id = $f_id ");
    }

    Map<String,dynamic> map = result![0];
    print(map.values.first);

    if(map.values.first.toString().toLowerCase() == 'null')
      return 0;
    else
      return int.parse(map.values.first.toString());

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
      return int.parse(map.values.first.toString());

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
      print(ex);
    }
    return _transactionList;
  }

  static Future<int> getAllFlockBirdsCount(int f_id,String str_date, String end_date) async {

    var result;

    if(f_id == -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Flock where acqusition_date BETWEEN '$str_date'and '$end_date'");
    }else if(f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Flock where f_id = $f_id ");

    }else if(f_id != -1 && !str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(bird_count) FROM Flock where f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date' ");

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

  static Future<int>  deleteFlock (Flock flock) async {
    var result = await _database?.rawQuery("DELETE FROM Flock WHERE f_id = '${flock.f_id}\'");
    return 1;
  }
  static Future<int>  updateFlockBirds (int count, int id) async {
    var result = await _database?.rawUpdate("UPDATE Flock SET active_bird_count = '${count}' WHERE f_id = ${id}");
    return 1;
  }

  static Future<Flock> findFlock(int id) async {

    var result =  await _database?.query('Flock', where: "f_id = ?", whereArgs: [id], limit: 1);
    Map<String, dynamic> json = result![0];

    Flock flock =  Flock.fromJson(json);
    print(flock);

    return flock;
  }

  static Future<List<Flock_Image>> getFlockImage(int f_id) async{
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