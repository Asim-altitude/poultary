
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/feed_batch.dart';
import '../../model/transaction_item.dart';
import 'ingridientfb.dart';

class FeedBatchFB {
  final FeedBatch feedbatch;
  List<IngredientFB>? ingredientList;
  TransactionItem? transaction;

  // 🔄 Added sync-related fields
   String? farm_id;
   DateTime? last_modified;
   String? modified_by;
   String? sync_status;

  FeedBatchFB(
      this.feedbatch, {
        this.ingredientList,
        this.transaction,
        this.farm_id,
        this.last_modified,
        this.modified_by,
        this.sync_status
      });

  /// 🔼 Convert to Firebase-compatible JSON
  Map<String, dynamic> toJson() {
    return {
      'feedbatch': feedbatch.toFBJson(),
      if (ingredientList != null)
        'ingredients': ingredientList!.map((e) => e.toJson()).toList(),
      if (transaction != null)
        'transaction': transaction!.toFBJson(),
      'farm_id': farm_id,
      'last_modified': FieldValue.serverTimestamp(), // for Firestore write
      'modified_by': modified_by,
      'sync_status':sync_status
    };
  }

  /// 🔽 Construct from Firebase snapshot or map
  factory FeedBatchFB.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FeedBatchFB(
      FeedBatch.fromJson(json['feedbatch']),
      ingredientList: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => IngredientFB.fromJson(e))
          .toList(),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      farm_id: json['farm_id'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      sync_status : json['sync_status']
    );
  }

  /// 💾 Convert to local-safe Firebase JSON (timestamp as string)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'feedbatch': feedbatch.toLocalFBJson(),
      if (ingredientList != null)
        'ingredients': ingredientList!.map((e) => e.toLocalFBJson()).toList(),
      if (transaction != null)
        'transaction': transaction!.toLocalFBJson(),
      'farm_id': farm_id,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'sync_status':sync_status
    };
  }
}
