class FeedIngredient {
  final int? id;
  final String name;
  final double pricePerKg;
  final String unit;

  FeedIngredient({
    this.id,
    required this.name,
    required this.pricePerKg,
    this.unit = 'kg',
  });

  // Convert object to map for DB
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
    };
    if (id != null) map['id'] = id!;
    return map;
  }

  // Convert map from DB to object
  factory FeedIngredient.fromMap(Map<String, dynamic> map) {
    return FeedIngredient(
      id: map['id'],
      name: map['name'],
      pricePerKg: map['price_per_kg'],
      unit: map['unit'] ?? 'kg',
    );
  }
}
