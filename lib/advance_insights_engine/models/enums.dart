/// All enumerations for the Poultry Insights Engine

/// Time period for analysis
enum TimePeriod {
  last30Days,
  last3Months,
  last6Months,
  last12Months,
  thisYear,
}

extension TimePeriodExtension on TimePeriod {
  int get days {
    switch (this) {
      case TimePeriod.last30Days:
        return 30;
      case TimePeriod.last3Months:
        return 90;
      case TimePeriod.last6Months:
        return 180;
      case TimePeriod.last12Months:
        return 365;
      case TimePeriod.thisYear:
        final now = DateTime.now();
        return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    }
  }

  String get labelKey {
    switch (this) {
      case TimePeriod.last30Days:
        return 'insights_period_30_days';
      case TimePeriod.last3Months:
        return 'insights_period_3_months';
      case TimePeriod.last6Months:
        return 'insights_period_6_months';
      case TimePeriod.last12Months:
        return 'insights_period_12_months';
      case TimePeriod.thisYear:
        return 'insights_period_this_year';
    }
  }
}

/// Focus areas for targeted analysis
enum FocusTag {
  all,
  feedEfficiency,
  eggProduction,
  financialPerformance,
  flockHealth,
  seasonalPatterns,
  predictions,
}

extension FocusTagExtension on FocusTag {
  String get labelKey {
    switch (this) {
      case FocusTag.all:
        return 'insights_focus_all';
      case FocusTag.feedEfficiency:
        return 'insights_focus_feed';
      case FocusTag.eggProduction:
        return 'insights_focus_production';
      case FocusTag.financialPerformance:
        return 'insights_focus_financial';
      case FocusTag.flockHealth:
        return 'insights_focus_health';
      case FocusTag.seasonalPatterns:
        return 'insights_focus_seasonal';
      case FocusTag.predictions:
        return 'insights_focus_predictions';
    }
  }

  String get iconName {
    switch (this) {
      case FocusTag.all:
        return 'analytics';
      case FocusTag.feedEfficiency:
        return 'grass';
      case FocusTag.eggProduction:
        return 'egg_alt';
      case FocusTag.financialPerformance:
        return 'attach_money';
      case FocusTag.flockHealth:
        return 'health_and_safety';
      case FocusTag.seasonalPatterns:
        return 'wb_sunny';
      case FocusTag.predictions:
        return 'trending_up';
    }
  }
}

/// Insight category
enum InsightCategory {
  feedEfficiency,
  production,
  financial,
  health,
  seasonal,
  prediction,
  anomaly,
  general,
}

extension InsightCategoryExtension on InsightCategory {
  String get labelKey {
    switch (this) {
      case InsightCategory.feedEfficiency:
        return 'insights_category_feed';
      case InsightCategory.production:
        return 'insights_category_production';
      case InsightCategory.financial:
        return 'insights_category_financial';
      case InsightCategory.health:
        return 'insights_category_health';
      case InsightCategory.seasonal:
        return 'insights_category_seasonal';
      case InsightCategory.prediction:
        return 'insights_category_prediction';
      case InsightCategory.anomaly:
        return 'insights_category_anomaly';
      case InsightCategory.general:
        return 'insights_category_general';
    }
  }
}

/// Severity level of an insight
enum InsightSeverity {
  positive,   // Green - performing well
  neutral,    // Blue - informational
  warning,    // Orange - needs attention
  critical,   // Red - urgent action required
}

extension InsightSeverityExtension on InsightSeverity {
  String get labelKey {
    switch (this) {
      case InsightSeverity.positive:
        return 'insights_severity_positive';
      case InsightSeverity.neutral:
        return 'insights_severity_neutral';
      case InsightSeverity.warning:
        return 'insights_severity_warning';
      case InsightSeverity.critical:
        return 'insights_severity_critical';
    }
  }

  String get emoji {
    switch (this) {
      case InsightSeverity.positive:
        return '✅';
      case InsightSeverity.neutral:
        return '💡';
      case InsightSeverity.warning:
        return '⚠️';
      case InsightSeverity.critical:
        return '🔴';
    }
  }
}

/// Trend direction
enum TrendDirection {
  stronglyImproving,
  improving,
  stable,
  declining,
  stronglyDeclining,
  insufficient, // not enough data
}

