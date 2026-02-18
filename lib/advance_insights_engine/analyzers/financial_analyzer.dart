import '../models/farm_record.dart';
import '../models/baseline.dart';
import '../models/insight.dart';
import '../models/enums.dart';
import '../utils/math_utils.dart';
import '../utils/date_utils.dart';

/// Analyzes financial performance and generates related insights.
class FinancialAnalyzer {
  List<Insight> analyze({
    required List<FarmRecord> periodRecords,
    required Baseline baseline,
    required String currencySymbol,
  }) {
    if (periodRecords.isEmpty || !baseline.hasSufficientData) return [];

    final insights = <Insight>[];

    insights.addAll(_analyzeProfitMarginVsBaseline(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeProfitTrend(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeCostPerUnit(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeIncomePerUnit(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeExpenseBalance(periodRecords, baseline, currencySymbol));
    insights.addAll(_analyzeROFI(periodRecords, baseline, currencySymbol));

    return insights;
  }

  // ─── Profit margin vs baseline ──────────────────────────────────

  List<Insight> _analyzeProfitMarginVsBaseline(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final currentMargin = InsightsMathUtils.mean(
        records.map((r) => r.profitMargin).toList());
    final baselineMargin = baseline.profitMargin.mean;

    if (baselineMargin == 0) return [];

    final changePoints = currentMargin - baselineMargin;
    final changePercent =
        InsightsMathUtils.percentChange(baselineMargin, currentMargin);

    if (changePercent >= 15) {
      return [
        Insight(
          id: 'profit_margin_strong',
          category: InsightCategory.financial,
          severity: InsightSeverity.positive,
          titleKey: 'insight_profit_margin_strong_title',
          descriptionKey: 'insight_profit_margin_strong_desc',
          titleNamedArgs: {
            'margin': currentMargin.toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentMargin.toStringAsFixed(1),
            'baseline': baselineMargin.toStringAsFixed(1),
            'change': changePoints.toStringAsFixed(1),
          },
          metrics: {
            'currentMargin': currentMargin,
            'baselineMargin': baselineMargin,
            'changePoints': changePoints,
          },
          impactScore: 88,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    } else if (changePercent <= -15) {
      return [
        Insight(
          id: 'profit_margin_declining',
          category: InsightCategory.financial,
          severity: changePercent <= -25
              ? InsightSeverity.critical
              : InsightSeverity.warning,
          titleKey: 'insight_profit_margin_declining_title',
          descriptionKey: 'insight_profit_margin_declining_desc',
          titleNamedArgs: {
            'margin': currentMargin.toStringAsFixed(1),
          },
          descriptionNamedArgs: {
            'current': currentMargin.toStringAsFixed(1),
            'baseline': baselineMargin.toStringAsFixed(1),
            'change': changePoints.abs().toStringAsFixed(1),
          },
          metrics: {
            'currentMargin': currentMargin,
            'baselineMargin': baselineMargin,
            'changePoints': changePoints,
          },
          recommendationKey: 'insight_profit_margin_declining_rec',
          impactScore: changePercent <= -25 ? 95 : 80,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Profit margin trend within the period ──────────────────────

  List<Insight> _analyzeProfitTrend(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    if (records.length < 7) return [];

    final sorted = InsightsDateUtils.sortByDate(records, (r) => r.date);
    final values = sorted.map((r) => r.profitMargin).toList();
    final trend = InsightsMathUtils.classifyTrend(values);

    if (trend.insufficient || trend.isStable) return [];

    if (trend.isImproving && trend.isStrong) {
      return [
        Insight(
          id: 'profit_strongly_growing',
          category: InsightCategory.financial,
          severity: InsightSeverity.positive,
          titleKey: 'insight_profit_growing_title',
          descriptionKey: 'insight_profit_growing_desc',
          metrics: {'slopePercent': trend.slopePercent},
          impactScore: 82,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    if (!trend.isImproving && trend.isStrong) {
      return [
        Insight(
          id: 'profit_strongly_declining',
          category: InsightCategory.financial,
          severity: InsightSeverity.warning,
          titleKey: 'insight_profit_declining_title',
          descriptionKey: 'insight_profit_declining_desc',
          metrics: {'slopePercent': trend.slopePercent},
          recommendationKey: 'insight_profit_declining_rec',
          impactScore: 85,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Cost per unit vs baseline ───────────────────────────────────

  List<Insight> _analyzeCostPerUnit(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final validRecords =
        records.where((r) => r.outputCount > 0 && r.totalExpense > 0);
    if (validRecords.isEmpty) return [];

    final currentCpU = InsightsMathUtils.mean(
        validRecords.map((r) => r.costPerUnit).toList());
    final baselineCpU = baseline.costPerUnit.mean;

    if (baselineCpU == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineCpU, currentCpU);

    if (changePercent >= 12) {
      return [
        Insight(
          id: 'cost_per_unit_rising',
          category: InsightCategory.financial,
          severity: InsightSeverity.warning,
          titleKey: 'insight_cost_per_unit_rising_title',
          descriptionKey: 'insight_cost_per_unit_rising_desc',
          titleNamedArgs: {'percent': changePercent.toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': '$currencySymbol${currentCpU.toStringAsFixed(2)}',
            'baseline': '$currencySymbol${baselineCpU.toStringAsFixed(2)}',
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'currentCostPerUnit': currentCpU,
            'baselineCostPerUnit': baselineCpU,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_cost_per_unit_rising_rec',
          impactScore: 72,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    } else if (changePercent <= -10) {
      return [
        Insight(
          id: 'cost_per_unit_falling',
          category: InsightCategory.financial,
          severity: InsightSeverity.positive,
          titleKey: 'insight_cost_per_unit_falling_title',
          descriptionKey: 'insight_cost_per_unit_falling_desc',
          titleNamedArgs: {'percent': changePercent.abs().toStringAsFixed(1)},
          descriptionNamedArgs: {
            'current': '$currencySymbol${currentCpU.toStringAsFixed(2)}',
            'baseline': '$currencySymbol${baselineCpU.toStringAsFixed(2)}',
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'currentCostPerUnit': currentCpU,
            'baselineCostPerUnit': baselineCpU,
            'changePercent': changePercent,
          },
          impactScore: 76,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Income per unit vs baseline ────────────────────────────────

  List<Insight> _analyzeIncomePerUnit(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final validRecords =
        records.where((r) => r.outputCount > 0 && r.totalIncome > 0);
    if (validRecords.isEmpty) return [];

    final currentIpU = InsightsMathUtils.mean(
        validRecords.map((r) => r.incomePerUnit).toList());
    final baselineIpU = baseline.incomePerUnit.mean;

    if (baselineIpU == 0) return [];

    final changePercent =
        InsightsMathUtils.percentChange(baselineIpU, currentIpU);

    if (changePercent >= 8) {
      return [
        Insight(
          id: 'income_per_unit_up',
          category: InsightCategory.financial,
          severity: InsightSeverity.positive,
          titleKey: 'insight_income_per_unit_up_title',
          descriptionKey: 'insight_income_per_unit_up_desc',
          descriptionNamedArgs: {
            'current': '$currencySymbol${currentIpU.toStringAsFixed(2)}',
            'baseline': '$currencySymbol${baselineIpU.toStringAsFixed(2)}',
            'percent': changePercent.toStringAsFixed(1),
          },
          metrics: {
            'currentIncomePerUnit': currentIpU,
            'baselineIncomePerUnit': baselineIpU,
            'changePercent': changePercent,
          },
          impactScore: 70,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    } else if (changePercent <= -10) {
      return [
        Insight(
          id: 'income_per_unit_down',
          category: InsightCategory.financial,
          severity: InsightSeverity.warning,
          titleKey: 'insight_income_per_unit_down_title',
          descriptionKey: 'insight_income_per_unit_down_desc',
          descriptionNamedArgs: {
            'current': '$currencySymbol${currentIpU.toStringAsFixed(2)}',
            'baseline': '$currencySymbol${baselineIpU.toStringAsFixed(2)}',
            'percent': changePercent.abs().toStringAsFixed(1),
          },
          metrics: {
            'currentIncomePerUnit': currentIpU,
            'baselineIncomePerUnit': baselineIpU,
            'changePercent': changePercent,
          },
          recommendationKey: 'insight_income_per_unit_down_rec',
          impactScore: 73,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Income/expense balance ──────────────────────────────────────

  List<Insight> _analyzeExpenseBalance(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final totalIncome =
        records.fold<double>(0, (s, r) => s + r.totalIncome);
    final totalExpense =
        records.fold<double>(0, (s, r) => s + r.totalExpense);
    if (totalExpense == 0) return [];

    final ratio = totalIncome / totalExpense;
    final baselineRatio = baseline.profitMargin.mean > 0
        ? 1 + (baseline.profitMargin.mean / 100)
        : 1.0;

    if (ratio < 1.0) {
      // Operating at a loss
      return [
        Insight(
          id: 'operating_at_loss',
          category: InsightCategory.financial,
          severity: InsightSeverity.critical,
          titleKey: 'insight_operating_at_loss_title',
          descriptionKey: 'insight_operating_at_loss_desc',
          descriptionNamedArgs: {
            'income': '$currencySymbol${totalIncome.toStringAsFixed(0)}',
            'expense': '$currencySymbol${totalExpense.toStringAsFixed(0)}',
            'loss': '$currencySymbol${(totalExpense - totalIncome).toStringAsFixed(0)}',
          },
          metrics: {
            'totalIncome': totalIncome,
            'totalExpense': totalExpense,
            'ratio': ratio,
          },
          recommendationKey: 'insight_operating_at_loss_rec',
          impactScore: 98,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    } else if (ratio < 1.1 && baselineRatio > 1.2) {
      // Margins have compressed significantly
      return [
        Insight(
          id: 'margins_compressed',
          category: InsightCategory.financial,
          severity: InsightSeverity.warning,
          titleKey: 'insight_margins_compressed_title',
          descriptionKey: 'insight_margins_compressed_desc',
          descriptionNamedArgs: {
            'ratio': ratio.toStringAsFixed(2),
            'baseline': baselineRatio.toStringAsFixed(2),
          },
          metrics: {'ratio': ratio, 'baselineRatio': baselineRatio},
          recommendationKey: 'insight_margins_compressed_rec',
          impactScore: 78,
          focusTags: [FocusTag.financialPerformance, FocusTag.all],
        )
      ];
    }

    return [];
  }

  // ─── Return on feed investment ───────────────────────────────────

  List<Insight> _analyzeROFI(
    List<FarmRecord> records,
    Baseline baseline,
    String currencySymbol,
  ) {
    final withBreakdown =
        records.where((r) => r.expenseBreakdown != null).toList();
    if (withBreakdown.isEmpty) return [];

    final currentROFI = InsightsMathUtils.mean(
        withBreakdown.map((r) => r.returnOnFeedInvestment).toList());

    if (currentROFI <= 0) return [];

    // Simply track direction — no external benchmark
    final sorted = InsightsDateUtils.sortByDate(withBreakdown, (r) => r.date);
    final rofiValues = sorted
        .map((r) => r.returnOnFeedInvestment)
        .where((v) => v > 0)
        .toList();
    final trend = InsightsMathUtils.classifyTrend(rofiValues);

    if (trend.isImproving && !trend.insufficient) {
      return [
        Insight(
          id: 'rofi_improving',
          category: InsightCategory.financial,
          severity: InsightSeverity.positive,
          titleKey: 'insight_rofi_improving_title',
          descriptionKey: 'insight_rofi_improving_desc',
          descriptionNamedArgs: {
            'rofi': currentROFI.toStringAsFixed(2),
          },
          metrics: {'currentROFI': currentROFI},
          impactScore: 65,
          focusTags: [FocusTag.financialPerformance, FocusTag.feedEfficiency],
        )
      ];
    }

    return [];
  }
}
