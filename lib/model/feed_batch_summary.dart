class FeedBatchStockSummary {
  final int batchId;
  final String batchName;
  final double totalStock;
  final double usedStock;
  final double availableStock;

  FeedBatchStockSummary({
    required this.batchId,
    required this.batchName,
    required this.totalStock,
    required this.usedStock,
    required this.availableStock,
  });
}
