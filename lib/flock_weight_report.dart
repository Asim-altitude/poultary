import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/flock.dart';
import 'package:poultary/model/weight_record.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'database/databse_helper.dart';
import 'database/events_databse_helper.dart';
import 'model/event_item.dart';

// -----------------------------------------------------
// Helper Report Model
// -----------------------------------------------------
class WeightReportRow {
  final DateTime date;
  final double weight;
  final double change;

  WeightReportRow({
    required this.date,
    required this.weight,
    required this.change,
  });

  bool get isGain => change >= 0;
}

// -----------------------------------------------------
// UNIVERSAL WEIGHT REPORT SCREEN
// -----------------------------------------------------
class WeightReportScreen extends StatefulWidget {

  const WeightReportScreen({Key? key}) : super(key: key);

  @override
  State<WeightReportScreen> createState() => _WeightReportScreenState();
}

class _WeightReportScreenState extends State<WeightReportScreen> {
  List<Flock> flocks = [];

  Flock? selectedFlock;

  List<WeightRecord> weightEvents = [];
  List<WeightReportRow> report = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();

    _loadFlocks();
  }

  // -----------------------------------------------------
  Future<void> _loadFlocks() async {
    flocks = await DatabaseHelper.getFlocks();
    if(flocks.length > 0) {
      selectedFlock = flocks[0];
      _loadWeightData();
    }
    setState(() {});
  }


  Future<void> _loadWeightData() async {

    setState(() => loading = true);

    weightEvents = await DatabaseHelper.getWeightRecords(selectedFlock!.f_id);

    weightEvents.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    _generateReport();

    setState(() => loading = false);
  }

  void _generateReport() {
    report.clear();

    for (int i = 0; i < weightEvents.length; i++) {
      final double currentWeight = weightEvents[i].averageWeight;// double.tryParse( ?? '0') ?? 0;
      final DateTime date = DateTime.parse(weightEvents[i].date);

      double change = 0;
      if (i > 0) {
        final double prevWeight = weightEvents[i - 1].averageWeight; //double.tryParse( ?? '0') ?? 0;
        change = currentWeight - prevWeight;
      }

      report.add(WeightReportRow(date: date, weight: currentWeight, change: change));
    }
  }

  double get totalGain => report.length < 2 ? 0 : report.last.weight - report.first.weight;

  double get averageChange => report.length < 2 ? 0 : totalGain / (report.length - 1);

  Future<void> exportPDF(BuildContext context) async {
    Utils.setupInvoiceInitials("Weight Report", "ALL_TIME".tr());
    Utils.INVOICE_HEADING = "Weight Report";
    Utils.INVOICE_SUB_HEADING = selectedFlock!.f_name;
    Utils.weight_list = weightEvents;
    Utils.selectedWeightFlock = selectedFlock;
    Utils.initialWeight = report.first.weight;
    Utils.currentWeight = report.last.weight;
    Utils.changeWeight = totalGain;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  PDFScreen(item: 6,)),
    );

  }
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
           'Weight Report'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Export as PDF",
            onPressed: () => exportPDF(context),
          ),
          /* IconButton(
            icon: Icon(Icons.insert_drive_file, color: Colors.white),
            tooltip: "Export as CSV",
            onPressed: exportCSV,
          ),*/
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔽 Flock & Animal Selectors (only if animal not passed)
             _buildSelectors(),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : report.isEmpty
                  ? Center(child: Text('No weight records found'.tr()))
                  : report.isNotEmpty
                  ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 16),
                    _buildChart(),
                    const SizedBox(height: 16),
                    _buildWeightList(),
                  ],
                ),
              )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  Widget _buildSelectors() {
    return Row(
      children: [
        // Flock Dropdown
        Expanded(
          child: _dropdown<Flock>(
            label: 'CHOOSE_FLOCK_1'.tr(),
            value: selectedFlock,
            items: flocks,
            text: (f) => f.f_name,
            onChanged: (f) {
              setState(() {
                selectedFlock = f;
              });
              _loadWeightData();
            },
          ),
        ),

      ],
    );
  }


  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) text,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(text(e)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  Widget _buildSummary() {
    return Row(
      children: [
        _summaryCard('Initial'.tr(), '${report.first.weight.toStringAsFixed(2)} ${Utils.selected_unit.tr()}'),
        _summaryCard('Now'.tr(), '${report.last.weight.toStringAsFixed(2)} ${Utils.selected_unit.tr()}'),
        _summaryCard(
          'Total Change'.tr(),
          '${totalGain >= 0 ? '+' : ''}${totalGain.toStringAsFixed(2)} ${Utils.selected_unit.tr()}',
          color: totalGain >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, {Color? color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------
  Widget _buildChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SfCartesianChart(
          title: ChartTitle(text: 'Weight Report'.tr()),
          primaryXAxis: DateTimeAxis(dateFormat: DateFormat('dd MMM')),
          primaryYAxis: NumericAxis(title: AxisTitle(text: '${'Weight'.tr()} (${Utils.selected_unit.tr()})')),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CartesianSeries>[
            LineSeries<WeightReportRow, DateTime>(
              dataSource: report,
              xValueMapper: (data, _) => data.date,
              yValueMapper: (data, _) => data.weight,
              markerSettings: const MarkerSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  Widget _buildWeightList() {
    return Column(
      children: report.map((row) {
        return Card(
          child: ListTile(
            leading: Icon(
              row.change >= 0 ? Icons.trending_up : Icons.trending_down,
              color: row.change >= 0 ? Colors.green : Colors.red,
            ),
            title: Text(
              '${row.weight.toStringAsFixed(2)} ${Utils.selected_unit.tr()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('dd MMM yyyy').format(row.date)),
            trailing: Text(
              row.change == 0
                  ? 'Start'.tr()
                  : '${row.change >= 0 ? '+' : ''}${row.change.toStringAsFixed(2)} ${Utils.selected_unit.tr()}',
              style: TextStyle(
                color: row.change >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
