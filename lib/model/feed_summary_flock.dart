class FlockFeedSummary {
  final String f_name;
  final double totalQuantity;

  FlockFeedSummary({required this.f_name, required this.totalQuantity});

  // Create a factory method to construct FeedSummary from query result
  factory FlockFeedSummary.fromMap(Map<String, dynamic> map) {
    return FlockFeedSummary(
      f_name: map['f_name'],
      totalQuantity: map['total_quantity']?.toDouble() ?? 0.0,
    );
  }
}
