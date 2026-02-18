import '../models/farm_record.dart';
import '../models/flock_info.dart';
import '../models/baseline.dart';
import '../models/insight.dart';
import '../models/insight_report.dart';
import '../models/performance_metrics.dart';
import '../models/enums.dart';
import '../analyzers/baseline_calculator.dart';
import '../analyzers/efficiency_analyzer.dart';
import '../analyzers/trend_analyzer.dart';
import '../analyzers/financial_analyzer.dart';
import '../analyzers/health_analyzer.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

/// The main entry point for the Poultry Insights Engine.
///
/// Usage:
/// ```dart
/// final engine = PoultryInsightsEngine();
///
/// final report = await engine.generateReport(
///   allRecords: myFarmRecords,
///   flockInfo: myFlockInfo,
///   period: TimePeriod.last6Months,
///   focusTags: [FocusTag.feedEfficiency, FocusTag.financialPerformance],
/// );
/// ```
class PoultryInsightsEngine {
  // ─── Sub-analyzers ───────────────────────────────────────────────
  final BaselineCalculator _baselineCalculator;
  final FeedEfficiencyAnalyzer _feedAnalyzer;
  final TrendAnalyzer _trendAnalyzer;
  final FinancialAnalyzer _financialAnalyzer;
  final HealthAnalyzer _healthAnalyzer;
  final AnomalyDetector _anomalyDetector;
  final SeasonalAnalyzer _seasonalAnalyzer;
  final PredictiveAnalyzer _predictiveAnalyzer;

