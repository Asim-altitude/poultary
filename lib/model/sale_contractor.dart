import 'package:cloud_firestore/cloud_firestore.dart';

class SaleContractor {
  int? id;
  String name;
  String type;
  String? address;
  String? phone;
  String? email;
  String? notes;
  String? createdAt;

  num? saleAmount = 0;
  num? pendingAmount = 0;
  num? clearedAmount = 0;

  // 🔄 Sync-related metadata (optional if needed separately)
  String? farm_id;
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;

  SaleContractor({
    this.id,
    required this.name,
    required this.type,
    this.address,
    this.phone,
    this.email,
    this.notes,
    this.createdAt,

    this.farm_id,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
  });

  // Convert SaleContractor object to map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt,

      if (farm_id != null) 'farm_id': farm_id,
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      'last_modified': last_modified!.toIso8601String(),
    };
  }

  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toLocalJson() {

    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt,

      if (farm_id != null) 'farm_id': farm_id,
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      'last_modified': last_modified!.toIso8601String(),
    };
  }


  /// 🔼 Convert to Firestore-safe JSON
  Map<String, dynamic> toFBJson() {

    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt,

      if (farm_id != null) 'farm_id': farm_id,
      if (sync_id != null) 'sync_id': sync_id,
      if (sync_status != null) 'sync_status': sync_status,
      if (modified_by != null) 'modified_by': modified_by,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

  // Convert map to SaleContractor object
  factory SaleContractor.fromMap(Map<String, dynamic> map) {
    final ts = map['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return SaleContractor(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      notes: map['notes'],
      createdAt: map['created_at'],

      farm_id: map['farm_id'],
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      modified_by: map['modified_by'],
      last_modified: lastModified,
    );
  }

  /// 🔽 Create from Firestore JSON snapshot
  factory SaleContractor.fromFBJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return SaleContractor(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      notes: json['notes'],
      createdAt: json['created_at'],

      farm_id: json['farm_id'],
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      last_modified: lastModified,
    );
  }

}
