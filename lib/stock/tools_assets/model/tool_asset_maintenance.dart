class ToolAssetMaintenance {
  int? id;
  int assetUnitId;

  /// Service | Repair | Inspection | Replacement
  String maintenanceType;

  String? description;

  double cost;
  String? performedBy;

  /// yyyy-MM-dd
  String maintenanceDate;

  /// yyyy-MM-dd (optional reminder)
  String? nextDueDate;

  /// Completed | Pending | Cancelled
  String status;

  String createdAt;
  String? updatedAt;

  int? trId;

  String? asset_sync_id;
  // 🔄 Sync fields
  String? sync_id;
  String? sync_status;
  DateTime? last_modified;
  String? modified_by;
  String? farm_id;

  ToolAssetMaintenance({
    this.id,
    required this.assetUnitId,
    required this.maintenanceType,
    this.description,
    this.cost = 0,
    this.performedBy,
    required this.maintenanceDate,
    this.nextDueDate,
    this.status = "Completed",
    required this.createdAt,
    this.updatedAt,
    this.trId,

    this.asset_sync_id,
    // Sync
    this.sync_id,
    this.sync_status,
    this.last_modified,
    this.modified_by,
    this.farm_id,
  });

  // ---------------- TO MAP ----------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_unit_id': assetUnitId,
      'maintenance_type': maintenanceType,
      'description': description,
      'cost': cost,
      'performed_by': performedBy,
      'maintenance_date': maintenanceDate,
      'next_due_date': nextDueDate,
      'status': status,
      'tr_id': trId,
      'created_at': createdAt,

      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- FROM MAP ----------------
  factory ToolAssetMaintenance.fromMap(Map<String, dynamic> map) {
    return ToolAssetMaintenance(
      id: map['id'],
      assetUnitId: map['asset_unit_id'],
      maintenanceType: map['maintenance_type'],
      description: map['description'],
      cost: (map['cost'] ?? 0).toDouble(),
      performedBy: map['performed_by'],
      maintenanceDate: map['maintenance_date'],
      nextDueDate: map['next_due_date'],
      status: map['status'] ?? "Completed",
      createdAt: map['created_at'],

      trId: map['tr_id'] == null
          ? null
          : int.tryParse(map['tr_id'].toString()),

      // Sync
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'])
          : null,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }


  // ---------------- TO MAP ----------------
  Map<String, dynamic> toFBMap() {
    return {
      'id': id,
      'asset_unit_id': assetUnitId,
      'maintenance_type': maintenanceType,
      'description': description,
      'cost': cost,
      'performed_by': performedBy,
      'maintenance_date': maintenanceDate,
      'next_due_date': nextDueDate,
      'status': status,
      'tr_id': trId,
      'created_at': createdAt,
      'updated_at': updatedAt,

      'asset_sync_id': asset_sync_id,
      // Sync
      'sync_id': sync_id,
      'sync_status': sync_status,
      'last_modified': last_modified?.toIso8601String(),
      'modified_by': modified_by,
      'farm_id': farm_id,
    };
  }

  // ---------------- FROM MAP ----------------
  factory ToolAssetMaintenance.fromFBMap(Map<String, dynamic> map) {
    return ToolAssetMaintenance(
      id: map['id'],
      assetUnitId: map['asset_unit_id'],
      maintenanceType: map['maintenance_type'],
      description: map['description'],
      cost: (map['cost'] ?? 0).toDouble(),
      performedBy: map['performed_by'],
      maintenanceDate: map['maintenance_date'],
      nextDueDate: map['next_due_date'],
      status: map['status'] ?? "Completed",
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],

      trId: map['tr_id'] == null
          ? null
          : int.tryParse(map['tr_id'].toString()),

      asset_sync_id: map['asset_sync_id'],
      // Sync
      sync_id: map['sync_id'],
      sync_status: map['sync_status'],
      last_modified: map['last_modified'] != null
          ? DateTime.tryParse(map['last_modified'])
          : null,
      modified_by: map['modified_by'],
      farm_id: map['farm_id'],
    );
  }
}
