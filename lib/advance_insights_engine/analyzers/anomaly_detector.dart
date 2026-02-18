import '../models/farm_record.dart';
import '../models/baseline.dart';
import '../models/insight.dart';
import '../models/enums.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

// ════════════════════════════════════════════════════════════════
//  HEALTH ANALYZER
// ════════════════════════════════════════════════════════════════

/// Analyzes flock health indicators from mortality and production patterns.
class HealthAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> periodRecords,
    required Baseline baseline,
  }) {
    if (periodRecords.isEmpty || !baseline.hasSufficientData) return [];

    final insights = <Insight>[];
    insights.addAll(_analyzeMortalityVsBaseline(periodRecords, baseline));
    insights.addAll(_analyzeMortalityTrend(periodRecords, baseline));
    insights.addAll(_analyzeHealthScore(periodRecords, baseline));
    return insights;
  }

  List<Insight> _analyzeMortalityVsBaseline(
      List<FarmRecord> records, Baseline baseline) {
    final currentMortality = InsightsMathUtils.mean(
        records.map((r) => r.mortalityRate).toList());
    final baselineMortality = baseline.mortalityRate.mean;

    if (baselineMortality == 0 && currentMortality == 0) {
      return [
        Insight(
          id: 'zero_mortality',
          category: InsightCategory.health,
          severity: InsightSeverity.positive,
          titleKey: 'insight_zero_mortality_title',
          descriptionKey: 'insight_zero_mortality_desc',
          impactScore: 72,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }

    if (baselineMortality == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineMortality, currentMortality);

    if (changePercent >= 100) {
      // Doubled or more
      return [
        Insight(
          id: 'mortality_spike',
          category: InsightCategory.health,
          severity: InsightSeverity.critical,
          titleKey: 'insight_mortality_spike_title',
          descriptionKey: 'insight_mortality_spike_desc',
          titleNamedArgs: {'times': (currentMortality / baselineMortality).toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': currentMortality.toStringAsFixed(2),
            'baseline': baselineMortality.toStringAsFixed(2),
            'times': (currentMortality / baselineMortality).toStringAsFixed(1),
          },
          metrics: {
            'currentMortality': currentMortality,
            'baselineMortality': baselineMortality,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_mortality_spike_rec',
          impactScore: 98,
          isAnomaly: true,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    } else if (changePercent >= 40) {
      return [
        Insight(
          id: 'mortality_elevated',
          category: InsightCategory.health,
          severity: InsightSeverity.warning,
          titleKey: 'insight_mortality_elevated_title',
          descriptionKey: 'insight_mortality_elevated_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(0)},
          descriptionNamedArgs: {
            'current': currentMortality.toStringAsFixed(2),
            'baseline': baselineMortality.toStringAsFixed(2),
            'percent': changePercent.toStringAsFixed(0),
          },
          metrics: {
            'currentMortality': currentMortality,
            'baselineMortality': baselineMortality,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_mortality_elevated_rec',
          impactScore: 82,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    } else if (changePercent <= -30) {
      return [
        Insight(
          id: 'mortality_improved',
          category: InsightCategory.health,
          severity: InsightSeverity.positive,
          titleKey: 'insight_mortality_improved_title',
          descriptionKey: 'insight_mortality_improved_desc',
          titleNamedArgs: {'percent': changePercent.abs().toStringAsFixed(0)},
          descriptionNamedArgs: {
            'current': currentMortality.toStringAsFixed(2),
            'baseline': baselineMortality.toStringAsFixed(2),
            'percent': changePercent.abs().toStringAsFixed(0),
          },
          metrics: {
            'currentMortality': currentMortality,
            'baselineMortality': baselineMortality,
            'changePercent': changePercent,
          },
          impactScore: 75,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }
    return [];
  }

  List<Insight> _analyzeMortalityTrend(
      List<FarmRecord> records, Baseline baseline) {
    if (records.length < 7) return [];

    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final values = sorted.map((r) => r.mortalityRate).toList();
    final trend = InsightsMathUtils.classifyTrend(values);

    if (!trend.insufficient && !trend.isImproving && trend.isStrong) {
      return [
        Insight(
          id: 'mortality_trending_up',
          category: InsightCategory.health,
          severity: InsightSeverity.warning,
          titleKey: 'insight_mortality_trending_up_title',
          descriptionKey: 'insight_mortality_trending_up_desc',
          metrics: {'slopePercent': trend.slopePercent},
          recommendationKey: 'insight_mortality_trending_up_rec',
          impactScore: 85,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }
    return [];
  }

  List<Insight> _analyzeHealthScore(
      List<FarmRecord> records, Baseline baseline) {
    // Composite: low mortality + consistent output + stable feed = good health
    final currentMortality = InsightsMathUtils.mean(
        records.map((r) => r.mortalityRate).toList());
    final outputConsistency = InsightsMathUtils.consistencyScore(
        records.map((r) => r.outputPerBird).toList());

    final mortalityScore =
        (100 - (currentMortality * 20)).clamp(0, 100).toDouble();
    final healthScore =
        InsightsMathUtils.clampScore((mortalityScore + outputConsistency) / 2);

    if (healthScore >= 80) {
      return [
        Insight(
          id: 'flock_health_excellent',
          category: InsightCategory.health,
          severity: InsightSeverity.positive,
          titleKey: 'insight_flock_health_excellent_title',
          descriptionKey: 'insight_flock_health_excellent_desc',
          descriptionNamedArgs: {
            'score': healthScore.toStringAsFixed(0),
          },
          metrics: {'healthScore': healthScore},
          impactScore: 60,
          focusTags: [FocusTag.flockHealth],
        )
      ];
    }
    return [];
  }
}

// ════════════════════════════════════════════════════════════════
//  ANOMALY DETECTOR
// ════════════════════════════════════════════════════════════════

/// Detects statistical anomalies in recent data compared to baseline.
class AnomalyDetector {
  List<Insight> detect({
    required List<FarmRecord> allRecords,
    required Baseline baseline,
  }) {
    if (allRecords.isEmpty || !baseline.hasSufficientData) return [];

    final insights = <Insight>[];
    final recent7 =
        InsightsDateUtils.lastNDays(allRecords, (r) => r.date, 7);

    if (recent7.isEmpty) return [];

    insights.addAll(_detectOutputAnomaly(recent7, baseline));
    insights.addAll(_detectFeedAnomaly(recent7, baseline));
    insights.addAll(_detectMortalityAnomaly(recent7, baseline));

    return insights;
  }

  List<Insight> _detectOutputAnomaly(
      List<FarmRecord> recent, Baseline baseline) {
    if (recent.isEmpty) return [];

    final avgOutput = InsightsMathUtils.mean(
        recent.map((r) => r.outputPerBird).toList());
    final deviation = baseline.outputPerBird.deviationFrom(avgOutput);

    if (deviation <= -2.0) {
      return [
        Insight(
          id: 'output_anomaly_low',
          category: InsightCategory.anomaly,
          severity: InsightSeverity.critical,
          titleKey: 'insight_output_anomaly_low_title',
          descriptionKey: 'insight_output_anomaly_low_desc',
          descriptionNamedArgs: {
            'current': avgOutput.toStringAsFixed(2),
            'normal': baseline.outputPerBird.mean.toStringAsFixed(2),
          },
          metrics: {
            'recentAvgOutput': avgOutput,
            'baselineMean': baseline.outputPerBird.mean,
            'deviations': deviation,
          },
          recommendationKey: 'insight_output_anomaly_rec',
          impactScore: 95,
          isAnomaly: true,
          focusTags: [FocusTag.eggProduction, FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }
    return [];
  }

  List<Insight> _detectFeedAnomaly(
      List<FarmRecord> recent, Baseline baseline) {
    if (recent.isEmpty) return [];

    final avgFeed = InsightsMathUtils.mean(
        recent.map((r) => r.feedPerBird).toList());
    final deviation = baseline.feedPerBird.deviationFrom(avgFeed);

    if (deviation >= 2.0) {
      return [
        Insight(
          id: 'feed_anomaly_high',
          category: InsightCategory.anomaly,
          severity: InsightSeverity.warning,
          titleKey: 'insight_feed_anomaly_high_title',
          descriptionKey: 'insight_feed_anomaly_high_desc',
          descriptionNamedArgs: {
            'current': avgFeed.toStringAsFixed(3),
            'normal': baseline.feedPerBird.mean.toStringAsFixed(3),
          },
          metrics: {
            'recentAvgFeed': avgFeed,
            'baselineMean': baseline.feedPerBird.mean,
            'deviations': deviation,
          },
          recommendationKey: 'insight_feed_anomaly_rec',
          impactScore: 75,
          isAnomaly: true,
          focusTags: [FocusTag.feedEfficiency, FocusTag.all],
        )
      ];
    }
    return [];
  }

  List<Insight> _detectMortalityAnomaly(
      List<FarmRecord> recent, Baseline baseline) {
    if (recent.isEmpty) return [];

    final avgMortality = InsightsMathUtils.mean(
        recent.map((r) => r.mortalityRate).toList());

    if (baseline.mortalityRate.mean == 0 && avgMortality > 0.5) {
      return [
        Insight(
          id: 'mortality_anomaly_new',
          category: InsightCategory.anomaly,
          severity: InsightSeverity.critical,
          titleKey: 'insight_mortality_anomaly_new_title',
          descriptionKey: 'insight_mortality_anomaly_new_desc',
          descriptionNamedArgs: {
            'current': avgMortality.toStringAsFixed(2),
          },
          metrics: {'recentMortality': avgMortality},
          recommendationKey: 'insight_mortality_anomaly_rec',
          impactScore: 95,
          isAnomaly: true,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }

    final deviation = baseline.mortalityRate.deviationFrom(avgMortality);
    if (deviation >= 2.5) {
      return [
        Insight(
          id: 'mortality_anomaly_spike',
          category: InsightCategory.anomaly,
          severity: InsightSeverity.critical,
          titleKey: 'insight_mortality_anomaly_spike_title',
          descriptionKey: 'insight_mortality_anomaly_spike_desc',
          descriptionNamedArgs: {
            'current': avgMortality.toStringAsFixed(2),
            'normal': baseline.mortalityRate.mean.toStringAsFixed(2),
          },
          metrics: {
            'recentMortality': avgMortality,
            'baselineMean': baseline.mortalityRate.mean,
            'deviations': deviation,
          },
          recommendationKey: 'insight_mortality_anomaly_rec',
          impactScore: 97,
          isAnomaly: true,
          focusTags: [FocusTag.flockHealth, FocusTag.all],
        )
      ];
    }
    return [];
  }
}

// ════════════════════════════════════════════════════════════════
//  SEASONAL ANALYZER
// ════════════════════════════════════════════════════════════════

/// Detects and reports seasonal patterns from the user's own data.
/// Requires 300+ days of data.
class SeasonalAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> allRecords,
    required Baseline baseline,
  }) {
    if (!baseline.hasSeasonalData ||
        baseline.monthlyPatterns.length < 6) return [];

    final insights = <Insight>[];

    insights.addAll(_analyzeSeasonalOutputPattern(baseline));
    insights.addAll(_analyzeSeasonalProfitPattern(baseline));
    insights.addAll(_analyzeSeasonalMortalityPattern(baseline));

    return insights;
  }

  List<Insight> _analyzeSeasonalOutputPattern(Baseline baseline) {
    final patterns = baseline.monthlyPatterns;
    if (patterns.length < 6) return [];

    final avgOutput = InsightsMathUtils.mean(
        patterns.map((p) => p.avgOutputPerBird).toList());

    final bestMonth =
        patterns.reduce((a, b) => a.avgOutputPerBird > b.avgOutputPerBird ? a : b);
    final worstMonth =
        patterns.reduce((a, b) => a.avgOutputPerBird < b.avgOutputPerBird ? a : b);

    final peakDrop = InsightsMathUtils.percentChange(
        bestMonth.avgOutputPerBird, worstMonth.avgOutputPerBird);

    if (peakDrop.abs() >= 15) {
      return [
        Insight(
          id: 'seasonal_output_pattern',
          category: InsightCategory.seasonal,
          severity: InsightSeverity.neutral,
          titleKey: 'insight_seasonal_output_title',
          descriptionKey: 'insight_seasonal_output_desc',
          descriptionNamedArgs: {
            'bestMonth': InsightsDateUtils.formatShort(
                DateTime(2024, bestMonth.month, 1)),
            'worstMonth': InsightsDateUtils.formatShort(
                DateTime(2024, worstMonth.month, 1)),
            'drop': peakDrop.abs().toStringAsFixed(1),
          },
          metrics: {
            'bestMonth': bestMonth.month,
            'worstMonth': worstMonth.month,
            'peakDropPercent': peakDrop,
          },
          recommendationKey: 'insight_seasonal_output_rec',
          impactScore: 70,
          focusTags: [FocusTag.seasonalPatterns, FocusTag.eggProduction],
        )
      ];
    }

    return [];
  }

  List<Insight> _analyzeSeasonalProfitPattern(Baseline baseline) {
    final patterns = baseline.monthlyPatterns;
    if (patterns.length < 6) return [];

    final bestMonth = patterns.reduce(
        (a, b) => a.avgProfitMargin > b.avgProfitMargin ? a : b);
    final worstMonth = patterns.reduce(
        (a, b) => a.avgProfitMargin < b.avgProfitMargin ? a : b);

    final diff = bestMonth.avgProfitMargin - worstMonth.avgProfitMargin;

    if (diff >= 10) {
      return [
        Insight(
          id: 'seasonal_profit_pattern',
          category: InsightCategory.seasonal,
          severity: InsightSeverity.neutral,
          titleKey: 'insight_seasonal_profit_title',
          descriptionKey: 'insight_seasonal_profit_desc',
          descriptionNamedArgs: {
            'bestMonth': InsightsDateUtils.formatShort(
                DateTime(2024, bestMonth.month, 1)),
            'worstMonth': InsightsDateUtils.formatShort(
                DateTime(2024, worstMonth.month, 1)),
            'diff': diff.toStringAsFixed(1),
          },
          metrics: {
            'bestMonth': bestMonth.month,
            'worstMonth': worstMonth.month,
            'marginDiff': diff,
          },
          recommendationKey: 'insight_seasonal_profit_rec',
          impactScore: 65,
          focusTags: [FocusTag.seasonalPatterns, FocusTag.financialPerformance],
        )
      ];
    }
    return [];
  }

  List<Insight> _analyzeSeasonalMortalityPattern(Baseline baseline) {
    final patterns = baseline.monthlyPatterns;
    if (patterns.length < 6) return [];

    final highMortalityMonths = patterns
        .where((p) => p.avgMortalityRate > baseline.mortalityRate.mean * 1.5)
        .toList();

    if (highMortalityMonths.length >= 2) {
      final monthNames = highMortalityMonths
          .map((p) =>
              InsightsDateUtils.formatShort(DateTime(2024, p.month, 1)))
          .join(', ');

      return [
        Insight(
          id: 'seasonal_mortality_pattern',
          category: InsightCategory.seasonal,
          severity: InsightSeverity.warning,
          titleKey: 'insight_seasonal_mortality_title',
          descriptionKey: 'insight_seasonal_mortality_desc',
          descriptionNamedArgs: {
            'months': monthNames,
          },
          metrics: {
            'highMonths': highMortalityMonths.map((p) => p.month).toList(),
          },
          recommendationKey: 'insight_seasonal_mortality_rec',
          impactScore: 72,
          focusTags: [FocusTag.seasonalPatterns, FocusTag.flockHealth],
        )
      ];
    }
    return [];
  }
}

// ════════════════════════════════════════════════════════════════
//  PREDICTIVE ANALYZER
// ════════════════════════════════════════════════════════════════

/// Generates 30-day forecasts based on the user's own trends.
class PredictiveAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> allRecords,
    required Baseline baseline,
  }) {
    if (allRecords.length < 30 || !baseline.canShowTrends) return [];

    final insights = <Insight>[];

    insights.addAll(_forecastOutput(allRecords, baseline));
    insights.addAll(_forecastFeedCosts(allRecords, baseline));
    insights.addAll(_forecastProfit(allRecords, baseline));

    return insights;
  }

  List<Insight> _forecastOutput(
      List<FarmRecord> records, Baseline baseline) {
    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final values = sorted.map((r) => r.outputPerBird).toList();
    final forecast = InsightsMathUtils.forecast(values, 30);

    if (forecast.isEmpty) return [];

    final forecastAvg = InsightsMathUtils.mean(forecast);
    final currentAvg = InsightsMathUtils.mean(values.sublist(
        (values.length * 0.7).toInt()));

    final changePercent =
        InsightsMathUtils.percentChange(currentAvg, forecastAvg);

    if (changePercent <= -10) {
      return [
        Insight(
          id: 'forecast_output_decline',
          category: InsightCategory.prediction,
          severity: InsightSeverity.neutral,
          titleKey: 'insight_forecast_output_decline_title',
          descriptionKey: 'insight_forecast_output_decline_desc',
          descriptionNamedArgs: {
            'percent': changePercent.abs().toStringAsFixed(1),
            'forecast': forecastAvg.toStringAsFixed(2),
          },
          metrics: {
            'forecastOutputPerBird': forecastAvg,
            'currentOutputPerBird': currentAvg,
            'forecastChangePercent': changePercent,
          },
          recommendationKey: 'insight_forecast_output_decline_rec',
          impactScore: 68,
          focusTags: [FocusTag.predictions, FocusTag.eggProduction],
        )
      ];
    } else if (changePercent >= 8) {
      return [
        Insight(
          id: 'forecast_output_increase',
          category: InsightCategory.prediction,
          severity: InsightSeverity.positive,
          titleKey: 'insight_forecast_output_increase_title',
          descriptionKey: 'insight_forecast_output_increase_desc',
          descriptionNamedArgs: {
            'percent': changePercent.toStringAsFixed(1),
            'forecast': forecastAvg.toStringAsFixed(2),
          },
          metrics: {
            'forecastOutputPerBird': forecastAvg,
            'currentOutputPerBird': currentAvg,
            'forecastChangePercent': changePercent,
          },
          impactScore: 60,
          focusTags: [FocusTag.predictions, FocusTag.eggProduction],
        )
      ];
    }

    return [];
  }

  List<Insight> _forecastFeedCosts(
      List<FarmRecord> records, Baseline baseline) {
    final withBreakdown = InsightsDateUtils.sortByDate(
        records.where((r) => r.expenseBreakdown != null).toList(),
        (r) => r.date);
    if (withBreakdown.length < 14) return [];

    final feedCostValues = withBreakdown
        .where((r) => r.feedConsumedKg > 0)
        .map((r) => r.expenseBreakdown!.feedCost / r.feedConsumedKg)
        .toList();

    final trend = InsightsMathUtils.classifyTrend(feedCostValues);

    if (!trend.isImproving && trend.isStrong && !trend.insufficient) {
      return [
        Insight(
          id: 'forecast_feed_cost_rising',
          category: InsightCategory.prediction,
          severity: InsightSeverity.neutral,
          titleKey: 'insight_forecast_feed_rising_title',
          descriptionKey: 'insight_forecast_feed_rising_desc',
          descriptionNamedArgs: {
            'percent': (trend.percentChangePerStep * 30).abs().toStringAsFixed(1),
          },
          metrics: {'feedCostTrendSlope': trend.slopePercent},
          recommendationKey: 'insight_forecast_feed_rising_rec',
          impactScore: 62,
          focusTags: [FocusTag.predictions, FocusTag.feedEfficiency],
        )
      ];
    }
    return [];
  }

  List<Insight> _forecastProfit(
      List<FarmRecord> records, Baseline baseline) {
    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final values = sorted.map((r) => r.profitMargin).toList();
    final trend = InsightsMathUtils.classifyTrend(values);

    if (!trend.isImproving && trend.isStrong && !trend.insufficient) {
      final projectedMargin = InsightsMathUtils.mean(
              values.sublist((values.length * 0.7).toInt())) +
          (trend.slopePercent * values.length * 0.3 * 100);

      return [
        Insight(
          id: 'forecast_profit_declining',
          category: InsightCategory.prediction,
          severity: InsightSeverity.neutral,
          titleKey: 'insight_forecast_profit_declining_title',
          descriptionKey: 'insight_forecast_profit_declining_desc',
          descriptionNamedArgs: {
            'projected': projectedMargin.toStringAsFixed(1),
          },
          metrics: {
            'projectedMargin': projectedMargin,
            'trendSlope': trend.slopePercent,
          },
          recommendationKey: 'insight_forecast_profit_declining_rec',
          impactScore: 70,
          focusTags: [FocusTag.predictions, FocusTag.financialPerformance],
        )
      ];
    }
    return [];
  }
}
