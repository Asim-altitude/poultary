class EggTransaction {
  final int? id;
  final int eggItemId;
  final int transactionId;

  EggTransaction({
    this.id,
    required this.eggItemId,
    required this.transactionId,
  });

  // Convert a StockExpense into a Map. Useful for inserts.
  Map<String, dynamic> toMap() {
    final map = {
      'egg_item_id': eggItemId,
      'transaction_id': transactionId,
    };

    if (id != null) {
      map['id'] = id!;
    }

    return map;
  }

  // Create a StockExpense from a Map (e.g., from a query result)
  factory EggTransaction.fromMap(Map<String, dynamic> map) {
    return EggTransaction(
      id: map['id'] as int?,
      eggItemId: map['egg_item_id'] as int,
      transactionId: map['transaction_id'] as int,
    );
  }

  @override
  String toString() {
    return 'StockExpense(id: $id, eggItemId: $eggItemId, transactionId: $transactionId)';
  }
}
