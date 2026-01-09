import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralStockTransaction {
  int? id;
  int itemId;                  // local sqlite item id

  String type;                 // IN / OUT
  double quantity;
  double? costPerUnit;
  double? totalCost;
  String date;
  int? trId;
  String? notes;

  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  GeneralStockTransaction({
    this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    this.costPerUnit,
    this.totalCost,
    required this.date,
    this.trId,
    this.notes,

    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // ---------------------------------------------------
  // ✅ LOCAL SQLITE → MAP
  // ---------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'total_cost': totalCost,
      'date': date,
      'tr_id': trId,
      'notes': notes,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------------------------------------------
  // ✅ LOCAL SQLITE ← MAP
  // ---------------------------------------------------
  factory GeneralStockTransaction.fromMap(Map<String, dynamic> map) {
    return GeneralStockTransaction(
      id: map['id'],
      itemId: map['item_id'],
      type: map['type'],
      quantity: (map['quantity']).toDouble(),
      costPerUnit: map['cost_per_unit']?.toDouble(),
      totalCost: map['total_cost']?.toDouble(),
      date: map['date'],
      trId: map['tr_id'],
      notes: map['notes'],


      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'])
          : null,
    );
  }

  // ---------------------------------------------------
  // ✅ FIRESTORE ← JSON
  // ---------------------------------------------------
  factory GeneralStockTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? lm;

    var ts = json['last_modified'];
    if (ts is Timestamp) lm = ts.toDate();
    else if (ts is String) lm = DateTime.tryParse(ts);
    else if (ts is int) lm = DateTime.fromMillisecondsSinceEpoch(ts);

    return GeneralStockTransaction(
      id: json['id'],
      itemId: json['item_id'],
      type: json['type'],
      quantity: (json['quantity']).toDouble(),
      costPerUnit: json['cost_per_unit']?.toDouble(),
      totalCost: json['total_cost']?.toDouble(),
      date: json['date'],
      trId: json['tr_id'],
      notes: json['notes'],

      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      last_modified: lm,
    );
  }

  // ---------------------------------------------------
  // ✅ FIRESTORE → JSON (LOCAL TIMESTAMP)
  // ---------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'total_cost': totalCost,
      'date': date,
      'tr_id': trId,
      'notes': notes,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------------------------------------------
  // ✅ FIRESTORE → JSON (SERVER TIMESTAMP)
  // ---------------------------------------------------
  Map<String, dynamic> toFBJson() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'total_cost': totalCost,
      'date': date,
      'tr_id': trId,
      'notes': notes,

      'sync_id': sync_id,
      'sync_status': sync_status,
      'modified_by': modified_by,
      'farm_id': farm_id,

      // server timestamp
      'last_modified': FieldValue.serverTimestamp(),
    };
  }
}
