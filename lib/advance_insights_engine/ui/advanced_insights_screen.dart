import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../engine/poultry_insights_engine.dart';
import '../models/enums.dart';
import '../models/farm_record.dart';
import '../models/flock_info.dart';
import '../models/insight.dart';
import '../models/insight_report.dart';
import '../models/performance_metrics.dart';


// ═══════════════════════════════════════════════════════════════
//  CURRENCY UTIL SHIM
//  Replace this with your actual Utils import:
//  import 'package:your_app/utils/utils.dart';
// ═══════════════════════════════════════════════════════════════


abstract class Utils {
  static String currency(double value, {String symbol = ''}) {
    final abs = value.abs();
    String formatted;
    if (abs >= 10000000)      formatted = '${(value / 10000000).toStringAsFixed(1)}Cr';
    else if (abs >= 100000)   formatted = '${(value / 100000).toStringAsFixed(1)}L';
    else if (abs >= 1000)     formatted = '${(value / 1000).toStringAsFixed(1)}K';
    else                      formatted = value.toStringAsFixed(0);
    return '$symbol$formatted';
  }

  static String number(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000)    return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════

abstract class _C {
  static const green  = Color(0xFF22C55E);
  static const blue   = Color(0xFF3B82F6);
  static const amber  = Color(0xFFF59E0B);
  static const red    = Color(0xFFEF4444);
  static const violet = Color(0xFF8B5CF6);
  static const teal   = Color(0xFF14B8A6);

  static Color severity(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.positive: return green;
      case InsightSeverity.neutral:  return blue;
      case InsightSeverity.warning:  return amber;
      case InsightSeverity.critical: return red;
    }
  }

