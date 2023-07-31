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
import '../model/flock_image.dart';
import '../model/transaction_item.dart';
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

  static Future<int?> insertMedVac(Vaccination_Medication vaccination_medication) async {

    return await _database?.insert(
      'Vaccination_Medication',
      vaccination_medication.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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

  static Future<int>  deleteFlock (Flock flock) async {
    var result = await _database?.rawQuery("DELETE FROM Flock WHERE f_id = '${flock.f_id}\'");
    return 1;
  }
  static Future<int>  updateFlockName (int count, int id) async {
    var result = await _database?.rawUpdate("UPDATE Flock SET bird_count = '${count}' WHERE f_id = ${id}");
    return 1;
  }
}