import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineStockHistory {
  int? id;
  int vaccineId;
  double quantity;
  String vaccineName;
  String unit;
  String source;
  String date;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  VaccineStockHistory({
    this.id,
    required this.vaccineId,
    required this.quantity,
    required this.vaccineName,
    required this.unit,
    required this.source,
    required this.date,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // 🔁 Convert to Map for local DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vaccine_id': vaccineId,
      'quantity': quantity,
      'vaccine_name': vaccineName,
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

  // 🔁 Create from local DB Map
  factory VaccineStockHistory.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    var ts = map['last_modified'];
    if (ts is String) lastModified = DateTime.tryParse(ts);
    if (ts is int) lastModified = DateTime.fromMillisecondsSinceEpoch(ts);

    return VaccineStockHistory(
      id: map['id'],
      vaccineId: map['vaccine_id'],
      quantity: map['quantity'],
      vaccineName: map['vaccine_name'],
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

  // 🔼 To Firestore JSON
  Map<String, dynamic> toFBJson() {
    return {
      'vaccine_id': vaccineId,
      'quantity': quantity,
      'vaccine_name': vaccineName,
      'unit': unit,
      'source': source,
      'date': date,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(), // Firestore timestamp
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // 🔽 From Firestore JSON
  factory VaccineStockHistory.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    var ts = json['last_modified'];
    if (ts is Timestamp) lastModified = ts.toDate();
    if (ts is String) lastModified = DateTime.tryParse(ts);
    if (ts is int) lastModified = DateTime.fromMillisecondsSinceEpoch(ts);

    return VaccineStockHistory(
      id: json['id'],
      vaccineId: json['vaccine_id'],
      quantity: (json['quantity'] as num).toDouble(),
      vaccineName: json['vaccine_name'],
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

  // 🔁 For local storage sync (timestamp as ISO string)
  Map<String, dynamic> toLocalFBJson() {
    return {
      'id':id,
      'vaccine_id': vaccineId,
      'quantity': quantity,
      'vaccine_name': vaccineName,
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