  static Color score(double s) {
    if (s >= 80) return green;
    if (s >= 60) return blue;
    if (s >= 40) return amber;
    return red;
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADVANCED INSIGHTS SCREEN
// ═══════════════════════════════════════════════════════════════

class AdvancedInsightsScreen extends StatefulWidget {
  final List<FarmRecord> allRecords;
  final FlockInfo flockInfo;

  const AdvancedInsightsScreen({
    super.key,
    required this.allRecords,
    required this.flockInfo,
  });

  @override
  State<AdvancedInsightsScreen> createState() => _AdvancedInsightsScreenState();
}

class _AdvancedInsightsScreenState extends State<AdvancedInsightsScreen>
    with SingleTickerProviderStateMixin {
  final _engine = PoultryInsightsEngine();

  TimePeriod _period = TimePeriod.last3Months;
  FocusTag   _focus  = FocusTag.all;

  InsightReport? _report;
  bool    _isLoading = false;
  String? _error;

  late final TabController _tab;

  static const _tabs = [
    (key: 'insights_all_insights',            icon: Icons.insights),
    (key: 'insights_category_tabs_feed',       icon: Icons.grass),
    (key: 'insights_category_tabs_production', icon: Icons.egg_alt),
    (key: 'insights_category_tabs_financial',  icon: Icons.account_balance_wallet),
    (key: 'insights_category_tabs_health',     icon: Icons.health_and_safety),
    (key: 'insights_category_tabs_seasonal',   icon: Icons.wb_sunny),
    (key: 'insights_category_tabs_forecast',   icon: Icons.trending_up),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _run();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final r = await _engine.generateReport(
        allRecords: widget.allRecords,
        flockInfo: widget.flockInfo,
        period: _period,
        focusTags: [_focus],
      );
      if (mounted) setState(() { _report = r; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Insight> _forTab(int i) {
    final r = _report!;
    switch (i) {
      case 0: return r.allInsights;
      case 1: return r.feedInsights;
      case 2: return r.productionInsights;
      case 3: return r.financialInsights;
      case 4: return r.healthInsights;
      case 5: return r.seasonalInsights;
      case 6: return r.predictiveInsights;
      default: return [];
    }
  }

  int _badge(int i) {
    if (_report == null) return 0;
    final r = _report!;
    switch (i) {
      case 0: return r.alerts.length;
      case 1: return r.feedInsights.length;
      case 2: return r.productionInsights.length;
      case 3: return r.financialInsights.length;
      case 4: return r.healthInsights.length;
      case 5: return r.seasonalInsights.length;
      case 6: return r.predictiveInsights.length;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym   = widget.flockInfo.currencySymbol;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('insights_report_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
            if (_report != null)
              Text(
                '${_report!.birdSpecies.tr()} · ${_period.labelKey.tr()}',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.45)),
              ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _run,
              tooltip: 'insights_generate_button'.tr(),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Horizontal filter chips ───────────────────────────────
          _FilterBar(
            period: _period, focus: _focus,
            onPeriodChanged: (p) { setState(() => _period = p); _run(); },
            onFocusChanged:  (f) { setState(() => _focus  = f); _run(); },
          ),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const _LoadingView()
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _run)
                    : _report == null
                        ? const SizedBox()
                        : _buildReport(sym, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(String sym, ThemeData theme) {
    final r         = _report!;
    final readiness = r.dataReadiness;

    if (!readiness.hasBasicInsights) {
      return _DataReadinessView(readiness: readiness);
    }

    return Column(
      children: [
        // ── Compact summary header ────────────────────────────────
        _SummaryHeader(report: r, currencySymbol: sym),

        // ── Tab bar with badge counts ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
            ),
          ),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorWeight: 2.5,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            tabs: List.generate(_tabs.length, (i) {
              final b = _badge(i);
              return Tab(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabs[i].icon, size: 13),
                    const SizedBox(width: 4),
                    Text(_tabs[i].key.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 10.5)),
                    if (b > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: i == 0 ? _C.red : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$b',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),

        // ── Tab views ────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: List.generate(_tabs.length, (i) => _InsightListTab(
              insights: _forTab(i),
              recommendations: i == 0 ? r.topRecommendations : [],
              alerts:          i == 0 ? r.alerts : [],
              readiness:       r.dataReadiness,
              showMeta:        i == 0,
            )),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUMMARY HEADER  (≈90dp tall, shows everything compactly)
// ═══════════════════════════════════════════════════════════════

class _SummaryHeader extends StatelessWidget {
  final InsightReport report;
  final String currencySymbol;
  const _SummaryHeader({required this.report, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final m      = report.metrics;
    final sc     = report.overallScore;
    final sColor = _C.score(sc.score);
    final profit = m.netProfit;
    final pColor = profit >= 0 ? _C.green : _C.red;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Score pill + 4 icon-chips ──────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScorePill(score: sc, color: sColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MiniChip(icon: Icons.egg_alt,
                          label: 'Production',
                          value: Utils.number(m.totalOutput),
                          color: _C.teal),
                      _MiniChip(icon: Icons.attach_money,
                          label: 'Profit',
                          value: Utils.currency(profit, symbol: currencySymbol),
                          color: pColor),
                      _MiniChip(icon: Icons.grass,
                          label: 'Feed/Bird',
                          value: '${m.avgFeedPerBird.toStringAsFixed(2)}kg',
                          color: _C.amber),
                      _MiniChip(icon: Icons.health_and_safety,
                          label: 'Mortality',
                          value: '${m.avgMortalityRatePercent.toStringAsFixed(1)}%',
                          color: _C.violet),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Row 2: Compact financial strip ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _Strip(label: 'Income',
                    value: Utils.currency(m.totalIncome, symbol: currencySymbol),
                    color: _C.green),
                _Divider(),
                _Strip(label: 'Expense',
                    value: Utils.currency(m.totalExpense, symbol: currencySymbol),
                    color: _C.red),
                _Divider(),
                _Strip(label: 'Net',
                    value: Utils.currency(profit, symbol: currencySymbol),
                    color: pColor),
                _Divider(),
                _Strip(label: 'Margin',
                    value: '${m.avgProfitMarginPercent.toStringAsFixed(1)}%',
                    color: pColor),
                _Divider(),
                _Strip(label: 'Avg/Bird',
                    value: '${m.avgOutputPerBird.toStringAsFixed(2)}',
                    color: _C.teal),
                _Divider(),
                _Strip(label: 'Birds',
                    value: Utils.number(m.avgBirdsCount),
                    color: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score pill ────────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final OverallScore score;
  final Color color;
  const _ScorePill({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 62,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(score.score.toStringAsFixed(0),
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          Text('/100',
              style: TextStyle(
                  color: color.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(score.feedScore,       color),
              const SizedBox(width: 2),
              _Dot(score.productionScore, color),
              const SizedBox(width: 2),
              _Dot(score.financialScore,  color),
              const SizedBox(width: 2),
              _Dot(score.healthScore,     color),
            ],
          ),
          const SizedBox(height: 3),
          Text(score.label.labelKey.tr(),
              style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double value;
  final Color color;
  const _Dot(this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value >= 60 ? color : color.withOpacity(0.2),
        ),
      );
}

// ── Mini chip ─────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MiniChip({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 11)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: theme.colorScheme.onSurface.withOpacity(0.4))),
      ],
    );
  }
}

// ── Financial strip helpers ───────────────────────────────────────────────────

class _Strip extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Strip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color ?? theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: TextStyle(
                  fontSize: 7.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: Theme.of(context).dividerColor.withOpacity(0.4),
      );
}

// ═══════════════════════════════════════════════════════════════
//  INSIGHT LIST TAB
// ═══════════════════════════════════════════════════════════════

class _InsightListTab extends StatelessWidget {
  final List<Insight>        insights;
  final List<Recommendation> recommendations;
  final List<InsightAlert>   alerts;
  final DataReadinessStatus  readiness;
  final bool                 showMeta;

  const _InsightListTab({
    required this.insights,
    required this.recommendations,
    required this.alerts,
    required this.readiness,
    required this.showMeta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 38,
                color: theme.colorScheme.onSurface.withOpacity(0.18)),
            const SizedBox(height: 8),
            Text('insights_empty_category'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.35))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        if (showMeta && alerts.isNotEmpty) ...[
          _AlertsBanner(alerts: alerts),
          const SizedBox(height: 10),
        ],
        if (recommendations.isNotEmpty) ...[
          _SectionLabel(title: 'insights_top_recommendations'.tr(), count: recommendations.length),
          const SizedBox(height: 6),
          ...recommendations.map((r) => _RecCard(rec: r)),
          const SizedBox(height: 12),
          _SectionLabel(title: 'insights_all_insights'.tr(), count: insights.length),
          const SizedBox(height: 6),
        ],
        ...insights.map((i) => _InsightCard(insight: i)),
        if (showMeta && !readiness.hasSeasonalInsights) ...[
          const SizedBox(height: 8),
          _ReadinessNudge(readiness: readiness),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ALERTS BANNER
// ═══════════════════════════════════════════════════════════════

class _AlertsBanner extends StatelessWidget {
  final List<InsightAlert> alerts;
  const _AlertsBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final criticals = alerts.where((a) => a.severity == InsightSeverity.critical).toList();
    final hasCrit   = criticals.isNotEmpty;
    final color     = hasCrit ? _C.red : _C.amber;
    final icon      = hasCrit ? Icons.error_rounded : Icons.warning_amber_rounded;
    final first     = hasCrit ? criticals.first : alerts.first;
    final extra     = alerts.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(first.titleKey.tr(namedArgs: first.titleNamedArgs),
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (extra > 0)
                  Text('+$extra more alert${extra > 1 ? 's' : ''}',
                      style: TextStyle(color: color.withOpacity(0.65), fontSize: 9)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(6)),
            child: Text('${alerts.length}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;
  const _SectionLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$count',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 10)),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
//  INSIGHT CARD  (compact collapsed, detailed expanded)
// ═══════════════════════════════════════════════════════════════

class _InsightCard extends StatefulWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ac;
  late final Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ac   = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ac.forward() : _ac.reverse();
  }

  IconData _catIcon(InsightCategory c) {
    switch (c) {
      case InsightCategory.feedEfficiency: return Icons.grass;
      case InsightCategory.production:     return Icons.egg_alt;
      case InsightCategory.financial:      return Icons.account_balance_wallet;
      case InsightCategory.health:         return Icons.health_and_safety;
      case InsightCategory.seasonal:       return Icons.wb_sunny;
      case InsightCategory.prediction:     return Icons.trending_up;
      case InsightCategory.anomaly:        return Icons.notifications_active;
      case InsightCategory.general:        return Icons.insights;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final insight = widget.insight;
    final color   = _C.severity(insight.severity);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _open ? color.withOpacity(0.45) : color.withOpacity(0.18),
              width: _open ? 1.3 : 1),
          boxShadow: [BoxShadow(
              color: color.withOpacity(_open ? 0.07 : 0.025),
              blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Collapsed row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Icon badge
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(_catIcon(insight.category), color: color, size: 15),
                ),
                Positioned(top: -3, right: -3,
                  child: Container(width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 9),

              // Text
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(insight.titleKey.tr(namedArgs: insight.titleNamedArgs),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(insight.descriptionKey.tr(namedArgs: insight.descriptionNamedArgs),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 6),

              // Impact badge + chevron
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(insight.impactScore.toStringAsFixed(0),
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.28), size: 15),
                ),
              ]),
            ]),
          ),

          // ── Expanded panel ────────────────────────────────────────
          SizeTransition(
            sizeFactor: _anim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(height: 1, color: color.withOpacity(0.18)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(insight.descriptionKey.tr(namedArgs: insight.descriptionNamedArgs),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                          fontSize: 11)),

                  if (insight.recommendationKey != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(7)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.tips_and_updates_rounded, color: color, size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            insight.recommendationKey!.tr(
                                namedArgs: insight.recommendationNamedArgs),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.78),
                                fontSize: 10.5),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Row(children: [
                    _Tag(insight.category.labelKey.tr(), color),
                    if (insight.isAnomaly) ...[
                      const SizedBox(width: 5),
                      _Tag('⚡ Anomaly', _C.red),
                    ],
                    const Spacer(),
                    Text('Impact ',
                        style: TextStyle(
                            fontSize: 8.5,
                            color: theme.colorScheme.onSurface.withOpacity(0.35))),
                    SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: insight.impactScore / 100,
                          minHeight: 5,
                          backgroundColor: color.withOpacity(0.14),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w600)),
      );
}

// ═══════════════════════════════════════════════════════════════
//  RECOMMENDATION CARD
// ═══════════════════════════════════════════════════════════════

class _RecCard extends StatelessWidget {
  final Recommendation rec;
  const _RecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isUrgent = rec.isUrgent;
    final color    = isUrgent ? _C.red : _C.violet;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.07), color.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7)),
          child: Icon(
              isUrgent ? Icons.priority_high_rounded : Icons.task_alt_rounded,
              color: color, size: 14),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (isUrgent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: color,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('insights_urgent'.tr(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(rec.titleKey.tr(namedArgs: rec.titleNamedArgs),
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: color, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 3),
            Text(rec.descriptionKey.tr(namedArgs: rec.descriptionNamedArgs),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.62),
                    fontSize: 10.5)),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  READINESS NUDGE  (inline at bottom of list)
// ═══════════════════════════════════════════════════════════════

class _ReadinessNudge extends StatelessWidget {
  final DataReadinessStatus readiness;
  const _ReadinessNudge({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final progress = (readiness.totalDays / 300.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.14)),
      ),
      child: Row(children: [
        Icon(Icons.auto_graph_rounded,
            color: theme.colorScheme.primary, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('insights_readiness_progress'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 10)),
              Text('insights_days_of_data'.tr(
                      namedArgs: {'days': '${readiness.totalDays}'}),
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9, color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 5,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.1)),
            ),
            const SizedBox(height: 3),
            Text(
              readiness.hasTrendInsights
                  ? 'insights_unlock_seasonal'.tr(
                      namedArgs: {'days': '${readiness.daysUntilSeasonal}'})
                  : 'insights_unlock_trends'.tr(
                      namedArgs: {'days': '${readiness.daysUntilTrends}'}),
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.45)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DATA READINESS FULL VIEW  (< 14 days)
// ═══════════════════════════════════════════════════════════════

class _DataReadinessView extends StatelessWidget {
  final DataReadinessStatus readiness;
  const _DataReadinessView({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final progress = (readiness.totalDays / 14.0).clamp(0.0, 1.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.analytics_outlined, size: 34,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('insights_building_baseline_title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('insights_building_baseline_desc'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
          const SizedBox(height: 26),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 9)),
          const SizedBox(height: 10),
          Text('insights_days_of_data'
                  .tr(namedArgs: {'days': '${readiness.totalDays}'}),
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('insights_unlock_trends'
                  .tr(namedArgs: {'days': '${readiness.daysUntilTrends}'}),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FILTER BAR  (horizontal scrollable chip row)
// ═══════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final TimePeriod period;
  final FocusTag   focus;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final ValueChanged<FocusTag>   onFocusChanged;

  const _FilterBar({
    required this.period, required this.focus,
    required this.onPeriodChanged, required this.onFocusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.4))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          ...TimePeriod.values.map((p) => _Chip(
                label: p.labelKey.tr(),
                selected: period == p,
                color: theme.colorScheme.primary,
                onTap: () => onPeriodChanged(p),
              )),
          Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
              color: theme.dividerColor),
          ...FocusTag.values.map((f) => _Chip(
                label: f.labelKey.tr(),
                selected: focus == f,
                color: _C.violet,
                onTap: () => onFocusChanged(f),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color  color;
  final VoidCallback onTap;
  const _Chip({
    required this.label, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 5, top: 5, bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? color : color.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LOADING + ERROR VIEWS
// ═══════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: 12),
        Text('insights_generating'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme.onSurface.withOpacity(0.45))),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                color: _C.red, size: 26),
          ),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55))),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text('insights_generate_button'.tr()),
          ),
        ]),
      ),
    );
  }
}
