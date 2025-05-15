class FeedBatchItem {
  final int? id;
  final int batchId;
  final int ingredientId;
  final double quantity;

  FeedBatchItem({
    this.id,
    required this.batchId,
    required this.ingredientId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'batch_id': batchId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
    };
    if (id != null) map['id'] = id!;
    return map;
  }

  factory FeedBatchItem.fromMap(Map<String, dynamic> map) {
    return FeedBatchItem(
      id: map['id'],
      batchId: map['batch_id'],
      ingredientId: map['ingredient_id'],
      quantity: map['quantity'],
    );
  }
}
