import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/flock_detail.dart';
import '../../model/transaction_item.dart';

class BirdsModification {
  final Flock_Detail flockDetail;
  TransactionItem? transaction;

   String? farm_id;
   DateTime? last_modified;
   String? modified_by;

  BirdsModification({
    required this.flockDetail,
    this.transaction,
    this.farm_id,
    this.last_modified,
    this.modified_by,
  });

  /// 🔄 Convert to Firestore-safe JSON
  Map<String, dynamic> toJson() {
    return {
      'flock_detail': flockDetail.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toFBJson(),
      'farm_id': farm_id,
      'modified_by': modified_by,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔽 Create from Firestore snapshot
  factory BirdsModification.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return BirdsModification(
      flockDetail: Flock_Detail.fromJson(json['flock_detail']),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      farm_id: json['farm_id'],
      modified_by: json['modified_by'],
      last_modified: lastModified,
    );
  }
}
