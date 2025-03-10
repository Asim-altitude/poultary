class VaccineStockSummary {
  int? vaccineId;
  String vaccineName;
  String unit;
  double totalStock;
  double usedStock;
  double availableStock;

  VaccineStockSummary({
    required this.vaccineName,
    required this.totalStock,
    required this.usedStock,
    required this.availableStock,
    required this.unit
  });

  // Factory constructor to create an object from a Map
  factory VaccineStockSummary.fromMap(Map<String, dynamic> map) {
    return VaccineStockSummary(
      vaccineName: map['vaccineName'],
      totalStock: (map['total_stock'] ?? 0).toDouble(),
      usedStock: (map['used_stock'] ?? 0).toDouble(),
      availableStock: (map['available_stock'] ?? 0).toDouble(),
      unit: map['unit'],
    );
  }
}
