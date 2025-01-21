class FeedSummary {
  final String feedName;
  final double totalQuantity;

  FeedSummary({required this.feedName, required this.totalQuantity});

  // Create a factory method to construct FeedSummary from query result
  factory FeedSummary.fromMap(Map<String, dynamic> map) {
    return FeedSummary(
      feedName: map['feed_name'],
      totalQuantity: map['total_quantity']?.toDouble() ?? 0.0,
    );
  }
}
