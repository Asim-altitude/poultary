class InventoryStockModel {

  int? stockId;

  int itemId;

  String itemName;

  String unit;

  double quantity;

  double totalCost;

  double costPerUnit;

  String date;

  String inventoryType;

  InventoryStockModel({
    this.stockId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.totalCost,
    required this.costPerUnit,
    required this.date,
    required this.inventoryType,
  });
}