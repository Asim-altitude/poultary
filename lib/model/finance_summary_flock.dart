class FlockIncomeExpense {
  int fId;
  String fName;
  double totalIncome;
  double totalExpense;

  FlockIncomeExpense({
    required this.fId,
    required this.fName,
    required this.totalIncome,
    required this.totalExpense,
  });

  // Factory method to create an instance from a database query result
  factory FlockIncomeExpense.fromMap(Map<String, dynamic> map) {
    return FlockIncomeExpense(
      fId: map['f_id'],
      fName: map['f_name'],
      totalIncome: (map['total_income'] as num).toDouble(),
      totalExpense: (map['total_expense'] as num).toDouble(),
    );
  }

  // Convert an instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'f_id': fId,
      'f_name': fName,
      'total_income': totalIncome,
      'total_expense': totalExpense,
    };
  }
}
