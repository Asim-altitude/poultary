import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/connectors/v1.dart';
import 'package:poultary/model/egg_item.dart';
import 'package:poultary/model/flock.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/model/medicine_stock_history.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';

import '../financial_report_screen.dart';
import '../model/bird_item.dart';
import '../model/category_item.dart';
import '../model/custom_category.dart';
import '../model/custom_category_data.dart';
import '../model/egg_income.dart';
import '../model/eggs_chart_data.dart';
import '../model/farm_item.dart';
import '../model/feed_batch.dart';
import '../model/feed_batch_item.dart';
import '../model/feed_batch_summary.dart';
import '../model/feed_ingridient.dart';
import '../model/feed_item.dart';
import '../model/feed_report_item.dart';
import '../model/feed_stock_history.dart';
import '../model/feed_stock_summary.dart';
import '../model/feed_summary.dart';
import '../model/feed_summary_flock.dart';
import '../model/feedflock_report_item.dart';
import '../model/finance_chart_data.dart';
import '../model/finance_summary_flock.dart';
import '../model/flock_detail.dart';
import '../model/flock_image.dart';
import '../model/health_chart_data.dart';
import '../model/medicine_stock_summary.dart';
import '../model/sale_contractor.dart';
import '../model/schedule_notification.dart';
import '../model/stock_expense.dart';
import '../model/transaction_item.dart';
import '../model/used_item.dart';
import '../model/vaccine_stock_history.dart';
import '../model/vaccine_stock_summary.dart';
import '../model/weight_record.dart';
import '../multiuser/model/permission.dart';
import '../multiuser/model/role.dart';
import '../multiuser/model/sync_queue.dart';
import '../multiuser/model/user.dart';
import '../multiuser/utils/SyncStatus.dart';
import '../utils/utils.dart';
import 'package:uuid/uuid.dart';

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



  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
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
    return await openDatabase(path,readOnly: false, /*onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 1) {



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

        ]; // Add your actual table names

        for (final table in tables) {
          await addSyncColumnsToTable( table);
          await assignSyncIds(table);
        }
      }
    }*/);
  }

  Future<void> addSyncColumnsToTable(String tableName) async {
    final columns = await _getTableColumns( tableName);

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

  Future<void> assignSyncIds(String tableName) async {
    final uuid = Uuid();

    String idColumn = (tableName.toLowerCase() == "flock" || tableName.toLowerCase() == "flock_detail") ? "f_id" : "id";

    print("SYNC_TABLE $tableName ID $idColumn");
    try {
      final List<Map<String, Object?>>? rows = await _database?.query(
        tableName,
        where: 'sync_id IS NULL OR sync_id = ""',
      );

      for (final row in rows!) {
        final id = row[idColumn]; // assuming each row has an `id` column
        final newSyncId = uuid.v4();
        await _database?.update(
          tableName,
          {'sync_id': newSyncId},
          where: '$idColumn = ?',
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
  Future<List<String>> _getTableColumns(String tableName) async {
    final result = await _database?.rawQuery('PRAGMA table_info($tableName)');
    return result!.map((row) => row['name'] as String).toList();
  }


  static Future<File> getFilePathDB() async {
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

  static restoreDatabase() async {
    File abcd = await _db.dBToCopy();
    String recoveryPath =
        "${abcd.absolute.path}/assets/poultary.db";
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

  static Future<void> createSyncFailedTable() async {
    await _database?.execute('''
      CREATE TABLE IF NOT EXISTS SyncQueue(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT,                     
  payload TEXT,                  
  sync_id TEXT,  
  operation_type TEXT,               
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TEXT
)
  ''');
  }

  static Future<void> createSaleContractorTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS SaleContractor(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      address TEXT,
      phone TEXT,
      email TEXT,
      notes TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  }

  static Future<void> createCategoriesDataTable() async {
    await _database?.execute('''
      CREATE TABLE IF NOT EXISTS CustomCategoryData(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      f_id INTEGER NOT NULL,
      c_id INTEGER NOT NULL,
      f_name TEXT NOT NULL,
      c_type TEXT NOT NULL,
      c_name TEXT NOT NULL,
      item_type TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      date TEXT NOT NULL,
      note TEXT
    )
    ''');
  }

  static Future<void> createCustomCategoriesTableIfNotExists() async {
    await _database?.execute('''
      CREATE TABLE IF NOT EXISTS CustomCategory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        itemtype TEXT NOT NULL,
        cat_type TEXT NOT NULL,
        unit TEXT NOT NULL,
        enabled INTEGER NOT NULL,
        icon INTEGER NOT NULL
      )
    ''');
  }


  static Future<void> createWeightRecordTableIfNotExists() async {
    await _database?.execute('''
  CREATE TABLE IF NOT EXISTS WeightRecord(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    f_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    average_weight REAL NOT NULL,
    number_of_birds INTEGER,
    notes TEXT
  );
''');
  }


  static Future<void> createMultiUserTables() async {
  await _database?.execute('''
      CREATE TABLE IF NOT EXISTS permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      );
    ''');

  await _database?.execute('''
      CREATE TABLE IF NOT EXISTS roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

  await _database?.execute('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        role_id INTEGER,
        permission_id INTEGER,
        PRIMARY KEY (role_id, permission_id),
        FOREIGN KEY (role_id) REFERENCES roles(id),
        FOREIGN KEY (permission_id) REFERENCES permissions(id)
      );
    ''');

  }


  static Future<void> createUsersTableIfNotExists() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS User(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      farm_id TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL
    )
  ''');
  }

  static Future<void> saveToSyncQueue({
    required String type,
    required String syncId,
    required String payload,
    required String opType,
    String? lastError,
  }) async {
    await _database?.insert("SyncQueue", {
      'type': type,
      'sync_id': syncId,
      'payload': payload,
      'retry_count': 0,
      'operation_type' : opType,
      'last_error': lastError,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateSyncQueueError({required int id, required String error,required int retryCount}) async {
    await _database?.update(
      'SyncQueue',
      {
        'retry_count': retryCount,
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<List<SyncQueue>?> getAllSyncQueueItems(String syncId) async {
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'SyncQueue',
        where: 'sync_id = ?',
        whereArgs: [syncId],
      );

      return maps.map((map) => SyncQueue.fromMap(map)).toList();
    } catch (ex) {
      print('Error fetching sync queue items: $ex');
      return null;
    }
  }



  static Future<void> deleteSyncQueueRecord(int id) async {
    await _database?.delete('SyncQueue', where: 'id = ?', whereArgs: [id]);
  }


  static Future<bool> checkIfRecordExistsSyncID(String table, String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      table,                        // Your table name
      columns: ['sync_id'],
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    return result!.isNotEmpty;
  }

  static Future<bool> checkFlockBySyncID(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'Flock',                        // Your table name
      columns: ['sync_id'],
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    return result!.isNotEmpty;
  }

  static Future<FeedBatch?> getFeedBatchById(int Id) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'FeedBatch',
      where: 'id = ?',
      whereArgs: [Id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedBatch.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<FeedBatch?> getFeedBatchBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'FeedBatch',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedBatch.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<Feeding?> getFeedingBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'Feeding',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return Feeding.fromJson(result.first);
    } else {
      return null;
    }
  }


  static Future<VaccineStockHistory?> getVaccineStockHistotyByID(String id) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'VaccineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return VaccineStockHistory.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<VaccineStockHistory?> getVaccineStockHistotyBySyncID(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'VaccineStockHistory',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return VaccineStockHistory.fromMap(result.first);
    } else {
      return null;
    }
  }


  static Future<MedicineStockHistory?> getMedicineStockHistotyByID(String id) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'MedicineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return MedicineStockHistory.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<MedicineStockHistory?> getMedicineStockHistotyBySyncID(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'MedicineStockHistory',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return MedicineStockHistory.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<FeedStockHistory?> getFeedStockHistotyByID(String id) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'FeedStockHistory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedStockHistory.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<FeedStockHistory?> getFeedStockHistotyBySyncID(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'FeedStockHistory',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedStockHistory.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<CustomCategoryData?> getCustomCategoryDataBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'CustomCategoryData',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return CustomCategoryData.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<SaleContractor?> getSaleContractorBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'SaleContractor',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return SaleContractor.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<WeightRecord?> getWeightRecordBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'WeightRecord',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return WeightRecord.fromJson(result.first);
    } else {
      return null;
    }
  }


  static Future<SubItem?> getSubCategoryBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'Category_Detail',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return SubItem.fromJson(result.first);
    } else {
      return null;
    }
  }


  static Future<CustomCategory?> getCustomCategoryBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'CustomCategory',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return CustomCategory.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<FeedIngredient?> getFeedIngredientBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'FeedIngredient',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedIngredient.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<TransactionItem?> getTransactionBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'Transactions',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return TransactionItem.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<Vaccination_Medication?> getVaccinationBySyncId(String syncId) async {
    final List<Map<String, dynamic>>? result = await _database?.query(
      'Vaccination_Medication',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return Vaccination_Medication.fromJson(result.first);
    } else {
      return null;
    }
  }

  static Future<Flock?> getFlockBySyncId(String? syncId) async {

    if(syncId == null || syncId == "")
      return Flock(f_id: -1, f_name: "Farm Wide", purpose: "All Purpose", icon: "", acqusition_type: "", acqusition_date: "", notes: "notes");

    final List<Map<String, dynamic>>? result = await _database?.query(
      'Flock',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return Flock.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<int?> insertUser(MultiUser user) async {

    return await _database?.insert('User', user.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<MultiUser>> getAllUsers() async {
    try {
      final result = await _database?.query('User');
      return result!.map((map) => MultiUser.fromMap(map)).toList();
    }
    catch(ex){
      print(ex);
      return [];
    }
  }

  static Future<List<MultiUser>> getAllNonAdminUsers() async {
    final result = await _database?.query(
      'User',
      where: 'role != ?',
      whereArgs: ['Admin'],
    );
    return result!.map((map) => MultiUser.fromMap(map)).toList();
  }


  static Future<int?> updateUser(MultiUser user) async {
    return await  _database?.update(
      'User',
      user.toLocalMap(),
      where: 'email = ?',
      whereArgs: [user.email],
    );
  }

  static Future<int?> deleteUser(String email) async {
    return await  _database?.delete(
      'User',
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  static Future<MultiUser?> loginUser(String email, String password) async {
    final hashed = Utils().hashPassword(password);
    final result = await _database?.query(
      'User',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashed],
    );
    if (result!.isNotEmpty) {
      return MultiUser.fromMap(result.first);
    }
    return null;
  }



  static Future<int?> insertRole(Role role) async {
  return await _database?.insert('roles', role.toMap());
  }

  static Future<int?> updateRole(Role role) async {
  return await _database?.update('roles', role.toMap(), where: 'id = ?', whereArgs: [role.id]);
  }

  static Future<int?> deleteRole(int roleId) async {
  await  _database?.delete('role_permissions', where: 'role_id = ?', whereArgs: [roleId]);
  // Then delete role
  return await  _database?.delete('roles', where: 'id = ?', whereArgs: [roleId]);
  }

  static Future<List<Role>> getAllRoles() async {
  final List<Map<String, Object?>>? maps = await  _database?.query('roles');
  return maps!.map((map) => Role.fromMap(map)).toList();
  }

  static Future<List<Permission>> getAllPermissions() async {
  final List<Map<String, Object?>>? maps = await  _database?.query('permissions');
  return maps!.map((map) => Permission.fromMap(map)).toList();
  }

  static Future<int?> insertPermission(Permission permission) async {
  return await  _database?.insert('permissions', permission.toMap());
  }

  static Future<void> insertPermissionIfNotExists(Permission permission) async {
    final List<Map<String, dynamic>> existing = await _database!.query(
      'permissions',
      where: 'name = ?',
      whereArgs: [permission.name],
    );

    if (existing.isEmpty) {
      await _database!.insert('permissions', permission.toMap());
    }
  }


  static Future<void> assignPermissionsToRole(int roleId, List<int> permissionIds) async {
    // First clear existing permissions
    await _database?.delete(
        'role_permissions', where: 'role_id = ?', whereArgs: [roleId]);
    // Insert new ones
    for (int pid in permissionIds) {
      await _database?.insert('role_permissions', {
        'role_id': roleId,
        'permission_id': pid,
      });
    }
  }


  static Future<List<Permission>> getPermissionsForRole(int roleId) async {
  final List<Map<String, Object?>>? results = await  _database?.rawQuery('''
      SELECT p.* FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      WHERE rp.role_id = ?
    ''', [roleId]);

  return results!.map((map) => Permission.fromMap(map)).toList();
  }




  static Future<WeightRecord?> getLatestWeightRecord(int flockId) async {
    final db = _database;
    if (db == null) return null;

    final List<Map<String, dynamic>> result = await db.query(
      'WeightRecord',
      where: 'f_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return WeightRecord.fromMap(result.first);
    }

    return null;
  }


  // Insert
  static Future<int> insertWeightRecord(WeightRecord record) async {
    final db = _database;
    if (db == null) return -1;
    return await db.insert('WeightRecord', record.toMap());
  }

// Get all for a flock
  static Future<List<WeightRecord>> getWeightRecords(int flockId) async {
    final db = _database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'WeightRecord',
      where: 'f_id = ?',
      whereArgs: [flockId],
      orderBy: 'date ASC',
    );
    return maps.map((map) => WeightRecord.fromMap(map)).toList();
  }

// Update
  static Future<int> updateWeightRecord(WeightRecord record) async {
    final db = _database;
    if (db == null || record.id == null) return 0;
    return await db.update(
      'WeightRecord',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

// Delete
  static Future<int?> deleteWeightRecord(int id) async {
    return await _database?.delete(
      'WeightRecord',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Insert a SaleContractor into the database
  static Future<void> insertSaleContractor(SaleContractor contractor) async {

    await _database?.insert(
      'SaleContractor',
      contractor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if exists
    );
  }

  // Get all contractors or filter by type
  static Future<List<SaleContractor>> getContractors({String? type}) async {

    List<Map<String, dynamic>>? maps;

    if (type == null) {
      // Fetch all contractors
      maps = await _database?.query('SaleContractor');
    } else {
      // Fetch contractors by type
      maps = await _database?.query(
        'SaleContractor',
        where: 'type = ?',
        whereArgs: [type],
      );
    }

    // Convert List<Map<String, dynamic>> to List<SaleContractor>
    return List.generate(maps!.length, (i) {
      return SaleContractor.fromMap(maps![i]);
    });
  }

  // Update a SaleContractor
  static Future<void> updateSaleContractor(SaleContractor contractor) async {

    await _database?.update(
      'SaleContractor',
      contractor.toMap(),
      where: 'id = ?',
      whereArgs: [contractor.id],
    );
  }


  // Delete a SaleContractor by id
  static Future<void> deleteSaleContractor(int id) async {

    await _database?.delete(
      'SaleContractor',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<TransactionItem>> getTransactionsForContractor(String contractorName) async {
     // Assuming you have a method to get the database instance
    List<Map<String, Object?>>? result = await _database?.query(
      'Transactions',
      where: 'sold_purchased_from = ? AND type = ?',
      whereArgs: [contractorName, 'Income'],
    );

    // Convert the result to a list of TransactionItem objects
    return result!.map((e) => TransactionItem.fromJson(e)).toList();
  }

  static Future<List<Flock_Detail>> getMortalityRecords(int flockId, String reason) async {

    final List<Map<String, Object?>>? maps = await _database?.query(
      'Flock_Detail',
      where: 'f_id = ? AND item_type = ? AND reason = ?',
      whereArgs: [flockId, 'Reduction', reason],
      orderBy: 'acqusition_date DESC',
    );
    return List.generate(maps!.length, (i) => Flock_Detail.fromJson(maps[i]));
  }


  /// **Fetches a unique list of category types (cat_type)**
  static Future<List<String>?> getUniqueCategoryTypes() async {

    final List<Map<String, Object?>> result = await _database!.rawQuery('''
    SELECT DISTINCT name FROM CustomCategory
  ''');

    return result.map((e) => e['name'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>() // Ensures type safety
        .toList();
  }

  static Future<List<CustomCategoryData>> getCustomCategoriesData(int? selectedFlock, String str_date, String end_date, String? selectedType, String sort) async {

    String query = 'SELECT * FROM CustomCategoryData WHERE 1=1';
    List<dynamic> args = [];

    if (selectedFlock != null) {
      if(selectedFlock==-1){

      }else {
        query += ' AND f_id = ?';
        args.add(selectedFlock);
      }
    }

    if (selectedType != null && selectedType.isNotEmpty) {
      query += ' AND c_type = ?';
      args.add(selectedType);
    }

    if (str_date != null && str_date.isNotEmpty) {
      query += ' AND date >= ?';
      args.add(str_date);
    }

    if (end_date != null && end_date.isNotEmpty) {
      query += ' AND date <= ?';
      args.add(end_date);
    }

    if (sort != null && sort.isNotEmpty) {
      query += ' ORDER BY date $sort';
    }

    final List<Map<String, Object?>>? maps = await _database?.rawQuery(query, args);

    return List.generate(maps!.length, (i) {
      return CustomCategoryData.fromMap(maps[i]);
    });
  }

  static Future<int?> updateCustomCategoryData(CustomCategoryData feeding) async {

    // We'll update the first row just as an example
    int id = 1;

    // do the update and get the number of affected rows
    int? updateCount = await _database?.update(
        "CustomCategoryData",
        feeding.toMap(),
        where: 'id= ?',
        whereArgs: [feeding.id]);

    print("Updated...");

    // show the results: print all rows in the db

  }

  static Future<int?> insertCategoryData(CustomCategoryData category) async {

    return await _database?.insert('CustomCategoryData', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  static Future<int?> insertCustomCategory(CustomCategory category) async {
    return await _database?.insert('CustomCategory', category.toMap());
  }

  static Future<List<CustomCategory>?> getCustomCategories() async {
    final result = await _database?.query('CustomCategory');
    return result?.map((map) => CustomCategory.fromMap(map)).toList();
  }

  static Future<int?> updateCategory(CustomCategory category) async {
    return await _database?.update(
      'CustomCategory',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<int?> deleteCategory(int id) async {
    return await _database?.delete(
      'CustomCategory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int?> deleteCategoryData(int id) async {
    return await _database?.delete(
      'CustomCategoryData',
      where: 'c_id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> addEggColorColumn() async {
    try {
      // Check if the 'egg_color' column exists
      final tableInfo = await _database?.rawQuery("PRAGMA table_info(Eggs)");
      bool? hasColumn = tableInfo?.any((column) => column['name'] == 'egg_color');
      print("OKOKOKOK: ${hasColumn}");
      if(hasColumn==null){
        hasColumn = false;
      }

      if (!hasColumn) {
        // Add the column if it doesn't exist
        await _database?.execute("ALTER TABLE Eggs ADD COLUMN egg_color TEXT DEFAULT 'white'");
        // Update existing rows to have 'white' as default (optional since DEFAULT handles it)
        await _database?.rawUpdate("UPDATE Eggs SET egg_color = 'white' WHERE egg_color IS NULL");
        print("COLOR COLUMN ADDED");
      }
      else{
        print("COLOR COLUMN NULL");

      }
    } catch (e) {
      print("Error adding 'egg_color' column: $e");
    }
  }

  static Future<void> addQuantityColumnMedicine() async {
    try {
      final tableInfo = await _database?.rawQuery("PRAGMA table_info(Vaccination_Medication)");
      bool hasColumn = tableInfo?.any((column) => column['name'] == 'quantity') ?? false;

      if (!hasColumn) {
        await _database?.execute("ALTER TABLE Vaccination_Medication ADD COLUMN quantity TEXT DEFAULT '1'");

        // Set default value for NULL or empty values
        await _database?.rawUpdate("UPDATE Vaccination_Medication SET quantity = '1' WHERE quantity IS NULL OR quantity = ''");

        print("COLUMN 'quantity' ADDED");
      } else {
        // Ensure default values for existing records
        await _database?.rawUpdate("UPDATE Vaccination_Medication SET quantity = '1' WHERE quantity IS NULL OR quantity = ''");

        print("COLUMN 'quantity' ALREADY EXISTS - Default values updated if needed");
      }
    } catch (e) {
      print("Error adding/updating 'quantity' column: $e");
    }
  }

  static Future<void> addUnitColumnMedicine() async {
    try {
      final tableInfo = await _database?.rawQuery("PRAGMA table_info(Vaccination_Medication)");
      bool hasColumn = tableInfo?.any((column) => column['name'] == 'unit') ?? false;

      if (!hasColumn) {
        await _database?.execute("ALTER TABLE Vaccination_Medication ADD COLUMN unit TEXT DEFAULT 'g'");

        // Set default value for NULL or empty values
        await _database?.rawUpdate("UPDATE Vaccination_Medication SET unit = 'g' WHERE unit IS NULL OR unit = ''");

        print("COLUMN 'unit' ADDED");
      } else {
        // Ensure default values for existing records
        await _database?.rawUpdate("UPDATE Vaccination_Medication SET unit = 'g' WHERE unit IS NULL OR unit = ''");

        print("COLUMN 'unit' ALREADY EXISTS - Default values updated if needed");
      }
    } catch (e) {
      print("Error adding/updating 'unit' column: $e");
    }
  }

  static Future<void> addFlockInfoColumn() async {
    try {
      // Check if the 'flock_new' column exists
      final tableInfo = await _database?.rawQuery("PRAGMA table_info(Flock)");
      bool hasColumn = tableInfo?.any((column) => column['name'] == 'flock_new') ?? false;

      if (!hasColumn) {
        // Add the new column with a default value of 0
        await _database?.execute("ALTER TABLE Flock ADD COLUMN flock_new INTEGER DEFAULT 0");

        // Ensure existing rows also get the default value
        await _database?.rawUpdate("UPDATE Flock SET flock_new = 0 WHERE flock_new IS NULL");

        print("COLUMN 'flock_new' ADDED");
      } else {
        print("COLUMN 'flock_new' ALREADY EXISTS");
      }
    } catch (e) {
      print("Error adding 'flock_new' column: $e");
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

  static Future<int?> getCategoryIdByName(String categoryName) async {

    List<Map<String, dynamic>>? result = await _database?.query(
      'Category',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [categoryName],
    );

    if (result!.isNotEmpty) {
      return result.first['id']; // Return existing category ID
    }
    return null; // Return null if category not found
  }


  static Future<int?> addCategoryIfNotExists(CategoryItem category) async {

    // Check if category name already exists
    List<Map<String, dynamic>>? existing = await _database?.query(
      'Category',
      where: 'name = ?',
      whereArgs: [category.name],
    );

    if (existing!.isNotEmpty) {
      // If category exists, return its ID
      return existing.first['id'];
    } else {
      // Insert the new category and return the new ID
      return await _database?.insert(
        'Category',
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<int?> addSubcategoryIfNotExists(int categoryId, String subcategoryName) async {

    // Check if the subcategory already exists
    int? existingId = await getSubcategoryId(categoryId, subcategoryName);
    if (existingId != null) return existingId; // Return existing ID if found

    // If not found, insert new subcategory
    int? newId = await _database?.insert(
      'Category_Detail',
      {'c_id': categoryId, 'name': subcategoryName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return newId; // Return new subcategory ID
  }


  static Future<int?> getSubcategoryId(int categoryId, String subcategoryName) async {

    List<Map<String, dynamic>>? result = await _database?.query(
      'Category_Detail',
      columns: ['id'],
      where: 'c_id = ? AND name = ?',
      whereArgs: [categoryId, subcategoryName],
    );

    if (result!.isNotEmpty) {
      return result.first['id']; // Return existing subcategory ID
    }
    return null; // Return null if subcategory does not exist
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

  static Future<Eggs?> getSingleEggsByID(int id) async {

    final map = await _database?.rawQuery(
        "SELECT * FROM Eggs WHERE id = ?",[id]
    );

    if (map!.isNotEmpty) {
      return Eggs.fromJson(map.first);
    } else {
      return null;
    }
  }

  static Future<Eggs?> getSingleEggsBySyncID(String sync_id) async {

    final map = await _database?.rawQuery(
        "SELECT * FROM Eggs WHERE sync_id = ?",[sync_id]
    );

    if (map!.isNotEmpty) {
      return Eggs.fromJson(map.first);
    } else {
      return null;
    }
  }

  static Future<Flock_Detail?> getSingleFlockDetailsBySyncID(String sync_id) async {

    final map = await _database?.rawQuery(
        "SELECT * FROM Flock_Detail WHERE sync_id = ?",[sync_id]
    );

    if (map!.isNotEmpty) {
      return Flock_Detail.fromJson(map.first);
    } else {
      return null;
    }
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

  static Future<List<Eggs>> getFilteredEggsWithSort(
      int f_id, String type, String str_date, String end_date, String sort) async {

    var result;

    String baseQuery = '''
    SELECT Eggs.*, Flock.f_name 
    FROM Eggs 
    LEFT JOIN Flock ON Eggs.f_id = Flock.f_id
  ''';

    String whereClause = '';
    List<String> conditions = [];

    // Build WHERE clause based on filters
    if (f_id != -1) {
      conditions.add("Eggs.f_id = $f_id");
    }

    if (type != 'All') {
      conditions.add("Eggs.isCollection = $type");
    }

    if (str_date.isNotEmpty && end_date.isNotEmpty) {
      conditions.add("Eggs.collection_date BETWEEN '$str_date' AND '$end_date'");
    }

    if (conditions.isNotEmpty) {
      whereClause = "WHERE " + conditions.join(" AND ");
    }

    String finalQuery = '''
    $baseQuery
    $whereClause
    ORDER BY Eggs.collection_date $sort
  ''';

    result = await _database?.rawQuery(finalQuery);

    List<Eggs> _transactionList = [];
    if (result != null && result.isNotEmpty) {
      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> json = Map<String, dynamic>.from(result[i]);
// This is now safe because `json` is mutable

        // Override f_name from JOIN result if available
        json['f_name'] = result[i]['f_name'];

        Eggs _transaction = Eggs.fromJson(json);

        if(_transaction.f_id == -1)
          _transaction.f_name = "Farm Wide";

        _transactionList.add(_transaction);
      }
    }

    return _transactionList;
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

  static Future<List<Flock_Detail>>  getFilteredFlockDetailsWithSort(int f_id,String type,String str_date, String end_date, String sort) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where acqusition_date BETWEEN '$str_date' and '$end_date' ORDER BY acqusition_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Flock_Detail ORDER BY acqusition_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where item_type = '$type' ORDER BY acqusition_date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN  '$str_date' and '$end_date' ORDER BY acqusition_date $sort");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and acqusition_date BETWEEN '$str_date' and '$end_date' ORDER BY acqusition_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Flock_Detail where f_id = $f_id ORDER BY acqusition_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and item_type = '$type' ORDER BY acqusition_date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Flock_Detail where f_id = $f_id and item_type = '$type' and acqusition_date BETWEEN  '$str_date' and '$end_date' ORDER BY acqusition_date $sort");
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

  static Future<List<Flock_Detail>> getFilteredFlockDetails(int f_id, String type, String str_date, String end_date) async {
    final List<String> conditions = [];
    final List<String> whereArgs = [];

    String baseQuery = '''
    SELECT fd.*, f.f_name 
    FROM Flock_Detail fd
    JOIN Flock f ON fd.f_id = f.f_id
  ''';

    if (f_id != -1) {
      conditions.add('fd.f_id = $f_id');
    }

    if (type != 'All') {
      conditions.add("fd.item_type = '$type'");
    }

    if (str_date.isNotEmpty && end_date.isNotEmpty) {
      conditions.add("fd.acqusition_date BETWEEN '$str_date' AND '$end_date'");
    }

    String finalQuery = baseQuery;
    if (conditions.isNotEmpty) {
      finalQuery += ' WHERE ' + conditions.join(' AND ');
    }

    final result = await _database?.rawQuery(finalQuery);

    List<Flock_Detail> _transactionList = [];
    if (result != null && result.isNotEmpty) {
      for (var json in result) {
        _transactionList.add(Flock_Detail.fromJson(json));
      }
    }

    return _transactionList;
  }

  static Future<List<Vaccination_Medication>>  getFilteredMedicationWithSort(int f_id,String type,String str_date, String end_date, String sort) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where date BETWEEN '$str_date' and '$end_date' ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where type = '$type' ORDER BY date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where type = '$type' and date BETWEEN  '$str_date' and '$end_date' ORDER BY date $sort");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and date BETWEEN '$str_date' and '$end_date' ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Vaccination_Medication where f_id = $f_id ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and type = '$type' ORDER BY date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Vaccination_Medication where f_id = $f_id and type = '$type' and date BETWEEN  '$str_date' and '$end_date' ORDER BY date $sort");
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

  static Future<List<Feeding>>  getFilteredFeedingWithSort(int f_id,String type,String str_date, String end_date, String sort) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where feeding_date BETWEEN '$str_date' and '$end_date' ORDER BY feeding_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Feeding ORDER BY feeding_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding ");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where and feeding_date BETWEEN  '$str_date' and '$end_date' ORDER BY feeding_date $sort");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id and feeding_date BETWEEN '$str_date' and '$end_date' ORDER BY feeding_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Feeding where f_id = $f_id ORDER BY feeding_date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id ORDER BY feeding_date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Feeding where f_id = $f_id  and feeding_date BETWEEN  '$str_date' and '$end_date' ORDER BY feeding_date $sort");
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

  static Future<List<FlockIncomeExpense>?> getFlockWiseIncomeExpense(String str,String end) async {
    String query = '''
  SELECT 
      t.f_id,
      f.f_name, -- ✅ Get latest name from Flock table
      SUM(CASE WHEN t.type = 'Income' THEN t.amount ELSE 0 END) AS total_income,
      SUM(CASE WHEN t.type = 'Expense' THEN t.amount ELSE 0 END) AS total_expense
  FROM Transactions t
  JOIN Flock f ON t.f_id = f.f_id -- ✅ Join Flock table to get the latest name
  WHERE t.date >= '$str' AND t.date <= '$end'
  GROUP BY t.f_id
  ORDER BY f.f_name;
''';

    List<Map<String, Object?>>? result = await _database?.rawQuery(query);
    return result?.map((map) => FlockIncomeExpense.fromMap(map)).toList();
  }



  static Future<List<FlockFeedSummary>> getMyMostUsedFeedsByFlock(int f_id, String str_date, String end_date) async {
    var result;

    String baseQuery =
        "SELECT Flock.f_name AS f_name, SUM(Feeding.quantity) AS total_quantity "
        "FROM Feeding "
        "JOIN Flock ON Feeding.f_id = Flock.f_id ";

    String groupOrder = " GROUP BY Flock.f_name ORDER BY total_quantity DESC";

    if (f_id == -1 && str_date.isNotEmpty && end_date.isNotEmpty) {
      result = await _database?.rawQuery(
          baseQuery +
              "WHERE Feeding.feeding_date BETWEEN '$str_date' AND '$end_date'" +
              groupOrder
      );
    } else if (f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          baseQuery +
              "WHERE Feeding.f_id = '$f_id'" +
              groupOrder
      );
    } else if (f_id != -1 && str_date.isNotEmpty && end_date.isNotEmpty) {
      result = await _database?.rawQuery(
          baseQuery +
              "WHERE Feeding.f_id = '$f_id' AND Feeding.feeding_date BETWEEN '$str_date' AND '$end_date'" +
              groupOrder
      );
    } else if (f_id == -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          baseQuery + groupOrder
      );
    }

    List<FlockFeedSummary> _feedList = [];
    if (result != null && result.isNotEmpty) {
      for (var json in result) {
        FlockFeedSummary feedSummary = FlockFeedSummary.fromMap(json);
        _feedList.add(feedSummary);
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

  static Future<int> getAllFlockBirdsCount(int f_id, String str_date, String end_date) async {
    List<Map<String, Object?>>? result;

    if (f_id == -1 && str_date.isNotEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(active_bird_count) as total FROM Flock WHERE acqusition_date BETWEEN '$str_date' AND '$end_date'");
    } else if (f_id != -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT active_bird_count as total FROM Flock WHERE f_id = $f_id");
    } else if (f_id != -1 && str_date.isNotEmpty) {
      result = await _database?.rawQuery(
          "SELECT active_bird_count as total FROM Flock WHERE f_id = $f_id AND acqusition_date BETWEEN '$str_date' AND '$end_date'");
    } else if (f_id == -1 && str_date.isEmpty) {
      result = await _database?.rawQuery(
          "SELECT sum(active_bird_count) as total FROM Flock");
    }

    if (result == null || result.isEmpty || result.first['total'] == null) {
      return 0;
    }

    return int.parse(result.first['total'].toString());
  }

  static Future<int> getAllFlockInitialBirdsCount(int f_id,String str_date, String end_date) async {

    var result;

    try {

      if (f_id == -1 && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT sum(bird_count) FROM Flock where flock_new = 0 AND acqusition_date BETWEEN '$str_date'and '$end_date'");
      } else if (f_id != -1 && str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT bird_count FROM Flock where flock_new = 0 AND f_id = $f_id ");
      } else if (f_id != -1 && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT bird_count FROM Flock where flock_new = 0 AND f_id = $f_id and acqusition_date BETWEEN '$str_date'and '$end_date' ");
      } else if (f_id == -1 && str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT sum(bird_count) FROM Flock where flock_new = 0");
      }


      Map<String, dynamic> map = result![0];
      print(map.values.first);

      if (map.values.first.toString().toLowerCase() == 'null')
        return 0;
      else
        return int.parse(map.values.first.toString());
    }
    catch(ex){
      print(ex);
      return 0;
    }

  }

  static Future<int> getBirdsCalculations(int f_id, String type,String str_date, String end_date) async {

    var result;

    if(f_id==-1) {
      result = await _database?.rawQuery(
          "SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN '$str_date' and '$end_date'");
      print("SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and acqusition_date BETWEEN '$str_date' and '$end_date'");
    }else if (f_id!=-1){
      result = await _database?.rawQuery(
          "SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and f_id = $f_id and acqusition_date BETWEEN '$str_date' and '$end_date'");
      print("SELECT sum(item_count) FROM Flock_Detail where item_type = '$type' and f_id = $f_id and acqusition_date BETWEEN '$str_date' and '$end_date'");
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

  static Future<int> getUniqueEggCalculationsGoodBad(int f_id,int type,String str_date, String end_date) async {

    var result;

    String column = 'good_eggs';
    if(type==0)
      column = 'spoilt_eggs';

    result = await _database?.rawQuery(
        "SELECT sum("+column+") FROM Eggs where isCollection = 1 and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");
    print("SELECT sum("+column+") FROM Eggs where isCollection = 1 and f_id = $f_id and collection_date BETWEEN '$str_date'and '$end_date'");


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
    if (_database == null) {
      print("DB IS NULL");
      return null;
    }// Handle null database case

    final List<Map<String, dynamic>>? map = await _database!.rawQuery(
        "SELECT * FROM Transactions WHERE id = ?", [id]);

    if (map == null || map.isEmpty) {
      return null;
    } else {
      return TransactionItem.fromJson(map.first);
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

  static Future<List<FinancialItem>?> getTopIncomeItems(int f_id, String str, String end) async {
    String query = '''
    SELECT sale_item, SUM(amount) as total_amount
    FROM transactions
    WHERE type = 'Income' AND date >= '$str' AND date <= '$end' ''';

    if (f_id != -1) {
      query += " AND f_id = $f_id";
    }

    query += " GROUP BY sale_item ORDER BY total_amount DESC LIMIT 5";

    final List<Map<String, Object?>>? results = await _database?.rawQuery(query);

    return results?.map((map) => FinancialItem(
      name: map['sale_item'].toString(),
      amount: (map['total_amount'] as num).toDouble(),
      icon: Icons.trending_up, // Icon for Income items
    )).toList();
  }

  static Future<List<FinancialItem>?> getTopExpenseItems(int f_id, String str, String end) async {
    String query = '''
    SELECT expense_item, SUM(amount) as total_amount
    FROM transactions
    WHERE type = 'Expense' AND date >= '$str' AND date <= '$end' ''';

    if (f_id != -1) {
      query += " AND f_id = $f_id";
    }

    query += " GROUP BY expense_item ORDER BY total_amount DESC LIMIT 5";

    final List<Map<String, Object?>>? results = await _database?.rawQuery(query);

    return results?.map((map) => FinancialItem(
      name: map['expense_item'].toString(),
      amount: (map['total_amount'] as num).toDouble(),
      icon: Icons.trending_down, // Icon for Expense items
    )).toList();
  }

  static Future<List<TransactionItem>> getEggSaleTransactions() async {
    final result = await _database?.rawQuery(
        "SELECT * FROM Transactions WHERE type = 'Income' AND sale_item = 'Egg Sale' ORDER BY date DESC"
    );

    List<TransactionItem> eggSales = [];

    if (result != null && result.isNotEmpty) {
      for (var row in result) {
        eggSales.add(TransactionItem.fromJson(row));
      }
    }

    return eggSales;
  }


  static Future<List<TransactionItem>>  getFilteredTransactionsWithSort(int f_id,String type,String str_date, String end_date,String sort) async {

    var result = null;

    if(f_id == -1) {
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where date BETWEEN '$str_date' and '$end_date' ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Transactions ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where type = '$type' ORDER BY date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where type = '$type' and date BETWEEN  '$str_date' and '$end_date' ORDER BY date $sort");
      }
    }else{
      if (type == 'All' && !str_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and date BETWEEN '$str_date' and '$end_date' ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty && type == 'All') {
        result = await _database?.rawQuery("SELECT * FROM Transactions where f_id = $f_id ORDER BY date $sort");
      } else if (str_date.isEmpty && end_date.isEmpty) {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and type = '$type' ORDER BY date $sort");
      } else {
        result = await _database?.rawQuery(
            "SELECT * FROM Transactions where f_id = $f_id and type = '$type' and date BETWEEN  '$str_date' and '$end_date' ORDER BY date $sort");
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
  static Future<List<Eggs_Chart_Item>>  getEggsReportData(String strDate,String endDate, int itype, int f_id) async {

    var result;
    if(f_id != -1)
      result = await _database?.rawQuery("SELECT collection_date,sum(total_eggs) FROM Eggs WHERE collection_date >= '$strDate' and collection_date <= '$endDate' and isCollection = '$itype' and f_id = $f_id  GROUP BY collection_date");
   else
      result = await _database?.rawQuery("SELECT collection_date,sum(total_eggs) FROM Eggs WHERE collection_date >= '$strDate' and collection_date <= '$endDate' and isCollection = '$itype'  GROUP BY collection_date");

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
  static Future<List<Finance_Chart_Item>>  getFinanceChartData(int f_id, String strDate, String endDate, String itype) async {
    var result = null;
    if(f_id ==-1)
      result = await _database?.rawQuery("SELECT type,date,sum(CAST(REPLACE(amount,',','.') as REAL)) FROM Transactions WHERE date >= '$strDate' and date <= '$endDate' and type = '$itype'  GROUP BY date");
   else
      result = await _database?.rawQuery("SELECT type,date,sum(CAST(REPLACE(amount,',','.') as REAL)) FROM Transactions WHERE f_id = $f_id AND date >= '$strDate' and date <= '$endDate' and type = '$itype'  GROUP BY date");

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

  static Future<void> createFeedIngridentTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS FeedIngredient (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  price_per_kg REAL NOT NULL,
  unit TEXT DEFAULT 'kg')
  ''');
  }

  static Future<void> createFeedBatchTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS FeedBatch(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  transaction_id TEXT NOT NULL,
  total_weight REAL NOT NULL,
  total_price REAL NOT NULL)
  ''');
  }

  static Future<void> createFeedBatchItemTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS FeedBatchItem (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL,
  ingredient_id INTEGER NOT NULL,
  quantity REAL NOT NULL,
  FOREIGN KEY (batch_id) REFERENCES FeedBatch(id) ON DELETE CASCADE,
  FOREIGN KEY (ingredient_id) REFERENCES FeedIngredient(id) ON DELETE CASCADE)
  ''');
  }

  static Future<void> createStockExpenseJunction() async {
    // 3. Create stock_expense linking table
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS StockExpense (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      stock_item_id INTEGER NOT NULL,
      transaction_id INTEGER NOT NULL,
      FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE)
  ''');
  }

  static Future<void> createEggTransactionJunction() async {
    // 3. Create stock_expense linking table
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS EggTransaction(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      egg_item_id INTEGER NOT NULL,
      transaction_id INTEGER NOT NULL)
  ''');
  }

  static Future<void> createFeedStockHistoryTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS FeedStockHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      feed_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      feed_name TEXT NOT NULL,
      unit TEXT NOT NULL,
      source TEXT NOT NULL,
      date TEXT NOT NULL
    )
  ''');
  }

  static Future<void> createMedicineStockHistoryTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS MedicineStockHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medicine_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      medicine_name TEXT NOT NULL,
      unit TEXT NOT NULL,
      source TEXT NOT NULL,
      date TEXT NOT NULL
    )
  ''');
  }

  static Future<void> createVaccineStockHistoryTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS VaccineStockHistory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vaccine_id INTEGER NOT NULL,
      quantity REAL NOT NULL,
      vaccine_name TEXT NOT NULL,
      unit TEXT NOT NULL,
      source TEXT NOT NULL,
      date TEXT NOT NULL
    )
  ''');
  }

  static Future<void> createScheduledNotificationsTable() async {
    await _database?.execute('''
    CREATE TABLE IF NOT EXISTS ScheduledNotification (
      id INTEGER PRIMARY KEY,
      bird_type TEXT NOT NULL,
      flock_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      scheduled_at TEXT NOT NULL,
      recurrence TEXT NOT NULL
    )
  ''');
  }

  static Future<int?> insertNotification(ScheduledNotification notification) async {
    return await _database?.insert(
      'ScheduledNotification',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int?> updateNotification( ScheduledNotification notification) async {
    return await _database?.update(
      'ScheduledNotification',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  static Future<int?> deleteNotification( int id) async {
    return await _database?.delete(
      'ScheduledNotification',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScheduledNotification>?> getAllNotifications() async {
    final List<Map<String, dynamic>?>? maps = await _database?.query('ScheduledNotification');
    return maps!.map((map) => ScheduledNotification.fromMap(map!)).toList();
  }

  static Future<List<ScheduledNotification>> getScheduledNotificationsByFlockId(int flockId) async {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>?>? rows = await _database?.query(
      'ScheduledNotification',
      where: 'flock_id = ? AND scheduled_at >= ?',
      whereArgs: [flockId, nowMillis],
    );

    return rows!.isNotEmpty
        ? rows.map((row) => ScheduledNotification.fromMap(row!)).toList()
        : <ScheduledNotification>[];
  }

  /// Add a stock expense link
  static Future<int?> insertStockJunction(StockExpense stockExpense) async {
    return await _database?.insert(
      'StockExpense',
      stockExpense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all stock_expense entries
  static Future<List<StockExpense>> getAll() async {
    final List<Map<String, Object?>>? maps = await _database?.query('StockExpense');
    return maps!.map((map) => StockExpense.fromMap(map)).toList();
  }


  /// Get a stock expense by stock_item_id
  static Future<StockExpense?> getByTransactionItemId(int transaction_id) async {
    final List<Map<String, Object?>>? maps = await _database?.query(
      'StockExpense',
      where: 'transaction_id = ?',
      whereArgs: [transaction_id],
    );

    if (maps!.isNotEmpty) {
      return StockExpense.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Get a stock expense by stock_item_id
  static Future<StockExpense?> getByStockItemId(int stockItemId) async {
    final List<Map<String, Object?>>? maps = await _database?.query(
      'StockExpense',
      where: 'stock_item_id = ?',
      whereArgs: [stockItemId],
    );

    if (maps!.isNotEmpty) {
      return StockExpense.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Delete stock_expense by stock_item_id
  static Future<int?> deleteByStockItemId(int stockItemId) async {
    return await _database?.delete(
      'StockExpense',
      where: 'stock_item_id = ?',
      whereArgs: [stockItemId],
    );
  }

  /// Delete stock_expense by transaction_id (optional helper)
  Future<int?> deleteByTransactionId(int transactionId) async {
    return await _database?.delete(
      'StockExpense',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  static Future<int?> deleteMedicineStockHistoryById(int id) async {

    return await _database?.delete(
      'MedicineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int?> deleteVaccineStockHistoryById(int id) async {

    return await _database?.delete(
      'VaccineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  /// Add a egg income link
  static Future<int?> insertEggJunction(EggTransaction stockExpense) async {
    return await _database?.insert(
      'EggTransaction',
      stockExpense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all stock_expense entries
  static Future<List<EggTransaction>> getAllEggsJunction() async {
    final List<Map<String, Object?>>? maps = await _database?.query('EggTransaction');
    return maps!.map((map) => EggTransaction.fromMap(map)).toList();
  }

  /// Get a stock expense by stock_item_id
  static Future<EggTransaction?> getByEggItemId(int stockItemId) async {
    final List<Map<String, Object?>>? maps = await _database?.query(
      'EggTransaction',
      where: 'egg_item_id = ?',
      whereArgs: [stockItemId],
    );

    if (maps!.isNotEmpty) {
      return EggTransaction.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Get a stock expense by stock_item_id
  static Future<EggTransaction?> getEggsByTransactionItemId(int transaction_id) async {
    final List<Map<String, Object?>>? maps = await _database?.query(
      'EggTransaction',
      where: 'transaction_id = ?',
      whereArgs: [transaction_id],
    );

    if (maps!.isNotEmpty) {
      return EggTransaction.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Delete stock_expense by stock_item_id
  static Future<int?> deleteByEggItemId(int stockItemId) async {
    return await _database?.delete(
      'EggTransaction',
      where: 'egg_item_id = ?',
      whereArgs: [stockItemId],
    );
  }

  /// Delete stock_expense by transaction_id (optional helper)
  Future<int?> deleteEggJunctionByTransactionId(int transactionId) async {
    return await _database?.delete(
      'EggTransaction',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  static Future<int?> insertBatch(FeedBatch batch) async {
    return await _database?.insert('FeedBatch', batch.toMap());
  }

  static Future<List<FeedBatch>> getAllBatches() async {
    final batchResults = await _database?.query('FeedBatch', orderBy: 'name ASC');
    if (batchResults == null) return [];

    print(batchResults);
    List<FeedBatch> batches = [];

    for (var batchMap in batchResults) {
      final batch = FeedBatch.fromMap(batchMap);

      // Get ingredients for this batch
      final ingredientResults = await _database!.rawQuery('''
      SELECT i.id as ingredient_id, i.name as ingredient_name, bi.quantity
      FROM FeedBatchItem bi
      INNER JOIN FeedIngredient i ON bi.ingredient_id = i.id
      WHERE bi.batch_id = ?
    ''', [batch.id]);

      batch.ingredients = ingredientResults.map((row) {
        return FeedBatchItemWithName(
          ingredientId: row['ingredient_id'] as int,
          ingredientName: row['ingredient_name'] as String,
          quantity: (row['quantity'] as num).toDouble(),
        );
      }).toList();

      batches.add(batch);
    }

    return batches;
  }


  static Future<void> updateBatch(FeedBatch batch) async {

    await _database?.update(
      'FeedBatch',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  static Future<FeedBatch?> getBatchById(int id) async {
    final result = await _database?.query(
      'FeedBatch',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedBatch.fromMap(result.first);
    }

    return null;
  }


  static Future<int?> deleteBatch(int id) async {
    return await _database?.delete(
      'FeedBatch',
      where: 'id = ?',
      whereArgs: [id],);
  }


  static Future<int?> insertBatchItem(FeedBatchItem item) async {
    return await _database?.insert('FeedBatchItem', item.toMap());
  }

  static Future<List<FeedBatchItem>?> getItemsByBatchId(int batchId) async {
    final result = await _database?.query(
      'FeedBatchItem',
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
    return result!.map((map) => FeedBatchItem.fromMap(map)).toList();
  }

  static Future<int?> deleteItemsByBatchId(int batchId) async {
    return await _database?.delete(
      'FeedBatchItem',
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  static Future<List<FeedIngredient>?> getAllIngredients() async {
    final result = await _database?.query('FeedIngredient', orderBy: 'name ASC');
    if (result == null) return [];

    return result.map((map) => FeedIngredient.fromMap(map)).toList();
  }

  static Future<FeedIngredient?> getIngredientById(int id) async {
    final result = await _database?.query(
      'FeedIngredient',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result != null && result.isNotEmpty) {
      return FeedIngredient.fromMap(result.first);
    }

    return null;
  }

  static Future<int?> insertIngredientWithSyncID(String name, double pricePerKg, String sync_id,  {String unit = 'KG'}) async {
    return await _database?.insert(
      'FeedIngredient',
      {
        'name': name,
        'price_per_kg': pricePerKg,
        'unit': unit,
        'sync_id' : sync_id,
        'sync_status': SyncStatus.SYNCED,
        'modified_by' : Utils.isMultiUSer? Utils.currentUser!.email :'',
        'farm_id' : Utils.isMultiUSer? Utils.currentUser!.farmId :'',
        'last_modified' : DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // or replace
    );
  }


  static Future<int?> insertIngredient(String name, double pricePerKg, {String unit = 'KG'}) async {
    return await _database?.insert(
      'FeedIngredient',
      {
        'name': name,
        'price_per_kg': pricePerKg,
        'unit': unit,
        'sync_id' : Utils.getUniueId(),
        'sync_status': SyncStatus.SYNCED,
        'modified_by' : Utils.isMultiUSer? Utils.currentUser!.email :'',
        'farm_id' : Utils.isMultiUSer? Utils.currentUser!.farmId :'',
        'last_modified' : DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // or replace
    );
  }

  static Future<int?> updateIngredientByObject(FeedIngredient ingredient) async {
    if (ingredient.id == null) return null;

    return await _database?.update(
      'FeedIngredient',
      {
        'name': ingredient.name,
        'price_per_kg': ingredient.pricePerKg,
        'unit': ingredient.unit,
        'sync_id': ingredient.sync_id,
        'sync_status': ingredient.sync_status,
        'last_modified': ingredient.last_modified?.toIso8601String(),
        'modified_by': ingredient.modified_by,
        'farm_id': ingredient.farm_id,
      },
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  static Future<int?> updateIngredient(int id, String name, double pricePerKg, String unit) async {
    return await _database?.update(
      'FeedIngredient',
      {
        'name': name,
        'price_per_kg': pricePerKg,
        'unit': unit,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int?> deleteIngredient( int id) async {
    return await _database?.delete(
      'FeedIngredient',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, dynamic>?> getIngredientByName(String name) async {
    final result = await _database?.query(
      'FeedIngredient',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result!.isNotEmpty ? result.first : null;
  }


  static Future<int?> insertVaccineStock(VaccineStockHistory stock) async {

    return await _database?.insert('VaccineStockHistory', stock.toMap());
  }

  static Future<int?> insertMedicineStock(MedicineStockHistory stock) async {

    return await _database?.insert('MedicineStockHistory', stock.toMap());
  }

  static Future<int?> insertFeedStock(FeedStockHistory stock) async {

    return await _database?.insert('FeedStockHistory', stock.toMap());
  }

  static Future<int?> updateFeedStock(FeedStockHistory stock) async {
    return await _database?.update(
      'FeedStockHistory',
      stock.toMap(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  static Future<int?> deleteFeedStock(int id) async {

    return await _database?.delete(
      'FeedStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<FeedStockHistory>> getAllFeedStock() async {

    final List<Map<String, Object?>>? maps = await _database?.query('FeedStockHistory');

    return List.generate(maps!.length, (i) {
      return FeedStockHistory.fromMap(maps[i]);
    });
  }

  static Future<List<FeedStockSummary>>? getFeedStockSummary() async {
    final List<Map<String, dynamic>>? maps = await _database?.rawQuery('''
    WITH FirstStock AS (
        SELECT feed_name, MIN(date) AS first_stock_date
        FROM FeedStockHistory
        GROUP BY feed_name
    )
    SELECT s.feed_name, 
           COALESCE(SUM(s.quantity), 0) AS total_stock,
           COALESCE((
             SELECT SUM(CAST(f.quantity AS REAL)) 
             FROM Feeding f
             WHERE f.feed_name = s.feed_name 
               AND f.feeding_date >= (SELECT first_stock_date FROM FirstStock WHERE feed_name = s.feed_name)
           ), 0) AS used_stock,
           (COALESCE(SUM(s.quantity), 0) - 
            COALESCE((SELECT SUM(CAST(f.quantity AS REAL)) 
                      FROM Feeding f
                      WHERE f.feed_name = s.feed_name 
                        AND f.feeding_date >= (SELECT first_stock_date FROM FirstStock WHERE feed_name = s.feed_name)
                    ), 0)
           ) AS available_stock
    FROM FeedStockHistory s
    GROUP BY s.feed_name;
  ''');

    if (maps == null || maps.isEmpty) return [];

    return maps.map((map) {
      String feedName = map['feed_name'] ?? "Unknown";

      return FeedStockSummary(
        feedName: feedName,
        totalStock: (map['total_stock'] as num?)?.toDouble() ?? 0.0,
        usedStock: (map['used_stock'] as num?)?.toDouble() ?? 0.0,
        availableStock: (map['available_stock'] as num?)?.toDouble() ?? 0.0,

      );
    }).toList();
  }

  static Future<List<MedicineStockSummary>> getMedicineStockSummary() async {
    final List<Map<String, dynamic>>? maps = await _database?.rawQuery('''
    WITH FirstStock AS (
        SELECT medicine_name, MIN(date) AS first_stock_date
        FROM MedicineStockHistory
        GROUP BY medicine_name
    )
    SELECT s.medicine_name, 
           s.unit,  
           COALESCE(SUM(s.quantity), 0) AS total_stock,
           COALESCE((
             SELECT SUM(CAST(m.quantity AS REAL)) 
             FROM Vaccination_Medication m
             WHERE m.medicine = s.medicine_name 
               AND m.type = 'Medication'  -- Only for medicines
               AND m.date >= (SELECT first_stock_date FROM FirstStock WHERE medicine_name = s.medicine_name)
           ), 0) AS used_stock,
           (COALESCE(SUM(s.quantity), 0) - 
            COALESCE((SELECT SUM(CAST(m.quantity AS REAL)) 
                      FROM Vaccination_Medication m
                      WHERE m.medicine = s.medicine_name 
                        AND m.type = 'Medication'  
                        AND m.date >= (SELECT first_stock_date FROM FirstStock WHERE medicine_name = s.medicine_name)
                    ), 0)
           ) AS available_stock
    FROM MedicineStockHistory s
    GROUP BY s.medicine_name, s.unit;
  ''');

    if (maps == null || maps.isEmpty) return [];

    return maps.map((map) {
      return MedicineStockSummary(
        medicineName: map['medicine_name'] ?? "Unknown",
        unit: map['unit'] ?? "Unknown",
        totalStock: (map['total_stock'] as num?)?.toDouble() ?? 0.0,
        usedStock: (map['used_stock'] as num?)?.toDouble() ?? 0.0,
        availableStock: (map['available_stock'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static Future<List<FeedStockSummary>> getFeedBatchStockSummary() async {
    final List<Map<String, dynamic>>? maps = await _database?.rawQuery('''
    SELECT 
      b.id AS batch_id,
      b.name AS batch_name,
      b.total_weight AS total_stock,
      COALESCE((
        SELECT SUM(CAST(f.quantity AS REAL))
        FROM Feeding f
        WHERE f.feed_name = b.name
      ), 0) AS used_stock,
      (b.total_weight - COALESCE((
        SELECT SUM(CAST(f.quantity AS REAL))
        FROM Feeding f
        WHERE f.feed_name = b.name
      ), 0)) AS available_stock
    FROM FeedBatch b
  ''');

    print(maps);
    if (maps == null || maps.isEmpty) return [];

    return maps.map((map) {
      return FeedStockSummary(
        feedName: map['batch_name'] ?? 'Unnamed',
        totalStock: (map['total_stock'] as num?)?.toDouble() ?? 0.0,
        usedStock: (map['used_stock'] as num?)?.toDouble() ?? 0.0,
        availableStock: (map['available_stock'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }


  static Future<List<VaccineStockSummary>> getVaccineStockSummary() async {
    final List<Map<String, dynamic>>? maps = await _database?.rawQuery('''
    WITH FirstStock AS (
        SELECT vaccine_name, MIN(date) AS first_stock_date
        FROM VaccineStockHistory
        GROUP BY vaccine_name
    )
    SELECT s.vaccine_name, 
           s.unit,  
           COALESCE(SUM(s.quantity), 0) AS total_stock,
           COALESCE((
             SELECT SUM(CAST(m.quantity AS REAL)) 
             FROM Vaccination_Medication m
             WHERE m.medicine = s.vaccine_name  
               AND m.type = 'Vaccination'  -- Only for vaccines
               AND m.date >= (SELECT first_stock_date FROM FirstStock WHERE vaccine_name = s.vaccine_name)
           ), 0) AS used_stock,
           (COALESCE(SUM(s.quantity), 0) - 
            COALESCE((SELECT SUM(CAST(m.quantity AS REAL)) 
                      FROM Vaccination_Medication m
                      WHERE m.medicine = s.vaccine_name  
                        AND m.type = 'Vaccination'  
                        AND m.date >= (SELECT first_stock_date FROM FirstStock WHERE vaccine_name = s.vaccine_name)
                    ), 0)
           ) AS available_stock
    FROM VaccineStockHistory s
    GROUP BY s.vaccine_name, s.unit;
  ''');

    if (maps == null || maps.isEmpty) return [];

    return maps.map((map) {
      return VaccineStockSummary(
        vaccineName: map['vaccine_name'] ?? "Unknown",
        unit: map['unit'] ?? "Unknown",
        totalStock: (map['total_stock'] as num?)?.toDouble() ?? 0.0,
        usedStock: (map['used_stock'] as num?)?.toDouble() ?? 0.0,
        availableStock: (map['available_stock'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static Future<List<VaccineStockHistory>> fetchVaccineStockHistory(String feed_name, String unit) async {
    final List<Map<String, dynamic>>? maps = await _database?.query(
      'VaccineStockHistory',
      where: 'vaccine_name = ? AND unit = ?',
      whereArgs: [feed_name, unit],
      orderBy: 'date DESC',
    );

    return List.generate(maps!.length, (i) => VaccineStockHistory.fromMap(maps[i]));
  }

  static Future<List<MedicineStockHistory>> fetchMedicineStockHistory(String feed_name, String unit) async {
     final List<Map<String, dynamic>>? maps = await _database?.query(
      'MedicineStockHistory',
      where: 'medicine_name = ? AND unit = ?',
      whereArgs: [feed_name, unit],
      orderBy: 'date DESC',
    );

    return List.generate(maps!.length, (i) => MedicineStockHistory.fromMap(maps[i]));
  }

  static Future<List<Eggs>> getStockHistory() async {
    final List<Map<String, Object?>>? maps = await _database?.query(
      'Eggs',
      where: 'isCollection = 1',
      orderBy: 'collection_date DESC',
    );

    return List.generate(maps!.length, (i) => Eggs.fromJson(maps[i]));
  }

  static Future<List<Eggs>> getStockHistoryPaginated({int page = 0, int pageSize = 20}) async {
    // Calculate offset based on page number
    final int offset = page * pageSize;

    final List<Map<String, Object?>>? maps = await _database?.query(
      'Eggs',
      where: 'id IS NOT NULL', // ✅ Only fetch rows with valid IDs
      orderBy: 'collection_date DESC',
      limit: pageSize,
      offset: offset,
    );

    return List.generate(maps?.length ?? 0, (i) => Eggs.fromJson(maps![i]));
  }


  static Future<void> deleteInvalidEggRecords() async {
    try
    {
      final count = await _database?.rawDelete('DELETE FROM Eggs WHERE id IS NULL');
      print("Deleted $count invalid egg records.");
    } catch (e) {
      print("Error while deleting invalid egg records: $e");
    }
  }


  static Future<Map<String, int>> getEggStockSummary() async {
    if (_database == null) {
      return {
        'totalCollected': 0,
        'totalUsed': 0,
        'availableStock': 0
      };
    }

    // Ensure rawQuery returns a non-null list
    final collectedResult = await _database!.rawQuery(
        "SELECT SUM(total_eggs) as total FROM Eggs WHERE isCollection = 1") ?? [];

    final usedResult = await _database!.rawQuery(
        "SELECT SUM(total_eggs) as total FROM Eggs WHERE isCollection = 0") ?? [];

    // Extract values safely using .first if available
    final totalCollected = collectedResult.isNotEmpty ? (collectedResult.first['total'] as int? ?? 0) : 0;
    final totalUsed = usedResult.isNotEmpty ? (usedResult.first['total'] as int? ?? 0) : 0;

    // Calculate remaining stock
    int availableStock = totalCollected - totalUsed;

    return {
      'totalCollected': totalCollected,
      'totalUsed': totalUsed,
      'availableStock': availableStock
    };
  }

  static Future<int> getFlockMortalityCount( int flockId) async {
     List<Map<String, Object?>>? result = null;

    if(flockId==-1){
      result = await _database?.rawQuery(
        '''
    SELECT SUM(item_count) as mortality
    FROM flock_detail
    WHERE item_type = 'Reduction' AND reason = 'MORTALITY'
    ''');
    } else {
     result = await _database?.rawQuery(
        '''
    SELECT SUM(item_count) as mortality
    FROM flock_detail
    WHERE f_id = ? AND item_type = 'Reduction' AND reason = 'MORTALITY'
    ''',
        [flockId],
      );
    }

    if (result!.isNotEmpty && result.first['mortality'] != null) {
      return result.first['mortality'] as int;
    } else {
      return 0;
    }
  }
  static Future<int> getFlockCullingCount( int flockId) async {
     List<Map<String, Object?>>? result = null;
    if(flockId==-1){
      result = await _database?.rawQuery(
        '''
    SELECT SUM(item_count) as culling
    FROM flock_detail
    WHERE item_type = 'Reduction' AND reason = 'CULLING'
    '''
      );
    }else{
      result = await _database?.rawQuery(
        '''
    SELECT SUM(item_count) as culling
    FROM flock_detail
    WHERE f_id = ? AND item_type = 'Reduction' AND reason = 'CULLING'
    ''',
        [flockId],
      );
    }

    if (result!.isNotEmpty && result.first['culling'] != null) {
      return result.first['culling'] as int;
    } else {
      return 0;
    }
  }

  static Future<int?> updateFlockInfoBySyncID(Flock flock) async {
    return await _database?.update(
      'Flock',
      flock.toJson(),
      where: 'sync_id = ?',
      whereArgs: [flock.sync_id],
    );
  }
  static Future<int?> updateFlockInfo(Flock flock) async {
    return await _database?.update(
      'Flock',
      flock.toJson(),
      where: 'f_id = ?',
      whereArgs: [flock.f_id],
    );
  }



  static Future<List<FeedStockHistory>> fetchStockHistory(String feed_name) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>>? maps = await _database?.query(
      'FeedStockHistory',
      where: 'feed_name = ?',
      whereArgs: [feed_name],
      orderBy: 'date DESC',
    );

    return List.generate(maps!.length, (i) => FeedStockHistory.fromMap(maps[i]));
  }

  static Future<List<String>?> getDistinctDoctorNames() async {
    final List<Map<String, Object?>>? results = await _database?.rawQuery('''
    SELECT DISTINCT doctor_name 
    FROM Vaccination_Medication 
    WHERE doctor_name IS NOT NULL AND doctor_name != ''
    ORDER BY doctor_name COLLATE NOCASE
  ''');

    return results!.map((row) => row['doctor_name'] as String).toList();
  }


  static Future<void> deleteFlockAndRelatedInfoSyncID(String sync_id, int f_id) async {

    // Begin a transaction to ensure atomicity
    await _database?.transaction((txn) async {

      await txn.delete('Eggs', where: 'f_id = ?', whereArgs: [f_id]);
      await txn.delete('Transactions', where: 'f_id = ?', whereArgs: [f_id]);
      await txn.delete('Feeding', where: 'f_id = ?', whereArgs: [f_id]);
      await txn.delete('Vaccination_Medication', where: 'f_id = ?', whereArgs: [f_id]);
      await txn.delete('Flock_Detail', where: 'f_id = ?', whereArgs: [f_id]);

      // Delete flock
      await txn.delete('Flock', where: 'sync_id = ?', whereArgs: [sync_id]);
    });

  }
  static Future<void> deleteFlockAndRelatedInfo(int flockId) async {

    // Begin a transaction to ensure atomicity
    await _database?.transaction((txn) async {

      await txn.delete('Eggs', where: 'f_id = ?', whereArgs: [flockId]);
      await txn.delete('Transactions', where: 'f_id = ?', whereArgs: [flockId]);
      await txn.delete('Feeding', where: 'f_id = ?', whereArgs: [flockId]);
      await txn.delete('Vaccination_Medication', where: 'f_id = ?', whereArgs: [flockId]);
      await txn.delete('Flock_Detail', where: 'f_id = ?', whereArgs: [flockId]);

      // Delete flock
      await txn.delete('Flock', where: 'f_id = ?', whereArgs: [flockId]);
    });

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
    var result = await _database?.rawQuery("DELETE FROM $table WHERE f_detail_id = $id");

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
  static Future<int>  deleteFlockDetailsRecord(int f_detal_id) async {
    var result = await _database?.rawQuery("DELETE FROM Flock_Detail WHERE f_detail_id = $f_detal_id");
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

  static Future<int> updateFarmSetup(FarmSetup? farmSetup) async {
    final result = await _database?.rawUpdate(
      '''
    UPDATE FarmSetup 
    SET name = ?, 
        image = ?, 
        modified = 1, 
        date = ?, 
        location = ?
    WHERE id = 1
    ''',
      [
        farmSetup?.name,
        farmSetup?.image,
        farmSetup?.date,
        farmSetup?.location,
      ],
    );
    return result ?? 0; // return number of rows updated
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