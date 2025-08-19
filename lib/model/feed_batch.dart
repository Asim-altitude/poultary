import 'package:cloud_firestore/cloud_firestore.dart';

class FeedBatch {
  int? id;
  final String name;
  final double totalWeight;
  final double totalPrice;
  int transaction_id;

  List<FeedBatchItemWithName> ingredients = []; // ignored in Firebase methods

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  FeedBatch({
    this.id,
    required this.name,
    required this.totalWeight,
    required this.totalPrice,
    required this.transaction_id,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'total_weight': totalWeight,
      'total_price': totalPrice,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
    if (id != null) map['id'] = id!;
    return map;
  }

  factory FeedBatch.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    final ts = map['last_modified'];
    if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FeedBatch(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      name: map['name'] ?? '',
      totalWeight: (map['total_weight'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      transaction_id: map['transaction_id'] is int
          ? map['transaction_id']
          : int.tryParse(map['transaction_id']?.toString() ?? '0') ?? 0,
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  /// 🔼 Firestore-safe JSON (for upload)
  Map<String, dynamic> toFBJson() {
    return {
      'name': name,
      'total_weight': totalWeight,
      'total_price': totalPrice,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔼 Firestore-safe JSON (for offline sync)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'name': name,
      'total_weight': totalWeight,
      'total_price': totalPrice,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  /// 🔽 Construct from Firestore JSON
  factory FeedBatch.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    }

    return FeedBatch(
      name: json['name'] ?? '',
      totalWeight: (json['total_weight'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),

      transaction_id: json['transaction_id'] is int
          ? json['transaction_id']
          : int.tryParse(json['transaction_id']?.toString() ?? ''),

      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }
}


class FeedBatchItemWithName {
  final int ingredientId;
  final String ingredientName;
  final double quantity;

  FeedBatchItemWithName({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
  });
}