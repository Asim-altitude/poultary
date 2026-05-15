import '../../model/feed_item.dart';
import '../../model/med_vac_item.dart';
import 'inventory_stock_model.dart';

class InventoryCostEngine {

  // =====================================================
  // NORMALIZE
  // =====================================================

  static String normalize(String value) {

    return value
        .trim()
        .toLowerCase();
  }

  // =====================================================
  // BUILD INVENTORY KEY
  // =====================================================

  static String buildKey({
    required String itemName,
    required String unit,
    required String inventoryType,
  }) {

    if (inventoryType == "feed") {
      return normalize(itemName);
    }

    return
      "${normalize(itemName)}_${normalize(unit)}";
  }

  // =====================================================
  // GROUP STOCKS
  // =====================================================

  static Map<String, List<InventoryStockModel>>
  groupStocks({

    required List<InventoryStockModel> stocks,
  }) {

    Map<String, List<InventoryStockModel>>
    grouped = {};

    for (var stock in stocks) {

      String key = buildKey(
        itemName: stock.itemName,
        unit: stock.unit,
        inventoryType: stock.inventoryType,
      );

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(stock);
    }

    // SORT BY DATE

    grouped.forEach((key, value) {

      value.sort(
            (a, b) =>
            a.date.compareTo(b.date),
      );
    });

    return grouped;
  }

  // =====================================================
  // CALCULATE WEIGHTED AVG
  // =====================================================

  static double calculateWeightedAverage({

    required List<InventoryStockModel> stocks,

    required DateTime consumptionDate,
  }) {

    double totalQty = 0;
    double totalCost = 0;

    for (var stock in stocks) {

      DateTime stockDate =
      DateTime.parse(stock.date);

      if (stockDate.isAfter(consumptionDate)) {
        continue;
      }

      totalQty += stock.quantity;

      totalCost += stock.totalCost;
    }

    // ===============================================

    if (totalQty > 0) {
      return totalCost / totalQty;
    }

    // FALLBACK

    if (stocks.isNotEmpty) {
      return stocks.last.costPerUnit;
    }

    return 0;
  }

  // =====================================================
  // FEED EXPENSE
  // =====================================================

  static double calculateFeedExpense({

    required int flockId,

    required String startDate,
    required String endDate,

    required List<Feeding> feedings,

    required List<InventoryStockModel> stocks,
  }) {

    double totalExpense = 0;

    DateTime start =
    DateTime.parse(startDate);

    DateTime end =
    DateTime.parse(endDate);

    Map<String, List<InventoryStockModel>>
    groupedStocks =
    groupStocks(stocks: stocks);

    Map<String, double> cache = {};

    for (var feeding in feedings) {

      if (feeding.f_id != flockId) {
        continue;
      }

      if (feeding.date == null) {
        continue;
      }

      DateTime feedingDate =
      DateTime.parse(feeding.date!);

      if (feedingDate.isBefore(start) ||
          feedingDate.isAfter(end)) {
        continue;
      }

      String feedName =
          feeding.feed_name ?? "";

      double qty =
          double.tryParse(
              feeding.quantity ?? "0") ?? 0;

      if (qty <= 0) {
        continue;
      }

      String key = buildKey(
        itemName: feedName,
        unit: "kg",
        inventoryType: "feed",
      );

      List<InventoryStockModel> stockList =
          groupedStocks[key] ?? [];

      if (stockList.isEmpty) {
        continue;
      }

      String cacheKey =
          "${key}_${feeding.date}";

      double weightedAvg = 0;

      if (cache.containsKey(cacheKey)) {

        weightedAvg = cache[cacheKey]!;

      } else {

        weightedAvg =
            calculateWeightedAverage(
              stocks: stockList,
              consumptionDate:
              feedingDate,
            );

        cache[cacheKey] =
            weightedAvg;
      }

      totalExpense +=
          qty * weightedAvg;
    }

    return totalExpense;
  }

  // =====================================================
  // MEDICINE/VACCINE EXPENSE
  // =====================================================

  static double calculateMedicationExpense({

    required int flockId,

    required String startDate,
    required String endDate,

    required List<Vaccination_Medication>
    consumptions,

    required List<InventoryStockModel> stocks,

    required String inventoryType,
  }) {

    double totalExpense = 0;

    DateTime start =
    DateTime.parse(startDate);

    DateTime end =
    DateTime.parse(endDate);

    Map<String, List<InventoryStockModel>>
    groupedStocks =
    groupStocks(stocks: stocks);

    Map<String, double> cache = {};

    for (var item in consumptions) {

      if (item.f_id != flockId) {
        continue;
      }

      DateTime consumptionDate =
      DateTime.parse(item.date);

      if (consumptionDate.isBefore(start) ||
          consumptionDate.isAfter(end)) {
        continue;
      }

      double qty =
          double.tryParse(
              item.quantity) ?? 0;

      if (qty <= 0) {
        continue;
      }

      String key = buildKey(
        itemName: item.medicine,
        unit: item.unit,
        inventoryType: inventoryType,
      );

      List<InventoryStockModel> stockList =
          groupedStocks[key] ?? [];

      if (stockList.isEmpty) {
        continue;
      }

      String cacheKey =
          "${key}_${item.date}";

      double weightedAvg = 0;

      if (cache.containsKey(cacheKey)) {

        weightedAvg = cache[cacheKey]!;

      } else {

        weightedAvg =
            calculateWeightedAverage(
              stocks: stockList,
              consumptionDate:
              consumptionDate,
            );

        cache[cacheKey] =
            weightedAvg;
      }

      totalExpense +=
          qty * weightedAvg;
    }

    return totalExpense;
  }
}