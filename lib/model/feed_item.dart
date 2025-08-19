import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

class Feeding {
  int? id;
  int? f_id;
  String? date;
  String f_name = "";
  String? feed_name;
  String? short_note;
  String? quantity;

  // 🔄 Sync-related metadata
  String? farm_id;
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? f_sync_id;

  Feeding({
    this.id,
    required this.f_id,
    required this.feed_name,
    required this.f_name,
    required this.quantity,
    required this.date,
    required this.short_note,
    this.farm_id,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.f_sync_id
  });

  Feeding.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    f_name = json['f_name'] ?? "";
    feed_name = json['feed_name']?.toString();
    quantity = json['quantity']?.toString();
    date = json['feeding_date']?.toString();
    short_note = json['short_note']?.toString();

    farm_id = json['farm_id'];
    sync_id = json['sync_id'];
    sync_status = json['sync_status'];
    modified_by = json['modified_by'];
    f_sync_id = json['f_sync_id'] ?? "";

    var ts = json['last_modified'];
    if (ts is Timestamp) {
      last_modified = ts.toDate();
    } else if (ts is String) {
      last_modified = DateTime.tryParse(ts);
    } else if (ts is int) {
      last_modified = DateTime.fromMillisecondsSinceEpoch(ts);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'f_name': f_name,
      'feed_name': feed_name,
      'quantity': quantity,
      'feeding_date': date,
      'short_note': short_note,
      'farm_id': farm_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  /// 🔄 To Firestore JSON (server timestamp)
  Map<String, dynamic> toFBJson() {
    return {
      'f_id': f_id,
      'f_name': f_name,
      'feed_name': feed_name,
      'quantity': quantity,
      'feeding_date': date,
      'short_note': short_note,
      'farm_id': farm_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'f_sync_id': f_sync_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalFBJson() {
    return {
      'f_id': f_id,
      'f_name': f_name,
      'feed_name': feed_name,
      'quantity': quantity,
      'feeding_date': date,
      'short_note': short_note,
      'farm_id': farm_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'f_sync_id': f_sync_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }
}


