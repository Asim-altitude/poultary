class Permission {
  final int? id;
  final String name;
  final String? description;

  Permission({this.id, required this.name, this.description});

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }
}
