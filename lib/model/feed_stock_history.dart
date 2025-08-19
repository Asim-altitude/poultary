import 'package:cloud_firestore/cloud_firestore.dart';

class FeedStockHistory {
  int? id;
  int feedId;
  double quantity;
  String feed_name;
  String unit;
  String source;
  String date;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  FeedStockHistory({
    this.id,
    required this.feedId,
    required this.quantity,
    required this.feed_name,
    required this.unit,
    required this.source,
    required this.date,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  /// ➕ Convert to local SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feed_id': feedId,
      'quantity': quantity,
      'feed_name': feed_name,
      'unit': unit,
      'source': source,
      'date': date,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// ⬇️ Construct from local SQLite Map
  factory FeedStockHistory.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    final ts = map['last_modified'];
    if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FeedStockHistory(
      id: map['id'],
      feedId: map['feed_id'],
      quantity: (map['quantity'] as num).toDouble(),
      feed_name: map['feed_name'],
      unit: map['unit'],
      source: map['source'],
      date: map['date'],
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  /// 🔼 Convert to Firebase-safe JSON
  Map<String, dynamic> toFBJson() {
    return {
      'feed_id': feedId,
      'quantity': quantity,
      'feed_name': feed_name,
      'unit': unit,
      'source': source,
      'date': date,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔽 Firebase snapshot to object
  factory FeedStockHistory.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    }

    return FeedStockHistory(
      id : json['id'],
      feedId: json['feed_id'],
      quantity: (json['quantity'] as num).toDouble(),
      feed_name: json['feed_name'],
      unit: json['unit'],
      source: json['source'],
      date: json['date'],
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lastModified,
    );
  }

  /// 📦 Convert to Firebase upload from local (with stored timestamp)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'feed_id': feedId,
      'quantity': quantity,
      'feed_name': feed_name,
      'unit': unit,
      'source': source,
      'date': date,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }
}
