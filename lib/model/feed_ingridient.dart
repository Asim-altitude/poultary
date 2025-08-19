import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/utils.dart';

class FeedIngredient {
  int? id;
  String name;
  double pricePerKg;
  String unit;

  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  FeedIngredient({
    this.id,
    required this.name,
    required this.pricePerKg,
    this.unit = 'kg',
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  /// 🗃️ Local DB Map
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
    if (id != null) map['id'] = id!;
    return map;
  }

  /// 🔄 Local DB to Object
  factory FeedIngredient.fromMap(Map<String, dynamic> map) {
    DateTime? lastModified;
    final ts = map['last_modified'];
    if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return FeedIngredient(
      id: map['id'],
      name: map['name'],
      pricePerKg: map['price_per_kg'],
      unit: map['unit'] ?? Utils.selected_unit,
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: lastModified,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }

  /// ☁️ To Firebase JSON
  Map<String, dynamic> toFBJson() {
    return {
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// ☁️ From Firebase JSON
  factory FeedIngredient.fromJson(Map<String, dynamic> json) {
    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    }

    return FeedIngredient(
      name: json['name'],
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      unit: json['unit'] ?? Utils.selected_unit,
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }

  /// ☁️ Upload from local with timestamp
  Map<String, dynamic> toLocalFBJson() {
    return {
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }
}
