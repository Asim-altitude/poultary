class WeightRecord {
  final int? id;
  final int f_id;
  final String date;
  final double averageWeight;
  final int? numberOfBirds;
  final String? notes;

  WeightRecord({
    this.id,
    required this.f_id,
    required this.date,
    required this.averageWeight,
    this.numberOfBirds,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'f_id': f_id,
      'date': date,
      'average_weight': averageWeight,
      'number_of_birds': numberOfBirds,
      'notes': notes,
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'],
      f_id: map['f_id'],
      date: map['date'],
      averageWeight: map['average_weight'],
      numberOfBirds: map['number_of_birds'],
      notes: map['notes'],
    );
  }
}
