import 'package:cloud_firestore/cloud_firestore.dart';


class MedicineUsageItem {
  final int? id;
  final int usageId;
  final String medicineName;
  final String diseaseName;
  final String unit;
  final double quantity;

  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  MedicineUsageItem({
    this.id,
    required this.usageId,
    required this.medicineName,
    required this.diseaseName,
    required this.unit,
    required this.quantity,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // -------------------------------------------------------------
  // ✅ FROM LOCAL SQLITE
  // -------------------------------------------------------------
  factory MedicineUsageItem.fromMap(Map<String, dynamic> map) {
    return MedicineUsageItem(
      id: map['id'] as int?,
      usageId: map['usage_id'] as int,
      medicineName: map['medicine_name'] as String,
      diseaseName: map['disease_name'] as String,
      unit: map['unit'] as String,

      quantity: map['quantity'] is int
          ? (map['quantity'] as int).toDouble()
          : map['quantity'] as double,

      // SQLite sync fields
      sync_id: map["sync_id"],
      sync_status: map["sync_status"],
      modified_by: map["modified_by"],
      farm_id: map["farm_id"],
      last_modified: map["last_modified"] != null
          ? DateTime.tryParse(map["last_modified"])
          : null,
    );
  }

  // -------------------------------------------------------------
  // ✅ TO LOCAL SQLITE
  // -------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usage_id': usageId,
      'medicine_name': medicineName,
      'disease_name': diseaseName,
      'unit': unit,
      'quantity': quantity,

      // SQLite sync fields
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // -------------------------------------------------------------
  // ✅ FROM FIREBASE FIRESTORE
  // -------------------------------------------------------------
  factory MedicineUsageItem.fromFBJson(Map<String, dynamic> map) {
    DateTime? lm;

    var ts = map["last_modified"];
    if (ts is Timestamp) {
      lm = ts.toDate();
    } else if (ts is String) {
      lm = DateTime.tryParse(ts);
    } else if (ts is int) {
      lm = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return MedicineUsageItem(
      id: map['id'],
      usageId: map['usage_id'],
      medicineName: map['medicine_name'],
      diseaseName: map['disease_name'],
      unit: map['unit'],

      quantity: map['quantity'] is int
          ? (map['quantity'] as int).toDouble()
          : map['quantity'] as double,

      sync_id: map["sync_id"],
      sync_status: map["sync_status"],
      modified_by: map["modified_by"],
      farm_id: map["farm_id"],
      last_modified: lm,
    );
  }

  // -------------------------------------------------------------
  // ✅ TO FIRESTORE JSON
  // -------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usage_id': usageId,
      'medicine_name': medicineName,
      'disease_name': diseaseName,
      'unit': unit,
      'quantity': quantity,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }
}
