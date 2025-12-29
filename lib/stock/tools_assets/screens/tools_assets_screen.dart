import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';

import '../../../database/databse_helper.dart';
import '../../../model/transaction_item.dart';
import '../../../multiuser/utils/RefreshMixin.dart';
import '../../../utils/utils.dart';
import '../model/tool_asset.dart';
import '../model/tool_asset_unit.dart';
import 'asset_unit_screen.dart';

class ToolsAssetsScreen extends StatefulWidget {
  const ToolsAssetsScreen({super.key});

  @override
  State<ToolsAssetsScreen> createState() => _ToolsAssetsScreenState();
}

class _ToolsAssetsScreenState extends State<ToolsAssetsScreen> with RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.ASSET_TOOL_STOCK)
      {
        _loadAssets();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<ToolAssetMaster> assets = [];
  bool isLoading = true;

  final toolCategories = [
    "Hand Tool",
    "Power Tool",
    "Measuring Tool",
    "Repair Tool",
    "Electrical Tool",
    "Other",
  ];

  final assetCategories = [
    "Machinery",
    "Vehicle",
    "Equipment",
    "Infrastructure",
    "Storage",
    "Monitoring Device",
    "Other",
  ];


  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final data = await DatabaseHelper.getAllToolAssetMasters();
    setState(() {
      assets = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),),
          child: AppBar(
            foregroundColor: Colors.white,
            title: Text(
              "Tools and Assets".tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
            elevation: 8,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assets.isEmpty
          ? _emptyState()
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: assets.length,
        itemBuilder: (_, i) => _assetCard(assets[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssetDialog,
        icon: const Icon(Icons.add),
        label:  Text("Add Asset".tr()),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          Icon(Icons.build_circle_outlined, size: 90, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No tools or assets added".tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            "Add farm tools, machinery or assets to track condition & maintenance",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _assetCard(ToolAssetMaster asset) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetUnitScreen(master: asset)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ------------------ ICON OR IMAGE ------------------
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 12),

              // ------------------ TEXT INFO ------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.category.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<List<ToolAssetUnit>>(
                      future: DatabaseHelper.getUnitsByMaster(asset.id!),
                      builder: (_, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final units = snap.data!;
                        final good = units.where((e) => e.condition == "Good").length;
                        final repair = units.where((e) => e.condition == "Needs Repair").length;
                        final damaged = units.where((e) => e.condition == "Damaged").length;
                        return Text(
                          "${"TOTAL".tr()}: ${units.length} | "
                              "${"Good".tr()}: $good | "
                              "${"Repair".tr()}: $repair | "
                              "${"Damaged".tr()}: $damaged",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        );

                      },
                    ),
                  ],
                ),
              ),

              // ------------------ DELETE BUTTON ------------------
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () async {

                  if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_stock")){
                    Utils.showMissingPermissionDialog(context, "delete_stock");
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title:  Text("Delete".tr()),
                      content: Text("RU_SURE".tr()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                      ],
                    ),
                  );
                  if (confirm ?? false) {
                    await DatabaseHelper.deleteToolAssetMaster(asset.id!);

                    if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_stock")){
                      await FireBaseUtils.deleteAssetStockTransRecord(asset);
                    }

                    await _loadAssets();
                    setState(() {}); // Reload the list
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showAddAssetDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: "pcs");
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final customCatCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    String selectedType = "Asset";
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categories =
            selectedType == "Tool" ? toolCategories : assetCategories;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- GRAB HANDLE --------
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                   Text(
                    "Add Tool / Asset".tr(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 18),

                  // -------- NAME --------
                  TextField(
                    controller: nameCtrl,
                    decoration: _input("Name", Icons.label),
                  ),

                  const SizedBox(height: 14),

                  // -------- TYPE (Soft Selector) --------
                  Row(
                    children: ["Tool", "Asset"].map((type) {
                      final bool isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedType = type;
                              selectedCategory = null; // reset category when type changes
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type.tr(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // -------- CATEGORY --------
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: _input("Category", Icons.list_alt),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),

                  if (selectedCategory == "Other") ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customCatCtrl,
                      decoration: _input("Custom Category", Icons.edit),
                    ),
                  ],

                  const SizedBox(height: 14),

                  TextField(
                    controller: unitCtrl,
                    decoration: _input(
                      "Unit",
                      Icons.scale,
                    ),
                  ),

                  const SizedBox(width: 12),

                  /*const SizedBox(height: 14),*/

                  /*// -------- PURCHASE PRICE --------
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _input("Unit Purchase Price", Icons.currency_exchange),
                  ),*/

                /*  const SizedBox(height: 14),

                // -------- LOCATION (OPTIONAL) --------
                  TextField(
                    controller: locationCtrl,
                    decoration: _input("Location (optional)", Icons.location_on),
                  ),
*/
                  const SizedBox(height: 14),
                  // -------- DESCRIPTION --------
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: _input("Notes (optional)", Icons.notes),
                  ),

                  const SizedBox(height: 22),

                  // -------- SAVE BUTTON --------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty ||
                            selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                              content: Text("PROVIDE_ALL".tr()),
                            ),
                          );
                          return;
                        }


                        if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_stock")){
                          Utils.showMissingPermissionDialog(context, "add_stock");
                          return;
                        }

                        final now = DateTime.now();

                        // 1️⃣ Insert MASTER
                        final master = ToolAssetMaster(
                          name: nameCtrl.text.trim(),
                          category: selectedCategory == "Other"
                              ? customCatCtrl.text.trim()
                              : selectedCategory!,
                          type: selectedType,
                          unit: unitCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          createdAt: now.toIso8601String(),
                          sync_id: Utils.getUniueId(),
                          sync_status: SyncStatus.SYNCED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.currentUser == null ? '' : Utils.currentUser!.email,
                          farm_id: Utils.currentUser == null ? '' : Utils.currentUser!.farmId,
                        );

                        final masterId =
                        await DatabaseHelper.insertToolAssetMaster(master);

                        if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                          await FireBaseUtils.uploadAssetStockTransRecord(master);
                        }

                    /*    int? qty = int.parse(qtyCtrl.text);
                        num unit_price = double.parse(priceCtrl.text);

                        num total_price = qty * unit_price;

                        TransactionItem trItem = TransactionItem(f_id: -1, date: DateFormat('yyyy-MM-dd').format(now), f_name: "Farm Wide", sale_item: "", expense_item: nameCtrl.text, type: "Expense", amount: total_price.toString(), payment_method: "Cash", payment_status: "CLEARED", sold_purchased_from: "Unknown", short_note: "$qty units of ${nameCtrl.text} Purchased", how_many: qty.toString(), extra_cost: "extra_cost", extra_cost_details: "extra_cost_details", flock_update_id: "-1", unitPrice: unit_price.toDouble());
                        int? trId = await DatabaseHelper.insertNewTransaction(trItem);


                        // 2️⃣ Insert UNITS WITH PRICE & DATE
                        await DatabaseHelper.insertMultipleToolAssetUnitsWithPurchase(
                          masterId,
                          int.parse(qtyCtrl.text),
                          unitPrice: double.parse(priceCtrl.text),
                          purchaseDate: DateFormat('yyyy-MM-dd').format(now),
                          location: locationCtrl.text.trim().isEmpty
                              ? null
                              : locationCtrl.text.trim(),
                          trId: trId
                        );
*/
                        Navigator.pop(context);
                        _loadAssets();
                      },

                      child:  Text(
                        "SAVE".tr(),
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label.tr(),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }



}
