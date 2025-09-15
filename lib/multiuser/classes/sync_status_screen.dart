import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../database/databse_helper.dart';
import '../../model/egg_income.dart';
import '../../model/egg_item.dart';
import '../../model/feed_batch.dart';
import '../../model/feed_batch_item.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/feed_stock_history.dart';
import '../../model/flock.dart';
import '../../model/flock_detail.dart';
import '../../model/flock_image.dart';
import '../../model/med_vac_item.dart';
import '../../model/medicine_stock_history.dart';
import '../../model/sale_contractor.dart';
import '../../model/stock_expense.dart';
import '../../model/sub_category_item.dart';
import '../../model/transaction_item.dart';
import '../../model/vaccine_stock_history.dart';
import '../../model/weight_record.dart';
import '../../utils/utils.dart';
import '../api/server_apis.dart';
import '../model/birds_modification.dart';
import '../model/egg_record.dart';
import '../model/feedbatchfb.dart';
import '../model/feedstockfb.dart';
import '../model/financeItem.dart';
import '../model/flockfb.dart';
import '../model/ingridientfb.dart';
import '../model/medicinestockfb.dart';
import '../model/vaccinestockfb.dart';
import '../utils/SyncManager.dart';
import '../utils/SyncStatus.dart';

class SyncScreen extends StatefulWidget {
  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final Map<String, String> modules = {
    "Flocks": FireBaseUtils.FLOCKS,
    "Birds": FireBaseUtils.BIRDS,
    "Eggs": FireBaseUtils.EGGS,
    "Feeding": FireBaseUtils.FEEDING,
    "Finance": FireBaseUtils.FINANCE,
    "Health": FireBaseUtils.HEALTH,
    "Feed Stock": FireBaseUtils.FEED_STOCK_HISTORY,
    "Vaccine Stock": FireBaseUtils.VACCINE_STOCK_HISTORY,
    "Medicine Stock": FireBaseUtils.MEDICINE_STOCK_HISTORY,
    "Feed Batches": FireBaseUtils.FEED_BATCH,
    "Feed Ingredients": FireBaseUtils.FEED_INGRIDIENT,
    "Sale Contractors": FireBaseUtils.SALE_CONTRACTOR,
    "Flock Weight": FireBaseUtils.WEIGHT_RECORD,
    "Categories": FireBaseUtils.SUB_CATEGORY,
  };

  Map<String, String?> lastSyncTimes = {};

  @override
  void initState() {
    super.initState();
    getLastSyncTime();
  }


  late DateTime? lastBackupDate;

  Future<void> getLastSyncTime() async {
    final docRef = FirebaseFirestore.instance.collection(
        FireBaseUtils.DB_BACKUP)
        .doc(Utils.currentUser!.farmId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final Timestamp? lastTimestamp = data?['timestamp'];
      print("DB BACKUP " + lastTimestamp.toString());
      if (lastTimestamp != null) {
        lastBackupDate = lastTimestamp.toDate();
        _loadSyncTimes();
      }
    } else {
      _loadSyncTimes();
    }
  }
  Future<void> _loadSyncTimes() async {
    Map<String, String?> temp = {};

    for (var entry in modules.entries) {
      final title = entry.key;
      final key = entry.value;

      final time = await SessionManager.getLastSyncTime(key);

      // 🖨️ Debug logs
      print("Module: $title | Key: $key | Raw time: $time");

      temp[title] = time != null
          ? formatTimeAgo(time)   // your utility
          : lastBackupDate != null
          ? formatTimeAgo(lastBackupDate)
          : "Unknown".tr();

      print("Module: $title | Formatted: ${temp[title]}");
    }

    setState(() {
      lastSyncTimes = temp;
    });
  }


