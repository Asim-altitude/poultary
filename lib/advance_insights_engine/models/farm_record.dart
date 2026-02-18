import 'enums.dart';

/// Expense breakdown for a single day or period
class ExpenseBreakdown {
  final double feedCost;
  final double medicineCost;
  final double laborCost;
  final double utilityCost;
  final double otherCost;

  const ExpenseBreakdown({
    this.feedCost = 0,
    this.medicineCost = 0,
    this.laborCost = 0,
    this.utilityCost = 0,
    this.otherCost = 0,
  });

  double get total =>
      feedCost + medicineCost + laborCost + utilityCost + otherCost;

  double get feedPercent => total > 0 ? (feedCost / total) * 100 : 0;
  double get medicinePercent => total > 0 ? (medicineCost / total) * 100 : 0;
  double get laborPercent => total > 0 ? (laborCost / total) * 100 : 0;
  double get utilityPercent => total > 0 ? (utilityCost / total) * 100 : 0;
  double get otherPercent => total > 0 ? (otherCost / total) * 100 : 0;

  ExpenseBreakdown operator +(ExpenseBreakdown other) => ExpenseBreakdown(
        feedCost: feedCost + other.feedCost,
        medicineCost: medicineCost + other.medicineCost,
        laborCost: laborCost + other.laborCost,
        utilityCost: utilityCost + other.utilityCost,
        otherCost: otherCost + other.otherCost,
      );

  Map<String, dynamic> toJson() => {
        'feedCost': feedCost,
        'medicineCost': medicineCost,
        'laborCost': laborCost,
        'utilityCost': utilityCost,
        'otherCost': otherCost,
      };

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) =>
      ExpenseBreakdown(
        feedCost: (json['feedCost'] as num?)?.toDouble() ?? 0,
        medicineCost: (json['medicineCost'] as num?)?.toDouble() ?? 0,
        laborCost: (json['laborCost'] as num?)?.toDouble() ?? 0,
        utilityCost: (json['utilityCost'] as num?)?.toDouble() ?? 0,
        otherCost: (json['otherCost'] as num?)?.toDouble() ?? 0,
      );

  static const ExpenseBreakdown zero = ExpenseBreakdown();
}

/// A single farm record representing one day's data
class FarmRecord {
  final String id;
  final DateTime date;

  /// Bird species for this record
  final BirdSpecies birdSpecies;

  /// Optional flock identifier (for multi-flock farms)
  final String? flockId;

  /// Number of birds alive at this date
  final int birdsCount;

  /// Primary output count (eggs, kg of meat, breeding pairs, etc.)
  final double outputCount;

  /// What the output represents
  final OutputType outputType;

  /// Total feed consumed in kg
  final double feedConsumedKg;

  /// Total income received (any currency, user's local currency)
  final double totalIncome;

  /// Total expenses (any currency, user's local currency)
  final double totalExpense;

  /// Optional detailed expense breakdown
  final ExpenseBreakdown? expenseBreakdown;

  /// Number of birds that died today
  final int mortalityCount;

  /// Number of birds sold today
  final int birdsSold;

  /// Number of new birds added today
  final int birdsAdded;

  /// Optional notes
  final String? notes;

  const FarmRecord({
    required this.id,
    required this.date,
    required this.birdSpecies,
    required this.birdsCount,
    required this.outputCount,
    required this.outputType,
    required this.feedConsumedKg,
    required this.totalIncome,
    required this.totalExpense,
    this.flockId,
    this.expenseBreakdown,
    this.mortalityCount = 0,
    this.birdsSold = 0,
    this.birdsAdded = 0,
    this.notes,
  });

  // ─── Derived helpers ───────────────────────────────────────────

  double get netProfit => totalIncome - totalExpense;
  double get profitMargin =>
      totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

  double get outputPerBird =>
      birdsCount > 0 ? outputCount / birdsCount : 0;

  double get feedPerBird =>
      birdsCount > 0 ? feedConsumedKg / birdsCount : 0;

  double get feedCostPerUnit {
    final feedCost = expenseBreakdown?.feedCost ?? 0;
    return outputCount > 0 ? feedCost / outputCount : 0;
  }

  double get costPerUnit =>
      outputCount > 0 ? totalExpense / outputCount : 0;

  double get incomePerUnit =>
      outputCount > 0 ? totalIncome / outputCount : 0;

  double get profitPerBird =>
      birdsCount > 0 ? netProfit / birdsCount : 0;

  double get mortalityRate =>
      birdsCount > 0 ? (mortalityCount / birdsCount) * 100 : 0;

  /// Feed conversion ratio: kg of feed per unit of output
  double get feedConversionRatio =>
      outputCount > 0 ? feedConsumedKg / outputCount : 0;

  /// Return on feed investment: income earned per unit of feed cost
  double get returnOnFeedInvestment {
    final feedCost = expenseBreakdown?.feedCost ?? 0;
    return feedCost > 0 ? totalIncome / feedCost : 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'birdSpecies': birdSpecies.name,
        'flockId': flockId,
        'birdsCount': birdsCount,
        'outputCount': outputCount,
        'outputType': outputType.name,
        'feedConsumedKg': feedConsumedKg,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'expenseBreakdown': expenseBreakdown?.toJson(),
        'mortalityCount': mortalityCount,
        'birdsSold': birdsSold,
        'birdsAdded': birdsAdded,
        'notes': notes,
      };

  factory FarmRecord.fromJson(Map<String, dynamic> json) => FarmRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        birdSpecies: BirdSpecies.values.firstWhere(
          (e) => e.name == json['birdSpecies'],
          orElse: () => BirdSpecies.other,
        ),
        flockId: json['flockId'] as String?,
        birdsCount: json['birdsCount'] as int,
        outputCount: (json['outputCount'] as num).toDouble(),
        outputType: OutputType.values.firstWhere(
          (e) => e.name == json['outputType'],
          orElse: () => OutputType.other,
        ),
        feedConsumedKg: (json['feedConsumedKg'] as num).toDouble(),
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpense: (json['totalExpense'] as num).toDouble(),
        expenseBreakdown: json['expenseBreakdown'] != null
            ? ExpenseBreakdown.fromJson(
                json['expenseBreakdown'] as Map<String, dynamic>)
            : null,
        mortalityCount: (json['mortalityCount'] as int?) ?? 0,
        birdsSold: (json['birdsSold'] as int?) ?? 0,
        birdsAdded: (json['birdsAdded'] as int?) ?? 0,
        notes: json['notes'] as String?,
      );
}
