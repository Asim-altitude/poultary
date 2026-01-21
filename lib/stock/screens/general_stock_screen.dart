import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/RefreshMixin.dart';

import '../../multiuser/utils/SyncStatus.dart';
import '../../utils/fb_analytics.dart';
import '../../utils/utils.dart';
import '../model/general_stock.dart';
import 'general_stock_transactions.dart';

class GeneralStockScreen extends StatefulWidget {
  const GeneralStockScreen({super.key});

  @override
  State<GeneralStockScreen> createState() => _GeneralStockScreenState();
}

class _GeneralStockScreenState extends State<GeneralStockScreen> with RefreshMixin {
  List<GeneralStockItem> items = [];
  bool loading = true;


  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.GENERAL_STOCK) {
       _loadItems();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();

    AnalyticsUtil.logScreenView(screenName: "gen_stock_screen");
  }

  Future<void> _loadItems() async {
    final result = await DatabaseHelper.getAllGeneralStockItems();
    List<GeneralStockItem> updated = [];

    for (var item in result) {
      double totalIn = await DatabaseHelper.getTotalInForItem(item.id!);
      double totalOut = await DatabaseHelper.getTotalOutForItem(item.id!);

      item.totalIn = totalIn;
      item.totalOut = totalOut;

      updated.add(item);
    }

    setState(() {
      loading = false;
      items = updated;
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
            bottomRight: Radius.circular(0.0),
          ),
          child: AppBar(
            title: Text(
              "General Stock".tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            elevation: 8,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_stock")){
            Utils.showMissingPermissionDialog(context, "add_stock");
            return;
          }

          _showAddItemDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ?  Center(
        child: Text(
          "No stock items created".tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
    final item = items[index];
    return InkWell(
      onTap: ()  async {
       await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  GeneralStockTransactionsScreen(generalStockItem: item,)),);

       await _loadItems();
      },
        child: buildStockCard(item));
    }
        ),
    );
  }


  Widget buildStockCard(GeneralStockItem item) {
    bool isLowStock = item.currentQuantity <= item.minQuantity;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ------------------ IMAGE OR ICON ------------------
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                item.image!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2,
                    size: 32, color: Colors.black54),
              ),
            ),

            const SizedBox(width: 12),

            // ------------------ MAIN INFO ------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- NAME ----------
                  Text(
                    item.name.tr(),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  // ---------- CATEGORY ----------
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item.category.tr(),
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /*// ---------- QUANTITY ----------
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 16,
                        color: isLowStock ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Stock: ${item.currentQuantity} ${item.unit}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isLowStock ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),*/

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.call_received, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text("IN".tr()+": ${item.totalIn}", style: TextStyle(fontSize: 13)),

                      const SizedBox(width: 12),

                      Icon(Icons.call_made, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text("OUT".tr()+": ${item.totalOut}", style: TextStyle(fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        "Stock".tr()+": ${item.totalIn! - item.totalOut!} ${item.unit}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // ---------- LOW STOCK BADGE ----------
                  if (isLowStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Low stock • Min".tr()+": ${item.minQuantity}",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ------------------ DELETE BUTTON ------------------
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                bool confirmed = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title:  Text("Confirm Delete".tr()),
                    content:  Text(
                        "Are you sure you want to delete this stock item?".tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child:  Text("CANCEL".tr()),
                      ),
                      TextButton(
                        onPressed: () async {

                          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_stock")){
                            Utils.showMissingPermissionDialog(context, "delete_stock");
                            return;
                          }

                          final transactions = await DatabaseHelper.getStockTransactionsForItem(item.id!);

                          for(int i=0;i<transactions.length;i++) {

                            if(transactions[i].trId != null)
                             await DatabaseHelper.deleteItem("Transactions", transactions[i].trId!);

                          }

                          await DatabaseHelper.deleteGeneralStockItem(item.id!);
                          await DatabaseHelper.deleteStockTransactionByItemID(item.id!);

                          if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_stock")){
                            await FireBaseUtils.deleteGenStockRecord(item);
                          }

                          await _loadItems();
                          Navigator.pop(context);
                        },
                        child:  Text("Delete".tr(),
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed) {
                  await DatabaseHelper.deleteGeneralStockItem(item.id!);
                  _loadItems(); // reload the list after deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text("Stock item deleted".tr())),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController();
    String? selectedCategory;

    final categories = [
      "Cleaning Items",
      "Packaging",
      "Materials",
      "Fuel",
      "Stationery",
      "Accessories",
      "Storage",
      "Other",
    ];


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 18,
                  right: 18,
                  top: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
                    // --------------------- GRAB HANDLE ---------------------
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
              
                    // --------------------- TITLE ---------------------
                    const Text(
                      "Add Stock Item",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
              
                    // --------------------- ITEM NAME ---------------------
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Item Name",
                        prefixIcon: const Icon(Icons.label_important_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
              
                    // --------------------- CATEGORY SELECTION ---------------------
                    const Text(
                      "Category",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
              
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((c) {
                        final isSelected = selectedCategory == c;
                        return GestureDetector(
                          onTap: () => setState(() {
                            selectedCategory = c;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              
                    const SizedBox(height: 10),
              
              // --------------------- SHOW CUSTOM CATEGORY FIELD IF "OTHER" ---------------------
                    if (selectedCategory == "Other")
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: TextField(
                          controller: catCtrl, // ← OPTIONAL: you can also use another controller
                          decoration: InputDecoration(
                            labelText: "Category Name",
                            prefixIcon: const Icon(Icons.edit),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
              
                    const SizedBox(height: 20),
              
              
                    // --------------------- UNIT ---------------------
                    TextField(
                      controller: unitCtrl,
                      decoration: InputDecoration(
                        labelText: "Unit (kg, pcs, litre)",
                        prefixIcon: const Icon(Icons.scale),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
              
                    // --------------------- MIN QUANTITY ---------------------
                    TextField(
                      controller: minQtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Minimum Quantity",
                        prefixIcon: const Icon(Icons.warning_rounded, color: Colors.orange),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
              
                    const SizedBox(height: 22),
              
                    // --------------------- SAVE BUTTON ---------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty || selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill all required fields"),
                              ),
                            );
                            return;
                          }
              
                          final item = GeneralStockItem(
                            name: nameCtrl.text.trim(),
                            category: selectedCategory == "Other"
                          ? catCtrl.text.trim()
                              : selectedCategory!,
                            unit: unitCtrl.text.trim(),
                            minQuantity: double.tryParse(minQtyCtrl.text) ?? 0,
                            createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            sync_id: Utils.getUniueId(),
                              sync_status : SyncStatus.SYNCED,
                              modified_by : Utils.isMultiUSer? Utils.currentUser!.email : "",
                              last_modified : Utils.getTimeStamp(),
                             farm_id : Utils.isMultiUSer? Utils.currentUser!.farmId : ""

                          );
              
                          await DatabaseHelper.insertGeneralStockItem(item);

                          if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                            await FireBaseUtils.uploadGenStockRecord(item);
                          }

                          Navigator.pop(context);
                          _loadItems();
                        },
                        child: const Text(
                          "Save Item",
                          style: TextStyle(
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

}
