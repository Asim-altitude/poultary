import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/RefreshMixin.dart';
import 'package:poultary/stock/tools_assets/screens/unit_maintainance_screen.dart';

import '../../../database/databse_helper.dart';
import '../../../model/transaction_item.dart';
import '../../../multiuser/model/assetunitfb.dart';
import '../../../multiuser/utils/SyncStatus.dart';
import '../../../utils/utils.dart';
import '../model/tool_asset.dart';
import '../model/tool_asset_unit.dart';

class AssetUnitScreen extends StatefulWidget {
  final ToolAssetMaster master;

  const AssetUnitScreen({Key? key, required this.master}) : super(key: key);

  @override
  State<AssetUnitScreen> createState() => _AssetUnitScreenState();
}

class _AssetUnitScreenState extends State<AssetUnitScreen> with RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.ASSET_UNIT_STOCK)
      {
        _loadUnits();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<ToolAssetUnit> units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final data = await DatabaseHelper.getUnitsByMaster(widget.master.id!);
    setState(() => units = data);
  }

  void _showAddEditUnitDialog({ToolAssetUnit? unit}) {
    final conditionOptions = ["Good", "Fair", "Needs Repair", "Damaged"];
    final statusOptions = ["Active", "In Repair", "Lost", "Disposed"];

    String selectedCondition = unit?.condition ?? "Good";
    String selectedStatus = unit?.status ?? "Active";

    final assignedCtrl = TextEditingController(text: unit?.assignedTo ?? "");
    final notesCtrl = TextEditingController(text: unit?.notes ?? "");
    final priceCtrl =
    TextEditingController(text: unit?.purchasePrice.toString() ?? "0");
    final dateCtrl = TextEditingController(
        text: unit?.purchaseDate ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final assetCodeCtrl =
    TextEditingController(text: unit?.assetCode ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      unit == null
                          ? "Add Asset Unit".tr()
                          : "Edit Asset Unit".tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Asset Code
                    TextField(
                      controller: assetCodeCtrl,
                      decoration:
                      _input("Asset Code (optional)".tr(), Icons.qr_code),
                    ),
                    const SizedBox(height: 16),

                    // Condition
                    Text(
                      "Condition".tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 6),
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        return Wrap(
                          spacing: 8,
                          children: conditionOptions.map((c) {
                            final selected = selectedCondition == c;
                            return ChoiceChip(
                              label: Text(c.tr()),
                              selected: selected,
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.blue.shade300,
                              labelStyle: TextStyle(
                                color:
                                selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) =>
                                  setLocalState(() => selectedCondition = c),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Text(
                      "Status".tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 6),
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        return Wrap(
                          spacing: 8,
                          children: statusOptions.map((s) {
                            final selected = selectedStatus == s;
                            return ChoiceChip(
                              label: Text(s.tr()),
                              selected: selected,
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.green.shade300,
                              labelStyle: TextStyle(
                                color:
                                selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) =>
                                  setLocalState(() => selectedStatus = s),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Assigned To
                    TextField(
                      controller: assignedCtrl,
                      decoration:
                      _input("Assigned To (optional)".tr(), Icons.person),
                    ),
                    const SizedBox(height: 16),

                    // Price & Date
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                            _input("Price".tr(), Icons.currency_exchange),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            readOnly: true,
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate:
                                DateTime.tryParse(dateCtrl.text) ??
                                    DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                dateCtrl.text =
                                    DateFormat('yyyy-MM-dd').format(picked);
                              }
                            },
                            decoration: _input(
                                "Purchase Date".tr(), Icons.calendar_today),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration:
                      _input("Notes (optional)".tr(), Icons.notes),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          final now =
                          DateTime.now().toIso8601String();

                          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_stock")){
                            Utils.showMissingPermissionDialog(context, "add_stock");
                            return;
                          }

                          AssetUnitFBModel assetUnitModel;
                          if (unit == null)
                          {
                            TransactionItem trItem = TransactionItem(f_id: -1, date: DateFormat('yyyy-MM-dd').format(DateTime.now()), f_name: "Farm Wide", sale_item: "", expense_item: assetCodeCtrl.text, type: "Expense", amount: priceCtrl.text, payment_method: "Cash", payment_status: "CLEARED", sold_purchased_from: "Unknown", short_note: "${assetCodeCtrl.text} Purchased for ${priceCtrl.text}", how_many: "1", extra_cost: "extra_cost", extra_cost_details: "extra_cost_details", flock_update_id: "-1", unitPrice: double.parse(priceCtrl.text), sync_status: SyncStatus.SYNCED, last_modified: Utils.getTimeStamp(), modified_by: Utils.currentUser==null? "":Utils.currentUser!.email, farm_id: Utils.currentUser==null? "":Utils.currentUser!.farmId);
                            int? trId = await DatabaseHelper.insertNewTransaction(trItem);

                            var unit = ToolAssetUnit(
                              masterId: widget.master.id!,
                              assetCode: assetCodeCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : assetCodeCtrl.text.trim(),
                              condition: selectedCondition,
                              status: selectedStatus,
                              assignedTo: assignedCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : assignedCtrl.text.trim(),
                              purchasePrice:
                              double.tryParse(priceCtrl.text) ?? 0,
                              purchaseDate: dateCtrl.text,
                              notes: notesCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              createdAt: now,
                              trId: trId,
                              master_sync_id: widget.master.sync_id,
                              sync_id: Utils.getUniueId(),
                              sync_status: SyncStatus.SYNCED,
                              last_modified: Utils.getTimeStamp(),
                              modified_by: Utils.currentUser == null ? '' : Utils.currentUser!.email,
                              farm_id: Utils.currentUser == null ? '' : Utils.currentUser!.farmId,
                            );
                            await DatabaseHelper.insertToolAssetUnit(
                              unit
                            );
                           assetUnitModel = AssetUnitFBModel(unit: unit);
                           assetUnitModel.transaction = trItem;

                           if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                             await FireBaseUtils.uploadAssetUnitStockTransRecord(assetUnitModel);
                           }

                          }
                          else
                          {

                            TransactionItem? trItem = await DatabaseHelper.getSingleTransaction(unit.trId!.toString()); //TransactionItem(f_id: -1, date: DateFormat('yyyy-MM-dd').format(DateTime.now()), f_name: "Farm Wide", sale_item: "", expense_item: assetCodeCtrl.text, type: "Expense", amount: priceCtrl.text, payment_method: "Cash", payment_status: "CLEARED", sold_purchased_from: "Unknown", short_note: "${assetCodeCtrl.text} Purchased for ${priceCtrl.text}", how_many: "1", extra_cost: "extra_cost", extra_cost_details: "extra_cost_details", flock_update_id: "-1", unitPrice: double.parse(priceCtrl.text));
                            trItem!.unitPrice = double.tryParse(priceCtrl.text) ?? 0;
                            trItem.amount = priceCtrl.text;
                            trItem.expense_item = assetCodeCtrl.text;
                            trItem.short_note = notesCtrl.text;
                            await DatabaseHelper.updateTransaction(trItem);

                            var object = ToolAssetUnit(
                              id: unit.id,
                              masterId: unit.masterId,
                              assetCode: assetCodeCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : assetCodeCtrl.text.trim(),
                              condition: selectedCondition,
                              status: selectedStatus,
                              assignedTo: assignedCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : assignedCtrl.text.trim(),
                              purchasePrice:
                              double.tryParse(priceCtrl.text) ?? 0,
                              purchaseDate: dateCtrl.text,
                              notes: notesCtrl.text
                                  .trim()
                                  .isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              createdAt: unit.createdAt,
                              updatedAt: now,
                              trId: trItem.id,
                              master_sync_id: widget.master.sync_id,
                              sync_id: unit.sync_id,
                              sync_status: SyncStatus.UPDATED,
                              last_modified: Utils.getTimeStamp(),
                              modified_by: Utils.currentUser == null ? '' : Utils.currentUser!.email,
                              farm_id: Utils.currentUser == null ? '' : Utils.currentUser!.farmId,
                            );
                            await DatabaseHelper.updateToolAssetUnit(
                              object
                            );

                            assetUnitModel = AssetUnitFBModel(unit: object);
                            assetUnitModel.transaction = trItem;

                            if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_stock")){
                              await FireBaseUtils.updateAssetUnitStockTransRecord(assetUnitModel);
                            }
                          }
                          Navigator.pop(context);
                          _loadUnits();
                        },
                        child: Text(
                          "Save Unit".tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.master.name}"+"Units".tr())),
      body: units.isEmpty
          ?  Center(child: Text("No units added yet".tr()))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: units.length,
        itemBuilder: (context, index) {
          final u = units[index];
          return buildAssetUnitCard(u, index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUnitDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildAssetUnitCard(ToolAssetUnit u, int index) {
    // -------- Condition Color --------
    Color conditionColor;
    switch (u.condition) {
      case "Good":
        conditionColor = Colors.green.shade400;
        break;
      case "Fair":
        conditionColor = Colors.orange.shade400;
        break;
      case "Needs Repair":
        conditionColor = Colors.deepOrange.shade400;
        break;
      case "Damaged":
        conditionColor = Colors.red.shade400;
        break;
      default:
        conditionColor = Colors.grey.shade400;
    }

    // -------- Status Color --------
    Color statusColor;
    switch (u.status) {
      case "Active":
        statusColor = Colors.green.shade300;
        break;
      case "In Repair":
        statusColor = Colors.orange.shade300;
        break;
      case "Lost":
        statusColor = Colors.red.shade300;
        break;
      case "Disposed":
        statusColor = Colors.grey.shade400;
        break;
      default:
        statusColor = Colors.grey.shade300;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      // 🔥 OPEN MAINTENANCE LOG SCREEN
      onTap: () {
       u.assetCode = u.assetCode ?? "Unit".tr()+" ${index + 1}";
        /*Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetMaintenanceScreen(unit: u),
          ),
        );*/
      },

      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shadowColor: Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ---------------- ICON ----------------
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.precision_manufacturing,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              // ---------------- DETAILS ----------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.assetCode ?? "Unit".tr()+" ${index + 1}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Condition & Status
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _badge(u.condition, conditionColor),
                        _badge(u.status, statusColor),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Price".tr()+": ${u.purchasePrice.toStringAsFixed(2)} • "
                          "Date".tr()+": ${u.purchaseDate ?? ''}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------- ACTIONS ----------------
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _showAddEditUnitDialog(unit: u),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {

                      TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(u.trId.toString());
                      if(u.trId != null) {
                        await DatabaseHelper.deleteItem("Transactions", u.trId!);
                      }
                      await DatabaseHelper.deleteToolAssetUnit(u.id!);

                      u.master_sync_id = widget.master.sync_id;

                      AssetUnitFBModel assetUnitModel = AssetUnitFBModel(unit: u);
                      assetUnitModel.transaction = transaction;
                      if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_stock")){
                        await FireBaseUtils.deleteAssetUnitStockTransRecord(assetUnitModel);
                      }

                      _loadUnits();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

}
