import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItem {
  int? id = -1;
  int? f_id = -1;
  String date = "";
  String f_name = "";
  String sale_item = "";
  String expense_item = "";
  String type = "";
  String amount = "";
  String payment_method = "";
  String payment_status = "";
  String sold_purchased_from = "";
  String short_note = "";
  String how_many = "";
  String extra_cost = "";
  String extra_cost_details = "";
  String flock_update_id = "-1";
  double? unitPrice;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;

  TransactionItem({
    required this.f_id,
    required this.date,
    required this.f_name,
    required this.sale_item,
    required this.expense_item,
    required this.type,
    required this.amount,
    required this.payment_method,
    required this.payment_status,
    required this.sold_purchased_from,
    required this.short_note,
    required this.how_many,
    required this.extra_cost,
    required this.extra_cost_details,
    required this.flock_update_id,
    this.unitPrice,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;
    if (ts is fs.Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return TransactionItem(
      f_id: json['f_id'],
      date: json['date'] ?? '',
      f_name: json['f_name'] ?? '',
      sale_item: json['sale_item'] ?? '',
      expense_item: json['expense_item'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? '',
      payment_method: json['payment_method'] ?? '',
      payment_status: json['payment_status'] ?? '',
      sold_purchased_from: json['sold_purchased_from'] ?? '',
      short_note: json['short_note'] ?? '',
      how_many: json['how_many'] ?? '',
      extra_cost: json['extra_cost'] ?? '',
      extra_cost_details: json['extra_cost_details'] ?? '',
      flock_update_id: json['flock_update_id'] ?? '-1',
      unitPrice: json['unit_price'] ?? 0,
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      f_sync_id: json['f_sync_id'],
    )..id = json['id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'date': date,
      'f_name': f_name,
      'sale_item': sale_item,
      'expense_item': expense_item,
      'type': type,
      'amount': amount,
      'payment_method': payment_method,
      'payment_status': payment_status,
      'sold_purchased_from': sold_purchased_from,
      'short_note': short_note,
      'how_many': how_many,
      'extra_cost': extra_cost,
      'extra_cost_details': extra_cost_details,
      'flock_update_id': flock_update_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
      'unit_price': unitPrice ?? 0,
    };
  }

  Map<String, dynamic> toFBJson() {
    return {
      'id': id,
      'f_sync_id': f_sync_id,
      'f_id': f_id,
      'date': date,
      'f_name': f_name,
      'sale_item': sale_item,
      'expense_item': expense_item,
      'type': type,
      'amount': amount,
      'payment_method': payment_method,
      'payment_status': payment_status,
      'sold_purchased_from': sold_purchased_from,
      'short_note': short_note,
      'how_many': how_many,
      'extra_cost': extra_cost,
      'extra_cost_details': extra_cost_details,
      'flock_update_id': flock_update_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
      'unit_price': unitPrice ?? 0,
    };
  }

  Map<String, dynamic> toLocalFBJson() {
    return {
      'id': id,
      'f_sync_id': f_sync_id,
      'f_id': f_id,
      'date': date,
      'f_name': f_name,
      'sale_item': sale_item,
      'expense_item': expense_item,
      'type': type,
      'amount': amount,
      'payment_method': payment_method,
      'payment_status': payment_status,
      'sold_purchased_from': sold_purchased_from,
      'short_note': short_note,
      'how_many': how_many,
      'extra_cost': extra_cost,
      'extra_cost_details': extra_cost_details,
      'flock_update_id': flock_update_id,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
      'unit_price': unitPrice ?? 0,
    };
  }


  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  TransactionItem copyWith({
    int? id,
    int? f_id,
    String? date,
    String? f_name,
    String? sale_item,
    String? expense_item,
    String? type,
    String? amount,
    String? payment_method,
    String? payment_status,
    String? sold_purchased_from,
    String? short_note,
    String? how_many,
    String? extra_cost,
    String? extra_cost_details,
    String? flock_update_id,
    String? sync_id,
    String? sync_status,
    DateTime? last_modified,
    String? modified_by,
    String? farm_id,
    double? unitPrice,
  }) {
    return TransactionItem(
      f_id: f_id ?? this.f_id,
      date: date ?? this.date,
      f_name: f_name ?? this.f_name,
      sale_item: sale_item ?? this.sale_item,
      expense_item: expense_item ?? this.expense_item,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      payment_method: payment_method ?? this.payment_method,
      payment_status: payment_status ?? this.payment_status,
      sold_purchased_from: sold_purchased_from ?? this.sold_purchased_from,
      short_note: short_note ?? this.short_note,
      how_many: how_many ?? this.how_many,
      extra_cost: extra_cost ?? this.extra_cost,
      extra_cost_details: extra_cost_details ?? this.extra_cost_details,
      flock_update_id: flock_update_id ?? this.flock_update_id,
      sync_id: sync_id ?? this.sync_id,
      sync_status: sync_status ?? this.sync_status,
      last_modified: last_modified ?? this.last_modified,
      modified_by: modified_by ?? this.modified_by,
      farm_id: farm_id ?? this.farm_id,
      unitPrice: unitPrice ?? this.unitPrice,
    )..id = id ?? this.id;
  }
}


