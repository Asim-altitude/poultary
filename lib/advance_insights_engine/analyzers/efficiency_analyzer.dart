import '../models/farm_record.dart';
import '../models/baseline.dart';
import '../models/insight.dart';
import '../models/enums.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

/// Analyzes feed efficiency and generates feed-related insights.
/// All comparisons are relative to the user's own historical baseline.
class FeedEfficiencyAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> periodRecords,
    required Baseline baseline,
    required String currencySymbol,
  }) {
    if (periodRecords.isEmpty || !baseline.hasSufficientData) return [];

    final insights = <Insight>[];

    insights.addAll(_analyzeFeedPerBirdTrend(periodRecords, baseline));
    insights.addAll(_analyzeFeedConversionRatio(periodRecords, baseline));
    insights.addAll(_analyzeFeedCostPercent(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeFeedCostTrend(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeHalfPeriodComparison(periodRecords, baseline, currencySymbol));

    return insights;
  }

  // ─── Feed per bird trend ─────────────────────────────────────────

  List<Insight> _analyzeFeedPerBirdTrend(
      List<FarmRecord> records, Baseline baseline) {
    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final feedValues = sorted.map((r) => r.feedPerBird).toList();
    final currentAvg = InsightsMathUtils.mean(feedValues);
    final baselineAvg = baseline.feedPerBird.mean;

    if (baselineAvg == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineAvg, currentAvg);

    // Lower feed per bird = better efficiency
    if (changePercent <= -8) {
      return [
        Insight(
          id: 'feed_per_bird_improved',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.positive,
          titleKey: 'insight_feed_per_bird_improved_title',
          descriptionKey: 'insight_feed_per_bird_improved_desc',
          titleNamedArgs: {
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentAvg.toStringAsFixed(3),
            'baseline': baselineAvg.toStringAsFixed(3),
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'currentFeedPerBird': currentAvg,
            'baselineFeedPerBird': baselineAvg,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_feed_per_bird_improved_rec',
          impactScore: 78,
          focusTags: [FocusTag.feedEfficiency, FocusTag.all],
        )
      ];
    } else if (changePercent >= 10) {
      return [
        Insight(
          id: 'feed_per_bird_increased',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.warning,
          titleKey: 'insight_feed_per_bird_increased_title',
          descriptionKey: 'insight_feed_per_bird_increased_desc',
          titleNamedArgs: {
            'percent': changePercent.toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentAvg.toStringAsFixed(3),
            'baseline': baselineAvg.toStringAsFixed(3),
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'currentFeedPerBird': currentAvg,
            'baselineFeedPerBird': baselineAvg,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_feed_per_bird_increased_rec',
          impactScore: 72,
          focusTags: [FocusTag.feedEfficiency, FocusTag.all],
        )
      ];
    }

    return [
      Insight(
        id: 'feed_per_bird_stable',
        category: InsightCategory.feedEfficiency,
        severity: InsightSeverity.neutral,
        titleKey: 'insight_feed_stable_title',
        descriptionKey: 'insight_feed_stable_desc',
        descriptionNamedArgs: {
          'current': currentAvg.toStringAsFixed(3),
        },
        metrics: {
          'currentFeedPerBird': currentAvg,
          'changePercent': changePercent,
        },
        impactScore: 40,
        focusTags: [FocusTag.feedEfficiency],
      )
    ];
  }

  // ─── Feed conversion ratio ───────────────────────────────────────

  List<Insight> _analyzeFeedConversionRatio(
      List<FarmRecord> records, Baseline baseline) {
    final validRecords =
        records.where((r) => r.outputCount > 0 && r.feedConsumedKg > 0);
    if (validRecords.isEmpty) return [];

    final fcrValues =
        validRecords.map((r) => r.feedConversionRatio).toList();
    final currentFcr = InsightsMathUtils.mean(fcrValues);
    final baselineFcr = baseline.feedConversionRatio.mean;

    if (baselineFcr == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineFcr, currentFcr);

    if (changePercent <= -8) {
      return [
        Insight(
          id: 'fcr_improved',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.positive,
          titleKey: 'insight_fcr_improved_title',
          descriptionKey: 'insight_fcr_improved_desc',
          titleNamedArgs: {
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentFcr.toStringAsFixed(2),
            'baseline': baselineFcr.toStringAsFixed(2),
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'currentFcr': currentFcr,
            'baselineFcr': baselineFcr,
            'changePercent': changePercent,
          },
          impactScore: 82,
          focusTags: [FocusTag.feedEfficiency, FocusTag.all],
        )
      ];
    } else if (changePercent >= 10) {
      return [
        Insight(
          id: 'fcr_worsened',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.warning,
          titleKey: 'insight_fcr_worsened_title',
          descriptionKey: 'insight_fcr_worsened_desc',
          titleNamedArgs: {
            'percent': changePercent.toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentFcr.toStringAsFixed(2),
            'baseline': baselineFcr.toStringAsFixed(2),
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'currentFcr': currentFcr,
            'baselineFcr': baselineFcr,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_fcr_worsened_rec',
          impactScore: 75,
          focusTags: [FocusTag.feedEfficiency, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Feed cost as % of total expenses ───────────────────────────

  List<Insight> _analyzeFeedCostPercent(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final withBreakdown =
        records.where((r) => r.expenseBreakdown != null).toList();
    if (withBreakdown.isEmpty) return [];

    final feedCostPercents = withBreakdown
        .where((r) => r.totalExpense > 0)
        .map((r) => r.expenseBreakdown!.feedPercent)
        .toList();

    if (feedCostPercents.isEmpty) return [];

    final avgFeedPercent = InsightsMathUtils.mean(feedCostPercents);

    if (avgFeedPercent > 75) {
      return [
        Insight(
          id: 'feed_cost_high_percent',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.warning,
          titleKey: 'insight_feed_cost_high_percent_title',
          descriptionKey: 'insight_feed_cost_high_percent_desc',
          titleNamedArgs: {'percent': avgFeedPercent.toStringAsFixed(0)},
          descriptionNamedArgs: {'percent': avgFeedPercent.toStringAsFixed(1)},
          metrics: {
            'feedCostPercent': avgFeedPercent,
          },
          recommendationKey: 'insight_feed_cost_high_percent_rec',
          impactScore: 65,
          focusTags: [FocusTag.feedEfficiency, FocusTag.financialPerformance],
        )
      ];
    }
    return [];
  }

  // ─── Feed cost per kg trend ──────────────────────────────────────

  List<Insight> _analyzeFeedCostTrend(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    if (baseline.avgFeedCostPerKg == 0) return [];

    final withBreakdown = records
        .where((r) =>
            r.expenseBreakdown != null &&
            r.feedConsumedKg > 0 &&
            r.expenseBreakdown!.feedCost > 0)
        .toList();
    if (withBreakdown.isEmpty) return [];

    final recentCostPerKg = InsightsMathUtils.mean(withBreakdown
        .map((r) => r.expenseBreakdown!.feedCost / r.feedConsumedKg)
        .toList());

    final changePercent = InsightsMathUtils.percentChange(
        baseline.avgFeedCostPerKg, recentCostPerKg);

    if (changePercent >= 12) {
      return [
        Insight(
          id: 'feed_cost_per_kg_rising',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.warning,
          titleKey: 'insight_feed_cost_rising_title',
          descriptionKey: 'insight_feed_cost_rising_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': '$currencySymbol${recentCostPerKg.toStringAsFixed(2)}',
            'baseline': '$currencySymbol${baseline.avgFeedCostPerKg.toStringAsFixed(2)}',
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'recentCostPerKg': recentCostPerKg,
            'baselineCostPerKg': baseline.avgFeedCostPerKg,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_feed_cost_rising_rec',
          impactScore: 70,
          focusTags: [FocusTag.feedEfficiency, FocusTag.financialPerformance],
        )
      ];
    }
    return [];
  }

  // ─── Half-period comparison ──────────────────────────────────────

  List<Insight> _analyzeHalfPeriodComparison(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    if (records.length < 10) return [];

    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final halves = InsightsDateUtils.splitInHalf(sorted);

    final firstHalfFeed = InsightsMathUtils.mean(
        halves.first.map((r) => r.feedPerBird).toList());
    final secondHalfFeed = InsightsMathUtils.mean(
        halves.second.map((r) => r.feedPerBird).toList());

    if (firstHalfFeed == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(firstHalfFeed, secondHalfFeed);

    if (changePercent <= -10) {
      return [
        Insight(
          id: 'feed_half_period_improved',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.positive,
          titleKey: 'insight_feed_half_period_improved_title',
          descriptionKey: 'insight_feed_half_period_improved_desc',
          titleNamedArgs: {'percent': changePercent.abs().toStringAsFixed(1)},
          descriptionNamedArgs: {
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'firstHalfFeed': firstHalfFeed,
            'secondHalfFeed': secondHalfFeed,
            'changePercent': changePercent,
          },
          impactScore: 60,
          focusTags: [FocusTag.feedEfficiency],
        )
      ];
    } else if (changePercent >= 10) {
      return [
        Insight(
          id: 'feed_half_period_declined',
          category: InsightCategory.feedEfficiency,
          severity: InsightSeverity.warning,
          titleKey: 'insight_feed_half_period_declined_title',
          descriptionKey: 'insight_feed_half_period_declined_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'firstHalfFeed': firstHalfFeed,
            'secondHalfFeed': secondHalfFeed,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_feed_half_period_declined_rec',
          impactScore: 62,
          focusTags: [FocusTag.feedEfficiency],
        )
      ];
    }

    return [];
  }
}
