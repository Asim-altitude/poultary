import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'dart:math';

import 'model/egg_item.dart';
import 'model/feed_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/transaction_item.dart';
import 'model/weight_record.dart';
import 'package:poultary/utils/utils.dart';

// ═══════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════
class _C {
  static const blue       = Color(0xFF1565C0);
  static const blueLight  = Color(0xFFE3F2FD);
  static const green      = Color(0xFF2E7D32);
  static const greenLight = Color(0xFFE8F5E9);
  static const greenMid   = Color(0xFF558B2F);
  static const amber      = Color(0xFFE65100);
  static const amberLight = Color(0xFFFFF3E0);
  static const red        = Color(0xFFC62828);
  static const redLight   = Color(0xFFFFEBEE);
  static const ink        = Color(0xFF1A1A2E);
  static const inkMid     = Color(0xFF4A4A6A);
  static const inkLight   = Color(0xFF9E9EBA);
  static const surface    = Color(0xFFF4F6FB);
  static const card       = Colors.white;
  static const border     = Color(0xFFE8EAF0);
  static const divider    = Color(0xFFF0F2F8);
}

// ═══════════════════════════════════════════════════════════════════
// PERFORMANCE METRICS MODEL
// ═══════════════════════════════════════════════════════════════════
class PerformanceMetrics {
  final double fcr;
  final double livabilityPercent;
  final double adgGrams;
  final double epef;
  final int totalMortality;
  final int totalCulls;
  final int ageDays;
  final double latestAvgWeightKg;
  final double totalFeedKg;
  final double totalWeightGainedKg;
  final double? henDayProductionPercent;
  final double? eggRejectionPercent;
  final int? totalGoodEggs;
  final int? totalBadEggs;
  final double birdSaleRevenue;
  final double eggSaleRevenue;
  final int birdsSold;
  final List<Map<String, dynamic>> fcrWeeklyTrend;
  final List<WeightRecord> weightRecords;

  const PerformanceMetrics({
    required this.fcr,
    required this.livabilityPercent,
    required this.adgGrams,
    required this.epef,
    required this.totalMortality,
    required this.totalCulls,
    required this.ageDays,
    required this.latestAvgWeightKg,
    required this.totalFeedKg,
    required this.totalWeightGainedKg,
    this.henDayProductionPercent,
    this.eggRejectionPercent,
    this.totalGoodEggs,
    this.totalBadEggs,
    required this.birdSaleRevenue,
    required this.eggSaleRevenue,
    required this.birdsSold,
    required this.fcrWeeklyTrend,
    required this.weightRecords,
  });
}

// ═══════════════════════════════════════════════════════════════════
// PERFORMANCE CALCULATOR
// ═══════════════════════════════════════════════════════════════════
class PerformanceCalculator {
  static PerformanceMetrics compute({
    required Flock flock,
    required List<Flock_Detail> flockDetails,
    required List<Feeding> feedingRecords,
    required List<WeightRecord> weightRecords,
    required List<Eggs> eggRecords,
    required List<TransactionItem> transactions,
  }) {
    final initialBirds = flock.bird_count ?? 0;
    final startDate    = DateTime.tryParse(flock.acqusition_date) ?? DateTime.now();
    final ageDays      = DateTime.now().difference(startDate).inDays.clamp(1, 9999);

    final reductions     = flockDetails.where((d) => d.item_type.toLowerCase() == 'reduction').toList();
    final totalMortality = reductions.where((d) => d.reason.toUpperCase() == 'MORTALITY').fold<int>(0, (s, d) => s + d.item_count);
    final totalCulls     = reductions.where((d) => d.reason.toUpperCase() == 'CULLING').fold<int>(0,  (s, d) => s + d.item_count);

    final survivingBirds    = (initialBirds - totalMortality - totalCulls).clamp(0, initialBirds);
    final livabilityPercent = initialBirds > 0 ? (survivingBirds / initialBirds) * 100 : 0.0;

    final sortedWeights = List<WeightRecord>.from(weightRecords)..sort((a, b) => a.date.compareTo(b.date));
    final latestWeight  = sortedWeights.isNotEmpty ? sortedWeights.last.averageWeight  : 0.0;
    final initialWeight = sortedWeights.isNotEmpty ? sortedWeights.first.averageWeight : 0.0;
    final latestAvgWeightKg = latestWeight;
    final adgGrams          = ageDays > 0 ? (latestWeight - initialWeight) / ageDays : 0.0;

    final totalFeedKg        = feedingRecords.fold<double>(0.0, (s, f) => s + (double.tryParse(f.quantity ?? '0') ?? 0.0));
    final totalWeightGainedKg = ((latestWeight - initialWeight) * survivingBirds);
    final fcr                 = totalWeightGainedKg > 0 ? totalFeedKg / totalWeightGainedKg : 0.0;
    final epef                = (fcr > 0 && ageDays > 0) ? (livabilityPercent * latestAvgWeightKg * 100) / (fcr * ageDays) : 0.0;

    final fcrWeeklyTrend = _computeWeeklyFCR(
      feedingRecords: feedingRecords,
      weightRecords: sortedWeights,
      initialBirds: survivingBirds,
    );

    double? henDayProductionPercent;
    double? eggRejectionPercent;
    int?    totalGoodEggs;
    int?    totalBadEggs;

    if (flock.purpose.toLowerCase().contains('layer') || flock.purpose.toLowerCase().contains('egg')) {
      totalGoodEggs = eggRecords.fold<int>(0, (s, e) => s + e.good_eggs);
      totalBadEggs  = eggRecords.fold<int>(0, (s, e) => s + e.bad_eggs);
      final totalEggs   = eggRecords.fold<int>(0, (s, e) => s + e.total_eggs);
      final activeBirds = flock.active_bird_count ?? survivingBirds;
      final recDays     = eggRecords.length.clamp(1, 9999);
      henDayProductionPercent = activeBirds > 0 ? (totalGoodEggs / (activeBirds * recDays)) * 100 : 0.0;
      eggRejectionPercent     = totalEggs > 0 ? (totalBadEggs! / totalEggs) * 100 : 0.0;
    }

    final birdSales       = transactions.where((t) => t.sale_item.toLowerCase() == 'bird sale');
    final eggSales        = transactions.where((t) => t.sale_item.toLowerCase() == 'egg sale');
    final birdSaleRevenue = birdSales.fold<double>(0.0, (s, t) => s + (double.tryParse(t.amount) ?? 0.0));
    final eggSaleRevenue  = eggSales.fold<double>(0.0,  (s, t) => s + (double.tryParse(t.amount) ?? 0.0));
    final birdsSold       = birdSales.fold<int>(0, (s, t) => s + (int.tryParse(t.how_many) ?? 0));

    return PerformanceMetrics(
      fcr: fcr, livabilityPercent: livabilityPercent, adgGrams: adgGrams, epef: epef,
      totalMortality: totalMortality, totalCulls: totalCulls, ageDays: ageDays,
      latestAvgWeightKg: latestAvgWeightKg, totalFeedKg: totalFeedKg,
      totalWeightGainedKg: totalWeightGainedKg, henDayProductionPercent: henDayProductionPercent,
      eggRejectionPercent: eggRejectionPercent, totalGoodEggs: totalGoodEggs,
      totalBadEggs: totalBadEggs, birdSaleRevenue: birdSaleRevenue,
      eggSaleRevenue: eggSaleRevenue, birdsSold: birdsSold,
      fcrWeeklyTrend: fcrWeeklyTrend, weightRecords: sortedWeights,
    );
  }

