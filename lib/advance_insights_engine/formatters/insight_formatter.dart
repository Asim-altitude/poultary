import '../models/insight.dart';
import '../models/insight_report.dart';
import '../models/enums.dart';
import '../models/performance_metrics.dart';

/// Formats insight keys for use in Flutter UI.
/// All strings use .tr() compatible localization keys.
///
/// In your Flutter app, call:
///   Text(insight.titleKey.tr(namedArgs: insight.titleNamedArgs))
///   Text(insight.descriptionKey.tr(namedArgs: insight.descriptionNamedArgs))
class InsightFormatter {
  const InsightFormatter();

  /// Returns the correct Flutter localization call string representation.
  /// In your UI layer, use this pattern:
  ///   Text(formatter.formatTitle(insight))
  ///   (but actually just call insight.titleKey.tr(...) directly in widgets)
  String buildTitleCall(Insight insight) {
    if (insight.titleNamedArgs.isNotEmpty) {
      return '${insight.titleKey}.tr(namedArgs: ${insight.titleNamedArgs})';
    }
    if (insight.titleArgs.isNotEmpty) {
      return '${insight.titleKey}.tr(args: ${insight.titleArgs})';
    }
    return '${insight.titleKey}.tr()';
  }

  /// Returns severity color hex for UI use
  String severityColorHex(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.positive:
        return '#22C55E'; // green-500
      case InsightSeverity.neutral:
        return '#3B82F6'; // blue-500
      case InsightSeverity.warning:
        return '#F59E0B'; // amber-500
      case InsightSeverity.critical:
        return '#EF4444'; // red-500
    }
  }

  /// Returns severity icon name (Material Icons)
  String severityIcon(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.positive:
        return 'check_circle';
      case InsightSeverity.neutral:
        return 'lightbulb';
      case InsightSeverity.warning:
        return 'warning_amber';
      case InsightSeverity.critical:
        return 'error';
    }
  }

  /// Returns category icon name (Material Icons)
  String categoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.feedEfficiency:
        return 'grass';
      case InsightCategory.production:
        return 'egg_alt';
      case InsightCategory.financial:
        return 'account_balance_wallet';
      case InsightCategory.health:
        return 'health_and_safety';
      case InsightCategory.seasonal:
        return 'wb_sunny';
      case InsightCategory.prediction:
        return 'trending_up';
      case InsightCategory.anomaly:
        return 'notifications_active';
      case InsightCategory.general:
        return 'insights';
    }
  }

  /// Returns a 0-100 score as a display string with label
  String formatScore(double score, String Function(String key) tr) {
    final label = PerformanceLabelExtension.fromScore(score).labelKey;
    return '${score.toStringAsFixed(0)}/100 - ${tr(label)}';
  }
}
