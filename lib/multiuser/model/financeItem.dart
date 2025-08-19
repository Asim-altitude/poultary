import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/flock_detail.dart';
import '../../model/transaction_item.dart';

class FinanceItem {
  final TransactionItem transaction;
  List<Flock_Detail>? flockDetails;

  // 🔄 Optional sync metadata
   String? sync_id;
   String? sync_status;
   DateTime? last_modified;
   String? modified_by;
   String? farm_id;

  FinanceItem({
    required this.transaction,
    this.flockDetails,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  Map<String, dynamic> toLocalJson() {
    return {
      'transaction': transaction.toLocalFBJson(),
      if (flockDetails != null)
        'flock_details': flockDetails!.map((e) => e.toLocalFBJson()).toList(),
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      if (farm_id != null) 'farm_id': farm_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toJson() {
    return {
      'transaction': transaction.toFBJson(),
      if (flockDetails != null)
        'flock_details': flockDetails!.map((e) => e.toLocalFBJson()).toList(),
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      if (farm_id != null) 'farm_id': farm_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔽 Construct from Firestore JSON
  factory FinanceItem.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FinanceItem(
      transaction: TransactionItem.fromJson(json['transaction']),
      flockDetails: (json['flock_details'] as List<dynamic>?)
          ?.map((e) => Flock_Detail.fromJson(e))
          .toList(),
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lastModified,
    );
  }
}
