class VaccineStockHistory {
  int? id;
  int vaccineId;
  double quantity;
  String vaccineName;
  String unit;
  String source;
  String date;

  VaccineStockHistory({
    this.id,
    required this.vaccineId,
    required this.quantity,
    required this.vaccineName,
    required this.unit,
    required this.source,
    required this.date,
  });

  // Convert a VaccineStockHistory object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vaccine_id': vaccineId,
      'quantity': quantity,
      'vaccine_name': vaccineName,
      'unit': unit,
      'source': source,
      'date': date,
    };
  }

  // Convert a Map to a VaccineStockHistory object
  factory VaccineStockHistory.fromMap(Map<String, dynamic> map) {
    return VaccineStockHistory(
      id: map['id'],
      vaccineId: map['vaccine_id'],
      quantity: map['quantity'],
      vaccineName: map['vaccine_name'],
      unit: map['unit'],
      source: map['source'],
      date: map['date'],
    );
  }
}