  PoultryInsightsEngine({
    BaselineCalculator? baselineCalculator,
    FeedEfficiencyAnalyzer? feedAnalyzer,
    TrendAnalyzer? trendAnalyzer,
    FinancialAnalyzer? financialAnalyzer,
    HealthAnalyzer? healthAnalyzer,
    AnomalyDetector? anomalyDetector,
    SeasonalAnalyzer? seasonalAnalyzer,
    PredictiveAnalyzer? predictiveAnalyzer,
  })  : _baselineCalculator =
            baselineCalculator ?? BaselineCalculator(),
        _feedAnalyzer = feedAnalyzer ?? FeedEfficiencyAnalyzer(),
        _trendAnalyzer = trendAnalyzer ?? TrendAnalyzer(),
        _financialAnalyzer = financialAnalyzer ?? FinancialAnalyzer(),
        _healthAnalyzer = healthAnalyzer ?? HealthAnalyzer(),
        _anomalyDetector = anomalyDetector ?? AnomalyDetector(),
        _seasonalAnalyzer = seasonalAnalyzer ?? SeasonalAnalyzer(),
        _predictiveAnalyzer = predictiveAnalyzer ?? PredictiveAnalyzer();

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  /// Generate a full insight report for the given period and focus.
  ///
  /// [allRecords] — ALL available farm records (used for baseline)
  /// [flockInfo]  — Flock metadata (species, currency, etc.)
  /// [period]     — Analysis window (last 30 days, 3 months, etc.)
  /// [focusTags]  — Which categories to emphasize (or FocusTag.all)
  Future<InsightReport> generateReport({
    required List<FarmRecord> allRecords,
    required FlockInfo flockInfo,
    required TimePeriod period,
    List<FocusTag> focusTags = const [FocusTag.all],
  }) async {
    // Sort all records by date
    final sorted =
        InsightsDateUtils.sortByDate(allRecords, (r) => r.date);

    // Filter by species if records are mixed
    final speciesRecords = sorted
        .where((r) => r.birdSpecies == flockInfo.primarySpecies)
        .toList();
    final effectiveRecords =
        speciesRecords.isNotEmpty ? speciesRecords : sorted;

    // ── Step 1: Build baseline from ALL available records ─────────
    final baseline = _baselineCalculator.compute(effectiveRecords);

    // ── Step 2: Filter records for the analysis period ────────────
    final periodStart = InsightsDateUtils.startDateForPeriod(period);
    final periodEnd = DateTime.now();
    final periodRecords = InsightsDateUtils.filterByDateRange(
        effectiveRecords, (r) => r.date, periodStart, periodEnd);

    // ── Step 3: Compute period metrics ────────────────────────────
    final metrics = _computeMetrics(
        periodRecords, effectiveRecords, baseline, periodStart, periodEnd);

    // ── Step 4: Run all analyzers ─────────────────────────────────
    final outputUnitKey =
        flockInfo.primarySpecies.defaultOutputType.unitKey;

    final feedInsights = _shouldInclude(FocusTag.feedEfficiency, focusTags)
        ? _feedAnalyzer.analyze(
            periodRecords: periodRecords,
            baseline: baseline,
            currencySymbol: flockInfo.currencySymbol,
          )
        : <Insight>[];

    final productionInsights =
        _shouldInclude(FocusTag.eggProduction, focusTags)
            ? _trendAnalyzer.analyze(
                periodRecords: periodRecords,
                baseline: baseline,
                outputUnitKey: outputUnitKey,
              )
            : <Insight>[];

    final financialInsights =
        _shouldInclude(FocusTag.financialPerformance, focusTags)
            ? _financialAnalyzer.analyze(
                periodRecords: periodRecords,
                baseline: baseline,
                currencySymbol: flockInfo.currencySymbol,
              )
            : <Insight>[];

    final healthInsights = _shouldInclude(FocusTag.flockHealth, focusTags)
        ? _healthAnalyzer.analyze(
            periodRecords: periodRecords,
            baseline: baseline,
          )
        : <Insight>[];

    // Anomalies always run (they use recent 7 days vs baseline)
    final anomalyInsights = _anomalyDetector.detect(
      allRecords: effectiveRecords,
      baseline: baseline,
    );

    final seasonalInsights =
        _shouldInclude(FocusTag.seasonalPatterns, focusTags)
            ? _seasonalAnalyzer.analyze(
                allRecords: effectiveRecords,
                baseline: baseline,
              )
            : <Insight>[];

    final predictiveInsights =
        _shouldInclude(FocusTag.predictions, focusTags)
            ? _predictiveAnalyzer.analyze(
                allRecords: effectiveRecords,
                baseline: baseline,
              )
            : <Insight>[];

    // ── Step 5: Compute overall score ─────────────────────────────
    final overallScore = _computeOverallScore(
      metrics: metrics,
      baseline: baseline,
      feedInsights: feedInsights,
      productionInsights: productionInsights,
      financialInsights: financialInsights,
      healthInsights: healthInsights,
    );

    // ── Step 6: Generate recommendations ─────────────────────────
    final allInsights = [
      ...anomalyInsights,
      ...feedInsights,
      ...productionInsights,
      ...financialInsights,
      ...healthInsights,
      ...seasonalInsights,
      ...predictiveInsights,
    ];

    final recommendations = _generateRecommendations(
        allInsights, flockInfo.currencySymbol);

    // ── Step 7: Generate alerts ───────────────────────────────────
    final alerts = _generateAlerts(allInsights);

    // ── Step 8: Data readiness ────────────────────────────────────
    final readiness = _computeReadiness(baseline);

    return InsightReport(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      generatedAt: DateTime.now(),
      period: period,
      appliedFilters: focusTags,
      birdSpecies: flockInfo.primarySpecies.labelKey,
      metrics: metrics,
      baseline: baseline,
      overallScore: overallScore,
      feedInsights: feedInsights,
      productionInsights: productionInsights,
      financialInsights: financialInsights,
      healthInsights: healthInsights,
      seasonalInsights: seasonalInsights,
      predictiveInsights: predictiveInsights,
      anomalyInsights: anomalyInsights,
      topRecommendations: recommendations,
      alerts: alerts,
      dataReadiness: readiness,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BASELINE ONLY (useful for dashboard overview)
  // ═══════════════════════════════════════════════════════════════

  /// Compute and return the user's historical baseline only.
  Baseline computeBaseline(List<FarmRecord> allRecords) {
    return _baselineCalculator.compute(allRecords);
  }

  /// Returns the data readiness status without a full report.
  DataReadinessStatus getReadinessStatus(List<FarmRecord> allRecords) {
    final baseline = _baselineCalculator.compute(allRecords);
    return _computeReadiness(baseline);
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  bool _shouldInclude(FocusTag tag, List<FocusTag> selected) {
    return selected.contains(FocusTag.all) || selected.contains(tag);
  }

  PerformanceMetrics _computeMetrics(
    List<FarmRecord> periodRecords,
    List<FarmRecord> allRecords,
    Baseline baseline,
    DateTime start,
    DateTime end,
  ) {
    if (periodRecords.isEmpty) {
      return PerformanceMetrics(
        periodStart: start,
        periodEnd: end,
        periodDays: end.difference(start).inDays,
        avgBirdsCount: 0,
        totalMortality: 0,
        avgMortalityRatePercent: 0,
        totalOutput: 0,
        avgDailyOutput: 0,
        avgOutputPerBird: 0,
        outputConsistencyScore: 0,
        totalFeedKg: 0,
        avgDailyFeedKg: 0,
        avgFeedPerBird: 0,
        avgFeedConversionRatio: 0,
        totalIncome: 0,
        totalExpense: 0,
        netProfit: 0,
        avgProfitMarginPercent: 0,
        avgProfitPerBird: 0,
        avgCostPerUnit: 0,
        avgIncomePerUnit: 0,
        avgFeedCostPercent: 0,
        outputTrend: TrendDirection.insufficient,
        feedEfficiencyTrend: TrendDirection.insufficient,
        profitTrend: TrendDirection.insufficient,
        mortalityTrend: TrendDirection.insufficient,
      );
    }

    final totalOutput = periodRecords.fold<double>(0, (s, r) => s + r.outputCount);
    final totalFeed = periodRecords.fold<double>(0, (s, r) => s + r.feedConsumedKg);
    final totalIncome = periodRecords.fold<double>(0, (s, r) => s + r.totalIncome);
    final totalExpense = periodRecords.fold<double>(0, (s, r) => s + r.totalExpense);
    final totalMortality = periodRecords.fold<int>(0, (s, r) => s + r.mortalityCount);

    final avgBirds = InsightsMathUtils.mean(
        periodRecords.map((r) => r.birdsCount.toDouble()).toList());
    final avgOutputPerBird = InsightsMathUtils.mean(
        periodRecords.map((r) => r.outputPerBird).toList());
    final avgFeedPerBird = InsightsMathUtils.mean(
        periodRecords.map((r) => r.feedPerBird).toList());
    final avgMortality = InsightsMathUtils.mean(
        periodRecords.map((r) => r.mortalityRate).toList());
    final avgProfitMargin = InsightsMathUtils.mean(
        periodRecords.map((r) => r.profitMargin).toList());
    final avgProfitPerBird = InsightsMathUtils.mean(
        periodRecords.map((r) => r.profitPerBird).toList());

    final validOutputRecords =
        periodRecords.where((r) => r.outputCount > 0).toList();
    final avgCostPerUnit = validOutputRecords.isNotEmpty
        ? InsightsMathUtils.mean(
            validOutputRecords.map((r) => r.costPerUnit).toList())
        : 0.0;
    final avgIncomePerUnit = validOutputRecords.isNotEmpty
        ? InsightsMathUtils.mean(
            validOutputRecords.map((r) => r.incomePerUnit).toList())
        : 0.0;
    final avgFcr = validOutputRecords.isNotEmpty
        ? InsightsMathUtils.mean(
            validOutputRecords.map((r) => r.feedConversionRatio).toList())
        : 0.0;

    final breakdownRecords =
        periodRecords.where((r) => r.expenseBreakdown != null).toList();
    final avgFeedCostPercent = breakdownRecords.isNotEmpty
        ? InsightsMathUtils.mean(
            breakdownRecords.map((r) => r.expenseBreakdown!.feedPercent).toList())
        : 0.0;

    final consistencyScore = InsightsMathUtils.consistencyScore(
        periodRecords.map((r) => r.outputPerBird).toList());

    // Period-over-period comparison
    final prevPeriod = InsightsDateUtils.previousPeriod(
        _durationToPeriod(end.difference(start).inDays));
    final prevRecords = InsightsDateUtils.filterByDateRange(
        allRecords, (r) => r.date, prevPeriod.start, prevPeriod.end);

    double? outputVsPrev, profitVsPrev, feedEffVsPrev, mortalityVsPrev;
    double? outputVsBaseline, feedVsBaseline, profitVsBaseline, mortalityVsBaseline;

    if (prevRecords.isNotEmpty) {
      final prevOutput = InsightsMathUtils.mean(
          prevRecords.map((r) => r.outputPerBird).toList());
      final prevProfit = InsightsMathUtils.mean(
          prevRecords.map((r) => r.profitMargin).toList());
      final prevFeed = InsightsMathUtils.mean(
          prevRecords.map((r) => r.feedPerBird).toList());
      final prevMortality = InsightsMathUtils.mean(
          prevRecords.map((r) => r.mortalityRate).toList());

      outputVsPrev = InsightsMathUtils.percentChange(prevOutput, avgOutputPerBird);
      profitVsPrev = InsightsMathUtils.percentChange(prevProfit, avgProfitMargin);
      feedEffVsPrev = InsightsMathUtils.percentChange(prevFeed, avgFeedPerBird);
      mortalityVsPrev = InsightsMathUtils.percentChange(prevMortality, avgMortality);
    }

    if (baseline.hasSufficientData) {
      outputVsBaseline = InsightsMathUtils.percentChange(
          baseline.outputPerBird.mean, avgOutputPerBird);
      feedVsBaseline = InsightsMathUtils.percentChange(
          baseline.feedPerBird.mean, avgFeedPerBird);
      profitVsBaseline = InsightsMathUtils.percentChange(
          baseline.profitMargin.mean, avgProfitMargin);
      mortalityVsBaseline = InsightsMathUtils.percentChange(
          baseline.mortalityRate.mean, avgMortality);
    }

    return PerformanceMetrics(
      periodStart: start,
      periodEnd: end,
      periodDays: end.difference(start).inDays,
      avgBirdsCount: avgBirds,
      totalMortality: totalMortality,
      avgMortalityRatePercent: avgMortality,
      totalOutput: totalOutput,
      avgDailyOutput: totalOutput / periodRecords.length.toDouble(),
      avgOutputPerBird: avgOutputPerBird,
      outputConsistencyScore: consistencyScore,
      totalFeedKg: totalFeed,
      avgDailyFeedKg: totalFeed / periodRecords.length.toDouble(),
      avgFeedPerBird: avgFeedPerBird,
      avgFeedConversionRatio: avgFcr,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netProfit: totalIncome - totalExpense,
      avgProfitMarginPercent: avgProfitMargin,
      avgProfitPerBird: avgProfitPerBird,
      avgCostPerUnit: avgCostPerUnit,
      avgIncomePerUnit: avgIncomePerUnit,
      avgFeedCostPercent: avgFeedCostPercent,
      outputTrend: baseline.outputTrend,
      feedEfficiencyTrend: baseline.feedEfficiencyTrend,
      profitTrend: baseline.profitTrend,
      mortalityTrend: baseline.mortalityTrend,
      outputVsPreviousPeriodPercent: outputVsPrev,
      profitVsPreviousPeriodPercent: profitVsPrev,
      feedEfficiencyVsPreviousPeriodPercent: feedEffVsPrev,
      mortalityVsPreviousPeriodPercent: mortalityVsPrev,
      outputVsBaselinePercent: outputVsBaseline,
      feedVsBaselinePercent: feedVsBaseline,
      profitMarginVsBaselinePercent: profitVsBaseline,
      mortalityVsBaselinePercent: mortalityVsBaseline,
    );
  }

  OverallScore _computeOverallScore({
    required PerformanceMetrics metrics,
    required Baseline baseline,
    required List<Insight> feedInsights,
    required List<Insight> productionInsights,
    required List<Insight> financialInsights,
    required List<Insight> healthInsights,
  }) {
    if (!baseline.hasSufficientData) {
      return OverallScore(
        score: 0,
        label: PerformanceLabel.insufficient,
        feedScore: 0,
        productionScore: 0,
        financialScore: 0,
        healthScore: 0,
      );
    }

    double _categoryScore(List<Insight> insights) {
      if (insights.isEmpty) return 60.0;
      double score = 60.0;
      for (final insight in insights) {
        switch (insight.severity) {
          case InsightSeverity.positive:
            score += insight.impactScore * 0.2;
            break;
          case InsightSeverity.neutral:
            break;
          case InsightSeverity.warning:
            score -= insight.impactScore * 0.15;
            break;
          case InsightSeverity.critical:
            score -= insight.impactScore * 0.3;
            break;
        }
      }
      return InsightsMathUtils.clampScore(score);
    }

    final feedScore = _categoryScore(feedInsights);
    final productionScore = _categoryScore(productionInsights);
    final financialScore = _categoryScore(financialInsights);
    final healthScore = _categoryScore(healthInsights);

    // Weighted composite
    final composite = (feedScore * 0.25 +
        productionScore * 0.30 +
        financialScore * 0.30 +
        healthScore * 0.15);

    final overall = InsightsMathUtils.clampScore(composite);

    return OverallScore(
      score: overall,
      label: PerformanceLabelExtension.fromScore(overall),
      feedScore: feedScore,
      productionScore: productionScore,
      financialScore: financialScore,
      healthScore: healthScore,
    );
  }

  List<Recommendation> _generateRecommendations(
    List<Insight> allInsights,
    String currencySymbol,
  ) {
    final recommendations = <Recommendation>[];
    final seen = <String>{};

    // Sort by impact (critical first, then by impactScore)
    final sorted = List<Insight>.from(allInsights)
      ..sort((a, b) {
        final severityOrder = {
          InsightSeverity.critical: 0,
          InsightSeverity.warning: 1,
          InsightSeverity.positive: 2,
          InsightSeverity.neutral: 3,
        };
        final sev =
            severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
        if (sev != 0) return sev;
        return b.impactScore.compareTo(a.impactScore);
      });

    for (final insight in sorted) {
      if (insight.recommendationKey == null) continue;
      if (seen.contains(insight.recommendationKey)) continue;
      seen.add(insight.recommendationKey!);

      recommendations.add(Recommendation(
        id: 'rec_${insight.id}',
        titleKey: '${insight.recommendationKey}_title',
        descriptionKey: insight.recommendationKey!,
        descriptionNamedArgs: insight.recommendationNamedArgs,
        impactScore: insight.impactScore,
        category: insight.category,
        relatedInsightIds: [insight.id],
        isUrgent: insight.severity == InsightSeverity.critical,
      ));

      if (recommendations.length >= 5) break;
    }

    return recommendations;
  }

  List<InsightAlert> _generateAlerts(List<Insight> allInsights) {
    return allInsights
        .where((i) =>
            i.severity == InsightSeverity.critical ||
            (i.severity == InsightSeverity.warning && i.isAnomaly))
        .map((i) => InsightAlert(
              id: 'alert_${i.id}',
              severity: i.severity,
              titleKey: i.titleKey,
              titleNamedArgs: i.titleNamedArgs,
              descriptionKey: i.descriptionKey,
              descriptionNamedArgs: i.descriptionNamedArgs,
              category: i.category,
              requiresImmediateAction:
                  i.severity == InsightSeverity.critical,
            ))
        .toList();
  }

  DataReadinessStatus _computeReadiness(Baseline baseline) {
    final days = baseline.totalDays;
    ReadinessLevel level;
    if (days < Baseline.minDaysForBasic) {
      level = ReadinessLevel.insufficient;
    } else if (days < Baseline.minDaysForTrends) {
      level = ReadinessLevel.basic;
    } else if (days < 90) {
      level = ReadinessLevel.developing;
    } else if (days < Baseline.minDaysForSeasonal) {
      level = ReadinessLevel.good;
    } else {
      level = ReadinessLevel.full;
    }

    return DataReadinessStatus(
      totalDays: days,
      hasBasicInsights: days >= Baseline.minDaysForBasic,
      hasTrendInsights: days >= Baseline.minDaysForTrends,
      hasSeasonalInsights: days >= Baseline.minDaysForSeasonal,
      daysUntilTrends: baseline.daysUntilTrends,
      daysUntilSeasonal: baseline.daysUntilSeasonal,
      level: level,
    );
  }

  TimePeriod _durationToPeriod(int days) {
    if (days <= 30) return TimePeriod.last30Days;
    if (days <= 90) return TimePeriod.last3Months;
    if (days <= 180) return TimePeriod.last6Months;
    return TimePeriod.last12Months;
  }
}
