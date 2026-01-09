import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/transaction_item.dart';
import '../../stock/tools_assets/model/tool_asset_maintenance.dart';

class AssetUnitMaintenanceFBModel {
  /// Firestore document id
  String? masterId;

  /// Full Maintenance object
  ToolAssetMaintenance maintenance;

  /// Optional linked transaction
  TransactionItem? transaction;

  // ---------------- SYNC META ----------------
  String? sync_id;
  String? sync_status; // pending | synced | conflict
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  AssetUnitMaintenanceFBModel({
    this.masterId,
    required this.maintenance,
    this.transaction,

    // Sync
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // ---------------- TO FIREBASE JSON ----------------
  Map<String, dynamic> toJson() {
    return {
      'master_id': masterId,

      // 🔹 FULL OBJECTS
      'maintenance': maintenance.toFBMap(),
      'transaction': transaction?.toFBJson(),

      // 🔹 SYNC
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- TO LOCAL JSON ----------------
  Map<String, dynamic> toLocalJson() {
    return {
      'master_id': masterId,

      // 🔹 FULL OBJECTS
      'maintenance': maintenance.toMap(),
      'transaction': transaction?.toLocalFBJson(),

      // 🔹 SYNC
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- FROM FIREBASE JSON ----------------
  factory AssetUnitMaintenanceFBModel.fromJson(
      Map<String, dynamic> json, {
        String? documentId,
      }) {
    DateTime? lastModified;

    final lm = json['last_modified'];
    if (lm is Timestamp) {
      lastModified = lm.toDate();
    } else if (lm is String) {
      lastModified = DateTime.tryParse(lm);
    }

    return AssetUnitMaintenanceFBModel(
      masterId: documentId ?? json['master_id'],

      maintenance: ToolAssetMaintenance.fromFBMap(
        Map<String, dynamic>.from(json['maintenance']),
      ),

      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(
        Map<String, dynamic>.from(json['transaction']),
      )
          : null,

      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }

  // ---------------- COPY WITH ----------------
  AssetUnitMaintenanceFBModel copyWith({
    String? masterId,
    ToolAssetMaintenance? maintenance,
    TransactionItem? transaction,
    String? sync_status,
    DateTime? last_modified,
    String? modified_by,
    String? farm_id,
  }) {
    return AssetUnitMaintenanceFBModel(
      masterId: masterId ?? this.masterId,
      maintenance: maintenance ?? this.maintenance,
      transaction: transaction ?? this.transaction,
      sync_status: sync_status ?? this.sync_status,
      last_modified: last_modified ?? this.last_modified,
      modified_by: modified_by ?? this.modified_by,
      farm_id: farm_id ?? this.farm_id,
      sync_id: sync_id,
    );
  }
}
