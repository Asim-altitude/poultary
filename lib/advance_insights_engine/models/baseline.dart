import 'enums.dart';

/// Represents a statistical range (min, max, mean, stdDev)
class StatRange {
  final double min;
  final double max;
  final double mean;
  final double stdDev;
  final double median;

  const StatRange({
    required this.min,
    required this.max,
    required this.mean,
    required this.stdDev,
    required this.median,
  });

  double get normalLow => mean - stdDev;
  double get normalHigh => mean + stdDev;

  /// Returns whether the value is within normal range (within 1 std dev)
  bool isNormal(double value) =>
      value >= normalLow && value <= normalHigh;

  /// Returns deviation from mean in std-dev units
  double deviationFrom(double value) =>
      stdDev > 0 ? (value - mean) / stdDev : 0;

  /// Returns percent change from mean
  double percentFromMean(double value) =>
      mean > 0 ? ((value - mean) / mean) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'mean': mean,
        'stdDev': stdDev,
        'median': median,
      };

  factory StatRange.fromJson(Map<String, dynamic> json) => StatRange(
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        mean: (json['mean'] as num).toDouble(),
        stdDev: (json['stdDev'] as num).toDouble(),
        median: (json['median'] as num).toDouble(),
      );

  static const StatRange zero = StatRange(
    min: 0,
    max: 0,
    mean: 0,
    stdDev: 0,
    median: 0,
  );
}

/// Monthly seasonal snapshot
class MonthlyPattern {
  final int month; // 1-12
  final double avgOutputPerBird;
  final double avgFeedPerBird;
  final double avgProfitMargin;
  final double avgMortalityRate;
  final int recordCount;

  const MonthlyPattern({
    required this.month,
    required this.avgOutputPerBird,
    required this.avgFeedPerBird,
    required this.avgProfitMargin,
    required this.avgMortalityRate,
    required this.recordCount,
  });

  Map<String, dynamic> toJson() => {
        'month': month,
        'avgOutputPerBird': avgOutputPerBird,
        'avgFeedPerBird': avgFeedPerBird,
        'avgProfitMargin': avgProfitMargin,
        'avgMortalityRate': avgMortalityRate,
        'recordCount': recordCount,
      };

  factory MonthlyPattern.fromJson(Map<String, dynamic> json) => MonthlyPattern(
        month: json['month'] as int,
        avgOutputPerBird: (json['avgOutputPerBird'] as num).toDouble(),
        avgFeedPerBird: (json['avgFeedPerBird'] as num).toDouble(),
        avgProfitMargin: (json['avgProfitMargin'] as num).toDouble(),
        avgMortalityRate: (json['avgMortalityRate'] as num).toDouble(),
        recordCount: json['recordCount'] as int,
      );
}

/// The user's historical baseline — computed from their own data.
/// This is the core reference point for ALL insights.
class Baseline {
  /// Total days of data available
  final int totalDays;

  /// Whether there is enough data for reliable insights
  final bool hasSufficientData;

  /// Minimum days needed for basic insights
  static const int minDaysForBasic = 14;

  /// Minimum days needed for trend analysis
  static const int minDaysForTrends = 30;

  /// Minimum days needed for seasonal patterns
  static const int minDaysForSeasonal = 300;

  // ─── Output stats ──────────────────────────────────────────────
  final StatRange outputPerBird;
  final StatRange dailyOutput;
  final TrendDirection outputTrend;
  final double recentOutputPerBird; // last 14 days avg

  // ─── Feed stats ────────────────────────────────────────────────
  final StatRange feedPerBird;
  final StatRange feedConversionRatio;
  final TrendDirection feedEfficiencyTrend;
  final double recentFeedPerBird; // last 14 days avg
  final double avgFeedCostPerKg; // derived from expense data

  // ─── Financial stats ───────────────────────────────────────────
  final StatRange profitMargin;
  final StatRange profitPerBird;
  final StatRange costPerUnit;
  final StatRange incomePerUnit;
  final TrendDirection profitTrend;
  final double recentProfitMargin; // last 14 days avg

  // ─── Health stats ──────────────────────────────────────────────
  final StatRange mortalityRate;
  final TrendDirection mortalityTrend;
  final double recentMortalityRate; // last 14 days avg

  // ─── Seasonal patterns (only populated with 300+ days) ─────────
  final List<MonthlyPattern> monthlyPatterns;
  final bool hasSeasonalData;

  // ─── Flock stats ───────────────────────────────────────────────
  final double avgBirdsCount;
  final double peakBirdsCount;

  // ─── Computed from ─────────────────────────────────────────────
  final DateTime computedAt;
  final DateTime? dataStartDate;
  final DateTime? dataEndDate;

  const Baseline({
    required this.totalDays,
    required this.hasSufficientData,
    required this.outputPerBird,
    required this.dailyOutput,
    required this.outputTrend,
    required this.recentOutputPerBird,
    required this.feedPerBird,
    required this.feedConversionRatio,
    required this.feedEfficiencyTrend,
    required this.recentFeedPerBird,
    required this.avgFeedCostPerKg,
    required this.profitMargin,
    required this.profitPerBird,
    required this.costPerUnit,
    required this.incomePerUnit,
    required this.profitTrend,
    required this.recentProfitMargin,
    required this.mortalityRate,
    required this.mortalityTrend,
    required this.recentMortalityRate,
    required this.monthlyPatterns,
    required this.hasSeasonalData,
    required this.avgBirdsCount,
    required this.peakBirdsCount,
    required this.computedAt,
    this.dataStartDate,
    this.dataEndDate,
  });

  bool get canShowTrends => totalDays >= minDaysForTrends;
  bool get canShowSeasonal => totalDays >= minDaysForSeasonal;
  int get daysUntilTrends =>
      (minDaysForTrends - totalDays).clamp(0, minDaysForTrends);
  int get daysUntilSeasonal =>
      (minDaysForSeasonal - totalDays).clamp(0, minDaysForSeasonal);

  Map<String, dynamic> toJson() => {
        'totalDays': totalDays,
        'hasSufficientData': hasSufficientData,
        'outputPerBird': outputPerBird.toJson(),
        'dailyOutput': dailyOutput.toJson(),
        'outputTrend': outputTrend.name,
        'recentOutputPerBird': recentOutputPerBird,
        'feedPerBird': feedPerBird.toJson(),
        'feedConversionRatio': feedConversionRatio.toJson(),
        'feedEfficiencyTrend': feedEfficiencyTrend.name,
        'recentFeedPerBird': recentFeedPerBird,
        'avgFeedCostPerKg': avgFeedCostPerKg,
        'profitMargin': profitMargin.toJson(),
        'profitPerBird': profitPerBird.toJson(),
        'costPerUnit': costPerUnit.toJson(),
        'incomePerUnit': incomePerUnit.toJson(),
        'profitTrend': profitTrend.name,
        'recentProfitMargin': recentProfitMargin,
        'mortalityRate': mortalityRate.toJson(),
        'mortalityTrend': mortalityTrend.name,
        'recentMortalityRate': recentMortalityRate,
        'monthlyPatterns':
            monthlyPatterns.map((e) => e.toJson()).toList(),
        'hasSeasonalData': hasSeasonalData,
        'avgBirdsCount': avgBirdsCount,
        'peakBirdsCount': peakBirdsCount,
        'computedAt': computedAt.toIso8601String(),
        'dataStartDate': dataStartDate?.toIso8601String(),
        'dataEndDate': dataEndDate?.toIso8601String(),
      };
}
