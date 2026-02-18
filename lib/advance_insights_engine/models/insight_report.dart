import 'enums.dart';
import 'insight.dart';
import 'performance_metrics.dart';
import 'baseline.dart';

/// The complete insight report returned by the engine
class InsightReport {
  final String reportId;
  final DateTime generatedAt;
  final TimePeriod period;
  final List<FocusTag> appliedFilters;
  final String birdSpecies; // display name

  /// Core performance metrics for the analysis period
  final PerformanceMetrics metrics;

  /// The user's historical baseline used for comparison
  final Baseline baseline;

  /// Overall composite score
  final OverallScore overallScore;

  // ─── Insights by category ──────────────────────────────────────
  final List<Insight> feedInsights;
  final List<Insight> productionInsights;
  final List<Insight> financialInsights;
  final List<Insight> healthInsights;
  final List<Insight> seasonalInsights;
  final List<Insight> predictiveInsights;
  final List<Insight> anomalyInsights;

  /// Top recommendations sorted by impact score
  final List<Recommendation> topRecommendations;

  /// Alerts requiring attention
  final List<InsightAlert> alerts;

  /// Data readiness status
  final DataReadinessStatus dataReadiness;

  InsightReport({
    required this.reportId,
    required this.generatedAt,
    required this.period,
    required this.appliedFilters,
    required this.birdSpecies,
    required this.metrics,
    required this.baseline,
    required this.overallScore,
    required this.feedInsights,
    required this.productionInsights,
    required this.financialInsights,
    required this.healthInsights,
    required this.seasonalInsights,
    required this.predictiveInsights,
    required this.anomalyInsights,
    required this.topRecommendations,
    required this.alerts,
    required this.dataReadiness,
  });

  /// All insights flattened into one list, sorted by impactScore desc
  List<Insight> get allInsights {
    return [
      ...anomalyInsights,
      ...feedInsights,
      ...productionInsights,
      ...financialInsights,
      ...healthInsights,
      ...seasonalInsights,
      ...predictiveInsights,
    ]..sort((a, b) => b.impactScore.compareTo(a.impactScore));
  }

  /// All critical and warning insights
  List<Insight> get criticalInsights => allInsights
      .where((i) =>
          i.severity == InsightSeverity.critical ||
          i.severity == InsightSeverity.warning)
      .toList();

  /// All positive insights
  List<Insight> get positiveInsights => allInsights
      .where((i) => i.severity == InsightSeverity.positive)
      .toList();

  /// Insights filtered by focus tags
  List<Insight> insightsForFocus(FocusTag tag) {
    if (tag == FocusTag.all) return allInsights;
    return allInsights
        .where((i) => i.focusTags.contains(tag))
        .toList();
  }

  /// Number of urgent alerts
  int get urgentAlertCount =>
      alerts.where((a) => a.requiresImmediateAction).length;

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'generatedAt': generatedAt.toIso8601String(),
        'period': period.name,
        'appliedFilters': appliedFilters.map((e) => e.name).toList(),
        'birdSpecies': birdSpecies,
        'metrics': metrics.toJson(),
        'overallScore': overallScore.toJson(),
        'feedInsights': feedInsights.map((e) => e.toJson()).toList(),
        'productionInsights':
            productionInsights.map((e) => e.toJson()).toList(),
        'financialInsights':
            financialInsights.map((e) => e.toJson()).toList(),
        'healthInsights': healthInsights.map((e) => e.toJson()).toList(),
        'seasonalInsights':
            seasonalInsights.map((e) => e.toJson()).toList(),
        'predictiveInsights':
            predictiveInsights.map((e) => e.toJson()).toList(),
        'anomalyInsights':
            anomalyInsights.map((e) => e.toJson()).toList(),
        'topRecommendations':
            topRecommendations.map((e) => e.toJson()).toList(),
        'alerts': alerts.map((e) => e.toJson()).toList(),
        'dataReadiness': dataReadiness.toJson(),
      };
}

/// Describes how ready the data is for generating full insights
class DataReadinessStatus {
  final int totalDays;
  final bool hasBasicInsights;
  final bool hasTrendInsights;
  final bool hasSeasonalInsights;
  final int daysUntilTrends;
  final int daysUntilSeasonal;
  final ReadinessLevel level;

  const DataReadinessStatus({
    required this.totalDays,
    required this.hasBasicInsights,
    required this.hasTrendInsights,
    required this.hasSeasonalInsights,
    required this.daysUntilTrends,
    required this.daysUntilSeasonal,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        'totalDays': totalDays,
        'hasBasicInsights': hasBasicInsights,
        'hasTrendInsights': hasTrendInsights,
        'hasSeasonalInsights': hasSeasonalInsights,
        'daysUntilTrends': daysUntilTrends,
        'daysUntilSeasonal': daysUntilSeasonal,
        'level': level.name,
      };
}

enum ReadinessLevel {
  insufficient,  // < 14 days
  basic,         // 14-29 days
  developing,    // 30-89 days
  good,          // 90-299 days
  full,          // 300+ days (seasonal available)
}

extension ReadinessLevelExtension on ReadinessLevel {
  String get labelKey {
    switch (this) {
      case ReadinessLevel.insufficient:
        return 'insights_readiness_insufficient';
      case ReadinessLevel.basic:
        return 'insights_readiness_basic';
      case ReadinessLevel.developing:
        return 'insights_readiness_developing';
      case ReadinessLevel.good:
        return 'insights_readiness_good';
      case ReadinessLevel.full:
        return 'insights_readiness_full';
    }
  }
}
