import '../models/farm_record.dart';
import '../models/baseline.dart';
import '../models/enums.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

/// Computes the user's historical baseline from their own farm data.
/// All insights are relative to this baseline — no external benchmarks needed.
class BaselineCalculator {
  /// Compute a comprehensive baseline from all available records.
  /// The more records provided, the richer the baseline.
  Baseline compute(List<FarmRecord> allRecords) {
    if (allRecords.isEmpty) {
      return _emptyBaseline();
    }

    final sorted =
        InsightsDateUtils.sortByDate(allRecords, (r) => r.date);

    final totalDays = sorted.isNotEmpty
        ? sorted.last.date.difference(sorted.first.date).inDays + 1
        : 0;

    final hasSufficient = totalDays >= Baseline.minDaysForBasic;

    // ── Extract daily value lists ────────────────────────────────
    final outputPerBirdValues =
        sorted.map((r) => r.outputPerBird).toList();
    final dailyOutputValues =
        sorted.map((r) => r.outputCount).toList();
    final feedPerBirdValues =
        sorted.map((r) => r.feedPerBird).toList();
    final fcrValues = sorted
        .where((r) => r.outputCount > 0)
        .map((r) => r.feedConversionRatio)
        .toList();
    final profitMarginValues =
        sorted.map((r) => r.profitMargin).toList();
    final profitPerBirdValues =
        sorted.map((r) => r.profitPerBird).toList();
    final costPerUnitValues = sorted
        .where((r) => r.outputCount > 0)
        .map((r) => r.costPerUnit)
        .toList();
    final incomePerUnitValues = sorted
        .where((r) => r.outputCount > 0)
        .map((r) => r.incomePerUnit)
        .toList();
    final mortalityRateValues =
        sorted.map((r) => r.mortalityRate).toList();

    // ── Feed cost per kg (from expense breakdown where available) ─
    final feedCostPerKgValues = sorted
        .where((r) =>
            r.expenseBreakdown != null &&
            r.feedConsumedKg > 0 &&
            r.expenseBreakdown!.feedCost > 0)
        .map((r) => r.expenseBreakdown!.feedCost / r.feedConsumedKg)
        .toList();

    final avgFeedCostPerKg = feedCostPerKgValues.isNotEmpty
        ? InsightsMathUtils.mean(feedCostPerKgValues)
        : 0.0;

    // ── Recent 14-day averages ────────────────────────────────────
    final recent14 = InsightsDateUtils.lastNDays(sorted, (r) => r.date, 14);
    final recentOutputPerBird = recent14.isNotEmpty
        ? InsightsMathUtils.mean(
            recent14.map((r) => r.outputPerBird).toList())
        : (outputPerBirdValues.isNotEmpty
            ? InsightsMathUtils.mean(outputPerBirdValues)
            : 0.0);
    final recentFeedPerBird = recent14.isNotEmpty
        ? InsightsMathUtils.mean(
            recent14.map((r) => r.feedPerBird).toList())
        : (feedPerBirdValues.isNotEmpty
            ? InsightsMathUtils.mean(feedPerBirdValues)
            : 0.0);
    final recentProfitMargin = recent14.isNotEmpty
        ? InsightsMathUtils.mean(
            recent14.map((r) => r.profitMargin).toList())
        : (profitMarginValues.isNotEmpty
            ? InsightsMathUtils.mean(profitMarginValues)
            : 0.0);
    final recentMortality = recent14.isNotEmpty
        ? InsightsMathUtils.mean(
            recent14.map((r) => r.mortalityRate).toList())
        : (mortalityRateValues.isNotEmpty
            ? InsightsMathUtils.mean(mortalityRateValues)
            : 0.0);

    // ── Trend analysis ────────────────────────────────────────────
    final outputTrend = _mapTrend(
        InsightsMathUtils.classifyTrend(outputPerBirdValues));
    // For feed, lower is better → invert direction
    final feedTrendRaw =
        InsightsMathUtils.classifyTrend(feedPerBirdValues);
    final feedEfficiencyTrend = _mapTrend(feedTrendRaw, invertDirection: true);
    final profitTrend =
        _mapTrend(InsightsMathUtils.classifyTrend(profitMarginValues));
    // For mortality, lower is better → invert
    final mortalityTrendRaw =
        InsightsMathUtils.classifyTrend(mortalityRateValues);
    final mortalityTrend =
        _mapTrend(mortalityTrendRaw, invertDirection: true);

    // ── Statistical ranges ────────────────────────────────────────
    StatRange buildRange(List<double> vals) {
      if (vals.isEmpty) return StatRange.zero;
      return StatRange(
        min: vals.reduce((a, b) => a < b ? a : b),
        max: vals.reduce((a, b) => a > b ? a : b),
        mean: InsightsMathUtils.mean(vals),
        stdDev: InsightsMathUtils.stdDev(vals),
        median: InsightsMathUtils.median(vals),
      );
    }

    // ── Seasonal patterns ─────────────────────────────────────────
    final monthlyPatterns = _computeMonthlyPatterns(sorted);
    final hasSeasonalData = totalDays >= Baseline.minDaysForSeasonal;

    // ── Bird counts ───────────────────────────────────────────────
    final birdCounts = sorted.map((r) => r.birdsCount.toDouble()).toList();
    final avgBirds =
        birdCounts.isNotEmpty ? InsightsMathUtils.mean(birdCounts) : 0.0;
    final peakBirds =
        birdCounts.isNotEmpty ? birdCounts.reduce((a, b) => a > b ? a : b) : 0.0;

    return Baseline(
      totalDays: totalDays,
      hasSufficientData: hasSufficient,
      outputPerBird: buildRange(outputPerBirdValues),
      dailyOutput: buildRange(dailyOutputValues),
      outputTrend: outputTrend,
      recentOutputPerBird: recentOutputPerBird,
      feedPerBird: buildRange(feedPerBirdValues),
      feedConversionRatio: buildRange(fcrValues),
      feedEfficiencyTrend: feedEfficiencyTrend,
      recentFeedPerBird: recentFeedPerBird,
      avgFeedCostPerKg: avgFeedCostPerKg,
      profitMargin: buildRange(profitMarginValues),
      profitPerBird: buildRange(profitPerBirdValues),
      costPerUnit: buildRange(costPerUnitValues),
      incomePerUnit: buildRange(incomePerUnitValues),
      profitTrend: profitTrend,
      recentProfitMargin: recentProfitMargin,
      mortalityRate: buildRange(mortalityRateValues),
      mortalityTrend: mortalityTrend,
      recentMortalityRate: recentMortality,
      monthlyPatterns: monthlyPatterns,
      hasSeasonalData: hasSeasonalData,
      avgBirdsCount: avgBirds,
      peakBirdsCount: peakBirds,
      computedAt: DateTime.now(),
      dataStartDate: sorted.isNotEmpty ? sorted.first.date : null,
      dataEndDate: sorted.isNotEmpty ? sorted.last.date : null,
    );
  }