  static List<Map<String, dynamic>> _computeWeeklyFCR({
    required List<Feeding> feedingRecords,
    required List<WeightRecord> weightRecords,
    required int initialBirds,
  }) {
    if (feedingRecords.isEmpty || weightRecords.isEmpty) return [];
    final Map<int, double> feedByWeek = {};
    for (final f in feedingRecords) {
      final date = DateTime.tryParse(f.date ?? '');
      if (date == null) continue;
      final w = _isoWeek(date);
      feedByWeek[w] = (feedByWeek[w] ?? 0) + (double.tryParse(f.quantity ?? '0') ?? 0.0);
    }
    final weeks   = feedByWeek.keys.toList()..sort();
    final trend   = <Map<String, dynamic>>[];
    double cumFeed = 0;
    for (int i = 0; i < weeks.length; i++) {
      cumFeed += feedByWeek[weeks[i]]!;
      final wt = _weightNearWeek(weightRecords, weeks[i]);
      if (wt == null || wt <= 0) continue;
      final initKg = weightRecords.first.averageWeight;
      final gainKg = (wt - initKg) * initialBirds;
      if (gainKg > 0) trend.add({'week': 'Wk {}'.tr(args: [(i + 1).toString()]), 'fcr': cumFeed / gainKg});
    }
    return trend;
  }

  static double? _weightNearWeek(List<WeightRecord> records, int target) {
    WeightRecord? best;
    int bestDiff = 9999;
    for (final r in records) {
      final d = DateTime.tryParse(r.date);
      if (d == null) continue;
      final diff = (_isoWeek(d) - target).abs();
      if (diff < bestDiff) { bestDiff = diff; best = r; }
    }
    return best?.averageWeight;
  }

