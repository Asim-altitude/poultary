import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class CustomCategory {
  int? id;
  String name;
  String itemtype;
  String cat_type;
  String unit;
  int enabled;
  IconData icon;
  String cIcon = "";

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;


  CustomCategory({
    this.id,
    required this.name,
    required this.itemtype,
    required this.cat_type,
    required this.unit,
    required this.enabled,
    required this.icon,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,

  });

  /// 🔽 From local DB
  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    var ts = map['last_modified'];
    if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return CustomCategory(
      id: map['id'],
      name: map['name'],
      itemtype: map['itemtype'],
      cat_type: map['cat_type'],
      unit: map['unit'],
      enabled: map['enabled'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],

    );
  }

  /// 🔽 From Firestore
  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return CustomCategory(
      name: json['name'] ?? '',
      itemtype: json['itemtype'] ?? '',
      cat_type: json['cat_type'] ?? '',
      unit: json['unit'] ?? '',
      enabled: json['enabled'] ?? 1,
      icon: IconData(json['icon'] ?? 0xe3af, fontFamily: 'MaterialIcons'),
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lastModified,
    );
  }

  /// 🔼 To local SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'itemtype': itemtype,
      'cat_type': cat_type,
      'unit': unit,
      'enabled': enabled,
      'icon': icon.codePoint,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// 🔼 To Firestore (local save — with DateTime)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'name': name,
      'itemtype': itemtype,
      'cat_type': cat_type,
      'unit': unit,
      'enabled': enabled,
      'icon': icon.codePoint,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// 🔼 To Firestore (remote upload — with server timestamp)
  Map<String, dynamic> toFBJson() {
    return {
      'name': name,
      'itemtype': itemtype,
      'cat_type': cat_type,
      'unit': unit,
      'enabled': enabled,
      'icon': icon.codePoint,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }
}
