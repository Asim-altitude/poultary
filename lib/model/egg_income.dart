import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';

class EggTransaction {
  final int? id;
  final int eggItemId;
  final int transactionId;

  // 🔄 Sync and multi-user fields
  final String syncId;
  final String syncStatus;
  final DateTime lastModified;
  final String modifiedBy;
  final String farmId;

  EggTransaction({
    this.id,
    required this.eggItemId,
    required this.transactionId,
    required this.syncId,
    required this.syncStatus,
    required this.lastModified,
    required this.modifiedBy,
    required this.farmId,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'egg_item_id': eggItemId,
      'transaction_id': transactionId,
      'sync_id': syncId,
      'sync_status': syncStatus,
      'last_modified': lastModified.toIso8601String(),
      'modified_by': modifiedBy,
      'farm_id': farmId,
    };
    return map;
  }

  Map<String, dynamic> toFBMap() {
    final map = {
      'id':id ?? 0,
      'egg_item_id': eggItemId,
      'transaction_id': transactionId,
      'sync_id': syncId,
      'sync_status': syncStatus,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modifiedBy,
      'farm_id': farmId,
    };
    return map;
  }

  factory EggTransaction.fromMap(Map<String, dynamic> map) {
    final ts = map['last_modified'];
    DateTime parsedDate;
    if (ts is fs.Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else if (ts is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      parsedDate = DateTime.now();
    }

    return EggTransaction(
      id: map['id'] as int?,
      eggItemId: map['egg_item_id'] as int,
      transactionId: map['transaction_id'] as int,
      syncId: map['sync_id'] ?? '',
      syncStatus: map['sync_status'] ?? 'pending',
      lastModified: parsedDate,
      modifiedBy: map['modified_by'] ?? '',
      farmId: map['farm_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory EggTransaction.fromJson(Map<String, dynamic> json) =>
      EggTransaction.fromMap(json);

  @override
  String toString() {
    return 'EggTransaction(id: $id, eggItemId: $eggItemId, transactionId: $transactionId, syncId: $syncId)';
  }
}
