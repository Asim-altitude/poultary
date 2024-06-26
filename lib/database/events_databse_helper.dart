import 'dart:ffi';

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
import '../model/event_item.dart';
import '../model/farm_item.dart';
import '../model/feed_item.dart';
import '../model/feed_report_item.dart';
import '../model/feedflock_report_item.dart';
import '../model/finance_chart_data.dart';
import '../model/flock_detail.dart';
import '../model/flock_image.dart';
import '../model/health_chart_data.dart';
import '../model/transaction_item.dart';
import '../model/used_item.dart';
class EventsDatabaseHelper  {
  static const _databaseName = "assets/events.db";

  static const user_table = 'MyEvents';

  static final EventsDatabaseHelper _db = EventsDatabaseHelper._internal();

  EventsDatabaseHelper._internal();
  static EventsDatabaseHelper get instance => _db;
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
      ByteData data = await rootBundle.load(join("assets", "events.db"));
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
        "${abcd.absolute.path}/assets/events.db";

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
        "${abcd.absolute.path}/assets/events.db";
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

  static Future<List<MyEvent>>  getAllReminders(int active) async {


    var result = null;
    if(active==-1){
      result = await _database?.rawQuery(
          "SELECT * FROM MyEvents");
    }else {
      result = await _database?.rawQuery(
          "SELECT * FROM MyEvents where isActive = '$active' ");
    }

    List<MyEvent> _birdList = [];
    MyEvent bird;
    if(result!=null){
      if(result.isNotEmpty){
        if(result.isNotEmpty){
          for(int i = 0 ; i < result.length ; i ++){
            Map<String, dynamic> json = result[i];

            bird = MyEvent.fromJson(json);
            _birdList.add(bird);
            print(_birdList);
          }
        }

        Map<String, dynamic> json = result[0];
        bird = MyEvent.fromJson(json);
      }
    }
    return _birdList;
  }

  static Future<int?> insertNewEvent(MyEvent myEvent) async{
    return await _database?.insert(
      'MyEvents',
      myEvent.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }




  static Future<int?> updateEvent(MyEvent? myEvent) async {


    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "MyEvents",
        myEvent!.toJson(),
        where: 'id= ?',
        whereArgs: [myEvent.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int>  deleteEventItem(int id) async {
    var result = await _database?.rawQuery("DELETE FROM MyEvents WHERE id = '$id'");
    return 1;
  }


}