import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:poultary/multiuser/model/general%20stock_transactions_fb.dart';
import 'package:poultary/multiuser/model/unit_maintenance_fb.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:poultary/stock/model/stock_transactions.dart';

import '../../database/databse_helper.dart';
import '../../model/custom_category.dart';
import '../../model/custom_category_data.dart';
import '../../model/egg_income.dart';
import '../../model/egg_item.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/feed_stock_history.dart';
import '../../model/flock.dart';
import '../../model/flock_detail.dart';
import '../../model/med_vac_item.dart';
import '../../model/medicine_stock_history.dart';
import '../../model/sale_contractor.dart';
import '../../model/sub_category_item.dart';
import '../../model/transaction_item.dart';
import '../../model/vaccine_stock_history.dart';
import '../../model/weight_record.dart';
import '../../stock/model/general_stock.dart';
import '../../stock/tools_assets/model/tool_asset.dart';
import '../../utils/utils.dart';
import '../model/assetunitfb.dart';
import '../model/birds_modification.dart';
import '../model/egg_record.dart';
import '../model/farm_plan.dart';
import '../model/feedbatchfb.dart';
import '../model/feedstockfb.dart';
import '../model/financeItem.dart';
import '../model/flockfb.dart';
import '../model/medicinestockfb.dart';
import '../model/multi_health_record.dart';
import '../model/sub_category_fb.dart';
import '../model/user.dart';
import '../model/vaccinestockfb.dart';

class FireBaseUtils{
  static final String FARMS = "farms";
  static final String USERS = "users";
  static final String DB_BACKUP = "db_backups";
  static final String EGG_TRANSACTIONS = "egg_transactions";
  static final String TRANSACTIONS = "transactions";
  static final String FLOCKS = "flocks";
  static final String FEEDING = "feeding";
  static final String HEALTH = "health";
  static final String MULTI_HEALTH = "multi_health";
  static final String GENERAL_STOCK = "general_stock";
  static final String GENERAL_STOCK_TRANS = "general_stock_transactions";
  static final String ASSET_TOOL_STOCK = "asset_tool_stock";
  static final String ASSET_UNIT_STOCK = "asset_unit_stock";
  static final String ASSET_UNIT_MAINTENANCE_STOCK = "asset_unit_maintenance_stock";
  static final String BIRDS = "birds";
  static final String EGGS = "eggs";
  static final String FINANCE = "finance";
  static final String FLOCK_DETAILS = "flock_details";
  static final String FLOCK_IMAGES = "flock_images";
  static final String CUSTOM_CATEGORY = "custom_categories";
  static final String CUSTOM_CATEGORY_DATA = "custom_category_data";
  static final String FEED_STOCK_HISTORY = "feed_stock_history";
  static final String MEDICINE_STOCK_HISTORY = "medicine_stock_history";
  static final String VACCINE_STOCK_HISTORY = "vaccine_stock_history";
  static final String FEED_INGRIDIENT = "feed_ingridient";
  static final String FEED_BATCH = "feed_batch";
  static final String SUB_CATEGORY = "sub_categories";
  static final String WEIGHT_RECORD = "weight_record";
  static final String SALE_CONTRACTOR = "sale_contractor";
  static final String MULTIUSER_PLAN = "multiuser_plan";
  //feed_stock_history




