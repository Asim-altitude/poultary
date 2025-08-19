import 'dart:convert';

import 'package:poultary/multiuser/model/vaccinestockfb.dart';

import '../../model/custom_category.dart';
import '../../model/custom_category_data.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/flock.dart';
import '../../model/flock_detail.dart';
import '../../model/med_vac_item.dart';
import '../../model/sub_category_item.dart';
import 'birds_modification.dart';
import 'egg_record.dart';
import 'feedbatchfb.dart';
import 'feedstockfb.dart';
import 'financeItem.dart';
import 'flockfb.dart';
import 'medicinestockfb.dart';

class SyncQueue {
  final int? id;
  final String type;
  final String syncId;
  final String payload;
  int retryCount;
  final String operationType;
  final String? lastError;
  final DateTime createdAt;

  SyncQueue({
    this.id,
    required this.type,
    required this.syncId,
    required this.payload,
    required this.retryCount,
    required this.operationType,
    this.lastError,
    required this.createdAt,
  });

  factory SyncQueue.fromMap(Map<String, dynamic> map) {
    return SyncQueue(
      id: map['id'] as int?,
      type: map['type'],
      syncId: map['sync_id'],
      payload: map['payload'],
      retryCount: map['retry_count'],
      operationType: map['operation_type'],
      lastError: map['last_error'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'sync_id': syncId,
      'payload': payload,
      'retry_count': retryCount,
      'operation_type': operationType,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
    };
  }

  dynamic toModel() {
    final Map<String, dynamic> json = jsonDecode(payload);

    switch (type) {
      case 'flock':
        return FlockFB.fromJson(json);
      case 'flocks':
        return FlockFB.fromJson(json);
      case 'feeding':
        return Feeding.fromJson(json);
      case 'health':
        return Vaccination_Medication.fromJson(json);
      case 'birds':
        return BirdsModification.fromJson(json);
      case 'eggs':
        return EggRecord.fromJson(json);
      case 'finance':
        return FinanceItem.fromJson(json);
      case 'flock_details':
        return Flock_Detail.fromJson(json);
    // Skip 'flock_images' intentionally
      case 'custom_categories':
        return CustomCategory.fromJson(json);
      case 'custom_category_data':
        return CustomCategoryData.fromJson(json);
      case 'feed_stock_history':
        return FeedStockFB.fromJson(json);
      case 'medicine_stock_history':
        return MedicineStockFB.fromJson(json);
      case 'vaccine_stock_history':
        return VaccineStockFB.fromJson(json);
      case 'feed_ingridient':
        return FeedIngredient.fromJson(json);
      case 'feed_batch':
        return FeedBatchFB.fromJson(json);
      case 'sub_categories':
        return SubItem.fromJson(json);
      default:
        throw UnsupportedError('Unknown sync type: $type');
    }
  }



}
