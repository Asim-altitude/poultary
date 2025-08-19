import 'dart:async';
import 'dart:core';



import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';

class Flock_Image {
  int? id;
  int? f_id;
  String image;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  Flock_Image({
    this.id,
    required this.f_id,
    required this.image,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  factory Flock_Image.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;
    if (ts is fs.Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return Flock_Image(
      id: json['id'],
      f_id: json['f_id'],
      image: json['image'] ?? '',
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'image': image,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  Map<String, dynamic> toFBJson() {
    return {
      'id': id,
      'f_id': f_id,
      'image': image,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  factory Flock_Image.fromMap(Map<String, dynamic> map) => Flock_Image.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Flock_Image copyWith({
    int? id,
    int? f_id,
    String? image,
    String? sync_id,
    String? sync_status,
    DateTime? last_modified,
    String? modified_by,
    String? farm_id,
  }) {
    return Flock_Image(
      id: id ?? this.id,
      f_id: f_id ?? this.f_id,
      image: image ?? this.image,
      sync_id: sync_id ?? this.sync_id,
      sync_status: sync_status ?? this.sync_status,
      last_modified: last_modified ?? this.last_modified,
      modified_by: modified_by ?? this.modified_by,
      farm_id: farm_id ?? this.farm_id,
    );
  }
}


