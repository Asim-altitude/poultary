import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/SyncStatus.dart';


class SubCategoryFB {

  final String category_id;
  final String category_name;
  final String sub_category_name;
  final String operation_type; // 'add', 'update', 'delete'


  final String sync_id;
  final String farm_id;
  final String modified_by;
  final DateTime? last_modified;
  final String syncStatus;

  SubCategoryFB({
    required this.sync_id,
    required this.category_id,
    required this.category_name,
    required this.sub_category_name,
    required this.farm_id,
    required this.modified_by,
    required this.operation_type,
    required this.syncStatus,
    this.last_modified,
  });

  factory SubCategoryFB.fromJson(Map<String, dynamic> json) {
    return SubCategoryFB(
      sync_id: json['sync_id'],
      category_id: json['category_id'],
      category_name: json['category_name'],
      sub_category_name: json['sub_category_name'],
      farm_id: json['farm_id'],
      modified_by: json['modified_by'],
      operation_type: json['operation_type'],
      syncStatus: json['sync_status'],
      last_modified: json['last_modified'] != null
          ? DateTime.tryParse(json['last_modified'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sync_id': sync_id,
      'category_id': category_id,
      'category_name': category_name,
      'sub_category_name': sub_category_name,
      'farm_id': farm_id,
      'modified_by': modified_by,
      'operation_type': operation_type,
      'sync_status': syncStatus,
      'last_modified': last_modified?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'sync_id': sync_id,
      'category_id': category_id,
      'category_name': category_name,
      'sub_category_name': sub_category_name,
      'farm_id': farm_id,
      'modified_by': modified_by,
      'operation_type': operation_type,
      'last_modified': FieldValue.serverTimestamp(),
    };
  }

}
