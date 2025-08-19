import 'dart:async';
import 'dart:core';



import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';

class Flock_Detail {
  int f_id = -1;
  int? f_detail_id;
  int item_count = 0;
  String item_type = "";
  String f_name = "";
  String acqusition_type = "";
  String acqusition_date = "";
  String short_note = "";
  String reason = "";
  String transaction_id = "-1";

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;


  Flock_Detail({
    required this.f_id,
    this.f_detail_id,
    required this.item_count,
    required this.item_type,
    required this.f_name,
    required this.acqusition_type,
    required this.acqusition_date,
    required this.short_note,
    required this.reason,
    required this.transaction_id,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id,
  });

  factory Flock_Detail.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;
    if (ts is fs.Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return Flock_Detail(
      f_id: json['f_id'],
      f_detail_id: json['f_detail_id'],
      item_count: json['item_count'] ?? 0,
      item_type: json['item_type'] ?? '',
      f_name: json['f_name'] ?? '',
      acqusition_type: json['acqusition_type'] ?? '',
      acqusition_date: json['acqusition_date'] ?? '',
      short_note: json['short_note'] ?? '',
      reason: json['reason'] ?? '',
      transaction_id: json['transaction_id'] ?? '-1',
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      f_sync_id: json['f_sync_id']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'f_detail_id': f_detail_id,
      'item_count': item_count,
      'item_type': item_type,
      'f_name': f_name,
      'acqusition_type': acqusition_type,
      'acqusition_date': acqusition_date,
      'short_note': short_note,
      'reason': reason,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  Map<String, dynamic> toFBJson() {
    return {
      'f_id': f_id,
      'f_sync_id': f_sync_id,
      'f_detail_id': f_detail_id,
      'item_count': item_count,
      'item_type': item_type,
      'f_name': f_name,
      'acqusition_type': acqusition_type,
      'acqusition_date': acqusition_date,
      'short_note': short_note,
      'reason': reason,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  Map<String, dynamic> toLocalFBJson() {
    return {
      'f_id': f_id,
      'f_sync_id': f_sync_id,
      'f_detail_id': f_detail_id,
      'item_count': item_count,
      'item_type': item_type,
      'f_name': f_name,
      'acqusition_type': acqusition_type,
      'acqusition_date': acqusition_date,
      'short_note': short_note,
      'reason': reason,
      'transaction_id': transaction_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  factory Flock_Detail.fromMap(Map<String, dynamic> map) => Flock_Detail.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Flock_Detail copyWith({
    int? f_id,
    int? f_detail_id,
    int? item_count,
    String? item_type,
    String? f_name,
    String? acqusition_type,
    String? acqusition_date,
    String? short_note,
    String? reason,
    String? transaction_id,
    String? sync_id,
    String? sync_status,
    DateTime? last_modified,
    String? modified_by,
    String? farm_id,
  }) {
    return Flock_Detail(
      f_id: f_id ?? this.f_id,
      f_detail_id: f_detail_id ?? this.f_detail_id,
      item_count: item_count ?? this.item_count,
      item_type: item_type ?? this.item_type,
      f_name: f_name ?? this.f_name,
      acqusition_type: acqusition_type ?? this.acqusition_type,
      acqusition_date: acqusition_date ?? this.acqusition_date,
      short_note: short_note ?? this.short_note,
      reason: reason ?? this.reason,
      transaction_id: transaction_id ?? this.transaction_id,
      sync_id: sync_id ?? this.sync_id,
      sync_status: sync_status ?? this.sync_status,
      last_modified: last_modified ?? this.last_modified,
      modified_by: modified_by ?? this.modified_by,
      farm_id: farm_id ?? this.farm_id,
    );
  }
}


