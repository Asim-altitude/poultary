class CustomCategoryData {
  int? id;
  int fId;
  int cId;
  String fName;
  String cType;
  String cName;
  String itemType;
  double quantity;
  String unit;
  String date;
  String note;

  CustomCategoryData({
    this.id,
    required this.fId,
    required this.cId,
    required this.cType,
    required this.cName,
    required this.itemType,
    required this.quantity,
    required this.unit,
    required this.date,
    required this.fName,
    required this.note,
  });

  // Convert a CustomCategoryData object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'f_id': fId,
      'c_id': cId,
      'c_type': cType,
      'c_name': cName,
      'item_type': itemType,
      'quantity': quantity,
      'unit': unit,
      'date':date,
      'f_name':fName,
      'note': note,
    };
  }

  // Create a CustomCategoryData object from a Map
  factory CustomCategoryData.fromMap(Map<String, dynamic> map) {
    return CustomCategoryData(
      id: map['id'],
      fId: map['f_id'],
      cId: map['c_id'],
      cType: map['c_type'],
      cName: map['c_name'],
      itemType: map['item_type'],
      quantity: map['quantity'].toDouble(),
      unit: map['unit'],
      note: map['note'] ?? "",
      date: map['date'],
      fName : map['f_name']
    );
  }
}
