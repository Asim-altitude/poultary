class RoleWithPermissions {
  final String role;
  final String farmId;
  final List<String> permissions;

  RoleWithPermissions({
    required this.role,
    required this.farmId,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'farm_id': farmId,
      'permissions': permissions,
    };
  }

  factory RoleWithPermissions.fromMap(Map<String, dynamic> map) {
    return RoleWithPermissions(
      role: map['role'],
      farmId: map['farm_id'],
      permissions: List<String>.from(map['permissions']),
    );
  }
}
