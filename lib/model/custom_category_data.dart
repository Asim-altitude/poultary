import 'package:cloud_firestore/cloud_firestore.dart';

class CustomCategoryData {
  int? id;
  int fId;
  int cId;
  String fName;
  String cType;
  String cName;
  String itemType;
  double quantity;
  String unit;
  String date;
  String note;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;

  CustomCategoryData({
    this.id,
    required this.fId,
    required this.cId,
    required this.cType,
    required this.cName,
    required this.itemType,
    required this.quantity,
    required this.unit,
    required this.date,
    required this.fName,
    required this.note,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id,
  });

  /// 🔼 Convert to SQLite/local Map
  Map<String, dynamic> toMap() {
    return {
      'f_id': fId,
      'c_id': cId,
      'c_type': cType,
      'c_name': cName,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'date': date,
      'f_name': fName,
      'note': note,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// 🔽 Construct from SQLite/local Map
  factory CustomCategoryData.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    var ts = map['last_modified'];
    if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return CustomCategoryData(
      id: map['id'],
      fId: map['f_id'],
      cId: map['c_id'],
      cType: map['c_type'],
      cName: map['c_name'],
      itemType: map['item_type'],
      quantity: map['quantity'] is int ? (map['quantity'] as int).toDouble() : map['quantity'].toDouble(),
      unit: map['unit'],
      date: map['date'],
      fName: map['f_name'],
      note: map['note'] ?? "",
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  /// 🔼 To Firestore-safe JSON (with `FieldValue.serverTimestamp`)
  Map<String, dynamic> toFBJson() {
    return {
      'f_id': fId,
      'c_id': cId,
      'c_type': cType,
      'c_name': cName,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'date': date,
      'f_name': fName,
      'note': note,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'f_sync_id': f_sync_id,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  /// 🔼 To local JSON (for local storage or sending without server timestamp)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'f_id': fId,
      'c_id': cId,
      'c_type': cType,
      'c_name': cName,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'date': date,
      'f_name': fName,
      'note': note,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,
      'f_sync_id': f_sync_id,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  /// 🔽 From Firestore document
  factory CustomCategoryData.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    var ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return CustomCategoryData(
      fId: json['f_id'],
      cId: json['c_id'],
      cType: json['c_type'],
      cName: json['c_name'],
      itemType: json['item_type'],
      quantity: (json['quantity'] is int)
          ? (json['quantity'] as int).toDouble()
          : json['quantity'].toDouble(),
      unit: json['unit'],
      date: json['date'],
      fName: json['f_name'],
      note: json['note'] ?? "",
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      f_sync_id: json['f_sync_id'],
      last_modified: lastModified,
    );
  }
}
