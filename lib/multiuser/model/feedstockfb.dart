import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/feed_stock_history.dart';
import '../../model/transaction_item.dart';

class FeedStockFB {
  final FeedStockHistory stock;
  TransactionItem? transaction;

  // 🔄 Optional sync metadata
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  FeedStockFB({
    required this.stock,
    this.transaction,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  /// 🔽 Construct from Firebase JSON
  factory FeedStockFB.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FeedStockFB(
      stock: FeedStockHistory.fromJson(json['stock']),
      transaction: json['transaction'] != null
          ? TransactionItem.fromJson(json['transaction'])
          : null,
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lastModified,
    );
  }

  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toJson() {
    return {
      'stock': stock.toFBJson(),
      if (transaction != null) 'transaction': transaction!.toFBJson(),
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      if (farm_id != null) 'farm_id': farm_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔼 Convert to Firebase-safe JSON using local timestamp
  Map<String, dynamic> toLocalJson() {
    return {
      'stock': stock.toLocalFBJson(),
      if (transaction != null) 'transaction': transaction!.toLocalFBJson(),
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      if (farm_id != null) 'farm_id': farm_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }
}
