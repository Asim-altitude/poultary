import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore Timestamp


class Flock {
  int f_id;
  String f_name;
  int? bird_count;
  int active;
  int? active_bird_count;
  int? flock_new;
  String purpose;
  String icon;
  String acqusition_type;
  String acqusition_date;
  String notes;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  Flock({
    required this.f_id,
    required this.f_name,
    this.bird_count,
    this.active = 1,
    this.active_bird_count,
    this.flock_new,
    required this.purpose,
    required this.icon,
    required this.acqusition_type,
    required this.acqusition_date,
    required this.notes,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // 🔄 Firestore / JSON
  factory Flock.fromJson(Map<String, dynamic> json) {
    final ts = json['last_modified'];
    DateTime? lastModified;
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return Flock(
      f_id: json['f_id'],
      f_name: json['f_name'] ?? '',
      bird_count: json['bird_count'],
      active: json['active'] ?? 1,
      active_bird_count: json['active_bird_count'],
      flock_new: json['flock_new'],
      purpose: json['purpose'] ?? '',
      icon: json['icon'] ?? '',
      acqusition_type: json['acqusition_type'] ?? '',
      acqusition_date: json['acqusition_date'] ?? '',
      notes: json['notes'] ?? '',
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
    );
  }

  Map<String, dynamic> toFBJson() {
    return {
      'f_id': f_id,
      'f_name': f_name,
      'bird_count': bird_count,
      'active': active,
      'active_bird_count': active_bird_count,
      'flock_new': flock_new,
      'purpose': purpose,
      'icon': icon,
      'acqusition_type': acqusition_type,
      'acqusition_date': acqusition_date,
      'notes': notes,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': FieldValue.serverTimestamp(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }
  Map<String, dynamic> toJson() {
    return {
      'f_name': f_name,
      'bird_count': bird_count,
      'active': active,
      'active_bird_count': active_bird_count,
      'flock_new': flock_new,
      'purpose': purpose,
      'icon': icon,
      'acqusition_type': acqusition_type,
      'acqusition_date': acqusition_date,
      'notes': notes,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // 🔄 For SQLite
  factory Flock.fromMap(Map<String, dynamic> map) {
    return Flock.fromJson(map);
  }

  Map<String, dynamic> toMap() => toJson();

  Flock copyWith({
    int? f_id,
    String? f_name,
    int? bird_count,
    int? active,
    int? active_bird_count,
    int? flock_new,
    String? purpose,
    String? icon,
    String? acqusition_type,
    String? acqusition_date,
    String? notes,
    String? sync_id,
    String? sync_status,
    DateTime? last_modified,
    String? modified_by,
    String? farm_id,
  }) {
    return Flock(
      f_id: f_id ?? this.f_id,
      f_name: f_name ?? this.f_name,
      bird_count: bird_count ?? this.bird_count,
      active: active ?? this.active,
      active_bird_count: active_bird_count ?? this.active_bird_count,
      flock_new: flock_new ?? this.flock_new,
      purpose: purpose ?? this.purpose,
      icon: icon ?? this.icon,
      acqusition_type: acqusition_type ?? this.acqusition_type,
      acqusition_date: acqusition_date ?? this.acqusition_date,
      notes: notes ?? this.notes,
      sync_id: sync_id ?? this.sync_id,
      sync_status: sync_status ?? this.sync_status,
      last_modified: last_modified ?? this.last_modified,
      modified_by: modified_by ?? this.modified_by,
      farm_id: farm_id ?? this.farm_id,
    );
  }
}