  static int _isoWeek(DateTime date) {
    final doy = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((doy - date.weekday + 10) / 7).floor();
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════
class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({super.key});

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  // State
  bool                  _loading        = true;
  List<Flock>           _flocks         = [];
  Flock?                _flock;
  List<Flock_Detail>    _flockDetails   = [];
  List<Feeding>         _feedings       = [];
  List<WeightRecord>    _weights        = [];
  List<Eggs>            _eggs           = [];
  List<TransactionItem> _transactions   = [];
  PerformanceMetrics?   _metrics;

  // Filter state
  String  _flockName   = '';
  int     _flockId     = -1;
  String  _filterKey   = 'THIS_MONTH';
  String  _filterLabel = 'THIS_MONTH';
  String  _strDate     = '';
  String  _endDate     = '';
  DateTimeRange? _range;
  List<String>   _flockNames = [];

  final List<String> _filterKeys = [
    'TODAY','YESTERDAY','THIS_MONTH','LAST_MONTH',
    'LAST3_MONTHS','LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // ── Data ─────────────────────────────────────────────────────────
  Future<void> _initData() async {
    _flocks = await DatabaseHelper.getFlocks();
    if (_flocks.isEmpty) { setState(() => _loading = false); return; }
    _flock     = _flocks.first;
    _flockId   = _flock!.f_id;
    _flockName = _flock!.f_name;
    _flockNames = _flocks.map((f) => f.f_name).toList();
    _applyFilter('THIS_MONTH');
  }

  Future<void> _loadData() async {
    if (_flock == null) return;
    setState(() => _loading = true);
    _flockDetails = await DatabaseHelper.getFilteredFlockDetails(_flock!.f_id, 'All', _strDate, _endDate);
    _feedings     = await DatabaseHelper.getFilteredFeeding(_flockId, 'All', _strDate, _endDate);
    _weights      = await DatabaseHelper.getWeightRecords(_flock!.f_id);
    _eggs         = await DatabaseHelper.getFilteredEggs(_flock!.f_id, 'All', _strDate, _endDate);
    _transactions = await DatabaseHelper.getFilteredTransactions(_flock!.f_id, 'All', _strDate, _endDate);
    _metrics = PerformanceCalculator.compute(
      flock: _flock!, flockDetails: _flockDetails, feedingRecords: _feedings,
      weightRecords: _weights, eggRecords: _eggs, transactions: _transactions,
    );
    setState(() => _loading = false);
  }

  void _selectFlock(String name) {
    for (final f in _flocks) {
      if (f.f_name == name) {
        _flock = f; _flockId = f.f_id; _flockName = f.f_name;
        break;
      }
    }
    _loadData();
  }

  // ── Date filter ───────────────────────────────────────────────────
  void _applyFilter(String key) {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    switch (key) {
      case 'TODAY':
        final d = DateTime.utc(now.year, now.month, now.day);
        _strDate = _endDate = fmt.format(d);
        break;
      case 'YESTERDAY':
        final d = DateTime.utc(now.year, now.month, now.day - 1);
        _strDate = _endDate = fmt.format(d);
        break;
      case 'THIS_MONTH':
        _strDate = fmt.format(DateTime.utc(now.year, now.month, 1));
        _endDate = fmt.format(DateTime.utc(now.year, now.month + 1).subtract(const Duration(days: 1)));
        break;
      case 'LAST_MONTH':
        _strDate = fmt.format(DateTime.utc(now.year, now.month - 1, 1));
        _endDate = fmt.format(DateTime.utc(now.year, now.month, 0));
        break;
      case 'LAST3_MONTHS':
        _strDate = fmt.format(DateTime.utc(now.year, now.month - 2, 1));
        _endDate = fmt.format(DateTime.utc(now.year, now.month, now.day));
        break;
      case 'LAST6_MONTHS':
        _strDate = fmt.format(DateTime.utc(now.year, now.month - 5, 1));
        _endDate = fmt.format(DateTime.utc(now.year, now.month, now.day));
        break;
      case 'THIS_YEAR':
        _strDate = fmt.format(DateTime.utc(now.year, 1, 1));
        _endDate = fmt.format(DateTime.utc(now.year, now.month, now.day));
        break;
      case 'LAST_YEAR':
        _strDate = fmt.format(DateTime.utc(now.year - 1, 1, 1));
        _endDate = fmt.format(DateTime.utc(now.year - 1, 12, 31));
        break;
      case 'ALL_TIME':
        _strDate = '1950-01-01';
        _endDate = fmt.format(now);
        break;
      case 'DATE_RANGE':
        _pickRange();
        return;
    }
    setState(() { _filterKey = key; _filterLabel = key; });
    _loadData();
  }

  Future<void> _pickRange() async {
    final now    = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate:  DateTime(now.year + 5),
      initialDateRange: _range ?? DateTimeRange(start: now, end: now),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: _C.blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      final fmt = DateFormat('yyyy-MM-dd');
      _range    = picked;
      _strDate  = fmt.format(picked.start);
      _endDate  = fmt.format(picked.end);
      final lbl = '${Utils.getFormattedDate(_strDate)} – ${Utils.getFormattedDate(_endDate)}';
      setState(() { _filterKey = 'DATE_RANGE'; _filterLabel = lbl; });
      _loadData();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    Utils.WIDTH_SCREEN  = MediaQuery.of(context).size.width;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height
        - MediaQuery.of(context).padding.top
        - MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.surface,
      appBar: _appBar(),
      body: Column(children: [
        _filterBar(),
        Expanded(child: _loading ? _loader() : _flock == null ? _empty() : _body()),
      ]),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _C.card,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: const IconThemeData(color: _C.ink),
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.insights_rounded, size: 18, color: _C.blue),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Performance Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.ink)),
        if (_flock != null)
          Text(_flock!.f_name,
            style: const TextStyle(fontSize: 11, color: _C.inkLight),
            overflow: TextOverflow.ellipsis),
      ])),
    ]),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: _C.border),
    ),
  );

  Widget _filterBar() => Container(
    color: _C.card,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(children: [
      // Flock dropdown
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _flockName.isEmpty ? null : _flockName,
            isExpanded: true,
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _C.inkMid),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink),
            onChanged: (v) { if (v != null) _selectFlock(v); },
            items: _flockNames.map((n) => DropdownMenuItem(
              value: n,
              child: Text(n, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink)),
            )).toList(),
          ),
        ),
      )),
      const SizedBox(width: 10),
      // Date filter chip
      GestureDetector(
        onTap: _showFilterSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _C.blueLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.blue.withOpacity(0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_rounded, size: 15, color: _C.blue),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Utils.WIDTH_SCREEN * 0.28),
              child: Text(_filterLabel.tr(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue),
                overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: _C.blue),
          ]),
        ),
      ),
    ]),
  );

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: _C.blue),
                const SizedBox(width: 8),
                Text('DATE_FILTER'.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink)),
              ]),
            ),
            Container(height: 1, color: _C.border),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filterKeys.length,
              itemBuilder: (_, i) {
                final key      = _filterKeys[i];
                final isActive = key == _filterKey;
                return InkWell(
                  onTap: () { Navigator.pop(ctx); _applyFilter(key); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    color: isActive ? _C.blueLight : Colors.transparent,
                    child: Row(children: [
                      Expanded(child: Text(key.tr(),
                        style: TextStyle(fontSize: 14, color: isActive ? _C.blue : _C.ink,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400))),
                      if (isActive)
                        const Icon(Icons.check_circle_rounded, size: 18, color: _C.blue),
                    ]),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ]),
        );
      },
    );
  }

  Widget _loader() => const Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(color: _C.blue, strokeWidth: 2.5),
      SizedBox(height: 16),
      Text('Calculating performance…', style: TextStyle(fontSize: 13, color: _C.inkLight)),
    ],
  ));

  Widget _empty() => const Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.flutter_dash, size: 48, color: _C.inkLight),
      SizedBox(height: 12),
      Text('No flocks found', style: TextStyle(fontSize: 15, color: _C.inkMid)),
    ],
  ));

  Widget _body() {
    final m       = _metrics!;
    final f       = _flock!;
    final isLayer = f.purpose.toLowerCase().contains('layer') ||
        f.purpose.toLowerCase().contains('egg');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FlockInfoCard(flock: f, ageDays: m.ageDays),
        const SizedBox(height: 20),

        _SectionHeader(
          title: 'Key Performance Indicators',
          subtitle: 'Based on {} data'.tr(args: [_filterLabel.tr()]),
        ),
        const SizedBox(height: 10),
        _KpiGrid(metrics: m),
        const SizedBox(height: 22),

        const _SectionHeader(title: 'Feed Conversion Ratio',
            subtitle: 'Total feed consumed ÷ total weight gained'),
        const SizedBox(height: 10),
        _FcrCard(metrics: m),
        const SizedBox(height: 22),

        if (_weights.isNotEmpty) ...[
          _SectionHeader(
            title: 'Weight & Growth (per Bird)',
            subtitle: '{} weigh-in records'.tr(args: [_weights.length.toString()]),
          ),
          const SizedBox(height: 10),
          _GrowthCard(weightRecords: _weights),
          const SizedBox(height: 22),
        ],

        const _SectionHeader(title: 'Flock Health & Mortality',
            subtitle: 'Deaths, culls and livability breakdown'),
        const SizedBox(height: 10),
        _MortalityCard(metrics: m, initialBirds: f.bird_count ?? 0),
        const SizedBox(height: 22),

        if (isLayer && m.henDayProductionPercent != null) ...[
          const _SectionHeader(title: 'Egg Performance',
              subtitle: 'Hen-day production and egg quality'),
          const SizedBox(height: 10),
          _EggCard(metrics: m),
          const SizedBox(height: 22),
        ],

        if (m.birdSaleRevenue > 0 || m.eggSaleRevenue > 0) ...[
          const _SectionHeader(title: 'Sales Summary',
              subtitle: 'Revenue from bird and egg sales'),
          const SizedBox(height: 10),
          _SalesCard(metrics: m),
          const SizedBox(height: 22),
        ],

        const _SectionHeader(title: 'Overall Efficiency Score',
            subtitle: 'European Production Efficiency Factor (EPEF)'),
        const SizedBox(height: 10),
        _EpefCard(metrics: m),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED UI PRIMITIVES
// ═══════════════════════════════════════════════════════════════════

// Uniform card shell
class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _CardShell({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

// Tinted section with selective rounded corners
class _TintSection extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool topRound;
  const _TintSection({required this.child, required this.color, this.topRound = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: topRound
          ? const BorderRadius.vertical(top: Radius.circular(16))
          : BorderRadius.zero,
    ),
    child: child,
  );
}

// Section header with blue left-bar accent
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 3, height: 34,
        margin: const EdgeInsets.only(right: 10, top: 1),
        decoration: BoxDecoration(color: _C.blue, borderRadius: BorderRadius.circular(2)),
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.tr(),    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.ink)),
        Text(subtitle.tr(), style: const TextStyle(fontSize: 11, color: _C.inkLight)),
      ])),
    ],
  );
}

