class FeedBatch {
  final int? id;
  final String name;
  final double totalWeight;
  final double totalPrice;
  final int transaction_id;

  List<FeedBatchItemWithName> ingredients = []; // <<-- Add this


  FeedBatch({
    this.id,
    required this.name,
    required this.totalWeight,
    required this.totalPrice,
    required this.transaction_id,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'total_weight': totalWeight,
      'total_price': totalPrice,
      'transaction_id': transaction_id
    };
    if (id != null) map['id'] = id!;
    return map;
  }

  factory FeedBatch.fromMap(Map<String, dynamic> map) {
    return FeedBatch(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      name: map['name'] ?? '',
      totalWeight: (map['total_weight'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      transaction_id: map['transaction_id'] is int
          ? map['transaction_id']
          : int.tryParse(map['transaction_id']?.toString() ?? '-1') ?? -1,
    );
  }

}


class FeedBatchItemWithName {
  final int ingredientId;
  final String ingredientName;
  final double quantity;

  FeedBatchItemWithName({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
  });
}