class FeedStockSummary {
  int? feedId;
  String feedName;
  double totalStock;
  double usedStock;
  double availableStock;

  FeedStockSummary({
    required this.feedName,
    required this.totalStock,
    required this.usedStock,
    required this.availableStock,
  });

  // Factory constructor to create an object from a Map
  factory FeedStockSummary.fromMap(Map<String, dynamic> map) {
    return FeedStockSummary(
      feedName: map['feed_name'],
      totalStock: (map['total_stock'] ?? 0).toDouble(),
      usedStock: (map['used_stock'] ?? 0).toDouble(),
      availableStock: (map['available_stock'] ?? 0).toDouble(),
    );
  }
}