// Status badge pill
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
    child: Text(label.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// ═══════════════════════════════════════════════════════════════════
// FLOCK INFO CARD
// ═══════════════════════════════════════════════════════════════════
class _FlockInfoCard extends StatelessWidget {
  final Flock flock;
  final int ageDays;
  const _FlockInfoCard({required this.flock, required this.ageDays});


  @override
  Widget build(BuildContext context) {
    final dateStr = flock.acqusition_date.length >= 10
        ? flock.acqusition_date.substring(0, 10)
        : flock.acqusition_date.isEmpty ? '—' : flock.acqusition_date;

    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      // Header
      _TintSection(color: _C.blue, topRound: true, child: Row(children: [
        Expanded(child: Text(flock.f_name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink),
          overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        _Pill(flock.active == 1 ? 'Active' : 'Closed',
          flock.active == 1 ? _C.green : _C.red),
        const SizedBox(width: 6),
        if (flock.purpose.isNotEmpty) _Pill(flock.purpose, _C.blue),
      ])),
      // Chips
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _ITile(Icons.egg_outlined,           'Initial Birds',  '${flock.bird_count ?? 0}',         _C.inkMid),
          _ITile(Icons.check_circle_outline,   'Active Birds',   '${flock.active_bird_count ?? 0}',  _C.green),
          _ITile(
            Icons.calendar_today_outlined,
            'Flock Age',
            '{} days'.tr(args: [ageDays.toString()]),
            _C.amber,
          ),
          _ITile(Icons.event_outlined,         'Started',        dateStr,                            _C.inkMid),
        ]),
      ),
    ]));
  }
}

