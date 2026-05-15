class FeedStockModel {

  int? stockId;

  int feedId;
  String feedName;

  double quantity;
  String unit;

  double totalCost;
  double costPerUnit;

  String date;

  FeedStockModel({
    this.stockId,
    required this.feedId,
    required this.feedName,
    required this.quantity,
    required this.unit,
    required this.totalCost,
    required this.costPerUnit,
    required this.date,
  });
}