extension TrendDirectionExtension on TrendDirection {
  String get labelKey {
    switch (this) {
      case TrendDirection.stronglyImproving:
        return 'insights_trend_strongly_improving';
      case TrendDirection.improving:
        return 'insights_trend_improving';
      case TrendDirection.stable:
        return 'insights_trend_stable';
      case TrendDirection.declining:
        return 'insights_trend_declining';
      case TrendDirection.stronglyDeclining:
        return 'insights_trend_strongly_declining';
      case TrendDirection.insufficient:
        return 'insights_trend_insufficient_data';
    }
  }

  bool get isPositive =>
      this == TrendDirection.stronglyImproving ||
      this == TrendDirection.improving;
  bool get isNegative =>
      this == TrendDirection.stronglyDeclining ||
      this == TrendDirection.declining;
}

/// Output type — species-agnostic
enum OutputType {
  eggs,
  meatKg,
  breedingPairs,
  other,
}

extension OutputTypeExtension on OutputType {
  String get labelKey {
    switch (this) {
      case OutputType.eggs:
        return 'insights_output_eggs';
      case OutputType.meatKg:
        return 'insights_output_meat';
      case OutputType.breedingPairs:
        return 'insights_output_breeding';
      case OutputType.other:
        return 'insights_output_other';
    }
  }

  String get unitKey {
    switch (this) {
      case OutputType.eggs:
        return 'insights_unit_eggs';
      case OutputType.meatKg:
        return 'insights_unit_kg';
      case OutputType.breedingPairs:
        return 'insights_unit_pairs';
      case OutputType.other:
        return 'insights_unit_units';
    }
  }
}

/// Bird species
enum BirdSpecies {
  chickenLayer,
  chickenBroiler,
  duck,
  turkey,
  pigeon,
  finch,
  peacock,
  quail,
  goose,
  other,
}

extension BirdSpeciesExtension on BirdSpecies {
  String get labelKey {
    switch (this) {
      case BirdSpecies.chickenLayer:
        return 'insights_species_chicken_layer';
      case BirdSpecies.chickenBroiler:
        return 'insights_species_chicken_broiler';
      case BirdSpecies.duck:
        return 'insights_species_duck';
      case BirdSpecies.turkey:
        return 'insights_species_turkey';
      case BirdSpecies.pigeon:
        return 'insights_species_pigeon';
      case BirdSpecies.finch:
        return 'insights_species_finch';
      case BirdSpecies.peacock:
        return 'insights_species_peacock';
      case BirdSpecies.quail:
        return 'insights_species_quail';
      case BirdSpecies.goose:
        return 'insights_species_goose';
      case BirdSpecies.other:
        return 'insights_species_other';
    }
  }

  OutputType get defaultOutputType {
    switch (this) {
      case BirdSpecies.chickenLayer:
      case BirdSpecies.duck:
      case BirdSpecies.quail:
      case BirdSpecies.goose:
        return OutputType.eggs;
      case BirdSpecies.chickenBroiler:
      case BirdSpecies.turkey:
        return OutputType.meatKg;
      case BirdSpecies.pigeon:
      case BirdSpecies.finch:
      case BirdSpecies.peacock:
        return OutputType.breedingPairs;
      case BirdSpecies.other:
        return OutputType.other;
    }
  }
}

/// Overall performance score label
enum PerformanceLabel {
  outstanding,
  excellent,
  good,
  aboveAverage,
  average,
  belowAverage,
  needsImprovement,
  insufficient,
}

extension PerformanceLabelExtension on PerformanceLabel {
  String get labelKey {
    switch (this) {
      case PerformanceLabel.outstanding:
        return 'insights_perf_outstanding';
      case PerformanceLabel.excellent:
        return 'insights_perf_excellent';
      case PerformanceLabel.good:
        return 'insights_perf_good';
      case PerformanceLabel.aboveAverage:
        return 'insights_perf_above_average';
      case PerformanceLabel.average:
        return 'insights_perf_average';
      case PerformanceLabel.belowAverage:
        return 'insights_perf_below_average';
      case PerformanceLabel.needsImprovement:
        return 'insights_perf_needs_improvement';
      case PerformanceLabel.insufficient:
        return 'insights_perf_insufficient_data';
    }
  }

  static PerformanceLabel fromScore(double score) {
    if (score >= 90) return PerformanceLabel.outstanding;
    if (score >= 80) return PerformanceLabel.excellent;
    if (score >= 70) return PerformanceLabel.good;
    if (score >= 60) return PerformanceLabel.aboveAverage;
    if (score >= 50) return PerformanceLabel.average;
    if (score >= 40) return PerformanceLabel.belowAverage;
    if (score >= 20) return PerformanceLabel.needsImprovement;
    return PerformanceLabel.insufficient;
  }
}
