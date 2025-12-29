import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:poultary/model/egg_income.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/multiuser/api/server_apis.dart';
import 'package:poultary/multiuser/model/multi_health_record.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:poultary/stock/model/general_stock.dart';
import 'package:poultary/stock/tools_assets/model/tool_asset_unit.dart';
import '../../database/databse_helper.dart';
import '../../model/custom_category.dart';
import '../../model/custom_category_data.dart';
import '../../model/egg_item.dart';
import '../../model/feed_batch.dart';
import '../../model/feed_batch_item.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/feed_stock_history.dart';
import '../../model/flock.dart';
import '../../model/flock_image.dart';
import '../../model/health/multi_medicine.dart';
import '../../model/med_vac_item.dart';
import '../../model/medicine_stock_history.dart';
import '../../model/sale_contractor.dart';
import '../../model/stock_expense.dart';
import '../../model/vaccine_stock_history.dart';
import '../../model/weight_record.dart';
import '../../stock/model/stock_transactions.dart';
import '../../stock/tools_assets/model/tool_asset.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/assetunitfb.dart';
import '../model/birds_modification.dart';
import '../model/egg_record.dart';
import '../model/feedbatchfb.dart';
import '../model/feedstockfb.dart';
import '../model/financeItem.dart';
import '../model/flockfb.dart';
import '../model/general stock_transactions_fb.dart';
import '../model/ingridientfb.dart';
import '../model/medicinestockfb.dart';
import '../model/vaccinestockfb.dart';
import 'Deduplicator.dart';
import 'FirebaseUtils.dart';
import 'RefreshEventBus.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _started = false;

  Set<String> _localWriteIds = {};

  void addModifiedId(String id) {
    _localWriteIds.add(id);
  }

  ValueNotifier<DateTime?>? mysyncTimeNotifier;
  void setSyncTimeNotifier(ValueNotifier<DateTime?> syncTimeNotifier) {
       mysyncTimeNotifier = syncTimeNotifier;
  }

  void startAllListeners(String farmId, DateTime? lastSyncTime) {
    if (_started) {
      print("ALREADY_STARTED");
      return;
    }
    _started = true;

    print("STARTING");

    startFockListening(farmId, lastSyncTime);
    startFinanceListening(farmId, lastSyncTime);
    startBirdModificationListening(farmId, lastSyncTime);
    startEggRecordListening(farmId, lastSyncTime);
    startFeedingListening(farmId, lastSyncTime);
    startCustomCategoryListening(farmId, lastSyncTime);
    startFeedIngredientListening(farmId, lastSyncTime);
    startHealthListening(farmId, lastSyncTime);
    startMultiHealthListening(farmId, lastSyncTime);
    startCustomCategoryDataListening(farmId, lastSyncTime);
    startFeedBatchFBListening(farmId, lastSyncTime);
    startFeedStockFBListening(farmId, lastSyncTime);
    startMedicineStockFBListening(farmId, lastSyncTime);
    startVaccineStockFBListening(farmId, lastSyncTime);
    startSubCategoryListening(farmId, lastSyncTime);
    startWeightRecordsListening(farmId, lastSyncTime);
    startSaleContractorListening(farmId, lastSyncTime);
    startGenStockListening(farmId, lastSyncTime);
    startGenStockTransListening(farmId, lastSyncTime);

    startToolAssetStockListening(farmId, lastSyncTime);
    startAssetUnitListening(farmId, lastSyncTime);

  }


  static final ValueNotifier<int> activeListeners = ValueNotifier<int>(0);

  static void startSync() {
    activeListeners.value++;
  }

  static void completeSync() {
    if (activeListeners.value > 0) {
      activeListeners.value--;
    }
  }

  static bool get isSyncing => activeListeners.value > 0;

  final List<StreamSubscription> _subscriptions = [];
  final deduplicator = UpdateDeduplicator();

  Future<void> startFockListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FLOCKS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    print("SYNC TIME $lastSyncTime");

    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FLOCKS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

     final _subscription = query.snapshots().listen((snapshot) async {

       if (!firstSnapshotHandled) {
         SyncManager().listenerCompleted(); // progress +1
         firstSnapshotHandled = true;
       }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data() as Map<String, dynamic>;
            Utils.backup_changes += snapshot.docChanges.length;
            startSync();
            FlockFB? flockFB = FlockFB.fromJson(data);
            print("🟢 New/Updated FLOCK: ${flockFB.flock.f_name} ${flockFB.flock.f_id} ${flockFB.flock.active_bird_count}");

            // Track latest timestamp for sync update
            if (flockFB.last_modified!.isAfter(lastSyncTime!)) {
              lastSyncTime = flockFB.last_modified;
            }

            if (_localWriteIds.contains(flockFB.flock.f_name)) {
              // 👇 Skip your own recent local write
              print("SELF MODIFICATION SKIPPED");
              _localWriteIds.remove(flockFB.flock.f_name); // Remove after skip (one-time)
              continue;
            }

           /* if(flockFB.modified_by == Utils.currentUser!.email)
              return;*/

           /* if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FLOCKS, flockFB.flock.sync_id!, flockFB.last_modified!))
              return;*/

            bool isAlreadyAdded = await DatabaseHelper.checkFlockBySyncID(flockFB.flock.sync_id!);
            if(isAlreadyAdded){
              if(flockFB.flock.sync_status == SyncStatus.UPDATED || flockFB.flock.sync_status == SyncStatus.SYNCED) {
                await DatabaseHelper.updateFlockInfoBySyncID(flockFB.flock);
                Flock? flock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
                await listenToFlockImagesUntilFound(flock!, flock.farm_id ?? "");
              }else if (flockFB.flock.sync_status == SyncStatus.DELETED) {
                //Delete Entire Flock and related Data
                Flock? flock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
                await DatabaseHelper.deleteFlockAndRelatedInfoSyncID(flockFB.flock.sync_id!, flock!.f_id);
              }

              SessionManager.setLastSyncTime(FireBaseUtils.FLOCKS, lastSyncTime!);

            }
            else
            {
              if(flockFB.flock.sync_status != SyncStatus.DELETED) {
                // Handle dependent data
               int? f_id =  await DatabaseHelper.insertFlock(flockFB.flock);
                if(flockFB.transaction != null) {
                  flockFB.transaction!.f_id = f_id!;
                  int? tr_id = await DatabaseHelper.insertNewTransaction(
                      flockFB.transaction!);
                  flockFB.flockDetail!.transaction_id = tr_id.toString();
                  flockFB.flockDetail!.f_id = f_id;
                  int? f_detail_id = await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
                  await DatabaseHelper.updateLinkedTransaction(tr_id!.toString(), f_detail_id!.toString());
                }else{
                  flockFB.flockDetail!.transaction_id = "-1";
                  flockFB.flockDetail!.f_id = f_id!;
                  await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
                }

                Flock? insertedFlock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
                print("FLOCK INSERTED ${insertedFlock!.toJson()}");
                await listenToFlockImagesUntilFound(insertedFlock, flockFB.flock.farm_id ?? "");

              }else{
                print(flockFB.flock.sync_status);
              }

              SessionManager.setLastSyncTime(FireBaseUtils.FLOCKS, lastSyncTime!);
            }
            RefreshEventBus().emit(FireBaseUtils.FLOCKS);
            completeSync();
            // Save/update in SQLite
          }
        }
        if(mysyncTimeNotifier != null)
          mysyncTimeNotifier!.value = lastSyncTime;
      });

      _subscriptions.add(_subscription);

      print("FLOCK SYNC STARTED");
    }
    catch(ex){
      print(ex);
      completeSync();
    }
  }

  Future<void> listenToFlockImagesUntilFound(Flock flock, String farmId,
      {Duration timeout = const Duration(seconds: 120)}) async
  {
    final String farm_id = farmId;
    final String? f_sync_id = flock.sync_id;

    print("⏳ Waiting for IMAGES $farm_id ${farm_id.length} $f_sync_id ${f_sync_id!.length}");

    final query = FirebaseFirestore.instance
        .collection(FireBaseUtils.FLOCK_IMAGES)
        .where('farm_id', isEqualTo: farm_id)
        .where('f_sync_id', isEqualTo: f_sync_id);

    final completer = Completer<void>();

    late final StreamSubscription sub;
    sub = query.snapshots().listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        print("✅ IMAGE FLOCKS FOUND ${snapshot.docs.length}");

        // Delete old images
        final oldImages = await DatabaseHelper.getFlockImage(flock.f_id);
        for (var img in oldImages) {
          final result = await DatabaseHelper.deleteItem("Flock_Image", img.id!);
          print("🗑️ DELETED $result");
        }

        // Save new images
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final List<dynamic>? imageUrls = data['image_urls'];

          if (imageUrls != null && imageUrls.isNotEmpty) {
            final urls = imageUrls.cast<String>();
            print("🖼️ Flock Image URLs: $urls");

            for (final url in urls) {
              final base64 = await FlockImageUploader().downloadImageAsBase64(url);
              if (base64 != null) {
                final flockImage = Flock_Image(
                  f_id: flock.f_id,
                  image: base64,
                  sync_id: Utils.getUniueId(),
                  sync_status: SyncStatus.SYNCED,
                  last_modified: flock.last_modified,
                  modified_by: flock.modified_by,
                  farm_id: flock.farm_id,
                );

                await DatabaseHelper.insertFlockImages(flockImage);
              }
            }
          }
        }

        // ✅ Cancel listener once processed
        await sub.cancel();
        if (!completer.isCompleted) completer.complete();
      } else {
        print("⚠️ Still waiting for images...");
      }
    });

    // Stop waiting after timeout (dispose listener)
    Future.delayed(timeout, () async {
      if (!completer.isCompleted) {
        print("⏱️ Timeout reached, no images found. Disposing listener.");
        await sub.cancel();
        completer.complete();
      }
    });

    return completer.future;
  }

  /// 🐣 BirdsModification listener
  Future<void> startBirdModificationListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.BIRDS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    bool firstSnapshotHandled = false; // 👈 flag to only count once


    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.BIRDS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {

        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final modification = BirdsModification.fromJson(data);
          print("🔄 BIRD MODIFIED: ${modification.flockDetail.item_type}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (modification.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = modification.last_modified;
          }

          /*if(modification.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.BIRDS, modification.flockDetail.sync_id!, modification.last_modified!)) {
            print("DUPLICATE");
            return;
          }*/

          // Save/update to SQLite:
          Flock? flock = await DatabaseHelper.getFlockBySyncId(modification.flockDetail.f_sync_id!);

          if(true) {

            bool isAlreadyAdded = await DatabaseHelper.checkIfRecordExistsSyncID('Flock_Detail',modification.flockDetail.sync_id!);

            if(isAlreadyAdded)
            {

              if(modification.flockDetail.sync_status == SyncStatus.UPDATED) {
                Flock_Detail? oldRecord = await DatabaseHelper
                    .getSingleFlockDetailsBySyncID(
                    modification.flockDetail.sync_id!);
                String transID = oldRecord!.transaction_id;
                int f_detail_id = oldRecord.f_detail_id!;

                modification.flockDetail.f_detail_id = f_detail_id;
                modification.flockDetail.transaction_id = transID;
                modification.flockDetail.f_id = oldRecord.f_id;
                await DatabaseHelper.updateFlock(modification.flockDetail);

                if (modification.transaction != null) {
                  modification.transaction!.flock_update_id =
                      oldRecord.f_detail_id.toString();
                  modification.transaction!.id = int.parse(transID);
                  modification.transaction!.f_id = oldRecord.f_id;
                  await DatabaseHelper.updateTransaction(
                      modification.transaction!);
                }
              }else if (modification.flockDetail.sync_status == SyncStatus.DELETED){
                Flock_Detail? oldRecord = await DatabaseHelper
                    .getSingleFlockDetailsBySyncID(
                    modification.flockDetail.sync_id!);

                await DatabaseHelper.deleteFlockDetailsRecord(oldRecord!.f_detail_id!);
              }

              SessionManager.setLastSyncTime(FireBaseUtils.BIRDS, lastSyncTime!);

            }
            else {
              if (modification.flockDetail.sync_status != SyncStatus.DELETED) {
                int? trId = -1;
                if (modification.transaction != null) {
                  modification.transaction!.f_id = flock!.f_id;
                  trId = await DatabaseHelper.insertNewTransaction(
                      modification.transaction!);
                }

                final detail = modification.flockDetail;
                detail.transaction_id = trId == null ? "-1" : trId.toString();
                detail.f_id = flock == null ? -1 : flock.f_id;

                int? f_detail_id = await DatabaseHelper.insertFlockDetail(
                    detail);
                if (trId != null) {
                  await DatabaseHelper.updateLinkedTransaction(
                      trId.toString(), f_detail_id.toString());
                }
              }

              SessionManager.setLastSyncTime(FireBaseUtils.BIRDS, lastSyncTime!);
            }
            RefreshEventBus().emit(FireBaseUtils.BIRDS);
            completeSync();
          }
        }
      });

      _subscriptions.add(sub);
      print("BIRDS SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ BirdModification sync error: $e");
    }
  }

  /// 🥚 EggRecord listener
  Future<void> startEggRecordListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.EGGS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.EGGS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub1 = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final eggRecord = EggRecord.fromJson(data);

          print("🥚 EGG RECORD SYNC: ${eggRecord.eggs.f_name}, ${eggRecord.eggs.total_eggs} ${eggRecord.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (eggRecord.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = eggRecord.last_modified;
          }
          /*if(eggRecord.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.EGGS, eggRecord.sync_id!, eggRecord.last_modified!)) {
            print("DUPLICATE EGG");
            return;
          }*/

          Flock? flock = await DatabaseHelper.getFlockBySyncId(eggRecord.eggs.f_sync_id!);

          bool isAlreadyAdded = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Eggs', eggRecord.eggs.sync_id!,
          );

          if (isAlreadyAdded) {
            if(eggRecord.sync_status == SyncStatus.UPDATED) {
              print("UPDATING EGG");
              Eggs? oldEggs = await DatabaseHelper.getSingleEggsBySyncID(
                  eggRecord.eggs.sync_id!);
              int oldId = oldEggs?.id ?? -1;

              TransactionItem? transactionItem = null;
              EggTransaction? eggTransaction = await DatabaseHelper
                  .getByEggItemId(oldEggs!.id!);
              if (eggTransaction != null) {
                transactionItem = await DatabaseHelper.getSingleTransaction(
                    eggTransaction.transactionId.toString());

                eggRecord.eggs.id = oldId;
                eggRecord.eggs.f_id = flock!.f_id;

                await DatabaseHelper.updateEggCollection(eggRecord.eggs);

                if (eggRecord.transaction != null && transactionItem != null) {
                  eggRecord.transaction!.id = transactionItem.id;
                  eggRecord.transaction!.f_id = flock.f_id;
                  await DatabaseHelper.updateTransaction(
                      eggRecord.transaction!);
                }
              }else{
                eggRecord.eggs.id = oldId;
                eggRecord.eggs.f_id = flock!.f_id;

                await DatabaseHelper.updateEggCollection(eggRecord.eggs);
              }
              print("UPDATED");
            }else if(eggRecord.sync_status == SyncStatus.DELETED) {
              Eggs? oldEggs = await DatabaseHelper.getSingleEggsBySyncID(
                  eggRecord.eggs.sync_id!);
              EggTransaction? eggTransaction = await DatabaseHelper.getByEggItemId(oldEggs!.id!);
              if(eggTransaction!= null) {
                DatabaseHelper.deleteItem("Transactions", eggTransaction.transactionId);
                DatabaseHelper.deleteByEggItemId(oldEggs.id!);
              }
              DatabaseHelper.deleteItem("Eggs", oldEggs.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.EGGS, lastSyncTime!);

          }
          else {
            if (eggRecord.sync_status != SyncStatus.DELETED){
              int? transId;
            if (eggRecord.transaction != null) {
              eggRecord.transaction!.f_id = flock!.f_id;

              transId = await DatabaseHelper.insertNewTransaction(
                  eggRecord.transaction!);
            }
            eggRecord.eggs.f_id = flock!.f_id;
            int? eggs_id = await DatabaseHelper.insertEggCollection(
                eggRecord.eggs);

            if (transId != null && eggs_id != null) {
              EggTransaction eggTransaction = EggTransaction(
                  eggItemId: eggs_id,
                  transactionId: transId,
                  syncId: Utils.getUniueId(),
                  syncStatus: SyncStatus.SYNCED,
                  lastModified: Utils.getTimeStamp(),
                  modifiedBy: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                  farmId: Utils.isMultiUSer ? Utils.currentUser!.farmId : '');
              DatabaseHelper.insertEggJunction(eggTransaction);
            }
          }

            SessionManager.setLastSyncTime(FireBaseUtils.EGGS, lastSyncTime!);

          }
          RefreshEventBus().emit(FireBaseUtils.EGGS);
          completeSync();
        }
      });

      _subscriptions.add(sub1);

      print("EGGS SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ EggRecord sync error: $e");
    }
  }

  /// 🍽️ Feeding listener
  Future<void> startFeedingListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FEEDING);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEEDING) // Replace with your collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final feeding = Feeding.fromJson(data);

          print("🔄 FEEDING SYNC: ${feeding.feed_name}, ${feeding.quantity}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (feeding.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = feeding.last_modified;
          }
         /* if(feeding.modified_by == Utils.currentUser!.email)
            return;

          if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FEEDING, feeding.sync_id!, feeding.last_modified!))
            return;*/

          // Check if already exists in local DB by sync_id
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Feeding', feeding.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(feeding.f_sync_id!);


          if (exists) {
            if(feeding.sync_status == SyncStatus.UPDATED) {
              Feeding? old = await DatabaseHelper.getFeedingBySyncId(feeding.sync_id!);
              if (old != null) {
                feeding.id = old.id;
                feeding.f_id = flock!.f_id;
                await DatabaseHelper.updateFeeding(feeding);
              }
            }else if (feeding.sync_status == SyncStatus.DELETED){
              Feeding? old = await DatabaseHelper.getFeedingBySyncId(feeding.sync_id!);
              await DatabaseHelper.deleteItem("Feeding", old!.id!);
            }
            SessionManager.setLastSyncTime(FireBaseUtils.FEEDING, lastSyncTime!);
          } else {
            if(feeding.sync_status != SyncStatus.DELETED) {
              feeding.f_id = flock!.f_id;
              await DatabaseHelper.insertNewFeeding(feeding);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEEDING, lastSyncTime!);

          }
          RefreshEventBus().emit(FireBaseUtils.FEEDING);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("FEEDING SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ Feeding sync error: $e");
    }
  }

  /// 💉 Vaccination/Medication listener
  Future<void> startHealthListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.HEALTH);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.HEALTH) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("HEALTH $data");
          startSync();
          final vaccination = Vaccination_Medication.fromJson(data);

          print("🔄 HEALTH SYNC: ${vaccination.medicine}, ${vaccination.bird_count}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (vaccination.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = vaccination.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Vaccination_Medication', vaccination.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(vaccination.f_sync_id!);
          Vaccination_Medication? old = await DatabaseHelper.getVaccinationBySyncId(vaccination.sync_id!);

          if (exists) {
            if (vaccination.sync_status == SyncStatus.UPDATED) {
              if (old != null) {
                vaccination.id = old.id;
                vaccination.f_id = old.f_id;
                await DatabaseHelper.updateHealth(vaccination);
              }
            } else if (vaccination.sync_status == SyncStatus.DELETED) {
              print("DELETING HEALTH");
              await DatabaseHelper.deleteItem("Vaccination_Medication", old!.id!);
              print("DELETED HEALTH");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.HEALTH, lastSyncTime!);

          } else {
            if(vaccination.sync_status != SyncStatus.DELETED) {
              vaccination.f_id = flock!.f_id;
              await DatabaseHelper.insertMedVac(vaccination);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.HEALTH, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.HEALTH);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("HEALTH SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ Vaccination sync error: $e");
    }
  }

  /// 💉 Vaccination/Medication listener
  Future<void> startMultiHealthListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.MULTI_HEALTH);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.MULTI_HEALTH) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("MULTI_HEALTH $data");
          startSync();
          final multiHealthRecord = MultiHealthRecord.fromJson(data);

          print("🔄 MULTI_HEALTH SYNC: ${multiHealthRecord.record!.medicine}, ${multiHealthRecord.record!.bird_count}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (multiHealthRecord.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = multiHealthRecord.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Vaccination_Medication', multiHealthRecord.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(multiHealthRecord.record!.f_sync_id!);
          Vaccination_Medication? old = await DatabaseHelper.getVaccinationBySyncId(multiHealthRecord.record!.sync_id!);

          if (exists) {
            if (multiHealthRecord.sync_status == SyncStatus.UPDATED) {
              if (old != null) {
                multiHealthRecord.record!.id = old.id;
                multiHealthRecord.record!.f_id = old.f_id;
                await DatabaseHelper.updateHealth(multiHealthRecord.record!);
                await DatabaseHelper.deleteMedicineUsageItemsByUsageId(old.id!);

                for(int i=0;i<multiHealthRecord.usageItems!.length;i++) {

                  MedicineUsageItem item = multiHealthRecord.usageItems!.elementAt(i);
                  MedicineUsageItem object = MedicineUsageItem(usageId: old.id!, medicineName: item.medicineName, diseaseName: item.diseaseName, unit: item.unit, quantity: item.quantity, sync_id: item.sync_id, sync_status: SyncStatus.SYNCED);
                  await DatabaseHelper.insertMedicineUsageItem(object);
                }
              }
            } else if (multiHealthRecord.sync_status == SyncStatus.DELETED) {
              print("DELETING HEALTH");
              await DatabaseHelper.deleteItem("Vaccination_Medication", old!.id!);
              print("DELETED HEALTH");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.MULTI_HEALTH, lastSyncTime!);

          } else {
            if(multiHealthRecord.sync_status != SyncStatus.DELETED) {
              multiHealthRecord.record!.f_id = flock!.f_id;
             int? id = await DatabaseHelper.insertMedVac(multiHealthRecord.record!);

              for(int i=0;i<multiHealthRecord.usageItems!.length;i++) {

                MedicineUsageItem item = multiHealthRecord.usageItems!.elementAt(i);
                MedicineUsageItem object = MedicineUsageItem(usageId: id!, medicineName: item.medicineName, diseaseName: item.diseaseName, unit: item.unit, quantity: item.quantity, sync_id: item.sync_id, sync_status: SyncStatus.SYNCED);
                await DatabaseHelper.insertMedicineUsageItem(object);
              }

            }

            SessionManager.setLastSyncTime(FireBaseUtils.MULTI_HEALTH, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.HEALTH);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("HEALTH SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ Vaccination sync error: $e");
    }
  }

  //
  Future<void> startGenStockListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.GENERAL_STOCK);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.GENERAL_STOCK) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("GENERAL_STOCK $data");
          startSync();
          final genStockRecord = GeneralStockItem.fromJson(data);

          print("🔄 GENERAL_STOCK SYNC: ${genStockRecord.sync_id}, ${genStockRecord.name}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (genStockRecord.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = genStockRecord.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'GeneralStockItems', genStockRecord.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(null);
          GeneralStockItem? old = await DatabaseHelper.getGenStockBySyncId(genStockRecord.sync_id!);

          if (exists) {
            if (genStockRecord.sync_status == SyncStatus.DELETED) {
              print("DELETING GENERAL_STOCK");
              await DatabaseHelper.deleteGeneralStockItem(old!.id!);
              await DatabaseHelper.deleteStockTransactionByItemID(old.id!);
              print("DELETED GENERAL_STOCK");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.GENERAL_STOCK, lastSyncTime!);

          } else {
            if(genStockRecord.sync_status != SyncStatus.DELETED) {
              int? id = await DatabaseHelper.insertGeneralStockItem(genStockRecord);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.GENERAL_STOCK, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.GENERAL_STOCK);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("GENERAL_STOCK SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ General Stock sync error: $e");
    }
  }

  Future<void> startGenStockTransListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.GENERAL_STOCK_TRANS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.GENERAL_STOCK_TRANS) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("GENERAL_STOCK_TRANS stock ID ${data['stock_sync_id']}");
          startSync();
          final genStockRecord = GeneralStockTransactionFB.fromJson(data);

          print("🔄 GENERAL_STOCK_TRANS SYNC: ${genStockRecord.sync_status}, ${genStockRecord.stockTransaction.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (genStockRecord.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = genStockRecord.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'GeneralStockTransactions', genStockRecord.stockTransaction.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(null);
          GeneralStockTransaction? old = await DatabaseHelper.getGenStockTransBySyncId(genStockRecord.stockTransaction.sync_id!);

          if (exists) {
            print("EXISTS");
            if (genStockRecord.sync_status == SyncStatus.DELETED) {
              print("DELETING GENERAL_STOCK_TRANS");
              if(old!.trId != null) {
                await DatabaseHelper.deleteItem("Transactions", old.trId!);
              }
              await DatabaseHelper.deleteStockTransaction(old.id!);
              print("DELETED GENERAL_STOCK_TRANS");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.GENERAL_STOCK_TRANS, lastSyncTime!);

          } else {
            print("NOT EXISTS ELSE CASE");
            if(genStockRecord.sync_status != SyncStatus.DELETED) {
              int? trId = null;
              if(genStockRecord.transactionItem != null){
                print("Transaction Added");
                trId = await DatabaseHelper.insertNewTransaction(genStockRecord.transactionItem!);
              }
              GeneralStockItem? generalStockItem = await DatabaseHelper.getGenStockBySyncId(genStockRecord.stock_sync_id);
              print(generalStockItem!.toJson());
              genStockRecord.stockTransaction.trId = trId;
              genStockRecord.stockTransaction.itemId = generalStockItem.id!;
              print(genStockRecord.stockTransaction.toJson());
              int? id = await DatabaseHelper.insertStockTransaction(genStockRecord.stockTransaction);

            }

            SessionManager.setLastSyncTime(FireBaseUtils.GENERAL_STOCK_TRANS, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.GENERAL_STOCK_TRANS);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("GENERAL_STOCK SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ General Stock sync error: $e");
    }
  }


  Future<void> startToolAssetStockListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.ASSET_TOOL_STOCK);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.ASSET_TOOL_STOCK) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("ASSET_TOOL_STOCK $data");
          startSync();
          final toolAssetMaster = ToolAssetMaster.fromMap(data);

          print("🔄 ASSET_TOOL_STOCK SYNC: ${toolAssetMaster.sync_id}, ${toolAssetMaster.name}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (toolAssetMaster.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = toolAssetMaster.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'ToolAssetMaster', toolAssetMaster.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(null);
          ToolAssetMaster? old = await DatabaseHelper.getToolAssetStockBySyncId(toolAssetMaster.sync_id!);

          if (exists) {
            if (toolAssetMaster.sync_status == SyncStatus.DELETED) {
              print("DELETING ASSET_TOOL_STOCK");
              await DatabaseHelper.deleteToolAssetMaster(old!.id!);
              print("DELETED ASSET_TOOL_STOCK");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.ASSET_TOOL_STOCK, lastSyncTime!);

          } else {
            if(toolAssetMaster.sync_status != SyncStatus.DELETED) {
              int? id = await DatabaseHelper.insertToolAssetMaster(toolAssetMaster);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.ASSET_TOOL_STOCK, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.ASSET_TOOL_STOCK);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("GENERAL_STOCK SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ General Stock sync error: $e");
    }
  }

  Future<void> startAssetUnitListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.ASSET_UNIT_STOCK);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.ASSET_UNIT_STOCK) // Replace with your actual collection constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          print("ASSET_UNIT_STOCK stock ID ${data['stock_sync_id']}");
          startSync();
          final assetUnitFBModel = AssetUnitFBModel.fromJson(data);

          print("🔄 ASSET_UNIT_STOCK SYNC: ${assetUnitFBModel.sync_status}, ${assetUnitFBModel.toLocalJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (assetUnitFBModel.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = assetUnitFBModel.last_modified;
          }

          /*if(vaccination.modified_by == Utils.currentUser!.email)
            return;
*/
          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.HEALTH, vaccination.sync_id!, vaccination.last_modified!))
            return;*/

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'ToolAssetUnit', assetUnitFBModel.unit.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(null);
          ToolAssetUnit? old = await DatabaseHelper.getToolAssetUnitBySyncId(assetUnitFBModel.unit.sync_id!);

          if (exists) {
            print("EXISTS");
            if (assetUnitFBModel.sync_status == SyncStatus.DELETED) {
              print("DELETING ASSET_UNIT_STOCK");
              if(old!.trId != null) {
                await DatabaseHelper.deleteItem("Transactions", old.trId!);
              }
              await DatabaseHelper.deleteToolAssetUnit(old.id!);
              print("DELETED ASSET_UNIT_STOCK");
            } else if(assetUnitFBModel.sync_status == SyncStatus.UPDATED){
              print("UPDATING...");
              ToolAssetMaster? toolAssetMaster = await DatabaseHelper.getToolAssetStockBySyncId(assetUnitFBModel.unit.master_sync_id!);
              TransactionItem? transactionItem = await DatabaseHelper.getSingleTransaction(old!.trId!.toString());
              transactionItem!.amount = assetUnitFBModel.transaction!.amount;
              transactionItem.unitPrice = assetUnitFBModel.transaction!.unitPrice;

              await DatabaseHelper.updateTransaction(transactionItem);
              print("Transaction UPdated");

              assetUnitFBModel.unit.masterId = toolAssetMaster!.id!;
              assetUnitFBModel.unit.trId = old.trId!;
              assetUnitFBModel.unit.id = old.id;
              await DatabaseHelper.updateToolAssetUnit(assetUnitFBModel.unit);
              print("ASSET_UNIT_STOCK Updated");

            }

            SessionManager.setLastSyncTime(FireBaseUtils.ASSET_UNIT_STOCK, lastSyncTime!);

          } else {
            print("NOT EXISTS ELSE CASE");
            if(assetUnitFBModel.sync_status != SyncStatus.DELETED) {
              int? trId = null;
              if(assetUnitFBModel.transaction != null){
                print("Transaction Added");
                trId = await DatabaseHelper.insertNewTransaction(assetUnitFBModel.transaction!);
              }
              ToolAssetMaster? toolAssetMaster = await DatabaseHelper.getToolAssetStockBySyncId(assetUnitFBModel.unit.master_sync_id!);
              print(toolAssetMaster!.toMap());
              assetUnitFBModel.unit.masterId = toolAssetMaster.id!;
              assetUnitFBModel.unit.trId = trId;
              print(assetUnitFBModel.unit.toMap());
              int? id = await DatabaseHelper.insertToolAssetUnit(assetUnitFBModel.unit);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.ASSET_UNIT_STOCK, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.ASSET_UNIT_STOCK);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("GENERAL_STOCK SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ General Stock sync error: $e");
    }
  }


  /// 💵 FinanceItem listener (with f_id sync fix)
  Future<void> startFinanceListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FINANCE);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FINANCE) // Replace with actual constant
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }


        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final finance = FinanceItem.fromJson(data);

          print("🔄 FINANCE SYNC: ${finance.transaction.type} ${finance.transaction.amount}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (finance.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = finance.last_modified;
          }

        /*  if(finance.modified_by == Utils.currentUser!.email)
            return;
*/
         /* if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FINANCE, finance.sync_id!, finance.last_modified!))
            return;*/

          final syncId = finance.transaction.sync_id;
          final status = finance.sync_status;

          if (syncId == null) continue;

          // ✅ Resolve f_id using f_sync_id
          if (finance.transaction.f_sync_id != null) {
            Flock? flock = await DatabaseHelper.getFlockBySyncId(finance.transaction.f_sync_id);
            if (flock != null) {
              finance.transaction.f_id = flock.f_id;
            }
          }

          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID("Transactions", syncId);
          TransactionItem? oldTxn = await DatabaseHelper.getTransactionBySyncId(syncId);

          if (exists) {
            if (status == SyncStatus.UPDATED) {
              if (oldTxn != null) {
                finance.transaction.id = oldTxn.id;
                finance.transaction.f_id = oldTxn.f_id;
                await DatabaseHelper.updateTransaction(finance.transaction);
                String farm_wide_f_detail_id = "";

                // 🐥 Update Flock_Detail list if present
                if (finance.flockDetails != null) {
                  for (var detail in finance.flockDetails!) {
                    // Resolve f_id via f_sync_id
                    if (detail.f_sync_id != null) {
                      Flock? flock = await DatabaseHelper.getFlockBySyncId(detail.f_sync_id!);
                      if (flock != null) {
                        detail.f_id = flock.f_id;
                      }
                    }

                    detail.transaction_id = oldTxn.id.toString();

                    Flock_Detail? existingDetail =
                    await DatabaseHelper.getSingleFlockDetailsBySyncID(detail.sync_id!);


                    if (existingDetail != null) {
                      detail.f_detail_id = existingDetail.f_detail_id;
                      await DatabaseHelper.updateFlock(detail);

                      if (farm_wide_f_detail_id == "")
                        farm_wide_f_detail_id = detail.f_detail_id.toString();
                      else
                        farm_wide_f_detail_id =
                            farm_wide_f_detail_id + "," + detail.f_detail_id.toString();
                    } else {
                      int? f_detail_id = -1;
                      f_detail_id =  await DatabaseHelper.insertFlockDetail(detail);
                      if (farm_wide_f_detail_id == "")
                        farm_wide_f_detail_id = f_detail_id.toString();
                      else
                        farm_wide_f_detail_id =
                            farm_wide_f_detail_id + "," + f_detail_id.toString();
                    }
                  }

                  if (farm_wide_f_detail_id != "") {
                    await DatabaseHelper.updateLinkedTransaction(oldTxn.id.toString(), farm_wide_f_detail_id.toString());
                  }
                }
              }
            } else if (status == SyncStatus.DELETED) {
              await DatabaseHelper.deleteItem("Transactions", oldTxn!.id!);
              if (finance.flockDetails != null) {
                for (var detail in finance.flockDetails!) {
                  if (detail.sync_id != null) {
                    Flock_Detail? existingDetail =
                    await DatabaseHelper.getSingleFlockDetailsBySyncID(detail.sync_id!);

                    await DatabaseHelper.deleteFlockDetailsRecord(existingDetail!.f_detail_id!);
                  }
                }
              }
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FINANCE, lastSyncTime!);
          } else {
            if (status != SyncStatus.DELETED) {
              Flock? flock = await DatabaseHelper.getFlockBySyncId(
                  finance.transaction.f_sync_id);

              // ➕ New transaction
              finance.transaction.f_id = flock!.f_id;
              int? txnId = await DatabaseHelper.insertNewTransaction(
                  finance.transaction);

              String farm_wide_f_detail_id = "";
              // 🐥 Insert new flock details if any
              if (finance.flockDetails != null) {
                for (var detail in finance.flockDetails!) {
                  // Resolve f_id via f_sync_id
                  if (detail.f_sync_id != null) {
                    Flock? flock = await DatabaseHelper.getFlockBySyncId(
                        detail.f_sync_id!);
                    if (flock != null) {
                      detail.f_id = flock.f_id;
                    }
                  }

                  detail.transaction_id = txnId.toString();
                  int? f_detail_id = await DatabaseHelper.insertFlockDetail(
                      detail);

                  if (farm_wide_f_detail_id == "")
                    farm_wide_f_detail_id = f_detail_id.toString();
                  else
                    farm_wide_f_detail_id =
                        farm_wide_f_detail_id + "," + f_detail_id.toString();

                  print("ID $farm_wide_f_detail_id");
                }

                if (farm_wide_f_detail_id != "") {
                  await DatabaseHelper.updateLinkedTransaction(
                      txnId.toString(), farm_wide_f_detail_id.toString());
                }
              }
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FINANCE, lastSyncTime!);

          }
          RefreshEventBus().emit(FireBaseUtils.FINANCE);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("FINANCE SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ Finance sync error: $e");
    }
  }

  Future<void> startCustomCategoryListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.CUSTOM_CATEGORY)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final category = CustomCategory.fromJson(data);

          print("🔄 CATEGORY SYNC: ${category.name}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (category.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = category.last_modified;
          }

          /*if(category.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.CUSTOM_CATEGORY, category.sync_id!, category.last_modified!))
            return;*/

          final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'CustomCategory', category.sync_id!,
          );

          if (exists) {
            if (category.sync_status == SyncStatus.UPDATED) {
              final old = await DatabaseHelper.getCustomCategoryBySyncId(category.sync_id!);
              if (old != null) {
                category.id = old.id;
                await DatabaseHelper.updateCategory(category);
              }
            } else if (category.sync_status == SyncStatus.DELETED) {
             // await DatabaseHelper.deleteItem("CustomCategory", category.id!);
              await DatabaseHelper.deleteCategoryData(category.id!);
              await DatabaseHelper.deleteCategory(category.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY, lastSyncTime!);
          } else {
            if(category.sync_status != SyncStatus.DELETED) {
              await DatabaseHelper.insertCustomCategory(category);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.CUSTOM_CATEGORY);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("CUSTOM CATEGORY SYNC STARTED");
    } catch (e) {
      print("❌ CustomCategory sync error: $e");
    }
  }

  Future<void> startCustomCategoryDataListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY_DATA);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.CUSTOM_CATEGORY_DATA)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final customData = CustomCategoryData.fromJson(data);

          print("🔄 CUSTOM DATA SYNC: ${customData.cName}, Qty: ${customData.quantity}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (customData.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = customData.last_modified;
          }

          /*if(customData.modified_by == Utils.currentUser!.email)
            return;*/

         /* if(!deduplicator.shouldProcessUpdate(FireBaseUtils.CUSTOM_CATEGORY_DATA, customData.sync_id!, customData.last_modified!))
            return;*/

          final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'CustomCategoryData', customData.sync_id!,
          );

          final flock = await DatabaseHelper.getFlockBySyncId(customData.f_sync_id!);

          if (exists) {
            if (customData.sync_status == SyncStatus.UPDATED) {
              final old = await DatabaseHelper.getCustomCategoryDataBySyncId(customData.sync_id!);
              if (old != null) {
                customData.id = old.id;
                customData.fId = flock?.f_id ?? old.fId;
                await DatabaseHelper.updateCustomCategoryData(customData);
              }
            } else if (customData.sync_status == SyncStatus.DELETED) {
              await DatabaseHelper.deleteItem("CustomCategoryData", customData.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY_DATA, lastSyncTime!);

          } else {
            if(customData.sync_status != SyncStatus.DELETED) {
              customData.fId = flock?.f_id ?? -1;
              await DatabaseHelper.insertCategoryData(customData);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.CUSTOM_CATEGORY_DATA, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.CUSTOM_CATEGORY_DATA);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("CUSTOM CATEGORY DATA SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ CustomCategoryData sync error: $e");
    }
  }

  /// 📦 Feed Stock FB Listener
  Future<void> startFeedStockFBListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FEED_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_STOCK_HISTORY) // replace with your actual collection name
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final item = FeedStockFB.fromJson(data);

          final FeedStockHistory stock = item.stock;
          final TransactionItem? txn = item.transaction;

          print("🔄 FEED STOCK SYNC: ${stock.feed_name} (${stock.quantity} ${stock.unit})");
          Utils.backup_changes += snapshot.docChanges.length;
          if (item.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = item.last_modified;
          }

          /*if(item.stock.modified_by == Utils.currentUser!.email)
            return;*/

         /* if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FEED_STOCK_HISTORY, item.stock.sync_id!, item.stock.last_modified!))
            return;*/

          // Check if stock already exists by sync_id
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'FeedStockHistory', stock.sync_id!,
          );

          if (exists) {
            final existing = await DatabaseHelper.getFeedStockHistotyBySyncID(stock.sync_id!);

            print("STOCK ${existing!.toLocalFBJson()}");
            if (item.sync_status == SyncStatus.UPDATED) {
              if (existing != null) {
                stock.id = existing.id;
                await DatabaseHelper.updateFeedStock(stock);
              }
            } else if (item.sync_status == SyncStatus.DELETED) {
             // await DatabaseHelper.deleteItem('FeedStockHistory', existing!.id!);
              StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing.id!);
              if(stockExpense != null){
               // TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(stockExpense.transactionId.toString());

                await DatabaseHelper.deleteByStockItemId(existing!.id!);
                await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);
              }

              DatabaseHelper.deleteFeedStock(existing.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_STOCK_HISTORY, lastSyncTime!);

          } else {
            if(item.sync_status != SyncStatus.DELETED) {
              stock.id = await DatabaseHelper.insertFeedStock(stock);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_STOCK_HISTORY, lastSyncTime!);

          }


          // 🔄 Handle optional transaction
          if (txn != null) {
            bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
              'Transactions', txn.sync_id!);

            if (txnExists) {
              final existingTxn = await DatabaseHelper.getTransactionBySyncId(txn.sync_id!);

              if (item.sync_status == SyncStatus.UPDATED || item.sync_status == SyncStatus.SYNCED) {
                if (existingTxn != null) {
                  txn.id = existingTxn.id;
                  await DatabaseHelper.updateTransaction(txn);
                }
              } else if (item.sync_status == SyncStatus.DELETED) {
                // Handled ABOVE IN FEED STOCK DELETE
                /*await DatabaseHelper.deleteItem('Transactions', existingTxn!.id!);
                final existing = await DatabaseHelper.getFeedStockHistotyBySyncID(stock.sync_id!);
                StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing!.id!);
                if(stockExpense != null){
                  await DatabaseHelper.deleteByStockItemId(existing.id!);
                  await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);
                }*/
              }
            } else {
              if(item.sync_status != SyncStatus.DELETED) {
                txn.id = await DatabaseHelper.insertNewTransaction(txn);
                final existing = await DatabaseHelper.getFeedStockHistotyBySyncID(stock.sync_id!);

                StockExpense stockExpense = StockExpense(
                    stockItemId: existing!.id!, transactionId: txn.id!);
                await DatabaseHelper.insertStockJunction(stockExpense);
              }
            }

          }

          RefreshEventBus().emit(FireBaseUtils.FEED_STOCK_HISTORY);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("FEED STOCK SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ FeedStockFB sync error: $e");
    }
  }

  /// 💊 Medicine Stock FB Listener
  Future<void> startMedicineStockFBListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.MEDICINE_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.MEDICINE_STOCK_HISTORY) // replace with your actual collection name
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final item = MedicineStockFB.fromJson(data);

          final MedicineStockHistory stock = item.stock;
          final TransactionItem? txn = item.transaction;

          print("🔄 MEDICINE STOCK SYNC: ${stock.medicineName} (${stock.quantity} ${stock.unit})");
          print("MEDICINE ${stock.toLocalFBJson()}");
          print("STOCK ${item.stock.toLocalFBJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (item.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = item.last_modified;
          }

          /*if(stock.modified_by == Utils.currentUser!.email)
            return;*/

        /*  if(!deduplicator.shouldProcessUpdate(FireBaseUtils.MEDICINE_STOCK_HISTORY, item.stock.sync_id!, item.stock.last_modified!))
            return;*/

          // ✅ Check for stock existence by sync_id
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'MedicineStockHistory', stock.sync_id!,
          );

          if (exists) {
            final existing = await DatabaseHelper.getMedicineStockHistotyBySyncID(stock.sync_id!);
            print("EXISTS ${existing!.toLocalFBJson()}");
            if (stock.sync_status == SyncStatus.UPDATED) {
              /*final existing = await DatabaseHelper.getMedicineStockHistotyBySyncID(stock.sync_id!);
              if (existing != null) {
                stock.id = existing.id;
                await DatabaseHelper.updatem(stock);
              }*/
            } else if (stock.sync_status == SyncStatus.DELETED) {
              StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing.id!);
              if (stockExpense != null) {
               // TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(stockExpense.transactionId.toString());

                await DatabaseHelper.deleteByStockItemId(existing.id!);
                await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);
              }
              await DatabaseHelper.deleteMedicineStockHistoryById(existing.id!);
             // await DatabaseHelper.deleteItem('MedicineStockHistory', existing!.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.MEDICINE_STOCK_HISTORY, lastSyncTime!);

          } else {
            if(stock.sync_status != SyncStatus.DELETED) {
              stock.id = await DatabaseHelper.insertMedicineStock(stock);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.MEDICINE_STOCK_HISTORY, lastSyncTime!);
          }

          // 🔄 Handle optional transaction
          if (txn != null) {
            bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
                'Transactions', txn.sync_id!);

            if (txnExists) {
              final existingTxn = await DatabaseHelper.getTransactionBySyncId(txn.sync_id!);

              if (stock.sync_status == SyncStatus.UPDATED) {
                if (existingTxn != null) {
                  txn.id = existingTxn.id;
                  await DatabaseHelper.updateTransaction(txn);
                }
              } else if (stock.sync_status == SyncStatus.DELETED) {
                // DELETED IN ABOVE CODE
               /* await DatabaseHelper.deleteItem('Transactions', existingTxn!.id!);
                final existing = await DatabaseHelper.getMedicineStockHistotyBySyncID(stock.sync_id!);

                StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing!.id!);
                if (stockExpense != null) {
                  await DatabaseHelper.deleteByStockItemId(existing.id!);
                  await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);
                }*/
              }
            } else {
              if(stock.sync_status != SyncStatus.DELETED) {
                txn.id = await DatabaseHelper.insertNewTransaction(txn);

                StockExpense stockExpense = StockExpense(
                  stockItemId: stock.id!,
                  transactionId: txn.id!,
                );
                await DatabaseHelper.insertStockJunction(stockExpense);
              }
            }
          }

          RefreshEventBus().emit(FireBaseUtils.MEDICINE_STOCK_HISTORY);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("MEDICINE SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ MedicineStockFB sync error: $e");
    }
  }

  /// 💉 Vaccine Stock FB Listener
  Future<void> startVaccineStockFBListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.VACCINE_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.VACCINE_STOCK_HISTORY) // Replace with actual collection name
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }
        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final item = VaccineStockFB.fromJson(data);

          final VaccineStockHistory stock = item.stock;
          final TransactionItem? txn = item.transaction;

          print("🔄 VACCINE STOCK SYNC: ${stock.vaccineName} (${stock.quantity} ${stock.unit})");

          Utils.backup_changes += snapshot.docChanges.length;
          if (item.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = item.last_modified;
          }
          /*if(stock.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.VACCINE_STOCK_HISTORY, item.stock.sync_id!, item.stock.last_modified!))
            return;*/

          // ✅ Check if stock already exists by sync_id
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'VaccineStockHistory', stock.sync_id!,
          );

          if (exists) {
            final existing = await DatabaseHelper.getVaccineStockHistotyBySyncID(stock.sync_id!);
            if (stock.sync_status == SyncStatus.UPDATED) {
              /*
              if (existing != null) {
                stock.id = existing.id;
                await DatabaseHelper.updateVaccineStock(stock);
              }*/
            } else if (stock.sync_status == SyncStatus.DELETED) {
             // await DatabaseHelper.deleteItem('VaccineStockHistory', existing!.id!);
              StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing!.id!);
              if(stockExpense != null)
              {
                //TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(stockExpense.transactionId.toString());

                await DatabaseHelper.deleteByStockItemId(existing.id!);
                await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);

              }

              await DatabaseHelper.deleteVaccineStockHistoryById(existing!.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.VACCINE_STOCK_HISTORY, lastSyncTime!);

          } else {
            if(stock.sync_status != SyncStatus.DELETED) {
              stock.id = await DatabaseHelper.insertVaccineStock(stock);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.VACCINE_STOCK_HISTORY, lastSyncTime!);

          }

          // 🔄 Handle optional transaction
          if (txn != null) {
            bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
              'Transactions', txn.sync_id!,
            );

            if (txnExists) {
              if (txn.sync_status == SyncStatus.UPDATED || txn.sync_status == SyncStatus.SYNCED) {
                final existingTxn = await DatabaseHelper.getTransactionBySyncId(txn.sync_id!);
                if (existingTxn != null) {
                  txn.id = existingTxn.id;
                  await DatabaseHelper.updateTransaction(txn);
                }
              } else if (txn.sync_status == SyncStatus.DELETED) {
                final existingTxn = await DatabaseHelper.getTransactionBySyncId(txn.sync_id!);
                await DatabaseHelper.deleteItem('Transactions', existingTxn!.id!);
                final existing = await DatabaseHelper.getVaccineStockHistotyBySyncID(stock.sync_id!);

                StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(existing!.id!);
                if (stockExpense != null) {
                  await DatabaseHelper.deleteByStockItemId(existing.id!);
                  await DatabaseHelper.deleteItem("Transactions", existingTxn.id!);
                }
              }
            } else {
              if(stock.sync_status != SyncStatus.DELETED) {
                txn.id = await DatabaseHelper.insertNewTransaction(txn);

                StockExpense stockExpense = StockExpense(
                  stockItemId: stock.id!,
                  transactionId: txn.id!,
                );
                await DatabaseHelper.insertStockJunction(stockExpense);
              }
            }
          }

          RefreshEventBus().emit(FireBaseUtils.VACCINE_STOCK_HISTORY);
          completeSync();
        }
      });

      _subscriptions.add(sub);

      print("VACCINE SYNC STARTED");
    } catch (e) {
      completeSync();
      print("❌ VaccineStockFB sync error: $e");
    }
  }

  /// 🌽 Feed Ingredient Sync Listener
  Future<void> startFeedIngredientListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FEED_INGRIDIENT);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_INGRIDIENT)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final FeedIngredient ingredient = FeedIngredient.fromJson(data);

          print("🔄 FEED INGREDIENT SYNC: ${ingredient.name} (${ingredient.pricePerKg}/${ingredient.unit})");
          Utils.backup_changes += snapshot.docChanges.length;
          if (ingredient.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = ingredient.last_modified;
          }

         /* if(ingredient.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FEED_INGRIDIENT, ingredient.sync_id!, ingredient.last_modified!))
            return;*/

          // Check if already exists by sync_id
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'FeedIngredient', ingredient.sync_id!);

          if (exists) {
            if (ingredient.sync_status == SyncStatus.UPDATED) {
              final old = await DatabaseHelper.getFeedIngredientBySyncId(ingredient.sync_id!);
              if (old != null) {
                ingredient.id = old.id;

                await DatabaseHelper.updateIngredient(ingredient.id!, ingredient.name, ingredient.pricePerKg, ingredient.unit);
              }
            } else if (ingredient.sync_status == SyncStatus.DELETED) {
              FeedIngredient? feedIngredient = await DatabaseHelper.getFeedIngredientBySyncId(ingredient.sync_id!);
              await DatabaseHelper.deleteItem("FeedIngredient", feedIngredient!.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_INGRIDIENT, lastSyncTime!);

          } else if (ingredient.sync_status != SyncStatus.DELETED) {
            await DatabaseHelper.insertIngredientWithSyncID(ingredient.name, ingredient.pricePerKg, ingredient.sync_id!);

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_INGRIDIENT, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.FEED_INGRIDIENT);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("FeedIngredient SYNC STARTED");// Add to your listener tracking list
    } catch (e) {
      completeSync();
      print("❌ FeedIngredient sync error: $e");
    }
  }

  /// 📦 Feed Batch FB Listener
  Future<void> startFeedBatchFBListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FEED_BATCH);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_BATCH) // Your Firestore collection name
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;

          startSync();
          final item = FeedBatchFB.fromJson(data);


          final FeedBatch batch = item.feedbatch;
          final List<IngredientFB>? ingredients = item.ingredientList;
          final TransactionItem? txn = item.transaction;

          print("🔄 FEED BATCH SYNC: ${batch.name} (${batch.totalWeight}kg) ${item.transaction!.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (item.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = item.last_modified;
          }

        /*  if(item.feedbatch.modified_by == Utils.currentUser!.email)
            return;*/

         /* if(!deduplicator.shouldProcessUpdate(FireBaseUtils.FEED_BATCH, batch.sync_id!, item.last_modified!))
            return;*/

          // 🧾 Check for existing FeedBatch
          bool exists = await DatabaseHelper.checkIfRecordExistsSyncID("FeedBatch", batch.sync_id!);

          if (exists) {
            if (item.sync_status == SyncStatus.UPDATED) {
              final existing = await DatabaseHelper.getFeedBatchBySyncId(batch.sync_id!);
              final exTrans = await DatabaseHelper.getTransactionBySyncId(txn!.sync_id!);
              if (existing != null) {
                batch.id = existing.id;
                txn.id = exTrans!.id;
                batch.transaction_id = exTrans.id!;
                await DatabaseHelper.updateBatch(batch);
                await DatabaseHelper.deleteItemsByBatchId(existing.id!);
                await DatabaseHelper.updateTransaction(txn);
                // Clear old
                if (ingredients != null) {
                  for (final ing in ingredients) {
                    print("ING SYNC_ID ${ing.sync_id} ${ing.qty}");
                    FeedIngredient? feedIngredient = await DatabaseHelper.getFeedIngredientBySyncId(ing.sync_id);

                    if(feedIngredient != null) {
                      print("ING ${feedIngredient.id.toString()} ");
                      await DatabaseHelper.insertBatchItem(FeedBatchItem(
                        batchId: batch.id!,
                        // Use the batchId from the insert or update
                        ingredientId: feedIngredient.id!,
                        quantity: ing.qty,
                      ));
                    }else{

                      int? ingID = await DatabaseHelper.insertIngredientWithSyncID(ing.ingredient!.name, ing.ingredient!.pricePerKg, ing.ingredient!.sync_id!);
                      await DatabaseHelper.insertBatchItem(FeedBatchItem(
                        batchId: batch.id!,
                        // Use the batchId from the insert or update
                        ingredientId: ingID!,
                        quantity: ing.qty,
                      ));
                    }
                  }
                }
              }
            } else if (item.sync_status == SyncStatus.DELETED) {

              final existing = await DatabaseHelper.getFeedBatchBySyncId(batch.sync_id!);

              if(existing != null)
                print("DELETING ${existing.toMap()}");
              else
                print("DELETING NULL");

              await DatabaseHelper.deleteItem("FeedBatch", existing!.id!);
              await DatabaseHelper.deleteItemsByBatchId(existing.id!);
              await DatabaseHelper.deleteItem("Transactions", existing.transaction_id);

              print("FEED BATCH DELETED");
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_BATCH, lastSyncTime!);

          }
          else {
            if (item.sync_status != SyncStatus.DELETED)
            {
              int? txnID = await DatabaseHelper.insertNewTransaction(txn!);
              batch.transaction_id = txnID!;
              int? newId = await DatabaseHelper.insertBatch(batch);
              batch.id = newId;

              if (ingredients != null) {
                for (final ing in ingredients) {
                  print("ING SYNC_ID ${ing.sync_id} ${ing.qty}");

                  FeedIngredient? feedIngredient = await DatabaseHelper
                      .getFeedIngredientBySyncId(ing.sync_id);
                  if (feedIngredient != null) {
                    print("ING ${feedIngredient.id.toString()} ");
                    await DatabaseHelper.insertBatchItem(FeedBatchItem(
                      batchId: batch.id!,
                      // Use the batchId from the insert or update
                      ingredientId: feedIngredient.id!,
                      quantity: ing.qty,
                    ));
                  } else {
                    int? ingID = await DatabaseHelper
                        .insertIngredientWithSyncID(
                        ing.ingredient!.name, ing.ingredient!.pricePerKg,
                        ing.ingredient!.sync_id!);
                    await DatabaseHelper.insertBatchItem(FeedBatchItem(
                      batchId: batch.id!,
                      // Use the batchId from the insert or update
                      ingredientId: ingID!,
                      quantity: ing.qty,
                    ));
                  }
                }
              }
            }

            SessionManager.setLastSyncTime(FireBaseUtils.FEED_BATCH, lastSyncTime!);

          }
          RefreshEventBus().emit(FireBaseUtils.FEED_BATCH);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("FEEDBATCH SYNC STARTED");// Add to your listener tracking list

    } catch (e) {
      completeSync();
      print("❌ FeedBatchFB sync error: $e");
    }
  }


  Future<void> startSubCategoryListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.SUB_CATEGORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.SUB_CATEGORY)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }

        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final category = SubItem.fromJson(data);

          print("🔄 CATEGORY SYNC: ${category.name} ${category.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (category.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = category.last_modified;
          }

          /*if(category.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.CUSTOM_CATEGORY, category.sync_id!, category.last_modified!))
            return;*/

          final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Category_Detail', category.sync_id!,
          );

          if (exists) {
            final old = await DatabaseHelper.getSubCategoryBySyncId(category.sync_id!);

            if (category.syncStatus == SyncStatus.UPDATED) {
              /*if (old != null) {
                category.id = old.id;
                await DatabaseHelper.up(category);
              }*/
            } else if (category.syncStatus == SyncStatus.DELETED) {
              // await DatabaseHelper.deleteItem("CustomCategory", category.id!);
              await DatabaseHelper.deleteSubItem(old!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.SUB_CATEGORY, lastSyncTime!);
          } else {
            if(category.syncStatus != SyncStatus.DELETED) {
              await DatabaseHelper.insertNewSubItem(category);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.SUB_CATEGORY, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.SUB_CATEGORY);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("SUB CATEGORY SYNC STARTED");
    } catch (e) {
      print("❌ SubCategory sync error: $e");
    }
  }


  Future<void> startWeightRecordsListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.WEIGHT_RECORD);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.WEIGHT_RECORD)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }
        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final weightRecord = WeightRecord.fromJson(data);

          print("🔄 WEIGHT_RECORD SYNC: ${weightRecord.averageWeight} ${weightRecord.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (weightRecord.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = weightRecord.last_modified;
          }

          /*if(category.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.CUSTOM_CATEGORY, category.sync_id!, category.last_modified!))
            return;*/

          final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'WeightRecord', weightRecord.sync_id!,
          );

          Flock? flock = await DatabaseHelper.getFlockBySyncId(weightRecord.f_sync_id!);


          if (exists) {
            final old = await DatabaseHelper.getWeightRecordBySyncId(weightRecord.sync_id!);

            if (weightRecord.sync_status == SyncStatus.UPDATED) {
              /*if (old != null) {
                category.id = old.id;
                await DatabaseHelper.up(category);
              }*/
            } else if (weightRecord.sync_status == SyncStatus.DELETED) {
              // await DatabaseHelper.deleteItem("CustomCategory", category.id!);
              await DatabaseHelper.deleteWeightRecord(old!.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.WEIGHT_RECORD, lastSyncTime!);
          } else {
            if(weightRecord.sync_status != SyncStatus.DELETED) {
              weightRecord.f_id = flock!.f_id;
              await DatabaseHelper.insertWeightRecord(weightRecord);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.WEIGHT_RECORD, lastSyncTime!);
          }

          RefreshEventBus().emit(FireBaseUtils.WEIGHT_RECORD);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("WEIGHT_RECORD SYNC STARTED");
    } catch (e) {
      print("❌ WEIGHT_RECORD sync error: $e");
    }
  }


  Future<void> startSaleContractorListening(String farmId, DateTime? lastSyncTime) async {

    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.SALE_CONTRACTOR);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }
    bool firstSnapshotHandled = false; // 👈 flag to only count once

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.SALE_CONTRACTOR)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final sub = query.snapshots().listen((snapshot) async {
        if (!firstSnapshotHandled) {
          SyncManager().listenerCompleted(); // progress +1
          firstSnapshotHandled = true;
        }
        for (var change in snapshot.docChanges) {
          startSync();
          final data = change.doc.data() as Map<String, dynamic>;
          final saleContractor = SaleContractor.fromFBJson(data);

          print("🔄 SALE_CONTRACTOR SYNC: ${saleContractor.name} ${saleContractor.toLocalJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (saleContractor.last_modified!.isAfter(lastSyncTime!)) {
            lastSyncTime = saleContractor.last_modified;
          }

          /*if(category.modified_by == Utils.currentUser!.email)
            return;*/

          /*if(!deduplicator.shouldProcessUpdate(FireBaseUtils.CUSTOM_CATEGORY, category.sync_id!, category.last_modified!))
            return;*/

          final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'SaleContractor', saleContractor.sync_id!,
          );


          if (exists) {
            final old = await DatabaseHelper.getSaleContractorBySyncId(saleContractor.sync_id!);

            if (saleContractor.sync_status == SyncStatus.UPDATED) {
              if (old != null) {
                saleContractor.id = old.id;
                await DatabaseHelper.updateSaleContractor(saleContractor);
              }
            } else if (saleContractor.sync_status == SyncStatus.DELETED) {
              // await DatabaseHelper.deleteItem("CustomCategory", category.id!);
              await DatabaseHelper.deleteSaleContractor(old!.id!);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.SALE_CONTRACTOR, lastSyncTime!);
          } else {
            if(saleContractor.sync_status != SyncStatus.DELETED) {
              await DatabaseHelper.insertSaleContractor(saleContractor);
            }

            SessionManager.setLastSyncTime(FireBaseUtils.SALE_CONTRACTOR, lastSyncTime!);
          }
          RefreshEventBus().emit(FireBaseUtils.SALE_CONTRACTOR);
          completeSync();
        }
      });

      _subscriptions.add(sub);
      print("SALE_CONTRACTOR SYNC STARTED");
    } catch (e) {
      print("❌ SALE_CONTRACTOR sync error: $e");
    }
  }


  /*Future<void> listenToTransactions(Flock flock, String farmId) async {
    final query = FirebaseFirestore.instance
        .collection(FireBaseUtils.TRANSACTIONS)
        .where('farm_id', isEqualTo: farmId)
        .where('f_sync_id', isEqualTo: flock.sync_id);

    final snapshot = await query.get();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print("📦 TRANSACTION fetched: $data");
      // TODO: Save/update locally in SQLite
      TransactionItem? transaction = TransactionItem.fromJson(data);
      transaction.f_id = flock.f_id;

      await DatabaseHelper.insertNewTransaction(transaction);
      print("Transaction SAVED ${transaction.toJson()}");
    }
  }
*/

  int _totalListeners = 0;
  int _completedListeners = 0;

  VoidCallback? _onAllComplete;
  Function(int completed, int total)? _onProgress;

  void init({
    required int totalListeners,
    VoidCallback? onAllComplete,
    Function(int completed, int total)? onProgress,
  }) {
    _totalListeners = totalListeners;
    _completedListeners = 0;
    _onAllComplete = onAllComplete;
    _onProgress = onProgress;
  }

  void listenerCompleted() {
    _completedListeners++;
    _onProgress?.call(_completedListeners, _totalListeners);

    if (_completedListeners >= _totalListeners) {
      _onAllComplete?.call();
    }
  }

  void reset() {
    _totalListeners = 0;
    _completedListeners = 0;
    _onAllComplete = null;
    _onProgress = null;
  }

  void stopAllListening()  {

    if(_started)
      {
        _started = false;
      }

    for (final sub in _subscriptions) {
      sub.cancel();
    }

    _subscriptions.clear();
  }
}
