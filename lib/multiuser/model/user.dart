class MultiUser {
  final int? id;
  String name;
  String email;
  String image;
  String password;
  String role;
  final String farmId;
  bool active;
  final String createdAt;

  MultiUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.farmId,
    required this.image,
    this.active = true,
    required this.createdAt,
  });


  factory MultiUser.fromMap(Map<String, dynamic> map) {
    return MultiUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      image: map['image'] ?? '',
      farmId: map['farm_id'],
      active: map['active'] == 1,
      createdAt: map['created_at']
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'farm_id': farmId,
      'active': active ? 1 : 0,
      'created_at': createdAt
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'farm_id': farmId,
      'image': image,
      'active': active ? 1 : 0,
      'created_at': createdAt
    };
  }
}
