import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecord {
  final int? id;
  int f_id;
  final String date;
  final double averageWeight;
  final int? numberOfBirds;
  final String? notes;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;

  WeightRecord({
    this.id,
    required this.f_id,
    required this.date,
    required this.averageWeight,
    this.numberOfBirds,
    this.notes,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id,
  });

  /// ✅ For local SQLite
  Map<String, dynamic> toMap() {
    return {
      'f_id': f_id,
      'date': date,
      'average_weight': averageWeight,
      'number_of_birds': numberOfBirds,
      'notes': notes,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'],
      f_id: map['f_id'],
      date: map['date'],
      averageWeight: map['average_weight']?.toDouble() ?? 0.0,
      numberOfBirds: map['number_of_birds'],
      notes: map['notes'],
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'])
          : null,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
      f_sync_id: map['f_sync_id'],
    );
  }

  /// ✅ For Firebase write
  Map<String, dynamic> toFirestoreJson() {
    return {
      'sync_id': sync_id,
      'f_id': f_id,
      'date': date,
      'average_weight': averageWeight,
      'number_of_birds': numberOfBirds,
      'notes': notes,
      'farm_id': farm_id,
      'modified_by': modified_by,
      'last_modified': FieldValue.serverTimestamp(),
      'f_sync_id': f_sync_id,
    };
  }

  /// ✅ Generic serialization (for SyncQueue or JSON APIs)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'f_id': f_id,
      'date': date,
      'average_weight': averageWeight,
      'number_of_birds': numberOfBirds,
      'notes': notes,
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
      'f_sync_id': f_sync_id,
    };
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {

    DateTime? lastModified;
    final ts = json['last_modified'];
    if (ts is Timestamp) {
      lastModified = ts.toDate();
    } else if (ts is String) {
      lastModified = DateTime.tryParse(ts);
    } else if (ts is int) {
      lastModified = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return WeightRecord(
      id: json['id'],
      f_id: json['f_id'],
      date: json['date'],
      averageWeight: json['average_weight']?.toDouble() ?? 0.0,
      numberOfBirds: json['number_of_birds'],
      notes: json['notes'],
      sync_id: json['sync_id'],
      sync_status: json['sync_status'],
      last_modified: lastModified,
      modified_by: json['modified_by'],
      farm_id: json['farm_id'],
      f_sync_id: json['f_sync_id'],
    );
  }
}

