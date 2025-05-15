class SaleContractor {
  int? id;
  String name;
  String type;
  String? address;
  String? phone;
  String? email;
  String? notes;
  String? createdAt;

  SaleContractor({
    this.id,
    required this.name,
    required this.type,
    this.address,
    this.phone,
    this.email,
    this.notes,
    this.createdAt,
  });

  // Convert SaleContractor object to map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  // Convert map to SaleContractor object
  factory SaleContractor.fromMap(Map<String, dynamic> map) {
    return SaleContractor(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }
}