  static Future<bool> upgradeMultiUserPlan(FarmPlan farmplan) async {
    try {

      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(MULTIUSER_PLAN)
          .doc(farmplan.farmId)
          .set(farmplan.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");

      return false;
    }
  }


  static Future<bool> uploadFlock(FlockFB flockfb) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FLOCKS)
          .doc(flockfb.flock.sync_id!)
          .set(flockfb.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FLOCKS,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(flockfb.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateFlock(Flock flock) async {
    final firestore = FirebaseFirestore.instance;

    try {
      Utils.showLoading();

      print('FLOCK ID ${flock.toJson()}');
      final docRef = firestore.collection(FLOCKS).doc(flock.sync_id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        print("EXISTS");
        print(docSnap.data());
        print(flock.toJson());
        // ✅ Update existing flock
        await docRef.update({
          'last_modified': FieldValue.serverTimestamp(),
          'modified_by': Utils.currentUser!.email,
          'flock': flock.toFBJson(),
        });
        return true;
      } else
      {
        print("CREATE NEW");
        // ✅ Create new flock if not exists
        flock.sync_status = SyncStatus.UPDATED;
        FlockFB flockFB = FlockFB(flock: flock)
          ..farm_id = flock.farm_id
          ..modified_by = flock.modified_by
          ..last_modified = flock.last_modified;

        await docRef.set(flockFB.toJson());
        print("CREATED");
        return true; // treat as success
      }
    } catch (e) {
      print("❌ Failed to update flock: $e");

      Utils.showError();

      // Save operation into local sync queue for retry later
      FlockFB flockFB = FlockFB(flock: flock)
        ..farm_id = flock.farm_id
        ..modified_by = flock.modified_by
        ..last_modified = flock.last_modified;

      await DatabaseHelper.saveToSyncQueue(
        type: FLOCKS,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(flockFB.toJson()),
        lastError: e.toString(),
      );

      return false;
    } finally {
      Utils.hideLoading();
    }
  }

  static Future<bool> uploadFeedingRecord(Feeding feeding) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FEEDING)
          .doc(feeding.sync_id!)
          .set(feeding.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEEDING,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(feeding.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateFeedingRecord(Feeding feeding) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FEEDING)
          .doc(feeding.sync_id!)
          .update(feeding.toFBJson()); // Use toFBJson to include serverTimestamp

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to update feeding: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadFeedingRecord(feeding);

        return false;
      } else {
        await DatabaseHelper.saveToSyncQueue(
          type: FEEDING,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(feeding.toLocalFBJson()),
          // save local timestamp version
          lastError: e.toString(),
        );
      }
      return false;
    }
  }

  static Future<bool> deleteFeedingRecord(Feeding feeding) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      feeding.sync_status = SyncStatus.DELETED;
      await firestore
          .collection(FEEDING)
          .doc(feeding.sync_id)
          .update({
          'sync_status' : SyncStatus.DELETED
      });

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");

      return false;
    }
  }
  static Future<bool> uploadHealthRecord(Vaccination_Medication health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(HEALTH)
          .doc(health.sync_id!)
          .set(health.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: HEALTH,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(health.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> uploadMultiHealthRecord(MultiHealthRecord health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      health.sync_id = health.record!.sync_id;
      health.sync_status = SyncStatus.SYNCED;
      health.modified_by = Utils.currentUser!.email;
      health.last_modified = Utils.getTimeStamp();
      health.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(MULTI_HEALTH)
          .doc(health.sync_id!)
          .set(health.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: MULTI_HEALTH,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(health.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateMultiHealthRecord(MultiHealthRecord health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      health.sync_id = health.record!.sync_id;
      health.sync_status = SyncStatus.UPDATED;
      health.modified_by = Utils.currentUser!.email;
      health.last_modified = Utils.getTimeStamp();
      health.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(MULTI_HEALTH)
          .doc(health.sync_id!)
          .update(health.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: MULTI_HEALTH,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(health.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteMultiHealthRecord(MultiHealthRecord health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      health.sync_id = health.record!.sync_id;
      health.sync_status = SyncStatus.DELETED;
      health.modified_by = Utils.currentUser!.email;
      health.last_modified = Utils.getTimeStamp();
      health.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(MULTI_HEALTH)
          .doc(health.sync_id!)
          .update(health.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: MULTI_HEALTH,
        syncId: Utils.currentUser!.email,
        opType: 'delete',
        payload: jsonEncode(health.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> uploadGenStockRecord(GeneralStockItem genStockItem) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;


      genStockItem.sync_status = SyncStatus.SYNCED;
      genStockItem.modified_by = Utils.currentUser!.email;
      genStockItem.last_modified = Utils.getTimeStamp();
      genStockItem.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(GENERAL_STOCK)
          .doc(genStockItem.sync_id!)
          .set(genStockItem.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: GENERAL_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(genStockItem.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> deleteGenStockRecord(GeneralStockItem genStockItem) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;


      genStockItem.sync_status = SyncStatus.DELETED;
      genStockItem.modified_by = Utils.currentUser!.email;
      genStockItem.last_modified = Utils.getTimeStamp();
      genStockItem.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(GENERAL_STOCK)
          .doc(genStockItem.sync_id!)
          .update(genStockItem.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: GENERAL_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'delete',
        payload: jsonEncode(genStockItem.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }



  static Future<bool> uploadGenStockTransRecord(GeneralStockTransactionFB genTransFB) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;


      genTransFB.sync_id = genTransFB.stockTransaction.sync_id;
      genTransFB.sync_status = SyncStatus.SYNCED;
      genTransFB.modified_by = Utils.currentUser!.email;
      genTransFB.last_modified = Utils.getTimeStamp();
      genTransFB.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(GENERAL_STOCK_TRANS)
          .doc(genTransFB.sync_id!)
          .set(genTransFB.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: GENERAL_STOCK_TRANS,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(genTransFB.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteGenStockTransRecord(GeneralStockTransactionFB genTransFB) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      genTransFB.sync_id = genTransFB.stockTransaction.sync_id;
      genTransFB.sync_status = SyncStatus.DELETED;
      genTransFB.modified_by = Utils.currentUser!.email;
      genTransFB.last_modified = Utils.getTimeStamp();
      genTransFB.farm_id = Utils.currentUser!.farmId;


      await firestore
          .collection(GENERAL_STOCK_TRANS)
          .doc(genTransFB.sync_id!)
          .set(genTransFB.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: GENERAL_STOCK_TRANS,
        syncId: Utils.currentUser!.email,
        opType: 'delete',
        payload: jsonEncode(genTransFB.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> uploadAssetStockTransRecord(ToolAssetMaster tooAssetObject) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(ASSET_TOOL_STOCK)
          .doc(tooAssetObject.sync_id!)
          .set(tooAssetObject.toFireStoreJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_TOOL_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(tooAssetObject.toMap()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteAssetStockTransRecord(ToolAssetMaster tooAssetObject) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      tooAssetObject.sync_status = SyncStatus.DELETED;
      tooAssetObject.last_modified = Utils.getTimeStamp();
      tooAssetObject.modified_by = Utils.currentUser!.email;
      await firestore
          .collection(ASSET_TOOL_STOCK)
          .doc(tooAssetObject.sync_id!)
          .update(tooAssetObject.toFireStoreJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_TOOL_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(tooAssetObject.toMap()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> uploadAssetUnitStockTransRecord(AssetUnitFBModel assetUnitModel) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      assetUnitModel.sync_status = SyncStatus.SYNCED;
      assetUnitModel.last_modified = Utils.getTimeStamp();
      assetUnitModel.modified_by = Utils.currentUser!.email;
      assetUnitModel.sync_id = assetUnitModel.unit.sync_id;
      assetUnitModel.farm_id = Utils.currentUser!.farmId;
      await firestore
          .collection(ASSET_UNIT_STOCK)
          .doc(assetUnitModel.sync_id!)
          .set(assetUnitModel.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_UNIT_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(assetUnitModel.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateAssetUnitStockTransRecord(AssetUnitFBModel assetUnitModel) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      assetUnitModel.sync_status = SyncStatus.UPDATED;
      assetUnitModel.last_modified = Utils.getTimeStamp();
      assetUnitModel.modified_by = Utils.currentUser!.email;
      assetUnitModel.sync_id = assetUnitModel.unit.sync_id;
      assetUnitModel.farm_id = Utils.currentUser!.farmId;
      await firestore
          .collection(ASSET_UNIT_STOCK)
          .doc(assetUnitModel.sync_id!)
          .update(assetUnitModel.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_UNIT_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(assetUnitModel.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteAssetUnitStockTransRecord(AssetUnitFBModel assetUnitModel) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      assetUnitModel.sync_status = SyncStatus.DELETED;
      assetUnitModel.last_modified = Utils.getTimeStamp();
      assetUnitModel.modified_by = Utils.currentUser!.email;
      assetUnitModel.sync_id = assetUnitModel.unit.sync_id;
      assetUnitModel.farm_id = Utils.currentUser!.farmId;
      await firestore
          .collection(ASSET_UNIT_STOCK)
          .doc(assetUnitModel.sync_id!)
          .update(assetUnitModel.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_UNIT_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'delete',
        payload: jsonEncode(assetUnitModel.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> uploadAssetUnitMaintenanceStockRecord(AssetUnitMaintenanceFBModel assetUnitModel) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      assetUnitModel.sync_status = SyncStatus.SYNCED;
      assetUnitModel.last_modified = Utils.getTimeStamp();
      assetUnitModel.modified_by = Utils.currentUser!.email;
      assetUnitModel.sync_id = assetUnitModel.maintenance.sync_id;
      assetUnitModel.farm_id = Utils.currentUser!.farmId;
      await firestore
          .collection(ASSET_UNIT_MAINTENANCE_STOCK)
          .doc(assetUnitModel.sync_id!)
          .set(assetUnitModel.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_UNIT_MAINTENANCE_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(assetUnitModel.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteAssetUnitMaintenanceStockTransRecord(AssetUnitMaintenanceFBModel assetUnitModel) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      assetUnitModel.sync_status = SyncStatus.DELETED;
      assetUnitModel.last_modified = Utils.getTimeStamp();
      assetUnitModel.modified_by = Utils.currentUser!.email;
      assetUnitModel.sync_id = assetUnitModel.maintenance.sync_id;
      assetUnitModel.farm_id = Utils.currentUser!.farmId;
      await firestore
          .collection(ASSET_UNIT_MAINTENANCE_STOCK)
          .doc(assetUnitModel.sync_id!)
          .update(assetUnitModel.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: ASSET_UNIT_MAINTENANCE_STOCK,
        syncId: Utils.currentUser!.email,
        opType: 'delete',
        payload: jsonEncode(assetUnitModel.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }



  static Future<bool> updateHealthRecord(Vaccination_Medication health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(HEALTH)
          .doc(health.sync_id!)
          .update(health.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadHealthRecord(health);

        return false;
      } else {
        await DatabaseHelper.saveToSyncQueue(
          type: HEALTH,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(health.toLocalFBJson()),
          lastError: e.toString(),
        );
      }
      return false;
    }
  }

  static Future<bool> deleteHealthRecord(Vaccination_Medication health) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      health.sync_status = SyncStatus.DELETED;
      await firestore
          .collection(HEALTH)
          .doc(health.sync_id)
          .update({
           'sync_status' : SyncStatus.DELETED
      });

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");

      return false;
    }
  }

  static Future<bool> uploadExpenseRecord(FinanceItem financeItem) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FINANCE)
          .doc(financeItem.sync_id!)
          .set(financeItem.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FINANCE,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(financeItem.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateExpenseRecord(FinanceItem financeItem) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FINANCE)
          .doc(financeItem.sync_id!)
          .update(financeItem.toJson());
      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadExpenseRecord(financeItem);

        return false;
      } else {
        await DatabaseHelper.saveToSyncQueue(
          type: FINANCE,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(financeItem.toLocalJson()),
          lastError: e.toString(),
        );
      }
      return false;
    }
  }

  static Future<bool> deleteFinanceRecord(FinanceItem financeItem) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      financeItem.sync_status = SyncStatus.DELETED;
      financeItem.transaction.sync_status = SyncStatus.DELETED;
      await firestore
          .collection(FINANCE)
          .doc(financeItem.sync_id!)
          .update(financeItem.toJson());
      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");

      return false;
    }
  }

  static Future<bool> uploadEggRecord(EggRecord eggRecord) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(EGGS)
          .doc(eggRecord.sync_id!)
          .set(eggRecord.toJson());
      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: EGGS,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(eggRecord.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateEggRecord(EggRecord eggRecord) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      if (eggRecord.sync_id == null) {
        throw Exception("sync_id is required to update EggRecord");
      }

      await firestore
          .collection(EGGS)
          .doc(eggRecord.sync_id)
          .update(eggRecord.toJson());

      Utils.hideLoading();
      print("✅ EggRecord updated successfully");
      return true;
    } catch (e) {
      print("❌ Failed to update EggRecord: $e");
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadEggRecord(eggRecord);

        return false;
      } else {
        await DatabaseHelper.saveToSyncQueue(
            type: EGGS,
            syncId: Utils.currentUser!.email,
            opType: 'update',
            payload: jsonEncode(eggRecord.toLocalJson()),
            lastError: e.toString());
      return false;
    }
    }
  }

  static Future<bool> deleteEggRecord(EggRecord eggRecord) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      eggRecord.sync_status = SyncStatus.DELETED;
      eggRecord.eggs.sync_status = SyncStatus.DELETED;
      await firestore
          .collection(EGGS)
          .doc(eggRecord.sync_id)
          .update(eggRecord.toJson());
      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadEggRecord(eggRecord);

        return false;
      } else {
        await DatabaseHelper.saveToSyncQueue(
            type: EGGS,
            syncId: Utils.currentUser!.email,
            opType: 'delete',
            payload: jsonEncode(eggRecord.toLocalJson()),
            lastError: e.toString());
        return false;
      }
      return false;
    }
  }

  static Future<bool> uploadBirdsDetails(BirdsModification birds) async {
    try {
      Utils.showLoading();
      print("uploadBirdsDetails ${birds.toJson()}");
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(BIRDS)
          .doc(birds.flockDetail.sync_id!)
          .set(birds.toJson());

      Utils.hideLoading();

      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: BIRDS,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(birds.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateBirdsDetails(BirdsModification birds) async {
    try {
      Utils.showLoading();
      print("uploadBirdsDetails ${birds.toJson()}");
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection(BIRDS).doc(birds.flockDetail.sync_id!);

      try {
        // Try updating the document
        await docRef.update(birds.toJson());
      } catch (e) {
        if (e is FirebaseException && e.code == 'not-found') {
          // Document doesn't exist, fallback to set
          await docRef.set(birds.toJson());
        } else {
          rethrow; // Let outer catch handle unexpected errors
        }
      }
      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to update birds: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: BIRDS,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(birds.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> deleteBirdsDetails(BirdsModification birds) async {
    try {
      Utils.showLoading();
      print("uploadBirdsDetails ${birds.toJson()}");
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection(BIRDS).doc(birds.flockDetail.sync_id!);

      birds.flockDetail.sync_status = SyncStatus.DELETED;
      try {
        // Try updating the document
        await docRef.update(birds.toJson());
      } catch (e) {
        if (e is FirebaseException && e.code == 'not-found') {
          // Document doesn't exist, fallback to set
          await docRef.set(birds.toJson());
        } else {
          rethrow; // Let outer catch handle unexpected errors
        }
      }

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to update birds: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: BIRDS,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(birds.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

/*
  static Future<bool> uploadTransactions(TransactionItem transaction) async {
    try {
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(TRANSACTIONS)
          .doc(transaction.sync_id!)
          .set(transaction.toFBJson());

      return true;
    } catch (e) {
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: 'transaction',
        syncId: transaction.sync_id!,
        opType: 'add',
        payload: jsonEncode(transaction.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> uploadFlockDetails(Flock_Detail flock_detail) async {
    try {
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(FLOCK_DETAILS)
          .doc(flock_detail.sync_id!)
          .set(flock_detail.toFBJson());

      return true;
    } catch (e) {
      print("❌ Failed to upload: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: 'flock_details',
        syncId: flock_detail.sync_id!,
        opType: 'add',
        payload: jsonEncode(flock_detail.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
*/

  static Future<void> saveFlockImagesToFirestore({
    required String farmId,
    required String flockId,
    required List<String> imageUrls,
    required String uploadedBy,
  }) async
  {
    final firestore = FirebaseFirestore.instance;
    final timestamp = FieldValue.serverTimestamp();

    try {
      final imagesCollection = firestore
          .collection(FLOCK_IMAGES)
          .doc("${farmId}_$flockId");

      await imagesCollection.set({
        'farm_id': farmId,
        'flock_id': flockId,
        'image_urls': imageUrls,
        'uploaded_by': uploadedBy,
        'timestamp': timestamp,
        'f_sync_id': flockId
      });

      print("✅ Flock images saved to Firestore");
    } catch (e) {
      print("❌ Failed to save images to Firestore: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FLOCK_IMAGES,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode({
          'farm_id': farmId,
          'flock_id': flockId,
          'image_urls': imageUrls,
          'uploaded_by': uploadedBy,
          'timestamp': timestamp,
          'f_sync_id': flockId
        }.toString()),
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  static Future<bool> addCustomCategory(CustomCategory category) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(CUSTOM_CATEGORY)
          .doc(category.sync_id)
          .set(category.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add custom category: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: CUSTOM_CATEGORY,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(category.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> updateCustomCategory(CustomCategory category) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(CUSTOM_CATEGORY)
          .doc(category.sync_id)
          .update(category.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await addCustomCategory(category);

        return false;
      } else {
        print("❌ Failed to add custom category: $e");
        // Optionally save to sync queue
        await DatabaseHelper.saveToSyncQueue(
          type: CUSTOM_CATEGORY,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(category.toLocalFBJson()),
          lastError: e.toString(),
        );
        return false; // Let outer catch handle unexpected errors
      }
    }
  }

  static Future<bool> addCustomCategoryData(CustomCategoryData categorydata) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(CUSTOM_CATEGORY_DATA)
          .doc(categorydata.sync_id)
          .set(categorydata.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add custom category: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: CUSTOM_CATEGORY_DATA,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(categorydata.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> updateCustomCategoryData(CustomCategoryData categorydata) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(CUSTOM_CATEGORY_DATA)
          .doc(categorydata.sync_id)
          .update(categorydata.toLocalFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await addCustomCategoryData(categorydata);

        return false;
      }else {
        print("❌ Failed to add custom category: $e");
        // Optionally save to sync queue
        await DatabaseHelper.saveToSyncQueue(
          type: CUSTOM_CATEGORY_DATA,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(categorydata.toLocalFBJson()),
          lastError: e.toString(),
        );
        return false;
      }
    }
  }


  static Future<bool> uploadFeedStockHistory(FeedStockFB item) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;


      await firestore
          .collection(FEED_STOCK_HISTORY)
          .doc(item.stock.sync_id)
          .set(item.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload FeedStockHistory: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEED_STOCK_HISTORY,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(item.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> updateFeedStockHistory(FeedStockFB item) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      if (item.stock.sync_id == null) {
        throw Exception("Missing sync_id for update operation.");
      }

      await firestore
          .collection(FEED_STOCK_HISTORY)
          .doc(item.stock.sync_id)
          .update(item.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadFeedStockHistory(item);

        return false;
      }else {
        print("❌ Failed to update FeedStockHistory: $e");
        await DatabaseHelper.saveToSyncQueue(
          type: FEED_STOCK_HISTORY,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(item.toJson()),
          lastError: e.toString(),
        );
        return false;
      }
    }
  }


  static Future<bool> uploadMedicineStock(MedicineStockFB medicine) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(MEDICINE_STOCK_HISTORY)
          .doc(medicine.stock.sync_id!)
          .set(medicine.toJson());

      Utils.hideLoading();
      print("✅ Medicine stock uploaded: ${medicine.stock.sync_id}");
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload medicine stock: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: MEDICINE_STOCK_HISTORY,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(medicine.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> updateMedicineStock(MedicineStockFB medicine) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(MEDICINE_STOCK_HISTORY)
          .doc(medicine.stock.sync_id!)
          .update(medicine.toJson());

      Utils.hideLoading();
      print("✅ Medicine stock updated: ${medicine.stock.sync_id}");
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadMedicineStock(medicine);

        return false;
      }else {
        print("❌ Failed to update medicine stock: $e");
        await DatabaseHelper.saveToSyncQueue(
          type: MEDICINE_STOCK_HISTORY,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(medicine.toLocalJson()),
          lastError: e.toString(),
        );
        return false;
      }
    }
  }



  static Future<bool> uploadVaccineStock(VaccineStockFB vaccine) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(VACCINE_STOCK_HISTORY)
          .doc(vaccine.stock.sync_id!)
          .set(vaccine.toJson());

      Utils.hideLoading();
      print("✅ Vaccine stock uploaded: ${vaccine.stock.sync_id}");
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload vaccine stock: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: VACCINE_STOCK_HISTORY,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(vaccine.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> updateVaccineStock(VaccineStockFB vaccine) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(VACCINE_STOCK_HISTORY)
          .doc(vaccine.stock.sync_id!)
          .update(vaccine.toJson());

      Utils.hideLoading();
      print("✅ Vaccine stock updated: ${vaccine.stock.sync_id}");
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await uploadVaccineStock(vaccine);

        return false;
      } else {
        print("❌ Failed to update vaccine stock: $e");
        await DatabaseHelper.saveToSyncQueue(
          type: VACCINE_STOCK_HISTORY,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(vaccine.toLocalFBJson()),
          lastError: e.toString(),);
        return false;
      }
    }
  }

  /// ➕ Add new FeedIngredient
  static Future<bool> addFeedIngredient(FeedIngredient ingredient) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      print("📤 Uploading FeedIngredient: ${ingredient.name}");
      await firestore
          .collection(FEED_INGRIDIENT)
          .doc(ingredient.sync_id)
          .set(ingredient.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload FeedIngredient: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEED_INGRIDIENT,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(ingredient.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  /// ✏️ Update existing FeedIngredient
  static Future<bool> updateFeedIngredient(FeedIngredient ingredient) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      print("✏️ Updating FeedIngredient: ${ingredient.name}");

      final docRef = firestore.collection(FEED_INGRIDIENT).doc(ingredient.sync_id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        print("⚠️ Document not found for sync_id: ${ingredient.sync_id}");
        addFeedIngredient(ingredient);
        return false;
      }

      await docRef.update(ingredient.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to update FeedIngredient: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEED_INGRIDIENT,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(ingredient.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  /// ➕ Add new FeedIngredient
  static Future<bool> addFeedBatch(FeedBatchFB feedbatchfb) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;


      await firestore
          .collection(FEED_BATCH)
          .doc(feedbatchfb.feedbatch.sync_id)
          .set(feedbatchfb.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to upload FeedBatch: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEED_BATCH,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(feedbatchfb.feedbatch.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  /// ✏️ Update existing FeedIngredient
  static Future<bool> updateFeedBatch(FeedBatchFB feedbatchfb) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      final docRef = firestore.collection(FEED_BATCH).doc(feedbatchfb.feedbatch.sync_id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        print("⚠️ Document not found for sync_id: ${feedbatchfb.feedbatch.sync_id}");
        addFeedBatch(feedbatchfb);
        return false;
      }

      await docRef.update(feedbatchfb.toJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to update FeedBatch: $e");
      await DatabaseHelper.saveToSyncQueue(
        type: FEED_BATCH,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(feedbatchfb.toLocalFBJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }


  static Future<bool> addSubCategory(SubItem category) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(SUB_CATEGORY)
          .doc(category.sync_id)
          .set(category.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add custom category: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: SUB_CATEGORY,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(category.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> updateSubCategory(SubItem category) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(SUB_CATEGORY)
          .doc(category.sync_id)
          .update(category.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await addSubCategory(category);

        return false;
      } else {
        print("❌ Failed to add custom category: $e");
        // Optionally save to sync queue
        await DatabaseHelper.saveToSyncQueue(
          type: SUB_CATEGORY,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(category.toJson()),
          lastError: e.toString(),
        );
        return false; // Let outer catch handle unexpected errors
      }
    }
  }

  static Future<bool> addWeightRecords(WeightRecord weightRecord) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(WEIGHT_RECORD)
          .doc(weightRecord.sync_id)
          .set(weightRecord.toFirestoreJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add weight records: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: WEIGHT_RECORD,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(weightRecord.toJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }
  static Future<bool> updateWeightRecords(WeightRecord weightRecord) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(WEIGHT_RECORD)
          .doc(weightRecord.sync_id)
          .update(weightRecord.toFirestoreJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      if (e is FirebaseException && e.code == 'not-found') {
        // Document doesn't exist, fallback to set
        await addWeightRecords(weightRecord);

        return false;
      } else {
        print("❌ Failed to add weight records: $e");
        // Optionally save to sync queue
        await DatabaseHelper.saveToSyncQueue(
          type: WEIGHT_RECORD,
          syncId: Utils.currentUser!.email,
          opType: 'update',
          payload: jsonEncode(weightRecord.toJson()),
          lastError: e.toString(),
        );
        return false; // Let outer catch handle unexpected errors
      }
    }
  }


  static Future<bool> addSaleContractor(SaleContractor saleContractor) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(SALE_CONTRACTOR)
          .doc(saleContractor.sync_id)
          .set(saleContractor.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add saleContractor: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: SALE_CONTRACTOR,
        syncId: Utils.currentUser!.email,
        opType: 'add',
        payload: jsonEncode(saleContractor.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }

  static Future<bool> updateSaleContractor(SaleContractor saleContractor) async {
    try {
      Utils.showLoading();
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(SALE_CONTRACTOR)
          .doc(saleContractor.sync_id)
          .update(saleContractor.toFBJson());

      Utils.hideLoading();
      return true;
    } catch (e) {
      Utils.showError();
      print("❌ Failed to add saleContractor: $e");
      // Optionally save to sync queue
      await DatabaseHelper.saveToSyncQueue(
        type: SALE_CONTRACTOR,
        syncId: Utils.currentUser!.email,
        opType: 'update',
        payload: jsonEncode(saleContractor.toLocalJson()),
        lastError: e.toString(),
      );
      return false;
    }
  }



}