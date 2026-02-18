import '../models/farm_record.dart';
import '../models/baseline.dart';
import '../models/insight.dart';
import '../models/enums.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

/// Analyzes production output trends and generates related insights.
class TrendAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> periodRecords,
    required Baseline baseline,
    required String outputUnitKey,
  }) {
    if (periodRecords.isEmpty || !baseline.hasSufficientData) return [];

    final insights = <Insight>[];

    insights.addAll(_analyzeOutputVsBaseline(periodRecords, baseline, outputUnitKey));
    insights.addAll(_analyzeOutputTrend(periodRecords, baseline, outputUnitKey));
    insights.addAll(_analyzeConsistency(periodRecords, baseline, outputUnitKey));
    insights.addAll(_analyzeHalfPeriodComparison(periodRecords, baseline, outputUnitKey));
    insights.addAll(_analyzeOutputPerBirdTrend(periodRecords, baseline, outputUnitKey));

    return insights;
  }

  // ─── Current vs baseline output ─────────────────────────────────

  List<Insight> _analyzeOutputVsBaseline(
    List<FarmRecord> records,
    Baseline baseline,
    String outputUnitKey,
  ) {
    final currentAvgOutput = InsightsMathUtils.mean(
        records.map((r) => r.outputPerBird).toList());
    final baselineAvg = baseline.outputPerBird.mean;
    if (baselineAvg == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineAvg, currentAvgOutput);

    if (changePercent >= 10) {
      return [
        Insight(
          id: 'output_above_baseline',
          category: InsightCategory.production,
          severity: InsightSeverity.positive,
          titleKey: 'insight_output_above_baseline_title',
          descriptionKey: 'insight_output_above_baseline_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': currentAvgOutput.toStringAsFixed(2),
            'baseline': baselineAvg.toStringAsFixed(2),
            'percent': changePercent.toStringAsFixed(1),
            'unit': outputUnitKey,
          },
          metrics: {
            'currentOutputPerBird': currentAvgOutput,
            'baselineOutputPerBird': baselineAvg,
            'changePercent': changePercent,
          },
          impactScore: 85,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    } else if (changePercent <= -10) {
      return [
        Insight(
          id: 'output_below_baseline',
          category: InsightCategory.production,
          severity: changePercent <= -20
              ? InsightSeverity.critical
              : InsightSeverity.warning,
          titleKey: 'insight_output_below_baseline_title',
          descriptionKey: 'insight_output_below_baseline_desc',
          titleNamedArgs: {'percent': changePercent.abs().toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': currentAvgOutput.toStringAsFixed(2),
            'baseline': baselineAvg.toStringAsFixed(2),
            'percent': changePercent.abs().toStringAsFixed(1),
            'unit': outputUnitKey,
          },
          metrics: {
            'currentOutputPerBird': currentAvgOutput,
            'baselineOutputPerBird': baselineAvg,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_output_below_baseline_rec',
          impactScore: changePercent <= -20 ? 92 : 78,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    }

    return [
      Insight(
        id: 'output_at_baseline',
        category: InsightCategory.production,
        severity: InsightSeverity.neutral,
        titleKey: 'insight_output_stable_title',
        descriptionKey: 'insight_output_stable_desc',
        descriptionNamedArgs: {
          'current': currentAvgOutput.toStringAsFixed(2),
          'unit': outputUnitKey,
        },
        metrics: {
          'currentOutputPerBird': currentAvgOutput,
          'changePercent': changePercent,
        },
        impactScore: 35,
        focusTags: [FocusTag.eggProduction],
      )
    ];
  }

  // ─── Output trend within the period ─────────────────────────────

  List<Insight> _analyzeOutputTrend(
    List<FarmRecord> records,
    Baseline baseline,
    String outputUnitKey,
  ) {
    if (records.length < 7) return [];

    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final values = sorted.map((r) => r.outputPerBird).toList();
    final trend = InsightsMathUtils.classifyTrend(values);

    if (trend.insufficient) return [];

    if (trend.isImproving && trend.isStrong) {
      return [
        Insight(
          id: 'output_strongly_improving',
          category: InsightCategory.production,
          severity: InsightSeverity.positive,
          titleKey: 'insight_output_strongly_improving_title',
          descriptionKey: 'insight_output_strongly_improving_desc',
          descriptionNamedArgs: {
            'percent': (trend.percentChangePerStep * records.length)
                .abs()
                .toStringAsFixed(1),
          },
          metrics: {
            'slopePercent': trend.slopePercent,
          },
          impactScore: 80,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    }

    if (!trend.isImproving && trend.isStrong) {
      return [
        Insight(
          id: 'output_strongly_declining',
          category: InsightCategory.production,
          severity: InsightSeverity.warning,
          titleKey: 'insight_output_strongly_declining_title',
          descriptionKey: 'insight_output_strongly_declining_desc',
          descriptionNamedArgs: {
            'percent': (trend.percentChangePerStep * records.length)
                .abs()
                .toStringAsFixed(1),
          },
          metrics: {'slopePercent': trend.slopePercent},
          recommendationKey: 'insight_output_declining_rec',
          impactScore: 82,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Output consistency ──────────────────────────────────────────

  List<Insight> _analyzeConsistency(
    List<FarmRecord> records,
    Baseline baseline,
    String outputUnitKey,
  ) {
    if (records.length < 7) return [];

    final values = records.map((r) => r.outputPerBird).toList();
    final consistencyScore = InsightsMathUtils.consistencyScore(values);
    final cv = InsightsMathUtils.coefficientOfVariation(values);

    if (consistencyScore >= 85) {
      return [
        Insight(
          id: 'output_very_consistent',
          category: InsightCategory.production,
          severity: InsightSeverity.positive,
          titleKey: 'insight_output_consistent_title',
          descriptionKey: 'insight_output_consistent_desc',
          descriptionNamedArgs: {
            'score': consistencyScore.toStringAsFixed(0),
          },
          metrics: {
            'consistencyScore': consistencyScore,
            'cv': cv,
          },
          impactScore: 65,
          focusTags: [FocusTag.eggProduction],
        )
      ];
    } else if (consistencyScore < 50) {
      return [
        Insight(
          id: 'output_inconsistent',
          category: InsightCategory.production,
          severity: InsightSeverity.warning,
          titleKey: 'insight_output_inconsistent_title',
          descriptionKey: 'insight_output_inconsistent_desc',
          descriptionNamedArgs: {
            'cv': cv.toStringAsFixed(1),
          },
          metrics: {
            'consistencyScore': consistencyScore,
            'cv': cv,
          },
          recommendationKey: 'insight_output_inconsistent_rec',
          impactScore: 68,
          focusTags: [FocusTag.eggProduction, FocusTag.flockHealth],
        )
      ];
    }

    return [];
  }

  // ─── Half-period output comparison ──────────────────────────────

  List<Insight> _analyzeHalfPeriodComparison(
    List<FarmRecord> records,
    Baseline baseline,
    String outputUnitKey,
  ) {
    if (records.length < 10) return [];

    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final halves = InsightsDateUtils.splitInHalf(sorted);

    final firstHalf = InsightsMathUtils.mean(
        halves.first.map((r) => r.outputPerBird).toList());
    final secondHalf = InsightsMathUtils.mean(
        halves.second.map((r) => r.outputPerBird).toList());

    if (firstHalf == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(firstHalf, secondHalf);

    if (changePercent >= 8) {
      return [
        Insight(
          id: 'output_second_half_better',
          category: InsightCategory.production,
          severity: InsightSeverity.positive,
          titleKey: 'insight_output_second_half_better_title',
          descriptionKey: 'insight_output_second_half_better_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'firstHalf': firstHalf,
            'secondHalf': secondHalf,
            'changePercent': changePercent,
          },
          impactScore: 55,
          focusTags: [FocusTag.eggProduction],
        )
      ];
    } else if (changePercent <= -8) {
      return [
        Insight(
          id: 'output_second_half_worse',
          category: InsightCategory.production,
          severity: InsightSeverity.warning,
          titleKey: 'insight_output_second_half_worse_title',
          descriptionKey: 'insight_output_second_half_worse_desc',
          titleNamedArgs: {'percent': changePercent.abs().toStringAsFixed(1)},
          descriptionNamedArgs: {
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'firstHalf': firstHalf,
            'secondHalf': secondHalf,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_output_second_half_worse_rec',
          impactScore: 60,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Output per bird trend ───────────────────────────────────────

  List<Insight> _analyzeOutputPerBirdTrend(
    List<FarmRecord> records,
    Baseline baseline,
    String outputUnitKey,
  ) {
    final currentAvgPerBird = InsightsMathUtils.mean(
        records.map((r) => r.outputPerBird).toList());
    final recentAvgPerBird = baseline.recentOutputPerBird;

    if (recentAvgPerBird == 0 || currentAvgPerBird == 0) return [];

    // Only fire if significantly different from very recent baseline
    final changePercent =
        InsightsMathUtils.percentChange(recentAvgPerBird, currentAvgPerBird);

    if (changePercent >= 12) {
      return [
        Insight(
          id: 'output_per_bird_up',
          category: InsightCategory.production,
          severity: InsightSeverity.positive,
          titleKey: 'insight_output_per_bird_up_title',
          descriptionKey: 'insight_output_per_bird_up_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': currentAvgPerBird.toStringAsFixed(2),
            'baseline': recentAvgPerBird.toStringAsFixed(2),
            'percent': changePercent.toStringAsFixed(1),
            'unit': outputUnitKey,
          },
          metrics: {
            'currentAvgPerBird': currentAvgPerBird,
            'recentBaseline': recentAvgPerBird,
            'changePercent': changePercent,
          },
          impactScore: 70,
          focusTags: [FocusTag.eggProduction, FocusTag.all],
        )
      ];
    }

    return [];
  }
}