class _ITile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ITile(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _C.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.tr(), style: const TextStyle(fontSize: 9, color: _C.inkLight, fontWeight: FontWeight.w500)),
        Text(value,  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.ink)),
      ]),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// KPI GRID  — 2×2, FittedBox prevents value overflow
// ═══════════════════════════════════════════════════════════════════
class _KpiGrid extends StatelessWidget {
  final PerformanceMetrics metrics;
  const _KpiGrid({required this.metrics});

  static String _fcrLbl(double v) { if (v==0) return 'No data'; if (v<1.8) return 'Excellent'; if (v<2.1) return 'Good'; if (v<2.4) return 'Average'; return 'Poor'; }
  static Color  _fcrCol(double v) { if (v==0) return _C.inkLight; if (v<1.8) return _C.green; if (v<2.1) return _C.greenMid; if (v<2.4) return _C.amber; return _C.red; }
  static String _livLbl(double v) { if (v>=96) return 'Excellent'; if (v>=93) return 'Good'; if (v>=90) return 'Average'; return 'High losses'; }
  static Color  _livCol(double v) { if (v>=96) return _C.green; if (v>=93) return _C.greenMid; if (v>=90) return _C.amber; return _C.red; }
  static String _epfLbl(double v) { if (v==0) return 'No data'; if (v>=350) return 'Excellent'; if (v>=280) return 'Good'; if (v>=200) return 'Average'; return 'Needs work'; }
  static Color  _epfCol(double v) { if (v==0) return _C.inkLight; if (v>=350) return _C.green; if (v>=280) return _C.greenMid; if (v>=200) return _C.amber; return _C.red; }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _KpiTile('FCR',         metrics.fcr.toStringAsFixed(2),         _fcrLbl(metrics.fcr),                _fcrCol(metrics.fcr),  Icons.swap_horiz_rounded,  'Feed ÷ weight gain\nLower = better')),
        const SizedBox(width: 10),
        Expanded(child: _KpiTile('Livability',  '${metrics.livabilityPercent.toStringAsFixed(1)}%', _livLbl(metrics.livabilityPercent), _livCol(metrics.livabilityPercent), Icons.favorite_rounded, 'Surviving birds\nTarget ≥ 96%')),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _KpiTile('Daily Gain',  '${metrics.adgGrams.toStringAsFixed(1)}g', 'per bird / day'.tr(), _C.blue, Icons.trending_up_rounded, 'Avg weight gained\nper bird per day')),
        const SizedBox(width: 10),
        Expanded(child: _KpiTile('EPEF Score',  metrics.epef.toStringAsFixed(2),        _epfLbl(metrics.epef),               _epfCol(metrics.epef), Icons.star_rounded,         'Overall efficiency\nTarget ≥ 280')),
      ]),
    ]);
  }
}

