import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';

class Eggs {
  int? id;
  int f_id = -1;
  String? image;
  String? f_name;
  int good_eggs = 0;
  int bad_eggs = 0;
  int total_eggs = 0;
  String? egg_color;
  String? date;
  int? isCollection;
  String? reduction_reason;
  String? short_note;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;

  Eggs({
    required this.f_id,
    required this.f_name,
    this.id,
    required this.image,
    required this.good_eggs,
    required this.bad_eggs,
    required this.egg_color,
    required this.total_eggs,
    required this.date,
    required this.short_note,
    required this.isCollection,
    required this.reduction_reason,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id,
  });

  factory Eggs.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;

    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return Eggs(
      id: json['id'],
      f_id: json['f_id'],
      image: json['image']?.toString(),
      f_name: json['f_name']?.toString(),
      good_eggs: json['good_eggs'] ?? 0,
      bad_eggs: json['spoilt_eggs'] ?? 0,
      total_eggs: json['total_eggs'] ?? 0,
      egg_color: json['egg_color'],
      date: json['collection_date']?.toString(),
      isCollection: json['isCollection'],
      reduction_reason: json['reduction_reason'],
      short_note: json['short_note']?.toString(),
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      f_sync_id: json['f_sync_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'image': image,
      'f_name': f_name,
      'good_eggs': good_eggs,
      'spoilt_eggs': bad_eggs,
      'total_eggs': total_eggs,
      'egg_color': egg_color,
      'collection_date': date,
      'isCollection': isCollection,
      'reduction_reason': reduction_reason,
      'short_note': short_note,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  Map<String, dynamic> toFBJson() {
    return {
      'f_id': f_id,
      'f_name': f_name ?? '',
      'image': image ?? '',
      'good_eggs': good_eggs,
      'spoilt_eggs': bad_eggs,
      'total_eggs': total_eggs,
      'egg_color': egg_color ?? '',
      'collection_date': date ?? '',
      'isCollection': isCollection ?? 1,
      'reduction_reason': reduction_reason ?? '',
      'short_note': short_note ?? '',
      'sync_id': sync_id ?? '',
      'sync_status': sync_status ?? '',
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by ?? '',
      'farm_id': farm_id ?? '',
      'f_sync_id': f_sync_id ?? '',
    };
  }

}