  Future<void> _refreshModule(String moduleName, String key) async {
    _isRefreshing = true;
    setState(() {
      syncingModules.add(moduleName); // start syncing
    });

    print("KEY $key");
    String farmId = Utils.currentUser!.farmId;

    try {
      if (key == FireBaseUtils.FLOCKS) {
        await syncFlocksOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.BIRDS) {
        await getBirdModifications(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.EGGS) {
        await fetchEggRecords(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.FEEDING) {
        await syncFeedingOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.FINANCE) {
        await syncFinanceOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.HEALTH) {
        await syncHealthOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.FEED_STOCK_HISTORY) {
        await syncFeedStockOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.VACCINE_STOCK_HISTORY) {
        await syncVaccineStockOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.MEDICINE_STOCK_HISTORY) {
        await syncMedicineStockOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.FEED_BATCH) {
        await syncFeedBatchOnce(farmId);
      } else if (key == FireBaseUtils.FEED_INGRIDIENT) {
        await syncFeedIngredientOnce(farmId);
      } else if (key == FireBaseUtils.SALE_CONTRACTOR) {
        await syncSaleContractorOnce(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.SUB_CATEGORY) {
        await startSubCategoryListening(farmId, lastBackupDate);
      } else if (key == FireBaseUtils.WEIGHT_RECORD) {
        await startWeightRecordsOneTimeSync(farmId, lastBackupDate);
      }
      // ✅ update this module’s last sync time
      await SessionManager.setLastSyncTime(key, DateTime.now());

      await _loadSyncTimes();
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      _isRefreshing = false;
      syncingModules.remove(moduleName);
      setState(() {
         // finish syncing
      });
    }
  }

  Future<void> _refreshAll() async {
    _isRefreshing = true;
    for (var entry in modules.entries) {

     await _refreshModule(entry.key, entry.value);
       // ⏳ wait 2 sec
      // don’t await here → run in parallel
    }

    _isRefreshing = false;
  }

  bool _isRefreshing = false;

  Set<String> syncingModules = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sync Status".tr(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [

      IconButton(
      icon: Icon(Icons.refresh_rounded, size: 28),
      tooltip: "Refresh All".tr(),
      onPressed: _isRefreshing ? null : _refreshAll, // disable when true
    ),

    ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: modules.entries.map((entry) {
          final moduleName = entry.key;
          final syncFunc = entry.value;
          final lastSync = lastSyncTimes[moduleName] ?? "Unknown".tr();
          final isSyncing = syncingModules.contains(moduleName);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: Colors.blue.shade700,
                  size: 26,
                ),
              ),
              title: Text(
                moduleName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "${"Last Sync:".tr()} $lastSync",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: isSyncing
                  ? SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : IconButton(
                icon: Icon(Icons.refresh_rounded, color: Colors.green),
                onPressed: () => _refreshModule(moduleName, syncFunc),
                tooltip: "Refresh ${moduleName}".tr(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return "${diff.inSeconds}s ago";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      // If more than a week, show the actual date
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }


  Future<void> syncFlocksOnce(String farmId, DateTime? lastSyncTime) async {
    try {
      // Get last saved sync time
      final lastTime = await SessionManager.getLastSyncTime(
          FireBaseUtils.FLOCKS);
      if (lastTime != null) {
        lastSyncTime = lastTime;
      }

      print("SYNC TIME $lastSyncTime");

      // Base query
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FLOCKS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      // 🔹 One-time fetch
      final snapshot = await query.get();

      print("📥 SYNC FLOCKS FETCHED: ${snapshot.docs.length}");

      DateTime? latestSyncTime = lastSyncTime;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        FlockFB flockFB = FlockFB.fromJson(data);

        print("🟢 Processing FLOCK: ${flockFB.flock.f_name}");

        if (flockFB.last_modified != null) {
          if (latestSyncTime == null ||
              flockFB.last_modified!.isAfter(latestSyncTime)) {
            latestSyncTime = flockFB.last_modified;
          }
        }

        bool isAlreadyAdded =
        await DatabaseHelper.checkFlockBySyncID(flockFB.flock.sync_id!);

        if (isAlreadyAdded) {
          if (flockFB.flock.sync_status == SyncStatus.UPDATED ||
              flockFB.flock.sync_status == SyncStatus.SYNCED) {
            await DatabaseHelper.updateFlockInfoBySyncID(flockFB.flock);
            Flock? flock =
            await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await listenToFlockImagesUntilFound(flock!, flock.farm_id ?? "");
          } else if (flockFB.flock.sync_status == SyncStatus.DELETED) {
            Flock? flock =
            await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await DatabaseHelper.deleteFlockAndRelatedInfoSyncID(
                flockFB.flock.sync_id!, flock!.f_id);
          }
        } else {
          if (flockFB.flock.sync_status != SyncStatus.DELETED) {
            int? f_id = await DatabaseHelper.insertFlock(flockFB.flock);

            if (flockFB.transaction != null) {
              flockFB.transaction!.f_id = f_id!;
              int? tr_id =
              await DatabaseHelper.insertNewTransaction(flockFB.transaction!);
              flockFB.flockDetail!.transaction_id = tr_id.toString();
              flockFB.flockDetail!.f_id = f_id;
              int? f_detail_id =
              await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
              await DatabaseHelper.updateLinkedTransaction(
                  tr_id!.toString(), f_detail_id!.toString());
            } else {
              flockFB.flockDetail!.transaction_id = "-1";
              flockFB.flockDetail!.f_id = f_id!;
              await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
            }

            Flock? insertedFlock =
            await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            print("✅ FLOCK INSERTED ${insertedFlock!.toJson()}");
            await listenToFlockImagesUntilFound(
                insertedFlock, flockFB.flock.farm_id ?? "");
          }
        }
      }

      if (latestSyncTime != null) {
        await SessionManager.setLastSyncTime(
            FireBaseUtils.FLOCKS, DateTime.now());
      }


      print("✅ One-time flock sync completed.");
    } catch (ex) {
      print("❌ Error during flock sync: $ex");
    }
  }

  Future<void> listenToFlockImagesUntilFound(Flock flock, String farmId,
      {Duration timeout = const Duration(seconds: 30)}) async
  {
    final String farm_id = farmId;
    final String? f_sync_id = flock.sync_id;

    print(
        "⏳ Waiting for IMAGES $farm_id ${farm_id.length} $f_sync_id ${f_sync_id!
            .length}");

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
          final result = await DatabaseHelper.deleteItem(
              "Flock_Image", img.id!);
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
              final base64 = await FlockImageUploader().downloadImageAsBase64(
                  url);
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

  /// 🐣 BirdsModification get (one-time fetch, no snapshot listener)
  Future<void> getBirdModifications(String farmId,
      DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.BIRDS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.BIRDS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastSyncTime),
        );
      }

      final snapshot = await query.get(); // 👈 one-time fetch


      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final modification = BirdsModification.fromJson(data);

        print("🔄 BIRD MODIFIED: ${modification.flockDetail.item_type}");
        Utils.backup_changes += snapshot.docs.length;

        if (modification.last_modified!.isAfter(lastSyncTime!)) {
          lastSyncTime = modification.last_modified;
        }

        // Save/update to SQLite:
        Flock? flock = await DatabaseHelper.getFlockBySyncId(modification.flockDetail.f_sync_id!,);

        if (true) {
          bool isAlreadyAdded = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Flock_Detail',
            modification.flockDetail.sync_id!,);

          if (isAlreadyAdded) {
            if (modification.flockDetail.sync_status == SyncStatus.UPDATED) {
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
            } else
            if (modification.flockDetail.sync_status == SyncStatus.DELETED) {
              Flock_Detail? oldRecord = await DatabaseHelper
                  .getSingleFlockDetailsBySyncID(
                  modification.flockDetail.sync_id!);

              await DatabaseHelper.deleteFlockDetailsRecord(
                  oldRecord!.f_detail_id!);
            }

            await SessionManager.setLastSyncTime(FireBaseUtils.BIRDS, DateTime.now());
          } else {
            if (modification.flockDetail.sync_status != SyncStatus.DELETED) {
              int? trId = -1;
              if (modification.transaction != null) {
                modification.transaction!.f_id = flock!.f_id;
                trId = await DatabaseHelper.insertNewTransaction(
                  modification.transaction!,
                );
              }

              final detail = modification.flockDetail;
              detail.transaction_id = trId == null ? "-1" : trId.toString();
              detail.f_id = flock == null ? -1 : flock.f_id;

              int? f_detail_id = await DatabaseHelper.insertFlockDetail(detail);
              if (trId != null) {
                await DatabaseHelper.updateLinkedTransaction(
                  trId.toString(),
                  f_detail_id.toString(),
                );
              }
            }

            await SessionManager.setLastSyncTime(FireBaseUtils.BIRDS, DateTime.now());
          }
        }
      }

      print("✅ Birds sync completed");
    } catch (e) {
      print("❌ BirdModification get error: $e");
    }
  }

  /// 🥚 EggRecord one-time fetch
  Future<void> fetchEggRecords(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.EGGS);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.EGGS)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get(); // 👈 one-time fetch

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final eggRecord = EggRecord.fromJson(data);

        print("🥚 EGG RECORD SYNC: ${eggRecord.eggs.f_name}, ${eggRecord.eggs
            .total_eggs} ${eggRecord.toJson()}");

        Utils.backup_changes += snapshot.docs.length;

        if (eggRecord.last_modified!.isAfter(lastSyncTime!)) {
          lastSyncTime = eggRecord.last_modified;
        }

        // Flock reference
        Flock? flock = await DatabaseHelper.getFlockBySyncId(
            eggRecord.eggs.f_sync_id!);

        // Check existing
        bool isAlreadyAdded = await DatabaseHelper.checkIfRecordExistsSyncID(
          'Eggs',
          eggRecord.eggs.sync_id!,
        );

        if (isAlreadyAdded) {
          if (eggRecord.sync_status == SyncStatus.UPDATED) {
            print("UPDATING EGG");

            Eggs? oldEggs = await DatabaseHelper.getSingleEggsBySyncID(
                eggRecord.eggs.sync_id!);
            int oldId = oldEggs?.id ?? -1;

            TransactionItem? transactionItem;
            EggTransaction? eggTransaction = await DatabaseHelper
                .getByEggItemId(oldEggs!.id!);

            if (eggTransaction != null) {
              transactionItem = await DatabaseHelper.getSingleTransaction(
                eggTransaction.transactionId.toString(),
              );

              eggRecord.eggs.id = oldId;
              eggRecord.eggs.f_id = flock!.f_id;

              await DatabaseHelper.updateEggCollection(eggRecord.eggs);

              if (eggRecord.transaction != null && transactionItem != null) {
                eggRecord.transaction!.id = transactionItem.id;
                eggRecord.transaction!.f_id = flock.f_id;
                await DatabaseHelper.updateTransaction(eggRecord.transaction!);
              }
            } else {
              eggRecord.eggs.id = oldId;
              eggRecord.eggs.f_id = flock!.f_id;
              await DatabaseHelper.updateEggCollection(eggRecord.eggs);
            }

            print("UPDATED");
          } else if (eggRecord.sync_status == SyncStatus.DELETED) {
            Eggs? oldEggs = await DatabaseHelper.getSingleEggsBySyncID(
                eggRecord.eggs.sync_id!);
            EggTransaction? eggTransaction = await DatabaseHelper
                .getByEggItemId(oldEggs!.id!);

            if (eggTransaction != null) {
              DatabaseHelper.deleteItem(
                  "Transactions", eggTransaction.transactionId);
              DatabaseHelper.deleteByEggItemId(oldEggs.id!);
            }
            DatabaseHelper.deleteItem("Eggs", oldEggs.id!);
          }

          await SessionManager.setLastSyncTime(FireBaseUtils.EGGS, DateTime.now());
        } else {
          if (eggRecord.sync_status != SyncStatus.DELETED) {
            int? transId;
            if (eggRecord.transaction != null) {
              eggRecord.transaction!.f_id = flock!.f_id;
              transId =
              await DatabaseHelper.insertNewTransaction(eggRecord.transaction!);
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
                farmId: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
              );
              DatabaseHelper.insertEggJunction(eggTransaction);
            }
          }

          await SessionManager.setLastSyncTime(FireBaseUtils.EGGS, DateTime.now());
        }
      }

      print("✅ EGGS FETCH COMPLETED");
    } catch (e) {
      print("❌ EggRecord fetch error: $e");
    }
  }

  /// 🍽️ One-time Feeding Sync
  Future<void> syncFeedingOnce(String farmId, DateTime? lastSyncTime) async {
    try {
      final lastTime = await SessionManager.getLastSyncTime(
          FireBaseUtils.FEEDING);
      if (lastTime != null) {
        lastSyncTime = lastTime;
      }

      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEEDING)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get(); // 👈 One-time fetch

      print("📥 FEEDING SYNC: fetched ${snapshot.docs.length} docs");

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final feeding = Feeding.fromJson(data);

        print("🔄 FEEDING SYNC: ${feeding.feed_name}, ${feeding.quantity}");

        if (lastSyncTime == null ||
            feeding.last_modified!.isAfter(lastSyncTime)) {
          lastSyncTime = feeding.last_modified;
        }

        // Check if already exists in local DB by sync_id
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'Feeding',
          feeding.sync_id!,
        );

        Flock? flock = await DatabaseHelper.getFlockBySyncId(
            feeding.f_sync_id!);

        if (exists) {
          if (feeding.sync_status == SyncStatus.UPDATED) {
            Feeding? old = await DatabaseHelper.getFeedingBySyncId(
                feeding.sync_id!);
            if (old != null) {
              feeding.id = old.id;
              feeding.f_id = flock?.f_id;
              await DatabaseHelper.updateFeeding(feeding);
            }
          } else if (feeding.sync_status == SyncStatus.DELETED) {
            Feeding? old = await DatabaseHelper.getFeedingBySyncId(
                feeding.sync_id!);
            if (old != null) {
              await DatabaseHelper.deleteItem("Feeding", old.id!);
            }
          }
        } else {
          if (feeding.sync_status != SyncStatus.DELETED) {
            feeding.f_id = flock?.f_id;
            await DatabaseHelper.insertNewFeeding(feeding);
          }
        }
      }

      // Save last sync time ✅
      if (lastSyncTime != null) {
        await SessionManager.setLastSyncTime(
            FireBaseUtils.FEEDING, lastSyncTime);
      }

      print("✅ Feeding one-time sync completed");
    } catch (e) {
      print("❌ Feeding one-time sync error: $e");
    }
  }

  Future<void> syncHealthOnce(String farmId, DateTime? lastSyncTime) async {
    try {
      final lastTime = await SessionManager.getLastSyncTime(
          FireBaseUtils.HEALTH);
      if (lastTime != null) {
        lastSyncTime = lastTime;
      }

      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.HEALTH)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get(); // 👈 one-time fetch

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print("HEALTH $data");

        final vaccination = Vaccination_Medication.fromJson(data);
        print("🔄 HEALTH SYNC: ${vaccination.medicine}, ${vaccination
            .bird_count}");
        Utils.backup_changes += snapshot.docs.length;

        if (lastSyncTime == null ||
            vaccination.last_modified!.isAfter(lastSyncTime)) {
          lastSyncTime = vaccination.last_modified;
        }

        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'Vaccination_Medication', vaccination.sync_id!,
        );

        Flock? flock = await DatabaseHelper.getFlockBySyncId(
            vaccination.f_sync_id!);
        Vaccination_Medication? old = await DatabaseHelper
            .getVaccinationBySyncId(vaccination.sync_id!);

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
        } else {
          if (vaccination.sync_status != SyncStatus.DELETED) {
            vaccination.f_id = flock!.f_id;
            await DatabaseHelper.insertMedVac(vaccination);
          }
        }

        await SessionManager.setLastSyncTime(
            FireBaseUtils.HEALTH, DateTime.now());
      }


      print("✅ One-time HEALTH sync completed");
    } catch (e) {
      print("❌ Vaccination sync error: $e");
    }
  }

  Future<void> syncFinanceOnce(String farmId, DateTime? lastSyncTime) async {
    try {
      final lastTime = await SessionManager.getLastSyncTime(
          FireBaseUtils.FINANCE);
      if (lastTime != null) {
        lastSyncTime = lastTime;
      }

      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FINANCE)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get(); // 👈 one-time fetch
      SyncManager().listenerCompleted(); // ✅ mark progress

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final finance = FinanceItem.fromJson(data);

        print("🔄 FINANCE SYNC: ${finance.transaction.type} ${finance.transaction
            .amount}");
        Utils.backup_changes += snapshot.docs.length;

        if (lastSyncTime == null ||
            finance.last_modified!.isAfter(lastSyncTime)) {
          lastSyncTime = finance.last_modified;
        }

        final syncId = finance.transaction.sync_id;
        final status = finance.sync_status;
        if (syncId == null) continue;

        // ✅ Resolve f_id from f_sync_id
        if (finance.transaction.f_sync_id != null) {
          Flock? flock = await DatabaseHelper.getFlockBySyncId(
              finance.transaction.f_sync_id);
          if (flock != null) {
            finance.transaction.f_id = flock.f_id;
          }
        }

        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            "Transactions", syncId);
        TransactionItem? oldTxn = await DatabaseHelper.getTransactionBySyncId(
            syncId);

        if (exists) {
          if (status == SyncStatus.UPDATED) {
            if (oldTxn != null) {
              finance.transaction.id = oldTxn.id;
              finance.transaction.f_id = oldTxn.f_id;
              await DatabaseHelper.updateTransaction(finance.transaction);
              String farmWideDetailIds = "";

              // 🐥 Update flock details if exist
              if (finance.flockDetails != null) {
                for (var detail in finance.flockDetails!) {
                  if (detail.f_sync_id != null) {
                    Flock? flock = await DatabaseHelper.getFlockBySyncId(
                        detail.f_sync_id!);
                    if (flock != null) {
                      detail.f_id = flock.f_id;
                    }
                  }

                  detail.transaction_id = oldTxn.id.toString();

                  Flock_Detail? existingDetail =
                  await DatabaseHelper.getSingleFlockDetailsBySyncID(
                      detail.sync_id!);

                  if (existingDetail != null) {
                    detail.f_detail_id = existingDetail.f_detail_id;
                    await DatabaseHelper.updateFlock(detail);

                    farmWideDetailIds = farmWideDetailIds.isEmpty
                        ? detail.f_detail_id.toString()
                        : "$farmWideDetailIds,${detail.f_detail_id}";
                  } else {
                    int? fDetailId = await DatabaseHelper.insertFlockDetail(
                        detail);
                    farmWideDetailIds = farmWideDetailIds.isEmpty
                        ? fDetailId.toString()
                        : "$farmWideDetailIds,$fDetailId";
                  }
                }

                if (farmWideDetailIds.isNotEmpty) {
                  await DatabaseHelper.updateLinkedTransaction(
                      oldTxn.id.toString(), farmWideDetailIds);
                }
              }
            }
          } else if (status == SyncStatus.DELETED) {
            await DatabaseHelper.deleteItem("Transactions", oldTxn!.id!);
            if (finance.flockDetails != null) {
              for (var detail in finance.flockDetails!) {
                if (detail.sync_id != null) {
                  Flock_Detail? existingDetail =
                  await DatabaseHelper.getSingleFlockDetailsBySyncID(
                      detail.sync_id!);
                  if (existingDetail != null) {
                    await DatabaseHelper.deleteFlockDetailsRecord(
                        existingDetail.f_detail_id!);
                  }
                }
              }
            }
          }
        } else {
          if (status != SyncStatus.DELETED) {
            // ➕ New transaction
            Flock? flock = await DatabaseHelper.getFlockBySyncId(
                finance.transaction.f_sync_id);
            finance.transaction.f_id = flock!.f_id;
            int? txnId = await DatabaseHelper.insertNewTransaction(
                finance.transaction);

            String farmWideDetailIds = "";
            if (finance.flockDetails != null) {
              for (var detail in finance.flockDetails!) {
                if (detail.f_sync_id != null) {
                  Flock? flock = await DatabaseHelper.getFlockBySyncId(
                      detail.f_sync_id!);
                  if (flock != null) {
                    detail.f_id = flock.f_id;
                  }
                }

                detail.transaction_id = txnId.toString();
                int? fDetailId = await DatabaseHelper.insertFlockDetail(detail);

                farmWideDetailIds = farmWideDetailIds.isEmpty
                    ? fDetailId.toString()
                    : "$farmWideDetailIds,$fDetailId";
              }

              if (farmWideDetailIds.isNotEmpty) {
                await DatabaseHelper.updateLinkedTransaction(
                    txnId.toString(), farmWideDetailIds);
              }
            }
          }
        }

        await SessionManager.setLastSyncTime(
            FireBaseUtils.FINANCE, DateTime.now());
      }

      print("✅ One-time FINANCE sync completed");
    } catch (e) {
      print("❌ Finance sync error: $e");
    }
  }

  Future<void> syncFeedStockOnce(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(
        FireBaseUtils.FEED_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_STOCK_HISTORY)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("✅ No new Feed Stock records to sync.");
        SyncManager().listenerCompleted();
        return;
      }

      SyncManager().listenerCompleted(); // progress +1

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final item = FeedStockFB.fromJson(data);

        final FeedStockHistory stock = item.stock;
        final TransactionItem? txn = item.transaction;

        print("🔄 FEED STOCK SYNC: ${stock.feed_name} (${stock.quantity} ${stock
            .unit})");

        if (item.last_modified != null &&
            (lastSyncTime == null ||
                item.last_modified!.isAfter(lastSyncTime))) {
          lastSyncTime = item.last_modified;
        }

        // 🔎 Check if stock exists
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'FeedStockHistory', stock.sync_id!,
        );

        if (exists) {
          final existing = await DatabaseHelper.getFeedStockHistotyBySyncID(
              stock.sync_id!);

          if (item.sync_status == SyncStatus.UPDATED) {
            if (existing != null) {
              stock.id = existing.id;
              await DatabaseHelper.updateFeedStock(stock);
            }
          } else if (item.sync_status == SyncStatus.DELETED) {
            StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(
                existing!.id!);
            if (stockExpense != null) {
              await DatabaseHelper.deleteByStockItemId(existing.id!);
              await DatabaseHelper.deleteItem(
                  "Transactions", stockExpense.transactionId);
            }
            DatabaseHelper.deleteFeedStock(existing.id!);
          }
        } else {
          if (item.sync_status != SyncStatus.DELETED) {
            stock.id = await DatabaseHelper.insertFeedStock(stock);
          }
        }

        // 🔄 Handle optional transaction
        if (txn != null) {
          bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Transactions', txn.sync_id!,
          );

          if (txnExists) {
            final existingTxn = await DatabaseHelper.getTransactionBySyncId(
                txn.sync_id!);

            if (item.sync_status == SyncStatus.UPDATED ||
                item.sync_status == SyncStatus.SYNCED) {
              if (existingTxn != null) {
                txn.id = existingTxn.id;
                await DatabaseHelper.updateTransaction(txn);
              }
            } else if (item.sync_status == SyncStatus.DELETED) {
              // Already deleted with stock
            }
          } else {
            if (item.sync_status != SyncStatus.DELETED) {
              txn.id = await DatabaseHelper.insertNewTransaction(txn);
              final existing = await DatabaseHelper.getFeedStockHistotyBySyncID(
                  stock.sync_id!);
              StockExpense stockExpense =
              StockExpense(stockItemId: existing!.id!, transactionId: txn.id!);
              await DatabaseHelper.insertStockJunction(stockExpense);
            }
          }
        }

        await SessionManager.setLastSyncTime(
            FireBaseUtils.FEED_STOCK_HISTORY, DateTime.now());
      }
    } catch (e) {
      print("❌ FeedStockFB one-time sync error: $e");
    }
  }

  Future<void> syncMedicineStockOnce(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(
        FireBaseUtils.MEDICINE_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.MEDICINE_STOCK_HISTORY)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("✅ No new Medicine Stock records to sync.");
        SyncManager().listenerCompleted();
        return;
      }

      SyncManager().listenerCompleted(); // progress +1

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final item = MedicineStockFB.fromJson(data);

        final MedicineStockHistory stock = item.stock;
        final TransactionItem? txn = item.transaction;

        print("🔄 MEDICINE STOCK SYNC: ${stock.medicineName} (${stock
            .quantity} ${stock.unit})");

        if (item.last_modified != null &&
            (lastSyncTime == null ||
                item.last_modified!.isAfter(lastSyncTime))) {
          lastSyncTime = item.last_modified;
        }

        // ✅ Check if record exists
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'MedicineStockHistory', stock.sync_id!,
        );

        if (exists) {
          final existing = await DatabaseHelper.getMedicineStockHistotyBySyncID(
              stock.sync_id!);
          print("EXISTS ${existing!.toLocalFBJson()}");

          if (stock.sync_status == SyncStatus.UPDATED) {
            // 🔧 Update logic here if required
            // stock.id = existing.id;
            // await DatabaseHelper.updateMedicineStock(stock);
          } else if (stock.sync_status == SyncStatus.DELETED) {
            StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(
                existing.id!);
            if (stockExpense != null) {
              await DatabaseHelper.deleteByStockItemId(existing.id!);
              await DatabaseHelper.deleteItem(
                  "Transactions", stockExpense.transactionId);
            }
            await DatabaseHelper.deleteMedicineStockHistoryById(existing.id!);
          }
        } else {
          if (stock.sync_status != SyncStatus.DELETED) {
            stock.id = await DatabaseHelper.insertMedicineStock(stock);
          }
        }

        await SessionManager.setLastSyncTime(
            FireBaseUtils.MEDICINE_STOCK_HISTORY, DateTime.now());

        // 🔄 Handle optional transaction
        if (txn != null) {
          bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
              'Transactions', txn.sync_id!);

          if (txnExists) {
            final existingTxn = await DatabaseHelper.getTransactionBySyncId(
                txn.sync_id!);

            if (stock.sync_status == SyncStatus.UPDATED) {
              if (existingTxn != null) {
                txn.id = existingTxn.id;
                await DatabaseHelper.updateTransaction(txn);
              }
            } else if (stock.sync_status == SyncStatus.DELETED) {
              // Already handled in stock delete
            }
          } else {
            if (stock.sync_status != SyncStatus.DELETED) {
              txn.id = await DatabaseHelper.insertNewTransaction(txn);

              StockExpense stockExpense = StockExpense(
                stockItemId: stock.id!,
                transactionId: txn.id!,
              );
              await DatabaseHelper.insertStockJunction(stockExpense);
            }
          }
        }
      }
    } catch (e) {
      print("❌ MedicineStockFB one-time sync error: $e");
    }
  }

  Future<void> syncVaccineStockOnce(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(
        FireBaseUtils.VACCINE_STOCK_HISTORY);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.VACCINE_STOCK_HISTORY)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("✅ No new Vaccine Stock records to sync.");
        SyncManager().listenerCompleted();
        return;
      }

      SyncManager().listenerCompleted(); // progress +1

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final item = VaccineStockFB.fromJson(data);

        final VaccineStockHistory stock = item.stock;
        final TransactionItem? txn = item.transaction;

        print("🔄 VACCINE STOCK SYNC: ${stock.vaccineName} (${stock
            .quantity} ${stock.unit})");

        if (item.last_modified != null &&
            (lastSyncTime == null ||
                item.last_modified!.isAfter(lastSyncTime))) {
          lastSyncTime = item.last_modified;
        }

        // ✅ Check if stock already exists
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'VaccineStockHistory', stock.sync_id!,
        );

        if (exists) {
          final existing = await DatabaseHelper.getVaccineStockHistotyBySyncID(
              stock.sync_id!);

          if (stock.sync_status == SyncStatus.UPDATED) {
            // Update logic if needed
            // stock.id = existing!.id;
            // await DatabaseHelper.updateVaccineStock(stock);
          } else if (stock.sync_status == SyncStatus.DELETED) {
            StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(
                existing!.id!);
            if (stockExpense != null) {
              await DatabaseHelper.deleteByStockItemId(existing.id!);
              await DatabaseHelper.deleteItem(
                  "Transactions", stockExpense.transactionId);
            }
            await DatabaseHelper.deleteVaccineStockHistoryById(existing.id!);
          }
        } else {
          if (stock.sync_status != SyncStatus.DELETED) {
            stock.id = await DatabaseHelper.insertVaccineStock(stock);
          }
        }

        await SessionManager.setLastSyncTime(
            FireBaseUtils.VACCINE_STOCK_HISTORY, DateTime.now());

        // 🔄 Handle optional transaction
        if (txn != null) {
          bool txnExists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'Transactions', txn.sync_id!,
          );

          if (txnExists) {
            final existingTxn = await DatabaseHelper.getTransactionBySyncId(
                txn.sync_id!);

            if (txn.sync_status == SyncStatus.UPDATED ||
                txn.sync_status == SyncStatus.SYNCED) {
              if (existingTxn != null) {
                txn.id = existingTxn.id;
                await DatabaseHelper.updateTransaction(txn);
              }
            } else if (txn.sync_status == SyncStatus.DELETED) {
              await DatabaseHelper.deleteItem('Transactions', existingTxn!.id!);
              final existing = await DatabaseHelper
                  .getVaccineStockHistotyBySyncID(stock.sync_id!);

              StockExpense? stockExpense = await DatabaseHelper
                  .getByStockItemId(existing!.id!);
              if (stockExpense != null) {
                await DatabaseHelper.deleteByStockItemId(existing.id!);
                await DatabaseHelper.deleteItem(
                    "Transactions", existingTxn.id!);
              }
            }
          } else {
            if (stock.sync_status != SyncStatus.DELETED) {
              txn.id = await DatabaseHelper.insertNewTransaction(txn);

              StockExpense stockExpense = StockExpense(
                stockItemId: stock.id!,
                transactionId: txn.id!,
              );
              await DatabaseHelper.insertStockJunction(stockExpense);
            }
          }
        }
      }
    } catch (e) {
      print("❌ VaccineStockFB one-time sync error: $e");
    }
  }

  Future<void> syncFeedIngredientOnce(String farmId) async {
    DateTime? lastSyncTime = await SessionManager.getLastSyncTime(
        FireBaseUtils.FEED_INGRIDIENT);

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_INGRIDIENT)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      SyncManager().listenerCompleted(); // progress +1

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final FeedIngredient ingredient = FeedIngredient.fromJson(data);

        print("🔄 FEED INGREDIENT SYNC (once): ${ingredient.name} (${ingredient
            .pricePerKg}/${ingredient.unit})");
        Utils.backup_changes += snapshot.docs.length;

        if (ingredient.last_modified!.isAfter(
            lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0))) {
          lastSyncTime = ingredient.last_modified;
        }

        // Check if already exists by sync_id
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            'FeedIngredient', ingredient.sync_id!);

        if (exists) {
          if (ingredient.sync_status == SyncStatus.UPDATED) {
            final old = await DatabaseHelper.getFeedIngredientBySyncId(
                ingredient.sync_id!);
            if (old != null) {
              ingredient.id = old.id;
              await DatabaseHelper.updateIngredient(
                ingredient.id!,
                ingredient.name,
                ingredient.pricePerKg,
                ingredient.unit,
              );
            }
          } else if (ingredient.sync_status == SyncStatus.DELETED) {
            FeedIngredient? feedIngredient =
            await DatabaseHelper.getFeedIngredientBySyncId(ingredient.sync_id!);
            if (feedIngredient != null) {
              await DatabaseHelper.deleteItem(
                  "FeedIngredient", feedIngredient.id!);
            }
          }
        } else if (ingredient.sync_status != SyncStatus.DELETED) {
          await DatabaseHelper.insertIngredientWithSyncID(
              ingredient.name, ingredient.pricePerKg, ingredient.sync_id!);
        }

        if (lastSyncTime != null) {
          await SessionManager.setLastSyncTime(
              FireBaseUtils.FEED_INGRIDIENT, lastSyncTime);
        }
      }

      print("✅ One-time FeedIngredient sync finished");
    } catch (e) {
      print("❌ FeedIngredient one-time sync error: $e");
    }
  }

  Future<void> syncFeedBatchOnce(String farmId) async {
    DateTime? lastSyncTime = await SessionManager.getLastSyncTime(
        FireBaseUtils.FEED_BATCH);

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FEED_BATCH)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
            'last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      SyncManager().listenerCompleted(); // progress +1

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final item = FeedBatchFB.fromJson(data);
        final FeedBatch batch = item.feedbatch;
        final List<IngredientFB>? ingredients = item.ingredientList;
        final TransactionItem? txn = item.transaction;

        print(
            "🔄 FEED BATCH SYNC (once): ${batch.name} (${batch.totalWeight}kg)");

        if (item.last_modified!.isAfter(
            lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0))) {
          lastSyncTime = item.last_modified;
        }

        // Check if FeedBatch already exists
        bool exists = await DatabaseHelper.checkIfRecordExistsSyncID(
            "FeedBatch", batch.sync_id!);

        if (exists) {
          if (item.sync_status == SyncStatus.UPDATED) {
            final existing = await DatabaseHelper.getFeedBatchBySyncId(
                batch.sync_id!);
            final exTrans = await DatabaseHelper.getTransactionBySyncId(
                txn!.sync_id!);
            if (existing != null && exTrans != null) {
              batch.id = existing.id;
              txn.id = exTrans.id;
              batch.transaction_id = exTrans.id!;
              await DatabaseHelper.updateBatch(batch);
              await DatabaseHelper.deleteItemsByBatchId(existing.id!);
              await DatabaseHelper.updateTransaction(txn);

              if (ingredients != null) {
                for (final ing in ingredients) {
                  FeedIngredient? feedIngredient =
                  await DatabaseHelper.getFeedIngredientBySyncId(ing.sync_id);

                  if (feedIngredient != null) {
                    await DatabaseHelper.insertBatchItem(FeedBatchItem(
                      batchId: batch.id!,
                      ingredientId: feedIngredient.id!,
                      quantity: ing.qty,
                    ));
                  } else {
                    int? ingID = await DatabaseHelper
                        .insertIngredientWithSyncID(
                        ing.ingredient!.name,
                        ing.ingredient!.pricePerKg,
                        ing.ingredient!.sync_id!);
                    await DatabaseHelper.insertBatchItem(FeedBatchItem(
                      batchId: batch.id!,
                      ingredientId: ingID!,
                      quantity: ing.qty,
                    ));
                  }
                }
              }
            }
          } else if (item.sync_status == SyncStatus.DELETED) {
            final existing = await DatabaseHelper.getFeedBatchBySyncId(
                batch.sync_id!);
            if (existing != null) {
              await DatabaseHelper.deleteItem("FeedBatch", existing.id!);
              await DatabaseHelper.deleteItemsByBatchId(existing.id!);
              await DatabaseHelper.deleteItem(
                  "Transactions", existing.transaction_id);
              print("🗑️ FEED BATCH DELETED");
            }
          }
        } else {
          if (item.sync_status != SyncStatus.DELETED) {
            int? txnID = await DatabaseHelper.insertNewTransaction(txn!);
            batch.transaction_id = txnID!;
            int? newId = await DatabaseHelper.insertBatch(batch);
            batch.id = newId;

            if (ingredients != null) {
              for (final ing in ingredients) {
                FeedIngredient? feedIngredient =
                await DatabaseHelper.getFeedIngredientBySyncId(ing.sync_id);
                if (feedIngredient != null) {
                  await DatabaseHelper.insertBatchItem(FeedBatchItem(
                    batchId: batch.id!,
                    ingredientId: feedIngredient.id!,
                    quantity: ing.qty,
                  ));
                } else {
                  int? ingID = await DatabaseHelper.insertIngredientWithSyncID(
                      ing.ingredient!.name,
                      ing.ingredient!.pricePerKg,
                      ing.ingredient!.sync_id!);
                  await DatabaseHelper.insertBatchItem(FeedBatchItem(
                    batchId: batch.id!,
                    ingredientId: ingID!,
                    quantity: ing.qty,
                  ));
                }
              }
            }
          }
        }

        if (lastSyncTime != null) {
          await SessionManager.setLastSyncTime(
              FireBaseUtils.FEED_BATCH, lastSyncTime);
        }
      }

      print("✅ One-time FeedBatch sync finished");
    } catch (e) {
      print("❌ FeedBatch one-time sync error: $e");
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

          final data = change.doc.data() as Map<String, dynamic>;
          final category = SubItem.fromJson(data);

          print("🔄 CATEGORY SYNC: ${category.name} ${category.toJson()}");
          Utils.backup_changes += snapshot.docChanges.length;
          if (category.last_modified!.isAfter(DateTime.now())) {
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

            await SessionManager.setLastSyncTime(FireBaseUtils.SUB_CATEGORY, DateTime.now());
          } else {
            if(category.syncStatus != SyncStatus.DELETED) {
              await DatabaseHelper.insertNewSubItem(category);
            }

            await SessionManager.setLastSyncTime(FireBaseUtils.SUB_CATEGORY, DateTime.now());
          }

        }
      });


      print("SUB CATEGORY SYNC STARTED");
    } catch (e) {
      print("❌ SubCategory sync error: $e");
    }
  }

  Future<void> startWeightRecordsOneTimeSync(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.WEIGHT_RECORD);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.WEIGHT_RECORD)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where('last_modified', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      // 👇 one-time fetch
      final snapshot = await query.get();

      // progress +1 (first snapshot only)
      SyncManager().listenerCompleted();

      for (var doc in snapshot.docs) {

        final data = doc.data() as Map<String, dynamic>;
        final weightRecord = WeightRecord.fromJson(data);

        print("🔄 ONE-TIME WEIGHT_RECORD SYNC: ${weightRecord.averageWeight} ${weightRecord.toJson()}");
        Utils.backup_changes++;

        if (lastSyncTime == null || weightRecord.last_modified!.isAfter(lastSyncTime)) {
          lastSyncTime = weightRecord.last_modified;
        }

        final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'WeightRecord', weightRecord.sync_id!,
        );

        Flock? flock = await DatabaseHelper.getFlockBySyncId(weightRecord.f_sync_id!);

        if (exists) {
          final old = await DatabaseHelper.getWeightRecordBySyncId(weightRecord.sync_id!);

          if (weightRecord.sync_status == SyncStatus.UPDATED) {
            // TODO: update if needed
          } else if (weightRecord.sync_status == SyncStatus.DELETED) {
            await DatabaseHelper.deleteWeightRecord(old!.id!);
          }
        } else {
          if (weightRecord.sync_status != SyncStatus.DELETED) {
            weightRecord.f_id = flock!.f_id;
            await DatabaseHelper.insertWeightRecord(weightRecord);
          }
        }

        if (lastSyncTime != null) {
          await SessionManager.setLastSyncTime(FireBaseUtils.WEIGHT_RECORD, lastSyncTime);
        }

      }

      print("✅ ONE-TIME WEIGHT_RECORD SYNC DONE");
    } catch (e) {
      print("❌ ONE-TIME WEIGHT_RECORD sync error: $e");
    }
  }

  Future<void> syncSaleContractorOnce(String farmId, DateTime? lastSyncTime) async {
    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.SALE_CONTRACTOR);
    if (lastTime != null) {
      lastSyncTime = lastTime;
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.SALE_CONTRACTOR)
          .where('farm_id', isEqualTo: farmId);

      if (lastSyncTime != null) {
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastSyncTime),
        );
      }

      final snapshot = await query.get(); // 👈 one-time fetch
      SyncManager().listenerCompleted(); // count progress immediately

      for (var doc in snapshot.docs) {

        final data = doc.data() as Map<String, dynamic>;
        final saleContractor = SaleContractor.fromFBJson(data);

        print("🔄 SALE_CONTRACTOR SYNC ONCE: ${saleContractor.name} ${saleContractor.toLocalJson()}");

        Utils.backup_changes += snapshot.docs.length;

        if (saleContractor.last_modified != null) {
          if (lastSyncTime == null || saleContractor.last_modified!.isAfter(lastSyncTime)) {
            lastSyncTime = saleContractor.last_modified;
          }
        }

        final exists = await DatabaseHelper.checkIfRecordExistsSyncID(
          'SaleContractor',
          saleContractor.sync_id!,
        );

        if (exists) {
          final old = await DatabaseHelper.getSaleContractorBySyncId(saleContractor.sync_id!);

          if (saleContractor.sync_status == SyncStatus.UPDATED) {
            if (old != null) {
              saleContractor.id = old.id;
              await DatabaseHelper.updateSaleContractor(saleContractor);
            }
          } else if (saleContractor.sync_status == SyncStatus.DELETED) {
            await DatabaseHelper.deleteSaleContractor(old!.id!);
          }
        } else {
          if (saleContractor.sync_status != SyncStatus.DELETED) {
            await DatabaseHelper.insertSaleContractor(saleContractor);
          }
        }

        if (lastSyncTime != null) {
          await SessionManager.setLastSyncTime(FireBaseUtils.SALE_CONTRACTOR, DateTime.now());
        }


      }

      print("✅ SALE_CONTRACTOR ONE-TIME SYNC COMPLETED");
    } catch (e) {
      print("❌ SALE_CONTRACTOR one-time sync error: $e");
    }
  }


}