class _KpiTile extends StatelessWidget {
  final String label, value, status, hint;
  final Color color;
  final IconData icon;
  const _KpiTile(this.label, this.value, this.status, this.color, this.icon, this.hint);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(label.tr(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.inkMid),
          overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 10),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1.0))),
      const SizedBox(height: 8),
      _Pill(status, color),
      const SizedBox(height: 6),
      Text(hint.tr(), style: const TextStyle(fontSize: 9, color: _C.inkLight, height: 1.4)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// FCR CARD
// ═══════════════════════════════════════════════════════════════════
class _FcrCard extends StatelessWidget {
  final PerformanceMetrics metrics;
  const _FcrCard({required this.metrics});

  Color get _col {
    final v = metrics.fcr;
    if (v == 0) return _C.inkLight;
    if (v < 1.8) return _C.green; if (v < 2.1) return _C.greenMid;
    if (v < 2.4) return _C.amber; return _C.red;
  }
  String get _lbl {
    final v = metrics.fcr;
    if (v == 0) return 'No data'; if (v < 1.8) return 'Excellent';
    if (v < 2.1) return 'Good';   if (v < 2.4) return 'Average'; return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final c = _col;
    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      // Formula — vertical layout avoids Row overflow
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FCR Breakdown'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink)),
          const SizedBox(height: 12),
          _FRow(Icons.inventory_2_outlined,   'Total feed consumed',  '${metrics.totalFeedKg.toStringAsFixed(1)} '+"KG".tr()),
          Padding(padding: const EdgeInsets.fromLTRB(4, 3, 0, 3),
            child: Text('÷', style: TextStyle(fontSize: 22, color: _C.inkLight, fontWeight: FontWeight.w200))),
          _FRow(Icons.monitor_weight_outlined,'Total weight gained', '${metrics.totalWeightGainedKg.toStringAsFixed(1)} '+"KG".tr()),
          Padding(padding: const EdgeInsets.fromLTRB(4, 3, 0, 3),
            child: Text('=', style: TextStyle(fontSize: 22, color: _C.inkLight, fontWeight: FontWeight.w200))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.2))),
            child: Row(children: [
              Icon(Icons.swap_horiz_rounded, size: 18, color: c),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FCR Result'.tr(), style: TextStyle(fontSize: 10, color: c.withOpacity(0.8))),
                Text(metrics.fcr.toStringAsFixed(2),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c)),
              ]),
              const Spacer(),
              _Pill(_lbl, c),
            ]),
          ),
        ],
      )),

      // Benchmark footer
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: _C.surface,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             Text('Benchmark scale'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.inkMid)),
            if (metrics.fcr > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('Your FCR'.tr()+': ${metrics.fcr.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
            ),
          ]),
          const SizedBox(height: 10),
          _FcrBar(fcr: metrics.fcr),
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _BL('Excellent','< 1.8',   Color(0xFF4CAF50)),
            _BL('Good',    '1.8–2.1', Color(0xFF8BC34A)),
            _BL('Average', '2.1–2.4', Color(0xFFFFC107)),
            _BL('Poor',    '> 2.4',   Color(0xFFF44336)),
          ]),
          if (metrics.fcrWeeklyTrend.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: _C.border),
            const SizedBox(height: 14),
             Text('Weekly FCR trend'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.inkMid)),
            const SizedBox(height: 10),
            _FcrTrend(trend: metrics.fcrWeeklyTrend),
          ],
        ]),
      ),
    ]));
  }
}

class _FRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _FRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 15, color: _C.inkMid),
      const SizedBox(width: 10),
      Expanded(child: Text(label.tr(), style: const TextStyle(fontSize: 12, color: _C.inkMid))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink)),
    ]),
  );
}

class _BL extends StatelessWidget {
  final String s, r;
  final Color c;
  const _BL(this.s, this.r, this.c);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(s.tr(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c)),
    Text(r.tr(), style: TextStyle(fontSize: 8, color: c.withOpacity(0.8))),
  ]);
}

class _FcrBar extends StatelessWidget {
  final double fcr;
  const _FcrBar({required this.fcr});

  @override
  Widget build(BuildContext context) {
    final pos = ((fcr - 1.0) / 2.0).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (ctx, box) => Stack(clipBehavior: Clip.none, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(height: 12, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFFFC107), Color(0xFFF44336)])))),
      if (fcr > 0)
        Positioned(
          left: (box.maxWidth * pos - 10).clamp(0.0, box.maxWidth - 20),
          top: -4,
          child: Container(width: 20, height: 20,
            decoration: BoxDecoration(
              color: _C.card, shape: BoxShape.circle,
              border: Border.all(color: _C.ink, width: 2.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]))),
    ]));
  }
}

class _FcrTrend extends StatelessWidget {
  final List<Map<String, dynamic>> trend;
  const _FcrTrend({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxFcr = trend.fold<double>(0.0, (m, e) => max(m, e['fcr'] as double));
    final barMax = max(maxFcr, 2.5);

    return SizedBox(
      height: 90,
      child: ClipRect( // prevents any overflow
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trend.map((e) {
            final fcr  = e['fcr'] as double;
            final frac = barMax > 0 ? (fcr / barMax).clamp(0.0, 1.0) : 0.0;

            final col = fcr < 1.8
                ? const Color(0xFF4CAF50)
                : fcr < 2.1
                ? const Color(0xFF8BC34A)
                : fcr < 2.4
                ? const Color(0xFFFFC107)
                : const Color(0xFFF44336);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Top value
                    Text(
                      fcr.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 8, color: _C.inkLight),
                    ),
                    const SizedBox(height: 3),

                    // Flexible bar (NO overflow now)
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: frac < 0.05 ? 0.05 : frac,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Bottom label
                    Text(
                      e['week'] as String,
                      style: const TextStyle(fontSize: 9, color: _C.inkLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════
// GROWTH CARD
// ═══════════════════════════════════════════════════════════════════
class _GrowthCard extends StatelessWidget {
  final List<WeightRecord> weightRecords;
  const _GrowthCard({required this.weightRecords});

  @override
  Widget build(BuildContext context) {
    final sorted  = List<WeightRecord>.from(weightRecords)..sort((a, b) => a.date.compareTo(b.date));
    final initial = sorted.first.averageWeight;
    final latest  = sorted.last.averageWeight;
    final gain    = latest - initial;

    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          _GStat('Initial Weight', '${initial.toStringAsFixed(2)}'+"KG".tr(), Icons.start_rounded,            _C.inkMid),
          _GStat('Current Weight', '${latest.toStringAsFixed(2)}'+"KG".tr(),  Icons.monitor_weight_outlined,  _C.blue),
          _GStat('Total Gain',     '+${gain.toStringAsFixed(2)}'+"KG".tr(),   Icons.trending_up_rounded,      gain >= 0 ? _C.green : _C.red),
        ])),
      if (sorted.length > 1) ...[
        Container(height: 1, color: _C.divider),
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Text('Weight records over time'.tr(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.inkMid)),
            const SizedBox(height: 12),
            _WTimeline(records: sorted),
          ])),
      ],
    ]));
  }
}

