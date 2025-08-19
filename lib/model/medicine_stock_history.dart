import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineStockHistory {
  int? id;
  int medicineId;
  double quantity;
  String medicineName;
  String unit;
  String source;
  String date;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  MedicineStockHistory({
    this.id,
    required this.medicineId,
    required this.quantity,
    required this.medicineName,
    required this.unit,
    required this.source,
    required this.date,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  /// Convert object to local SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'quantity': quantity,
      'medicine_name': medicineName,
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

  /// Convert local map to object
  factory MedicineStockHistory.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final ts = map['last_modified'];
    if (ts is String) parsedDate = DateTime.tryParse(ts);
    if (ts is int) parsedDate = DateTime.fromMillisecondsSinceEpoch(ts);

    return MedicineStockHistory(
      id: map['id'],
      medicineId: map['medicine_id'],
      quantity: map['quantity'],
      medicineName: map['medicine_name'],
      unit: map['unit'],
      source: map['source'],
      date: map['date'],
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: parsedDate,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  /// 🔼 Send to Firebase with server timestamp
  Map<String, dynamic> toFBJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
      'unit': unit,
      'source': source,
      'date': date,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// 🔽 From Firestore document snapshot
  factory MedicineStockHistory.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return MedicineStockHistory(
      id : json['id'],
      medicineId: json['medicine_id'],
      medicineName: json['medicine_name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      source: json['source'],
      date: json['date'],
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }

  /// 🗃️ For local sync queue storage
  Map<String, dynamic> toLocalFBJson() {
    return {
      'id' : id,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'quantity': quantity,
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
}
