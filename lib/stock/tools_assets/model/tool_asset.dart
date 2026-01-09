import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class ToolAssetMaster {
  int? id;

  // -------- Core Fields --------
  String name;
  String category;
  String type; // Tool | Asset
  String unit;
  String? description;
  String? image;

  // -------- Timestamps --------
  String createdAt;
  String? updatedAt;

  // -------- Sync Fields --------
  String? sync_id;
  String? sync_status;      // pending | synced | conflict
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  ToolAssetMaster({
    this.id,
    required this.name,
    required this.category,
    required this.type,
    this.unit = 'pcs',
    this.description,
    this.image,
    required this.createdAt,
    this.updatedAt,

    // Sync
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // -------- TO MAP --------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'unit': unit,
      'description': description,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,

      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }


  // -------- To FireStore Json --------
  Map<String, dynamic> toFireStoreJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'unit': unit,
      'description': description,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,

      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // -------- FROM MAP --------
  factory ToolAssetMaster.fromMap(Map<String, dynamic> map) {
    final ts = map['last_modified'];
    DateTime? lastModified;
    if (ts is fs.Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return ToolAssetMaster(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      type: map['type'],
      unit: map['unit'] ?? 'pcs',
      description: map['description'],
      image: map['image'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],

      // Sync
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }
}
