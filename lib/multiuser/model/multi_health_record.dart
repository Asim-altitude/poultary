import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/health/multi_medicine.dart';
import '../../model/med_vac_item.dart';

class MultiHealthRecord {
  // 🟦 Root level sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  // 🟦 Nested main record (Vaccination + Medication)
  Vaccination_Medication? record;

  // 🟦 Nested list of usage items
  List<MedicineUsageItem>? usageItems;

  MultiHealthRecord({
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
    this.record,
    this.usageItems,
  });

  // ----------------------------
  // FROM JSON (Firestore → App)
  // ----------------------------
  factory MultiHealthRecord.fromJson(Map<String, dynamic> json) {
    DateTime? lm;

    final ts = json["last_modified"];
    if (ts is Timestamp) lm = ts.toDate();
    else if (ts is String) lm = DateTime.tryParse(ts);
    else if (ts is int) lm = DateTime.fromMillisecondsSinceEpoch(ts);

    return MultiHealthRecord(
      sync_id: json["sync_id"],
      sync_status: json["sync_status"],
      modified_by: json["modified_by"],
      farm_id: json["farm_id"],
      last_modified: lm,

      record: Vaccination_Medication.fromJson(json["record"] ?? {}),

      usageItems: (json["usage_items"] as List<dynamic>? ?? [])
          .map((x) => MedicineUsageItem.fromFBJson(x))
          .toList(),
    );
  }

  // ----------------------------
  // TO JSON (App → Local / SQLite)
  // ----------------------------
  Map<String, dynamic> toJson() {
    return {
      "sync_id": sync_id,
      "sync_status": sync_status,
      "last_modified": last_modified?.toIso8601String(),
      "modified_by": modified_by,
      "farm_id": farm_id,

      "record": record!.toJson(),
      "usage_items": usageItems!.map((x) => x.toJson()).toList(),
    };
  }

  // ----------------------------
  // TO FIRESTORE (Server timestamp)
  // ----------------------------
  Map<String, dynamic> toFBJson() {
    return {
      "sync_id": sync_id,
      "sync_status": sync_status,
      "modified_by": modified_by,
      "farm_id": farm_id,

      "last_modified": FieldValue.serverTimestamp(),

      "record": record!.toFBJson(),
      "usage_items": usageItems!.map((x) => x.toJson()).toList(),
    };
  }
}
