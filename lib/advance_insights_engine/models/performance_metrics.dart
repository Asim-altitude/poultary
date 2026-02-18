import 'enums.dart';

/// Aggregated metrics for the analysis period
class PerformanceMetrics {
  // ─── Period info ───────────────────────────────────────────────
  final DateTime periodStart;
  final DateTime periodEnd;
  final int periodDays;

  // ─── Flock ─────────────────────────────────────────────────────
  final double avgBirdsCount;
  final int totalMortality;
  final double avgMortalityRatePercent;

  // ─── Production ────────────────────────────────────────────────
  final double totalOutput;
  final double avgDailyOutput;
  final double avgOutputPerBird;
  final double outputConsistencyScore; // 0-100 (100 = very stable)

  // ─── Feed ──────────────────────────────────────────────────────
  final double totalFeedKg;
  final double avgDailyFeedKg;
  final double avgFeedPerBird;
  final double avgFeedConversionRatio;

  // ─── Financial ─────────────────────────────────────────────────
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final double avgProfitMarginPercent;
  final double avgProfitPerBird;
  final double avgCostPerUnit;
  final double avgIncomePerUnit;
  final double avgFeedCostPercent; // feed cost as % of total expense

  // ─── Trend summaries ───────────────────────────────────────────
  final TrendDirection outputTrend;
  final TrendDirection feedEfficiencyTrend;
  final TrendDirection profitTrend;
  final TrendDirection mortalityTrend;

  // ─── Period-over-period comparison ─────────────────────────────
  final double? outputVsPreviousPeriodPercent;
  final double? profitVsPreviousPeriodPercent;
  final double? feedEfficiencyVsPreviousPeriodPercent;
  final double? mortalityVsPreviousPeriodPercent;

  // ─── Baseline comparison ───────────────────────────────────────
  final double? outputVsBaselinePercent;
  final double? feedVsBaselinePercent;
  final double? profitMarginVsBaselinePercent;
  final double? mortalityVsBaselinePercent;

  const PerformanceMetrics({
    required this.periodStart,
    required this.periodEnd,
    required this.periodDays,
    required this.avgBirdsCount,
    required this.totalMortality,
    required this.avgMortalityRatePercent,
    required this.totalOutput,
    required this.avgDailyOutput,
    required this.avgOutputPerBird,
    required this.outputConsistencyScore,
    required this.totalFeedKg,
    required this.avgDailyFeedKg,
    required this.avgFeedPerBird,
    required this.avgFeedConversionRatio,
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.avgProfitMarginPercent,
    required this.avgProfitPerBird,
    required this.avgCostPerUnit,
    required this.avgIncomePerUnit,
    required this.avgFeedCostPercent,
    required this.outputTrend,
    required this.feedEfficiencyTrend,
    required this.profitTrend,
    required this.mortalityTrend,
    this.outputVsPreviousPeriodPercent,
    this.profitVsPreviousPeriodPercent,
    this.feedEfficiencyVsPreviousPeriodPercent,
    this.mortalityVsPreviousPeriodPercent,
    this.outputVsBaselinePercent,
    this.feedVsBaselinePercent,
    this.profitMarginVsBaselinePercent,
    this.mortalityVsBaselinePercent,
  });

  Map<String, dynamic> toJson() => {
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'periodDays': periodDays,
        'avgBirdsCount': avgBirdsCount,
        'totalMortality': totalMortality,
        'avgMortalityRatePercent': avgMortalityRatePercent,
        'totalOutput': totalOutput,
        'avgDailyOutput': avgDailyOutput,
        'avgOutputPerBird': avgOutputPerBird,
        'outputConsistencyScore': outputConsistencyScore,
        'totalFeedKg': totalFeedKg,
        'avgDailyFeedKg': avgDailyFeedKg,
        'avgFeedPerBird': avgFeedPerBird,
        'avgFeedConversionRatio': avgFeedConversionRatio,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netProfit': netProfit,
        'avgProfitMarginPercent': avgProfitMarginPercent,
        'avgProfitPerBird': avgProfitPerBird,
        'avgCostPerUnit': avgCostPerUnit,
        'avgIncomePerUnit': avgIncomePerUnit,
        'avgFeedCostPercent': avgFeedCostPercent,
        'outputTrend': outputTrend.name,
        'feedEfficiencyTrend': feedEfficiencyTrend.name,
        'profitTrend': profitTrend.name,
        'mortalityTrend': mortalityTrend.name,
        'outputVsPreviousPeriodPercent': outputVsPreviousPeriodPercent,
        'profitVsPreviousPeriodPercent': profitVsPreviousPeriodPercent,
        'feedEfficiencyVsPreviousPeriodPercent':
            feedEfficiencyVsPreviousPeriodPercent,
        'mortalityVsPreviousPeriodPercent': mortalityVsPreviousPeriodPercent,
        'outputVsBaselinePercent': outputVsBaselinePercent,
        'feedVsBaselinePercent': feedVsBaselinePercent,
        'profitMarginVsBaselinePercent': profitMarginVsBaselinePercent,
        'mortalityVsBaselinePercent': mortalityVsBaselinePercent,
      };
}

/// Overall performance score for the analysis period
class OverallScore {
  /// Composite score from 0-100
  final double score;

  /// Derived label (Good, Excellent, Needs Improvement, etc.)
  final PerformanceLabel label;

  /// Sub-scores by category (0-100 each)
  final double feedScore;
  final double productionScore;
  final double financialScore;
  final double healthScore;

  const OverallScore({
    required this.score,
    required this.label,
    required this.feedScore,
    required this.productionScore,
    required this.financialScore,
    required this.healthScore,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'label': label.name,
        'feedScore': feedScore,
        'productionScore': productionScore,
        'financialScore': financialScore,
        'healthScore': healthScore,
      };
}
