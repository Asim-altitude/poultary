class MedicineStockSummary {
  int? medicineId;
  String medicineName;
  String unit;
  double totalStock;
  double usedStock;
  double availableStock;

  MedicineStockSummary({
    required this.medicineName,
    required this.totalStock,
    required this.usedStock,
    required this.availableStock,
    required this.unit
  });

  // Factory constructor to create an object from a Map
  factory MedicineStockSummary.fromMap(Map<String, dynamic> map) {
    return MedicineStockSummary(
      medicineName: map['medicine_name'],
      totalStock: (map['total_stock'] ?? 0).toDouble(),
      usedStock: (map['used_stock'] ?? 0).toDouble(),
      availableStock: (map['available_stock'] ?? 0).toDouble(),
      unit: map['unit'],
    );
  }
}
