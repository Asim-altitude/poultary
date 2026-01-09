import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/transaction_item.dart';
import '../../stock/model/stock_transactions.dart';

class GeneralStockTransactionFB {
  // 🔑 Identifies parent stock item in Firestore
  String stock_sync_id;

  // 📦 Stock movement (IN / OUT)
  GeneralStockTransaction stockTransaction;

  // 💰 Financial transaction (optional but linked)
  TransactionItem? transactionItem;

  // 🔄 Sync fields (ONLY HERE)
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  GeneralStockTransactionFB({
    required this.stock_sync_id,
    required this.stockTransaction,
    this.transactionItem,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // ---------------------------------------------------
  // ✅ FROM FIRESTORE
  // ---------------------------------------------------
  factory GeneralStockTransactionFB.fromJson(Map<String, dynamic> json) {
    DateTime? lm;

    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lm = ts.toDate();
    } else if (ts is String) {
      lm = DateTime.tryParse(ts);
    } else if (ts is int) {
      lm = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return GeneralStockTransactionFB(
      stock_sync_id: json['stock_sync_id'],

      stockTransaction:
      GeneralStockTransaction.fromMap(json['stock_transaction']),

      transactionItem: json['transaction_item'] != null
          ? TransactionItem.fromJson(json['transaction_item'])
          : null,

      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lm,
    );
  }

  // ---------------------------------------------------
  // ✅ TO JSON (LOCAL / CACHE)
  // ---------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'stock_sync_id': stock_sync_id,

      'stock_transaction': stockTransaction.toMap(),
      'transaction_item': transactionItem?.toJson(),

      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------------------------------------------
  // ✅ TO FIRESTORE (SERVER TIMESTAMP)
  // ---------------------------------------------------
  Map<String, dynamic> toFBJson() {
    return {
      'stock_sync_id': stock_sync_id,

      'stock_transaction': stockTransaction.toMap(),
      'transaction_item': transactionItem?.toFBJson(),

      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,

      'last_modified': FieldValue.serverTimestamp(),
    };
  }
}
