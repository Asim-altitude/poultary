class StockExpense {
  final int? id;
  final int stockItemId;
  final int transactionId;

  StockExpense({
    this.id,
    required this.stockItemId,
    required this.transactionId,
  });

  // Convert a StockExpense into a Map. Useful for inserts.
  Map<String, dynamic> toMap() {
    final map = {
      'stock_item_id': stockItemId,
      'transaction_id': transactionId,
    };

    if (id != null) {
      map['id'] = id!;
    }

    return map;
  }

  // Create a StockExpense from a Map (e.g., from a query result)
  factory StockExpense.fromMap(Map<String, dynamic> map) {
    return StockExpense(
      id: map['id'] as int?,
      stockItemId: map['stock_item_id'] as int,
      transactionId: map['transaction_id'] as int,
    );
  }

  @override
  String toString() {
    return 'StockExpense(id: $id, stockItemId: $stockItemId, transactionId: $transactionId)';
  }
}
