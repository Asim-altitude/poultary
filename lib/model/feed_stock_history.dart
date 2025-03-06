class FeedStockHistory {
  int? id;
  int feedId;
  double quantity;
  String feed_name;
  String unit;
  String source;
  String date;

  FeedStockHistory({
    this.id,
    required this.feedId,
    required this.quantity,
    required this.feed_name,
    required this.unit,
    required this.source,
    required this.date,
  });

  // Convert a FeedStockHistory object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feed_id': feedId,
      'quantity': quantity,
      'feed_name':feed_name,
      'unit': unit,
      'source': source,
      'date': date,
    };
  }

  // Convert a Map to a FeedStockHistory object
  factory FeedStockHistory.fromMap(Map<String, dynamic> map) {
    return FeedStockHistory(
      id: map['id'],
      feedId: map['feed_id'],
      quantity: map['quantity'],
      feed_name: map['feed_name'],
      unit: map['unit'],
      source: map['source'],
      date: map['date'],
    );
  }
}
