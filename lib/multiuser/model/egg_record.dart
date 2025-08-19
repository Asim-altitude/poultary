import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/egg_item.dart';
import '../../model/transaction_item.dart';

class EggRecord {
  final Eggs eggs;
  TransactionItem? transaction;

  // 🔄 Sync-related metadata (optional if needed separately)
   String? farm_id;
   String? sync_id;
   String? sync_status;
   DateTime? last_modified;
   String? modified_by;

  EggRecord({
    required this.eggs,
    this.transaction,
    this.farm_id,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
  });

  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toJson() {

    return {
      'eggs': eggs.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toFBJson(),
      if (farm_id != null) 'farm_id': farm_id,
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toLocalJson() {

    return {
      'eggs': eggs.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toLocalFBJson(),
      if (farm_id != null) 'farm_id': farm_id,
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  /// 🔽 Create from Firestore JSON snapshot
  factory EggRecord.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return EggRecord(
      eggs: Eggs.fromJson(json['eggs']),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      farm_id: json['farm_id'],
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      last_modified: lastModified,
    );
  }
}