  // ─── Private helpers ────────────────────────────────────────────

  List<MonthlyPattern> _computeMonthlyPatterns(List<FarmRecord> sorted) {
    final byMonth = InsightsDateUtils.groupByMonth(sorted, (r) => r.date);
    final patterns = <MonthlyPattern>[];

    // Aggregate same month across multiple years
    final monthAccumulator = <int, List<FarmRecord>>{};
    for (final entry in byMonth.entries) {
      final month = int.parse(entry.key.split('-')[1]);
      monthAccumulator.putIfAbsent(month, () => []).addAll(entry.value);
    }

    for (int m = 1; m <= 12; m++) {
      final records = monthAccumulator[m];
      if (records == null || records.isEmpty) continue;

      patterns.add(MonthlyPattern(
        month: m,
        avgOutputPerBird: InsightsMathUtils.mean(
            records.map((r) => r.outputPerBird).toList()),
        avgFeedPerBird: InsightsMathUtils.mean(
            records.map((r) => r.feedPerBird).toList()),
        avgProfitMargin: InsightsMathUtils.mean(
            records.map((r) => r.profitMargin).toList()),
        avgMortalityRate: InsightsMathUtils.mean(
            records.map((r) => r.mortalityRate).toList()),
        recordCount: records.length,
      ));
    }

    return patterns;
  }

  TrendDirection _mapTrend(
    TrendClassification classification, {
    bool invertDirection = false,
  }) {
    if (classification.insufficient) return TrendDirection.insufficient;
    if (classification.isStable) return TrendDirection.stable;

    final isImproving = invertDirection
        ? !classification.isImproving
        : classification.isImproving;

    if (isImproving) {
      return classification.isStrong
          ? TrendDirection.stronglyImproving
          : TrendDirection.improving;
    } else {
      return classification.isStrong
          ? TrendDirection.stronglyDeclining
          : TrendDirection.declining;
    }
  }

  Baseline _emptyBaseline() => Baseline(
        totalDays: 0,
        hasSufficientData: false,
        outputPerBird: StatRange.zero,
        dailyOutput: StatRange.zero,
        outputTrend: TrendDirection.insufficient,
        recentOutputPerBird: 0,
        feedPerBird: StatRange.zero,
        feedConversionRatio: StatRange.zero,
        feedEfficiencyTrend: TrendDirection.insufficient,
        recentFeedPerBird: 0,
        avgFeedCostPerKg: 0,
        profitMargin: StatRange.zero,
        profitPerBird: StatRange.zero,
        costPerUnit: StatRange.zero,
        incomePerUnit: StatRange.zero,
        profitTrend: TrendDirection.insufficient,
        recentProfitMargin: 0,
        mortalityRate: StatRange.zero,
        mortalityTrend: TrendDirection.insufficient,
        recentMortalityRate: 0,
        monthlyPatterns: [],
        hasSeasonalData: false,
        avgBirdsCount: 0,
        peakBirdsCount: 0,
        computedAt: DateTime.now(),
      );
}
