import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/weight_record.dart';

class WeightRecordScreen extends StatefulWidget {
  final int flockId,birdsCount;
  const WeightRecordScreen({super.key, required this.flockId, required this.birdsCount});

  @override
  State<WeightRecordScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightRecordScreen> {
  List<WeightRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadWeightRecords();
  }

  Future<void> _loadWeightRecords() async {
    final records = await DatabaseHelper.getWeightRecords(widget.flockId);
    setState(() => _records = records);
  }

  void _showAddWeightDialog() {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),

                child: Row(
                  children:  [
                    SizedBox(width: 10),
                    Text(
                      "Add Per Bird Weight".tr(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Per Bird Weight".tr()+" (${Utils.selected_unit.tr()})",
                  hintText: "e.g. 1.85".tr(),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Notes".tr(),
                  prefixIcon: const Icon(Icons.note_alt),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Date".tr()+": ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label:  Text("Change".tr()),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  )
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label:  Text("SAVE".tr(), style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final weight = double.tryParse(weightController.text.trim());
                    final notes = notesController.text.trim();
                    if (weight != null && weight > 0) {
                      await DatabaseHelper.insertWeightRecord(
                        WeightRecord(
                          f_id: widget.flockId,
                          date: DateFormat('yyyy-MM-dd').format(selectedDate),
                          averageWeight: weight,
                          numberOfBirds: widget.birdsCount,
                          notes: notes,
                        ),
                      );
                      Navigator.pop(context);
                      _loadWeightRecords();
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text("Weight Records".tr()), backgroundColor: Utils.getThemeColorBlue(), foregroundColor: Colors.white,),
      body: _records.isEmpty
          ?  Center(child: Text("No weight records yet.".tr()))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _records.length,
        itemBuilder: (_, i) {
          final record = _records[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.monitor_weight, color: Colors.blue),
              title: Text("${record.averageWeight.toStringAsFixed(2)} "+Utils.selected_unit),
              subtitle: Text(Utils.getFormattedDate(record.date)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await DatabaseHelper.deleteWeightRecord(record.id!);
                  _loadWeightRecords();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWeightDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label:  Text("Add".tr(), style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
