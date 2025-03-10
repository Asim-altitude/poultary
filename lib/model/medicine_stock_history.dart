class MedicineStockHistory {
  int? id;
  int medicineId;
  double quantity;
  String medicineName;
  String unit;
  String source;
  String date;

  MedicineStockHistory({
    this.id,
    required this.medicineId,
    required this.quantity,
    required this.medicineName,
    required this.unit,
    required this.source,
    required this.date,
  });

  // Convert a MedicineStockHistory object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'quantity': quantity,
      'medicine_name': medicineName,
      'unit': unit,
      'source': source,
      'date': date,
    };
  }

  // Convert a Map to a MedicineStockHistory object
  factory MedicineStockHistory.fromMap(Map<String, dynamic> map) {
    return MedicineStockHistory(
      id: map['id'],
      medicineId: map['medicine_id'],
      quantity: map['quantity'],
      medicineName: map['medicine_name'],
      unit: map['unit'],
      source: map['source'],
      date: map['date'],
    );
  }
}