class _GStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _GStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.15))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.tr(), style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
    ]),
  );
}

class _WTimeline extends StatelessWidget {
  final List<WeightRecord> records;
  const _WTimeline({required this.records});

  @override
  Widget build(BuildContext context) {
    final maxW = records.fold<double>(0.0, (m, r) => max(m, r.averageWeight));
    return Column(children: records.map((r) {
      final frac    = maxW > 0 ? r.averageWeight / maxW : 0.0;
      final dateStr = r.date.length >= 10 ? r.date.substring(0, 10) : r.date;
      return Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(width: 88, child: Text(dateStr,
            style: const TextStyle(fontSize: 10, color: _C.inkLight), overflow: TextOverflow.ellipsis)),
          Expanded(child: Stack(children: [
            Container(height: 10, decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(widthFactor: frac, child: Container(height: 10,
              decoration: BoxDecoration(color: _C.blue.withOpacity(0.75), borderRadius: BorderRadius.circular(5)))),
          ])),
          const SizedBox(width: 10),
          SizedBox(width: 52, child: Text('${r.averageWeight.toStringAsFixed(2)} '+"KG".tr(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.ink),
            textAlign: TextAlign.right)),
        ]));
    }).toList());
  }
}

// ═══════════════════════════════════════════════════════════════════
// MORTALITY CARD
// ═══════════════════════════════════════════════════════════════════
class _MortalityCard extends StatelessWidget {
  final PerformanceMetrics metrics;
  final int initialBirds;
  const _MortalityCard({required this.metrics, required this.initialBirds});

  @override
  Widget build(BuildContext context) {
    final morPct = initialBirds > 0 ? (metrics.totalMortality / initialBirds) * 100 : 0.0;
    final culPct = initialBirds > 0 ? (metrics.totalCulls     / initialBirds) * 100 : 0.0;
    final surPct = (100 - morPct - culPct).clamp(0.0, 100.0);
    final surCnt = initialBirds - metrics.totalMortality - metrics.totalCulls;
    final w      = (MediaQuery.of(context).size.width - 28 - 56) / 3;

    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      // Colour bar
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(height: 8, child: Row(children: [
          if (metrics.totalMortality > 0) Flexible(flex: morPct.round().clamp(1,100), child: Container(color: _C.red)),
          if (metrics.totalCulls > 0)     Flexible(flex: culPct.round().clamp(1,100), child: Container(color: _C.amber)),
          Flexible(flex: surPct.round().clamp(1,100), child: Container(color: _C.green)),
        ])),
      ),
      // Tiles
      Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          _MortTile('Dead',      metrics.totalMortality, morPct, _C.red,   _C.redLight,   Icons.remove_circle_outline,       w),
          const SizedBox(width: 10),
          _MortTile('Culled',    metrics.totalCulls,     culPct, _C.amber, _C.amberLight, Icons.content_cut_rounded,         w),
          const SizedBox(width: 10),
          _MortTile('Surviving', surCnt, metrics.livabilityPercent, _C.green, _C.greenLight, Icons.check_circle_outline_rounded, w),
        ]),
      ),
      // Legend
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          _dot(_C.red),  const SizedBox(width: 4),  Text('Dead'.tr()+'   ', style: TextStyle(fontSize: 10, color: _C.inkLight)),
          _dot(_C.amber),const SizedBox(width: 4),  Text('Culled'.tr()+'   ', style: TextStyle(fontSize: 10, color: _C.inkLight)),
          _dot(_C.green),const SizedBox(width: 4),  Text('Surviving'.tr(), style: TextStyle(fontSize: 10, color: _C.inkLight)),
        ]),
      ),
    ]));
  }

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _MortTile extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color, bgColor;
  final IconData icon;
  final double width;
  const _MortTile(this.label, this.count, this.percent, this.color, this.bgColor, this.icon, this.width);

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const Spacer(),
        Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color))),
      Text(label.tr(), style: TextStyle(fontSize: 10, color: color.withOpacity(0.75), fontWeight: FontWeight.w500)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// EGG CARD
// ═══════════════════════════════════════════════════════════════════
class _EggCard extends StatelessWidget {
  final PerformanceMetrics metrics;
  const _EggCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final hdp    = metrics.henDayProductionPercent ?? 0.0;
    final rej    = metrics.eggRejectionPercent    ?? 0.0;
    final hdpCol = hdp >= 80 ? _C.green : hdp >= 70 ? _C.amber : _C.red;
    final rejCol = rej < 3  ? _C.green : rej < 6   ? _C.amber : _C.red;
    final w      = (MediaQuery.of(context).size.width - 28 - 56) / 3;

    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      // HDP hero
      _TintSection(color: hdpCol, topRound: true, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.egg_outlined, size: 14, color: hdpCol),
            const SizedBox(width: 8),
             Expanded(child: Text('Hen-Day Production (HDP)'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink))),
             Text('Target ≥ 80%'.tr(), style: TextStyle(fontSize: 10, color: _C.inkLight)),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${hdp.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: hdpCol)),
            const SizedBox(width: 10),
            Padding(padding: const EdgeInsets.only(bottom: 5),
              child: _Pill(hdp >= 80 ? 'Excellent' : hdp >= 70 ? 'Good' : 'Low', hdpCol)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (hdp / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: hdpCol.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(hdpCol),
            ),
          ),
        ],
      )),
      // Egg stats row — fixed width tiles, no overflow
      Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          _EggTile('Good Eggs',     '${metrics.totalGoodEggs ?? 0}', 'collected', _C.green, w),
          const SizedBox(width: 10),
          _EggTile('Spoilt Eggs',   '${metrics.totalBadEggs ?? 0}',  'rejected',  _C.red,   w),
          const SizedBox(width: 10),
          _EggTile('Rejection Rate','${rej.toStringAsFixed(1)}%',
            rej < 3 ? 'Normal' : rej < 6 ? 'Moderate' : 'High', rejCol, w),
        ]),
      ),
    ]));
  }
}

