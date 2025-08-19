import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';


class Vaccination_Medication {
  int? id;
  int? f_id;
  String disease = "";
  String medicine = "";
  String date = "";
  String quantity = "";
  String unit = "";
  String type = "";
  String f_name = "";
  String short_note = "";
  String doctor_name = "";
  int bird_count = 0;

  // 🔄 Sync-related fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;
  String? f_sync_id;

  Vaccination_Medication({
    this.id,
    required this.f_id,
    required this.f_name,
    required this.disease,
    required this.medicine,
    required this.date,
    required this.type,
    required this.short_note,
    required this.bird_count,
    required this.doctor_name,
    required this.quantity,
    required this.unit,
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.f_sync_id,
  });

  Vaccination_Medication.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    f_id = json["f_id"];
    f_name = json["f_name"];
    disease = json['disease'].toString();
    medicine = json['medicine'].toString();
    date = json['date'].toString();
    type = json['type'].toString();
    short_note = json['short_note'].toString();
    bird_count = json["bird_count"];
    doctor_name = json['doctor_name'];
    quantity = json['quantity'];
    unit = json['unit'];

    // Sync-related
    sync_id = json['sync_id'];
    sync_status = json['sync_status'];
    modified_by = json['modified_by'];
    farm_id = json['farm_id'];
    f_sync_id = json['f_sync_id'];

    var ts = json['last_modified'];
    if (ts is Timestamp) {
      last_modified = ts.toDate();
    } else if (ts is String) {
      last_modified = DateTime.tryParse(ts);
    } else if (ts is int) {
      last_modified = DateTime.fromMillisecondsSinceEpoch(ts);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'f_id': f_id,
      'f_name': f_name,
      'disease': disease,
      'medicine': medicine,
      'date': date,
      'type': type,
      'short_note': short_note,
      'bird_count': bird_count,
      'doctor_name': doctor_name,
      'quantity': quantity,
      'unit': unit,

      // 🔄 Sync-related
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  /// Use this to send to Firestore with server timestamp
  Map<String, dynamic> toFBJson() {
    final data = toJson();
    data['f_sync_id'] = f_sync_id;
    data['last_modified'] = FieldValue.serverTimestamp(); // override with server timestamp
    return data;
  }

  Map<String, dynamic> toLocalFBJson() {
    final data = toJson();
    data['f_sync_id'] = f_sync_id;
    data['last_modified'] = last_modified?.toIso8601String(); // override with server timestamp
    return data;
  }
}


