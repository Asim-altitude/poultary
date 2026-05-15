import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/weight_record.dart';
import 'package:poultary/utils/utils.dart';
import 'package:language_picker/languages.dart';
import '../../model/transaction_item.dart';
import '../model/ai_response.dart';
import '../network_api.dart';

// ─────────────────────────────────────────────────────────────
//  FinancialAnalysisScreen
//  Collects all financial inputs from JSON schema and assembles
//  the full payload including auto-calculated metrics.
// ─────────────────────────────────────────────────────────────
class FinancialAnalysisScreen extends StatefulWidget {
  final int flockId;
  final String flockName;
  final String birdType;
  final int ageDays;
  final int initialBirds;
  final int currentBirds;
  final String duration;

  const FinancialAnalysisScreen({
    Key? key,
    required this.flockId,
    required this.flockName,
    required this.birdType,
    required this.ageDays,
    required this.initialBirds,
    required this.currentBirds,
    required this.duration
  }) : super(key: key);

  @override
  State<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen>
    with TickerProviderStateMixin {

  // ── Step control ─────────────────────────────────────────
  int _step = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── THEME ─────────────────────────────────────────────────
  static const Color _bg       = Color(0xFFF7F9FC);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _accent   = Color(0xFF0062FF);
  static const Color _accentLt = Color(0xFFEEF3FF);
  static const Color _green    = Color(0xFF10B981);
  static const Color _greenLt  = Color(0xFFECFDF5);
  static const Color _red      = Color(0xFFEF4444);
  static const Color _redLt    = Color(0xFFFEF2F2);
  static const Color _amber    = Color(0xFFF59E0B);
  static const Color _amberLt  = Color(0xFFFFFBEB);
  static const Color _purple   = Color(0xFF8B5CF6);
  static const Color _purpleLt = Color(0xFFF5F3FF);
  static const Color _txt1     = Color(0xFF111827);
  static const Color _txt2     = Color(0xFF6B7280);
  static const Color _border   = Color(0xFFE5E7EB);
  static const Color _fieldBg  = Color(0xFFF9FAFB);

  // ── Income controllers ────────────────────────────────────
  final _birdSalesCtrl    = TextEditingController();
  final _eggSalesCtrl    = TextEditingController();
  final _otherIncomeCtrl  = TextEditingController();

  // ── Expense controllers ───────────────────────────────────
  final _feedCostCtrl        = TextEditingController();
  final _medicineCostCtrl    = TextEditingController();
  final _laborCostCtrl       = TextEditingController();
  final _electricityCostCtrl = TextEditingController();
  final _otherExpensesCtrl   = TextEditingController();

  // ── Performance controllers ───────────────────────────────
  final _avgWeightCtrl    = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  // ── Currency symbol ───────────────────────────────────────
  String _currency = Utils.currency;
  final List<String> _currencies = ['PKR', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];

  // ── Computed values ───────────────────────────────────────
  double get _totalIncome =>
      (_parse(_birdSalesCtrl) + _parse(_otherIncomeCtrl)+ _parse(_eggSalesCtrl));

  double get _totalExpenses =>
      (_parse(_feedCostCtrl) + _parse(_medicineCostCtrl) +
          _parse(_laborCostCtrl) + _parse(_electricityCostCtrl) +
          _parse(_otherExpensesCtrl));

  double get _profit => _totalIncome - _totalExpenses;

  double get _profitPerBird =>
      widget.currentBirds > 0 ? _profit / widget.currentBirds : 0;

  double get _costPerBird =>
      widget.currentBirds > 0 ? _totalExpenses / widget.currentBirds : 0;

  double get _revenuePerBird =>
      widget.currentBirds > 0 ? _totalIncome / widget.currentBirds : 0;

  double  _mortalityPercent = 0;
  int mortality = 0;

  // FCR = total feed / (current birds × avg weight)
  double get _fcr {
    double totalFeed = _parse(_feedCostCtrl); // feed cost used as proxy; real FCR needs feed kg
    double avgWt = _parse(_avgWeightCtrl);
    if (widget.currentBirds > 0 && avgWt > 0 && _feedKgCtrl.text.isNotEmpty) {
      return _parse(_feedKgCtrl) / (widget.currentBirds * avgWt);
    }
    return 0;
  }

  final _feedKgCtrl = TextEditingController(); // extra field for FCR

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '')) ?? 0;


  Future<void> generateFinancialAnalysisData({
    required List<TransactionItem> transactions,
    int? flockId,
  }) async {

    double parseAmount(String value) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    }

    String normalize(String value) {
      return value.toLowerCase().trim();
    }

    final filteredTransactions = flockId == null
        ? transactions
        : transactions.where((t) => t.f_id == flockId).toList();

    double birdSales = 0;
    double eggSales = 0;
    double manureSales = 0;
    double otherIncome = 0;

    double feedCost = 0;
    double medicineCost = 0;
    double vaccinationCost = 0;
    double laborCost = 0;
    double electricityCost = 0;
    double transportCost = 0;
    double maintenanceCost = 0;
    double rentCost = 0;
    double chickPurchaseCost = 0;
    double otherExpenses = 0;

    double totalIncome = 0;
    double totalExpenses = 0;

    Map<String, double> incomeByCategory = {};
    Map<String, double> expenseByCategory = {};

    for (final t in filteredTransactions) {
      final type = normalize(t.type);
      final amount = parseAmount(t.amount);

      if (amount <= 0) continue;

      if (type == "income") {
        final item = normalize(t.sale_item);

        totalIncome += amount;
        incomeByCategory[t.sale_item] =
            (incomeByCategory[t.sale_item] ?? 0) + amount;

        if (item.contains("bird") ||
            item.contains("broiler") ||
            item.contains("hen") ||
            item.contains("chicken") ||
            item.contains("sale")) {
          birdSales += amount;
        } else if (item.contains("egg")) {
          eggSales += amount;
        } else if (item.contains("manure") ||
            item.contains("litter")) {
          manureSales += amount;
        } else {
          otherIncome += amount;
        }


        _birdSalesCtrl.text = birdSales.toString();
        _eggSalesCtrl.text = eggSales.toString();
        _otherIncomeCtrl.text = (manureSales + otherIncome).toString();
      }

      else if (type == "expense") {
        final item = normalize(t.expense_item);

        totalExpenses += amount;
        expenseByCategory[t.expense_item] =
            (expenseByCategory[t.expense_item] ?? 0) + amount;

        if (item.contains("feed")) {
          feedCost += amount;
        } else if (item.contains("medicine") ||
            item.contains("medication") ||
            item.contains("treatment") ||
            item.contains("drug")) {
          medicineCost += amount;
        } else if (item.contains("vaccine") ||
            item.contains("vaccination")) {
          vaccinationCost += amount;
        } else if (item.contains("labor") ||
            item.contains("salary") ||
            item.contains("worker")) {
          laborCost += amount;
        } else if (item.contains("electric") ||
            item.contains("electricity") ||
            item.contains("power")) {
          electricityCost += amount;
        } else if (item.contains("transport") ||
            item.contains("vehicle") ||
            item.contains("fuel")) {
          transportCost += amount;
        } else if (item.contains("maintenance") ||
            item.contains("repair")) {
          maintenanceCost += amount;
        } else if (item.contains("rent")) {
          rentCost += amount;
        } else if (item.contains("chick") ||
            item.contains("purchase bird") ||
            item.contains("bird purchase")) {
          chickPurchaseCost += amount;
        } else {
          otherExpenses += amount;
        }

      }
    }

     profit = totalIncome - totalExpenses;

     feedCostPercent =
     totalExpenses == 0 ? 0 : (feedCost / totalExpenses) * 100;

     _feedCostCtrl.text = feedCost.toString();
     _medicineCostCtrl.text = (medicineCost+vaccinationCost).toString();
     _otherExpensesCtrl.text = (laborCost+electricityCost+otherExpenses).toString();


     WeightRecord? avgWeight = await DatabaseHelper.getLatestWeightRecord(widget.flockId);
     if(avgWeight != null)
       {
         _avgWeightCtrl.text = avgWeight.averageWeight.toString();
         _targetWeightCtrl.text = (avgWeight.averageWeight+1).toString();
       }

     num feedCosumed = await DatabaseHelper.getTotalFeedConsumption(widget.flockId, str_date, end_date);
     _feedKgCtrl.text = feedCosumed.toString();

      mortality = await DatabaseHelper.getFlockMortalityCount(widget.flockId);
     _mortalityPercent = (mortality / widget.currentBirds) * 100;

     setState(() {

     });
  }

  double feedCostPercent = 0;
  double profit = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Rebuild on any text change to update live metrics
    for (final c in _allControllers) {
      c.addListener(() => setState(() {}));
    }

    init();
  }

  Future<void> init() async {
   getData(widget.duration);
  }

  Future<void> initData() async {
    List<TransactionItem> transactions = await DatabaseHelper.getFilteredTransactions(widget.flockId, "All", str_date, end_date);
    await generateFinancialAnalysisData(transactions: transactions);
  }

  List<TextEditingController> get _allControllers => [
    _birdSalesCtrl,_eggSalesCtrl, _otherIncomeCtrl,
    _feedCostCtrl, _medicineCostCtrl, _laborCostCtrl,
    _electricityCostCtrl, _otherExpensesCtrl,
    _avgWeightCtrl, _targetWeightCtrl, _feedKgCtrl,
  ];

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _allControllers) c.dispose();
    super.dispose();
  }

  void _animateTo(int s) {
    _fadeCtrl.reset();
    setState(() => _step = s);
    _fadeCtrl.forward();
  }

  // ── Steps meta ────────────────────────────────────────────
  final List<Map<String, dynamic>> _steps = [
    {'label': 'Income',      'icon': Icons.trending_up_rounded},
    {'label': 'Expenses',    'icon': Icons.receipt_long_rounded},
    {'label': 'Performance', 'icon': Icons.speed_rounded},
    {'label': 'Summary',     'icon': Icons.bar_chart_rounded},
  ];

  bool get _canProceed {
    switch (_step) {
      case 0: return _birdSalesCtrl.text.isNotEmpty;
      case 1: return _feedCostCtrl.text.isNotEmpty;
      case 2: return _avgWeightCtrl.text.isNotEmpty && _targetWeightCtrl.text.isNotEmpty;
      default: return true;
    }
  }

  Map<String, dynamic> _buildPayload(String lang, String token) => {
    "analysis_type": "financial",
    "language": lang,
    "firebase_token":token,
    "flock": {
      "flock_name":    widget.flockName,
      "bird_type":     widget.birdType,
      "age_days":      widget.ageDays,
      "initial_birds": widget.initialBirds,
      "current_birds": widget.currentBirds,
    },
    "income": {
      "bird_sales":    _parse(_birdSalesCtrl),
      "egg_sales":    _parse(_eggSalesCtrl),
      "other_income":  _parse(_otherIncomeCtrl),
      "total_income":  _totalIncome,
    },
    "expenses": {
      "feed_cost":        _parse(_feedCostCtrl),
      "medicine_cost":    _parse(_medicineCostCtrl),
      "labor_cost":       _parse(_laborCostCtrl),
      "electricity_cost": _parse(_electricityCostCtrl),
      "other_expenses":   _parse(_otherExpensesCtrl),
      "total_expenses":   _totalExpenses,
    },
    "calculated_metrics": {
      "profit":           double.parse(_profit.toStringAsFixed(2)),
      "profit_per_bird":  double.parse(_profitPerBird.toStringAsFixed(2)),
      "cost_per_bird":    double.parse(_costPerBird.toStringAsFixed(2)),
      "revenue_per_bird": double.parse(_revenuePerBird.toStringAsFixed(2)),
      "mortality_percent":double.parse(_mortalityPercent.toStringAsFixed(2)),
      "fcr":              double.parse(_fcr.toStringAsFixed(2)),
    },
    "performance": {
      "average_weight": _parse(_avgWeightCtrl),
      "target_weight":  _parse(_targetWeightCtrl),
    },
    "currency": _currency,
  };

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Column(
        children: [
          _flockBanner(),
          _stepBar(),

        if (aiResponse == null && !isLoading)...[
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: _buildStepContent(),
              ),
            ),
          ),
    ],

          if (isLoading) _loadingWidget(),

          if (aiResponse != null) _responseCard(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }


  Widget _loadingWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff6A5AE0).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "AI is analyzing your flock...",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff1A1F36),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Generating smart feed and health recommendations",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: Color(0xffEEEEF5),
              valueColor: AlwaysStoppedAnimation(Color(0xff6A5AE0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _responseCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "AI Analysis Result",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              aiResponse ?? "",
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff2D3352),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }


  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      initData();
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      initData();
    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      initData();
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      initData();
    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      initData();
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      initData();
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      initData();
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      initData();
    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      initData();
    }

  }


  // ── APP BAR ───────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _white,
    foregroundColor: _txt1,
    centerTitle: true,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 8),
      const Text("Financial Analysis",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.3)),
    ]),
   /* actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _currencyPicker(),
      ),
    ],*/

  );

  Widget _currencyPicker() => GestureDetector(
    onTap: () => _showCurrencySheet(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _accentLt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_currency,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _accent),
      ]),
    ),
  );

  void _showCurrencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text("Select Currency",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _txt1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _currencies.map((c) {
              bool sel = _currency == c;
              return GestureDetector(
                onTap: () { setState(() => _currency = c); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: sel ? _accentLt : _fieldBg,
                    border: Border.all(color: sel ? _accent : _border, width: sel ? 1.5 : 1),
                  ),
                  child: Text(c, style: TextStyle(
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? _accent : _txt1, fontSize: 13,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── FLOCK BANNER ──────────────────────────────────────────
  Widget _flockBanner() => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: _greenLt, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.egg_alt_rounded, color: _green, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.flockName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _txt1)),
        const SizedBox(height: 2),
        Text("${widget.birdType} · ${widget.ageDays} days old · $_currency",
            style: const TextStyle(fontSize: 12, color: _txt2)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _pillBadge("${widget.currentBirds}", Icons.pets_rounded, _green, _greenLt),
        const SizedBox(height: 4),
        Text("of ${widget.initialBirds} birds",
            style: const TextStyle(fontSize: 11, color: _txt2)),
      ]),
    ]),
  );

  Widget _pillBadge(String text, IconData icon, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: fg),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    ]),
  );

  // ── STEP BAR ──────────────────────────────────────────────
  Widget _stepBar() => Container(
    decoration: BoxDecoration(
      color: _white,
      border: Border(top: BorderSide(color: _border), bottom: BorderSide(color: _border)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    child: Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          bool filled = _step > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2, margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: filled
                    ? const LinearGradient(colors: [_green, Color(0xFF059669)])
                    : null,
                color: filled ? null : _border,
              ),
            ),
          );
        }
        int s = i ~/ 2;
        bool active = _step == s;
        bool done   = _step > s;
        return Expanded(
          child: GestureDetector(
            onTap: done ? () => _animateTo(s) : null,
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _green : (active ? _greenLt : Colors.transparent),
                  border: Border.all(color: done || active ? _green : _border, width: 2),
                  boxShadow: active
                      ? [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 10)]
                      : [],
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : Icon(_steps[s]['icon'] as IconData,
                      size: 14, color: active ? _green : _txt2),
                ),
              ),
              const SizedBox(height: 4),
              Text(_steps[s]['label'] as String,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _green : _txt2,
                  )),
            ]),
          ),
        );
      }),
    ),
  );

  // ── STEP ROUTER ───────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _incomeStep();
      case 1: return _expensesStep();
      case 2: return _performanceStep();
      case 3: return _summaryStep();
      default: return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  STEP 0 — INCOME
  // ─────────────────────────────────────────────────────────
  Widget _incomeStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Income Details", Icons.trending_up_rounded,
          "Enter all revenue sources for this batch", _green, _greenLt),
      const SizedBox(height: 15),
      _groupCard(
        title: "Revenue",
        icon: Icons.attach_money_rounded,
        iconColor: _green,
        iconBg: _greenLt,
        children: [
          _label("Bird Sales *"),
          const SizedBox(height: 8),
          _numField(
            controller: _birdSalesCtrl,
            hint: "e.g. 320000",
            icon: Icons.storefront_rounded,
            suffix: _currency,
          ),
          const SizedBox(height: 14),
          _label("Egg Sales *"),
          const SizedBox(height: 8),
          _numField(
            controller: _eggSalesCtrl,
            hint: "e.g. 320000",
            icon: Icons.egg,
            suffix: _currency,
          ),
          const SizedBox(height: 14),
          _label("Other Income"),
          const SizedBox(height: 8),
          _numField(
            controller: _otherIncomeCtrl,
            hint: "Manure, by-products, etc.",
            icon: Icons.add_circle_outline_rounded,
            suffix: _currency,
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Live total card
      if (_totalIncome > 0) _liveTotalCard(
        label: "Total Income",
        value: _totalIncome,
        color: _green,
        icon: Icons.trending_up_rounded,
      ),
      const SizedBox(height: 10),
      _infoTip(Icons.lightbulb_outline_rounded, _green, _greenLt,
          "Include all income sources. Accurate data gives better AI financial recommendations."),
    ],
  );

  // ─────────────────────────────────────────────────────────
  //  STEP 1 — EXPENSES
  // ─────────────────────────────────────────────────────────
  Widget _expensesStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Expense Breakdown", Icons.receipt_long_rounded,
          "Enter all costs incurred for this batch", _red, _redLt),
      const SizedBox(height: 20),
      _groupCard(
        title: "Production Costs",
        icon: Icons.inventory_2_rounded,
        iconColor: _amber,
        iconBg: _amberLt,
        children: [
          _label("Feed Cost *"),
          const SizedBox(height: 8),
          _numField(controller: _feedCostCtrl,
              hint: "e.g. 210000", icon: Icons.restaurant_rounded, suffix: _currency),
          const SizedBox(height: 14),
          _label("Medicine & Vaccination Cost"),
          const SizedBox(height: 8),
          _numField(controller: _medicineCostCtrl,
              hint: "e.g. 18000", icon: Icons.medication_rounded, suffix: _currency),
        ],
      ),
      const SizedBox(height: 14),
      _groupCard(
        title: "Operational Costs",
        icon: Icons.business_center_rounded,
        iconColor: _purple,
        iconBg: _purpleLt,
        children: [
          _label("Labor Cost"),
          const SizedBox(height: 8),
          _numField(controller: _laborCostCtrl,
              hint: "e.g. 25000", icon: Icons.people_rounded, suffix: _currency),
          const SizedBox(height: 14),
          _label("Electricity Cost"),
          const SizedBox(height: 8),
          _numField(controller: _electricityCostCtrl,
              hint: "e.g. 12000", icon: Icons.bolt_rounded, suffix: _currency),
          const SizedBox(height: 14),
          _label("Other Expenses"),
          const SizedBox(height: 8),
          _numField(controller: _otherExpensesCtrl,
              hint: "Transport, chick cost, etc.", icon: Icons.more_horiz_rounded, suffix: _currency),
        ],
      ),
      const SizedBox(height: 16),
      if (_totalExpenses > 0) _liveTotalCard(
        label: "Total Expenses",
        value: _totalExpenses,
        color: _red,
        icon: Icons.receipt_long_rounded,
      ),
      const SizedBox(height: 12),

      // Live P&L mini preview
      if (_totalIncome > 0 && _totalExpenses > 0) _plPreviewCard(),

      const SizedBox(height: 12),
      _infoTip(Icons.info_outline_rounded, _amber, _amberLt,
          "Feed cost is usually 60–70% of total expenses in broiler farming. Verify your numbers."),
    ],
  );

  Widget _plPreviewCard() {
    bool positive = _profit >= 0;
    Color c = positive ? _green : _red;
    Color bg = positive ? _greenLt : _redLt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: c, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(positive ? "Profitable Batch 🎉" : "Loss Detected ⚠️",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c)),
          const SizedBox(height: 2),
          Text("${positive ? '+' : ''}${_fmt(_profit)} $_currency  ·  "
              "${_fmt(_profitPerBird)} per bird",
              style: TextStyle(fontSize: 12, color: c.withOpacity(0.8))),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STEP 2 — PERFORMANCE
  // ─────────────────────────────────────────────────────────
  Widget _performanceStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Flock Performance", Icons.speed_rounded,
          "Weight and feed conversion data for analysis", _purple, _purpleLt),
      const SizedBox(height: 20),
      _groupCard(
        title: "Weight Performance",
        icon: Icons.monitor_weight_rounded,
        iconColor: _purple,
        iconBg: _purpleLt,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label("Avg Weight (kg) *"),
              const SizedBox(height: 8),
              _numField(controller: _avgWeightCtrl,
                  hint: "e.g. 1.8", icon: Icons.scale_rounded, suffix: "kg", decimal: true),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label("Target Weight (kg) *"),
              const SizedBox(height: 8),
              _numField(controller: _targetWeightCtrl,
                  hint: "e.g. 2.0", icon: Icons.flag_rounded, suffix: "kg", decimal: true),
            ])),
          ]),
          if (_avgWeightCtrl.text.isNotEmpty && _targetWeightCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            _weightProgressBar(),
          ],
        ],
      ),
      const SizedBox(height: 16),
      _groupCard(
        title: "Feed Conversion Ratio (FCR)",
        icon: Icons.loop_rounded,
        iconColor: _amber,
        iconBg: _amberLt,
        children: [
          _label("Total Feed Consumed (kg)"),
          const SizedBox(height: 8),
          _numField(controller: _feedKgCtrl,
              hint: "Total kg of feed used in this batch",
              icon: Icons.restaurant_menu_rounded, suffix: "kg", decimal: true),
          if (_fcr > 0) ...[
            const SizedBox(height: 14),
            _fcrBadge(),
          ],
        ],
      ),
      const SizedBox(height: 16),
      _mortalityCard(),
      const SizedBox(height: 12),
      _infoTip(Icons.speed_rounded, _purple, _purpleLt,
          "Ideal FCR for broilers: 1.6–1.9. Lower is better. Target weight deviation affects revenue."),
    ],
  );

  Widget _weightProgressBar() {
    double avg    = _parse(_avgWeightCtrl);
    double target = _parse(_targetWeightCtrl);
    double pct    = (target > 0) ? (avg / target).clamp(0.0, 1.0) : 0;
    bool onTrack  = avg >= target * 0.95;
    Color c = onTrack ? _green : _amber;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Weight Progress",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _txt2)),
        Text("${(pct * 100).toStringAsFixed(0)}% of target",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          backgroundColor: _fieldBg,
          color: c,
        ),
      ),
      const SizedBox(height: 6),
      Text(onTrack ? "✅ On track with target weight" : "⚠️ Below target — ${((target - avg)).toStringAsFixed(2)} kg gap",
          style: TextStyle(fontSize: 11.5, color: c, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _fcrBadge() {
    double fcr = _fcr;
    String rating;
    Color c;
    if (fcr <= 1.7)      { rating = "Excellent"; c = _green; }
    else if (fcr <= 1.9) { rating = "Good";      c = _amber; }
    else if (fcr <= 2.2) { rating = "Average";   c = _amber; }
    else                  { rating = "Poor";      c = _red;   }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: c.withOpacity(0.08),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.loop_rounded, color: c, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("FCR: ${fcr.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c)),
          Text("Rating: $rating",
              style: TextStyle(fontSize: 11, color: c.withOpacity(0.8))),
        ]),
      ]),
    );
  }

  Widget _mortalityCard() {
    double pct = _mortalityPercent;
    Color c = pct <= 3 ? _green : (pct <= 6 ? _amber : _red);
    String label = pct <= 3 ? "Normal" : (pct <= 6 ? "Elevated" : "High — Investigate");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: c.withOpacity(0.07),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.monitor_heart_rounded, color: c, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Mortality Rate",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _txt2)),
          const SizedBox(height: 2),
          Text("${pct.toStringAsFixed(1)}%  ·  $label",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c)),
          Text("${mortality} birds lost from ${widget.currentBirds}",
              style: const TextStyle(fontSize: 11, color: _txt2)),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STEP 3 — SUMMARY
  // ─────────────────────────────────────────────────────────
  Widget _summaryStep() {
    bool profitable = _profit >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // P&L Hero card
        _plHeroCard(profitable),
        const SizedBox(height: 16),

        // Metrics grid
        _metricsGrid(),
        const SizedBox(height: 16),

        // Expense breakdown
        _expenseBreakdown(),
        const SizedBox(height: 16),

        // Full summary
        _fullSummaryCard(),
        const SizedBox(height: 24),

        // Analyze button
        _analyzeButton(),
      ],
    );
  }

  Widget _plHeroCard(bool profitable) {
    Color c = profitable ? _green : _red;
    Color bg = profitable ? _greenLt : _redLt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [c.withOpacity(0.12), c.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(profitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: c, size: 20),
          const SizedBox(width: 8),
          Text(profitable ? "Profitable Batch" : "Loss Recorded",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                  color: c, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 10),
        Text("${profitable ? '+' : ''}${_fmt(_profit)} $_currency",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                color: c, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text("${_fmt(_totalIncome)} income  −  ${_fmt(_totalExpenses)} expenses",
            style: TextStyle(fontSize: 12.5, color: c.withOpacity(0.7))),
      ]),
    );
  }

  Widget _metricsGrid() {
    final items = [
      {'label': 'Revenue/Bird',  'value': '${_fmt(_revenuePerBird)} $_currency', 'icon': Icons.person_rounded,            'color': _green},
      {'label': 'Cost/Bird',     'value': '${_fmt(_costPerBird)} $_currency',    'icon': Icons.receipt_rounded,           'color': _red},
      {'label': 'Profit/Bird',   'value': '${_fmt(_profitPerBird)} $_currency',  'icon': Icons.savings_rounded,           'color': _profit >= 0 ? _green : _red},
      {'label': 'Mortality',     'value': '${_mortalityPercent.toStringAsFixed(1)}%', 'icon': Icons.monitor_heart_rounded,'color': _mortalityPercent <= 3 ? _green : _amber},
      {'label': 'FCR',           'value': _fcr > 0 ? _fcr.toStringAsFixed(2) : '—', 'icon': Icons.loop_rounded,          'color': _amber},
      {'label': 'Weight Gap',    'value': _weightGap(),                          'icon': Icons.scale_rounded,             'color': _purple},
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        Color c = item['color'] as Color;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _white,
            border: Border.all(color: _border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(item['icon'] as IconData, size: 16, color: c),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['label'] as String,
                    style: const TextStyle(fontSize: 10.5, color: _txt2, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item['value'] as String,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        );
      },
    );
  }

  Widget _expenseBreakdown() {
    final items = [
      {'label': 'Feed',        'val': _parse(_feedCostCtrl),        'color': _amber},
      {'label': 'Medicine',    'val': _parse(_medicineCostCtrl),    'color': _red},
      {'label': 'Labor',       'val': _parse(_laborCostCtrl),       'color': _purple},
      {'label': 'Electricity', 'val': _parse(_electricityCostCtrl), 'color': _accent},
      {'label': 'Other',       'val': _parse(_otherExpensesCtrl),   'color': _txt2},
    ].where((e) => (e['val'] as double) > 0).toList();

    if (items.isEmpty || _totalExpenses == 0) return const SizedBox();

    return _groupCard(
      title: "Expense Breakdown",
      icon: Icons.pie_chart_rounded,
      iconColor: _purple,
      iconBg: _purpleLt,
      children: items.map((item) {
        double val = item['val'] as double;
        double pct = val / _totalExpenses;
        Color c = item['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item['label'] as String,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _txt1)),
              Text("${_fmt(val)} ($_currency  ·  ${(pct * 100).toStringAsFixed(0)}%)",
                  style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 6,
                backgroundColor: _fieldBg, color: c,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _fullSummaryCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [_accent.withOpacity(0.06), _accent.withOpacity(0.02)],
      ),
      border: Border.all(color: _accent.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.summarize_rounded, size: 16, color: _accent),
        const SizedBox(width: 6),
        const Text("Analysis Summary",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
      ]),
      const SizedBox(height: 14),
      _summaryRow("Flock",          widget.flockName),
      _summaryRow("Bird Type",      widget.birdType),
      _summaryRow("Age",            "${widget.ageDays} days"),
      _summaryRow("Birds",          "${widget.currentBirds} / ${widget.initialBirds}"),
      _summaryRow("Total Income",   "${_fmt(_totalIncome)} $_currency"),
      _summaryRow("Total Expenses", "${_fmt(_totalExpenses)} $_currency"),
      _summaryRow("Net Profit",     "${_fmt(_profit)} $_currency"),
      _summaryRow("Avg Weight",     "${_parse(_avgWeightCtrl)} kg"),
      _summaryRow("Target Weight",  "${_parse(_targetWeightCtrl)} kg"),
      if (_fcr > 0)
        _summaryRow("FCR", _fcr.toStringAsFixed(2)),
    ]),
  );

  Widget _summaryRow(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(k, style: const TextStyle(fontSize: 12.5, color: _txt2))),
      Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _txt1)),
    ]),
  );

  String _weightGap() {
    double avg = _parse(_avgWeightCtrl);
    double tgt = _parse(_targetWeightCtrl);
    if (avg == 0 || tgt == 0) return '—';
    double gap = tgt - avg;
    return gap <= 0 ? '✅ On target' : '-${gap.toStringAsFixed(2)} kg';
  }

  String? aiResponse = null;
  bool isLoading = false;
  // ── ANALYZE BUTTON ────────────────────────────────────────
  Widget _analyzeButton() => GestureDetector(
    onTap: () async {
      String? token = await FirebaseAuth.instance.currentUser!
          .getIdToken();

      Language _selectedCupertinoLanguage = await Utils.getSelectedLanguage();

      final payload = _buildPayload(_selectedCupertinoLanguage.name,token!);
      debugPrint(payload.toString());
      setState(() {
        isLoading = true;
      });

      // ==========================================
      // API RESPONSE
      // ==========================================
      final result = await AIServer.askHealthAI(payload);

      if (result == null) {
        Utils.showToast("Error occured");
        setState(() {
          isLoading = false;
        });

        return;
      }

      aiResponse = result;

      double weeks = widget.ageDays / 7;

      await DatabaseHelper.insertResponse(
        AIResponse(
          flockId: widget.flockId.toString(),
          category: "health",
          title: "health",
          response: aiResponse!,
          creditsUsed: 3,
          createdAt: DateTime.now(),
          birdCount: widget.currentBirds,
          ageWeeks: weeks.toInt(),
        ),
      );

      isLoading = false;

      setState(() {});
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (_) => AskAIDetailsScreen(payload: payload)));
    },
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: _green.withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.bar_chart_rounded, size: 20, color: Colors.white),
        SizedBox(width: 10),
        Text("Analyze Finances with AI",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 0.4)),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
      ]),
    ),
  );

  // ── BOTTOM BAR ────────────────────────────────────────────
  Widget _bottomBar() {
    bool isLast = _step == _steps.length - 1;
    return Container(
      decoration: BoxDecoration(
          color: _white, border: Border(top: BorderSide(color: _border))),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        if (_step > 0) ...[
          GestureDetector(
            onTap: () => _animateTo(_step - 1),
            child: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _fieldBg, border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _txt2),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (!isLast) Expanded(child: _nextBtn()),
      ]),
    );
  }

  Widget _nextBtn() {
    bool enabled = _canProceed;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => _animateTo(_step + 1) : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                : null,
            color: enabled ? null : _fieldBg,
            border: Border.all(color: enabled ? Colors.transparent : _border),
            boxShadow: enabled
                ? [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Next: ${_steps[_step + 1]['label']}",
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : _txt2, letterSpacing: 0.3,
                )),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 17,
                color: enabled ? Colors.white : _txt2),
          ]),
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, String sub, Color fg, Color bg) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bg,
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: fg.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7))),
          ])),
        ]),
      );

  Widget _groupCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _white,
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt1)),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          ...children,
        ]),
      );

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _txt2));

  Widget _numField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? suffix,
    bool decimal = false,
  }) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.]' : r'[0-9]')),
        ],
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: _txt1, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFD1D5DB)),
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: Icon(icon, size: 18, color: _txt2),
          suffixText: suffix,
          suffixStyle: const TextStyle(
              fontSize: 12.5, color: _txt2, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5)),
        ),
      );

  Widget _liveTotalCard({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.07),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text("$label: ",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _txt2)),
          Text("${_fmt(value)} $_currency",
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ]),
      );

  Widget _infoTip(IconData icon, Color fg, Color bg, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bg,
        border: Border.all(color: fg.withOpacity(0.2))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: fg),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.85), height: 1.5))),
    ]),
  );

  String _fmt(double v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000)    return "${(v / 1000).toStringAsFixed(1)}K";
    return v.toStringAsFixed(0);
  }
}