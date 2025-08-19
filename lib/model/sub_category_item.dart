import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';

class SubItem{

  int? id;
  int? c_id;
  String? name;

   String? sync_id;
   String? farm_id;
   String? modified_by;
   DateTime? last_modified;
   String? syncStatus;

  SubItem(
      {
        required this.c_id,this.id, required this.name,
        this.sync_id,
        this.syncStatus,
        this.last_modified,
        this.modified_by,
        this.farm_id,
      });

  SubItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    c_id = json['c_id'];
    name = json['name'].toString();

    // Sync-related
    sync_id = json['sync_id'];
    syncStatus = json['sync_status'];
    modified_by = json['modified_by'];
    farm_id = json['farm_id'];

    var ts = json['last_modified'];
    if (ts is Timestamp) {
      last_modified = ts.toDate();
    } else if (ts is String) {
      last_modified = DateTime.tryParse(ts);
    } else if (ts is int) {
      last_modified = DateTime.fromMillisecondsSinceEpoch(ts);
    }
  }


  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['c_id'] = this.c_id;
    data['name'] = this.name;


    return data;
  }

  Map<String, dynamic> toFBJson() {
    final data = toJson();
    data['last_modified'] = FieldValue.serverTimestamp(); // override with server timestamp
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'c_id': c_id,
      'name': name,
      'sync_id': sync_id,
      'sync_status': syncStatus,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };

  }
}


