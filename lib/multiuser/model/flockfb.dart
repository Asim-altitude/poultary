import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/flock.dart';
import '../../model/flock_detail.dart';
import '../../model/transaction_item.dart';

class FlockFB {
  final Flock flock;
  final TransactionItem? transaction;
  final Flock_Detail? flockDetail;

   String? farm_id;
   DateTime? last_modified;
   String? modified_by;

  FlockFB({
    required this.flock,
    this.transaction,
    this.flockDetail,
    this.farm_id,
    this.last_modified,
    this.modified_by,
  });

  /// 🔄 Convert to Firestore-safe JSON
  Map<String, dynamic> toJson() {
    return {
      'flock': flock.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toFBJson(),
      if (flockDetail != null) 'flock_detail': flockDetail!.toFBJson(),
      'farm_id': farm_id,
      'modified_by': modified_by,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'flock': flock.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toFBJson(),
      if (flockDetail != null) 'flock_detail': flockDetail!.toFBJson(),
      'farm_id': farm_id,
      'modified_by': modified_by,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  factory FlockFB.fromLocalJson(Map<String, dynamic> json) {
    return FlockFB(
      flock: Flock.fromJson(json['flock']),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      flockDetail: json['flock_detail'] != null
          ? Flock_Detail.fromJson(json['flock_detail'])
          : null,
      farm_id: json['farm_id'],
      modified_by: json['modified_by'],
      last_modified: json['last_modified'] != null
          ? DateTime.tryParse(json['last_modified'])
          : null,
    );
  }


  /// 🔽 Create from Firestore snapshot
  factory FlockFB.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FlockFB(
      flock: Flock.fromJson(json['flock']),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      flockDetail: json['flock_detail'] != null
          ? Flock_Detail.fromJson(json['flock_detail'])
          : null,
      farm_id: json['farm_id'],
      modified_by: json['modified_by'],
      last_modified: lastModified,
    );
  }
}
