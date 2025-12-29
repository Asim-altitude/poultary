import 'package:cloud_firestore/cloud_firestore.dart';

class ToolAssetUnit {
  int? id;
  int masterId;

  String? assetCode;
  String condition; // Good | Fair | Needs Repair | Damaged
  String status;    // Active | In Repair | Lost | Disposed

  String? location;
  String? assignedTo;

  String? purchaseDate;
  double purchasePrice;
  String? notes;

  String createdAt;
  String? updatedAt;

  int? trId;

  String? master_sync_id;

  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  ToolAssetUnit({
    this.id,
    required this.masterId,
    this.assetCode,
    required this.condition,
    required this.status,
    this.location,
    this.assignedTo,
    this.purchaseDate,
    this.purchasePrice = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.trId,

    // Sync
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.master_sync_id,
    this.farm_id,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'master_id': masterId,
      'asset_code': assetCode,
      'condition': condition,
      'status': status,
      'location': location,
      'assigned_to': assignedTo,
      'purchase_date': purchaseDate,
      'purchase_price': purchasePrice,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tr_id': trId,

      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- FROM MAP ----------------
  factory ToolAssetUnit.fromMap(Map<String, dynamic> map) {
    return ToolAssetUnit(
      id: map['id'],
      masterId: map['master_id'],
      assetCode: map['asset_code'],
      condition: map['condition'],
      status: map['status'],
      location: map['location'],
      assignedTo: map['assigned_to'],
      purchaseDate: map['purchase_date'],
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      trId: int.tryParse(map['tr_id'].toString()) ?? -1,

      // Sync
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'])
          : null,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  // ---------------- TO FIREBASE JSON ----------------
  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'master_id': masterId,
      'asset_code': assetCode,
      'condition': condition,
      'status': status,
      'location': location,
      'assigned_to': assignedTo,
      'purchase_date': purchaseDate,
      'purchase_price': purchasePrice,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tr_id': trId,
      'master_sync_id': master_sync_id,

      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- FROM FIREBASE JSON ----------------
  factory ToolAssetUnit.fromFirebaseJson(Map<String, dynamic> map) {
    return ToolAssetUnit(
      id: map['id'],
      masterId: map['master_id'],
      assetCode: map['asset_code'],
      condition: map['condition'],
      status: map['status'],
      location: map['location'],
      assignedTo: map['assigned_to'],
      purchaseDate: map['purchase_date'],
      purchasePrice: (map['purchase_price'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      trId: map['tr_id'] == null
          ? null
          : int.tryParse(map['tr_id'].toString()),

      master_sync_id: map['master_sync_id'],
      // Sync
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'].toString())
          : null,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }


}
