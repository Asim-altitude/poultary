import 'package:flutter/material.dart';

import '../engine/poultry_insights_engine.dart';
import '../models/enums.dart';
import '../models/farm_record.dart';
import '../models/flock_info.dart';
import 'advanced_insights_screen.dart';

// ════════════════════════════════════════════════════════════════
//  USAGE EXAMPLE
//  Shows how to integrate PoultryInsightsEngine into your app.
// ════════════════════════════════════════════════════════════════

/// Step 1: Add to pubspec.yaml:
/// dependencies:
///   easy_localization: ^3.0.3
///
/// assets:
///   - assets/translations/

/// Step 2: Initialize EasyLocalization in main.dart:
/// void main() async {
///   await EasyLocalization.ensureInitialized();
///   runApp(
///     EasyLocalization(
///       supportedLocales: const [Locale('en'), Locale('ur'), Locale('hi')],
///       path: 'assets/translations',
///       fallbackLocale: const Locale('en'),
///       child: MyApp(),
///     ),
///   );
/// }

class InsightsExamplePage extends StatelessWidget {
  InsightsExamplePage({super.key});

  /// Example: Build FarmRecord list from your database
  List<FarmRecord> get _sampleRecords {
    final records = <FarmRecord>[];
    final rng = DateTime.now();

    for (int i = 180; i >= 0; i--) {
      final date = rng.subtract(Duration(days: i));
      final birds = 500;

      // Simulate realistic variation
      final dayOfYear = date.dayOfYear;
      final seasonFactor = 1.0 + 0.1 * _sin(dayOfYear / 365.0 * 2 * 3.14);
      final eggs = (birds * 0.85 * seasonFactor * (0.95 + _random(i) * 0.1)).round();
      final feedKg = birds * 0.13 * (1.0 + _random(i + 1) * 0.05);
      final income = eggs * 6.5 * (1.0 + _random(i + 2) * 0.02);
      final feedCost = feedKg * 28.0;
      final otherCost = birds * 0.05;
      final totalExpense = feedCost + otherCost + 200;

      records.add(FarmRecord(
        id: 'record_$i',
        date: date,
        birdSpecies: BirdSpecies.chickenLayer,
        birdsCount: birds,
        outputCount: eggs.toDouble(),
        outputType: OutputType.eggs,
        feedConsumedKg: feedKg,
        totalIncome: income,
        totalExpense: totalExpense,
        expenseBreakdown: ExpenseBreakdown(
          feedCost: feedCost,
          medicineCost: 50,
          laborCost: 100,
          utilityCost: 50,
          otherCost: otherCost,
        ),
        mortalityCount: _random(i + 3) > 0.98 ? 1 : 0,
      ));
    }

    return records;
  }

  /// Example: Build FlockInfo from your user preferences
  FlockInfo get _sampleFlockInfo => const FlockInfo(
        primarySpecies: BirdSpecies.chickenLayer,
        currencySymbol: '₹',  // Adapts to ANY currency
        countryCode: 'IN',    // Optional - just for context
        avgAgeWeeks: 48,
      );

  double _sin(double x) {
    // Simple sin approximation for demo
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  double _random(int seed) {
    return ((seed * 7 + 13) % 100) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedInsightsScreen(
      allRecords: _sampleRecords,
      flockInfo: _sampleFlockInfo,
    );
  }
}

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}

// ════════════════════════════════════════════════════════════════
//  PROGRAMMATIC USAGE
//  For custom integration without the built-in UI
// ════════════════════════════════════════════════════════════════

Future<void> programmaticUsageExample(List<FarmRecord> records) async {
  final engine = PoultryInsightsEngine();

  final flockInfo = const FlockInfo(
    primarySpecies: BirdSpecies.duck,   // Works for ANY species!
    currencySymbol: '\$',
  );

  // ── Full report (all insights) ────────────────────────────────
  final fullReport = await engine.generateReport(
    allRecords: records,
    flockInfo: flockInfo,
    period: TimePeriod.last6Months,
    focusTags: [FocusTag.all],
  );

  print('Overall score: ${fullReport.overallScore.score.toStringAsFixed(0)}/100');
  print('Total insights: ${fullReport.allInsights.length}');
  print('Critical alerts: ${fullReport.urgentAlertCount}');

  // ── Focused report (financial only) ──────────────────────────
  final financialReport = await engine.generateReport(
    allRecords: records,
    flockInfo: flockInfo,
    period: TimePeriod.last3Months,
    focusTags: [FocusTag.financialPerformance],
  );

  print('Financial insights: ${financialReport.financialInsights.length}');

  // ── Check data readiness ──────────────────────────────────────
  final readiness = engine.getReadinessStatus(records);
  print('Days of data: ${readiness.totalDays}');
  print('Has trend insights: ${readiness.hasTrendInsights}');
  print('Has seasonal insights: ${readiness.hasSeasonalInsights}');

  // ── Access insights with localization keys ────────────────────
  for (final insight in fullReport.criticalInsights) {
    // In Flutter, use .tr() on the keys:
    // Text(insight.titleKey.tr(namedArgs: insight.titleNamedArgs))
    // Text(insight.descriptionKey.tr(namedArgs: insight.descriptionNamedArgs))
    print('⚠️  ${insight.titleKey} | impact: ${insight.impactScore}');
  }

  // ── Access positive insights ──────────────────────────────────
  for (final insight in fullReport.positiveInsights.take(3)) {
    print('✅ ${insight.titleKey} | impact: ${insight.impactScore}');
  }

  // ── Top recommendations ───────────────────────────────────────
  for (final rec in fullReport.topRecommendations) {
    // In Flutter: Text(rec.titleKey.tr())
    print('💡 ${rec.titleKey} | urgent: ${rec.isUrgent}');
  }
}