class _EggTile extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final double width;
  const _EggTile(this.label, this.value, this.sub, this.color, this.width);

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.15))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.tr(), style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))),
      Text(sub, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// SALES CARD
// ═══════════════════════════════════════════════════════════════════
class _SalesCard extends StatelessWidget {
  final PerformanceMetrics metrics;
  const _SalesCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total = metrics.birdSaleRevenue + metrics.eggSaleRevenue;
    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      _TintSection(color: _C.green, topRound: true,
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _C.green.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: _C.green)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Text('Total Revenue'.tr(), style: TextStyle(fontSize: 11, color: _C.inkLight, fontWeight: FontWeight.w500)),
            Text('Rs'.tr()+' ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _C.green)),
          ]),
        ]),
      ),
      if (metrics.birdSaleRevenue > 0)
        _SRow(Icons.storefront_outlined, 'Bird Sales', '${metrics.birdsSold} birds sold', metrics.birdSaleRevenue, _C.blue),
      if (metrics.birdSaleRevenue > 0 && metrics.eggSaleRevenue > 0)
        Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: _C.divider),
      if (metrics.eggSaleRevenue > 0)
        _SRow(Icons.egg_outlined, 'Egg Sales', 'from egg records', metrics.eggSaleRevenue, _C.amber),
    ]));
  }
}

class _SRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final double revenue;
  final Color color;
  const _SRow(this.icon, this.label, this.sub, this.revenue, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink)),
        Text(sub.tr(),   style: const TextStyle(fontSize: 10, color: _C.inkLight)),
      ])),
      Text('Rs'.tr()+' ${revenue.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// EPEF CARD
// ═══════════════════════════════════════════════════════════════════
class _EpefCard extends StatelessWidget {
  final PerformanceMetrics metrics;
  const _EpefCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final epef  = metrics.epef;
    final color = epef >= 350 ? _C.green : epef >= 280 ? _C.greenMid : epef >= 200 ? _C.amber : _C.red;
    final label = epef >= 350 ? 'Excellent' : epef >= 280 ? 'Good' : epef >= 200 ? 'Average' : 'Needs work';

    return _CardShell(padding: EdgeInsets.zero, child: Column(children: [
      _TintSection(color: color, topRound: true,
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.star_rounded, size: 18, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('EPEF Score', style: TextStyle(fontSize: 11, color: _C.inkLight, fontWeight: FontWeight.w500)),
            const Text('European Production Efficiency Factor',
              style: TextStyle(fontSize: 10, color: _C.inkLight)),
          ])),
          // FittedBox prevents large number overflow
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FittedBox(child: Text(epef.toStringAsFixed(2),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color))),
            _Pill(label, color),
          ]),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
           Text("How it's calculated".tr(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.inkMid)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Text('(Livability% × Avg weight kg × 100) ÷ (FCR × Age days)'.tr(),
                style: TextStyle(fontSize: 10, color: _C.inkLight, fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text(
                '= (${metrics.livabilityPercent.toStringAsFixed(1)}% × '
                '${metrics.latestAvgWeightKg.toStringAsFixed(2)}kg × 100) ÷ '
                '(${metrics.fcr.toStringAsFixed(2)} × ${metrics.ageDays}d)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _EB('< 200',   'Poor',      _C.red),
            const SizedBox(width: 6),
            _EB('200–280', 'Average',   _C.amber),
            const SizedBox(width: 6),
            _EB('280–350', 'Good',      _C.greenMid),
            const SizedBox(width: 6),
            _EB('> 350',   'Excellent', _C.green),
          ]),
        ]),
      ),
    ]));
  }
}

class _EB extends StatelessWidget {
  final String range, status;
  final Color color;
  const _EB(this.range, this.status, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(status.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(range,  style: TextStyle(fontSize: 8, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
    ]),
  ));
}
