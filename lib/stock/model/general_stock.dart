import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralStockItem {
  int? id;
  String name;
  String category;
  String unit;
  double currentQuantity;
  double minQuantity;
  String? image;
  String? notes;
  String createdAt;

  double? totalIn;
  double? totalOut;

  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  GeneralStockItem({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.currentQuantity = 0,
    this.minQuantity = 0,
    this.image,
    this.notes,
    this.totalIn,
    this.totalOut,
    required this.createdAt,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // -----------------------------------------------------------
  // ✅ LOCAL SQLITE TO MAP
  // -----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'current_quantity': currentQuantity,
      'min_quantity': minQuantity,
      'image': image,
      'notes': notes,
      'created_at': createdAt,

      // sync fields for local storage
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // -----------------------------------------------------------
  // ✅ LOCAL SQLITE FROM MAP
  // -----------------------------------------------------------
  factory GeneralStockItem.fromMap(Map<String, dynamic> map) {
    return GeneralStockItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      unit: map['unit'],
      currentQuantity:
      (map['current_quantity'] ?? 0).toDouble(),
      minQuantity:
      (map['min_quantity'] ?? 0).toDouble(),
      image: map['image'],
      notes: map['notes'],
      createdAt: map['created_at'],

      sync_id: map["sync_id"],
      sync_status: map["sync_status"],
      modified_by: map["modified_by"],
      farm_id: map["farm_id"],
      last_modified: map["last_modified"] != null
          ? DateTime.tryParse(map["last_modified"])
          : null,
    );
  }

  // -----------------------------------------------------------
  // ✅ FIRESTORE FROM JSON
  // -----------------------------------------------------------
  factory GeneralStockItem.fromJson(Map<String, dynamic> json) {
    DateTime? lm;

    var ts = json["last_modified"];
    if (ts is Timestamp) lm = ts.toDate();
    else if (ts is String) lm = DateTime.tryParse(ts);
    else if (ts is int) lm = DateTime.fromMillisecondsSinceEpoch(ts);

    return GeneralStockItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      unit: json['unit'],
      currentQuantity:
      (json['current_quantity'] ?? 0).toDouble(),
      minQuantity:
      (json['min_quantity'] ?? 0).toDouble(),
      image: json['image'],
      notes: json['notes'],
      createdAt: json['created_at'],

      sync_id: json["sync_id"],
      sync_status: json["sync_status"],
      modified_by: json["modified_by"],
      farm_id: json["farm_id"],
      last_modified: lm,
    );
  }

  // -----------------------------------------------------------
  // ✅ FIRESTORE TO JSON (local fields)
  // -----------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'current_quantity': currentQuantity,
      'min_quantity': minQuantity,
      'image': image,
      'notes': notes,
      'created_at': createdAt,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // -----------------------------------------------------------
  // ✅ FIRESTORE TO JSON WITH SERVER TIMESTAMP
  // -----------------------------------------------------------
  Map<String, dynamic> toFBJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'current_quantity': currentQuantity,
      'min_quantity': minQuantity,
      'image': image,
      'notes': notes,
      'created_at': createdAt,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,

      // Firestore server timestamp
      'last_modified': FieldValue.serverTimestamp(),
    };
  }
}
