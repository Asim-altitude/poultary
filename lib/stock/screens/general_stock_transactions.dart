import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';

import '../../multiuser/model/general stock_transactions_fb.dart';
import '../../utils/utils.dart';
import '../model/general_stock.dart';
import '../model/stock_transactions.dart';

class GeneralStockTransactionsScreen extends StatefulWidget {

  GeneralStockItem generalStockItem;
  GeneralStockTransactionsScreen({Key? key, required this.generalStockItem}) : super(key: key);

  @override
  State<GeneralStockTransactionsScreen> createState() =>
      _GeneralStockTransactionsScreenState();
}

class _GeneralStockTransactionsScreenState
    extends State<GeneralStockTransactionsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<GeneralStockTransaction> inTransactions = [];
  List<GeneralStockTransaction> outTransactions = [];
  List<GeneralStockTransaction> allTransactions = [];
  List<GeneralStockItem> allItems = [];
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }
  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }


  Future<void> _loadTransactions() async {
   // allItems = await DatabaseHelper.getAllGeneralStockItems();
    allItems = [];
    allItems.add(widget.generalStockItem);
    final transactions = await DatabaseHelper.getStockTransactionsForItem(widget.generalStockItem.id!);

    setState(() {
      allTransactions = transactions;
      inTransactions =
          transactions.where((t) => t.type == 'IN').toList();
      outTransactions =
          transactions.where((t) => t.type == 'OUT').toList();
    });

  }

  void _showAddTransactionDialog(String defaultType) {
    GeneralStockItem? selectedItem;
    final quantityCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = defaultType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 18,
              right: 18,
              top: 12),
          child: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                   Text(
                    "Add Stock Transaction".tr(),
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Stock Item Dropdown
                  DropdownButtonFormField<GeneralStockItem>(
                    decoration: InputDecoration(
                      labelText: "Select Item".tr(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    items: allItems
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    ))
                        .toList(),
                    value: selectedItem,
                    onChanged: (v) => setState(() => selectedItem = v),
                  ),
                  const SizedBox(height: 12),

                  // Type Toggle
                  Row(
                    children: [
                      ChoiceChip(
                        label:  Text("IN".tr()),
                        selected: type == "IN",
                        onSelected: (_) => setState(() => type = "IN"),
                        selectedColor: Colors.green.shade100,
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label:  Text("OUT".tr()),
                        selected: type == "OUT",
                        onSelected: (_) => setState(() => type = "OUT"),
                        selectedColor: Colors.red.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quantity
                  TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Quantity".tr(),
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cost per unit
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == "IN"? "Cost per unit (optional)".tr() : "Profit per unit (optional)".tr(),
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: "Notes (optional)".tr(),
                      prefixIcon: const Icon(Icons.note),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () async {

                        GeneralStockTransactionFB genTransFB;

                        if (selectedItem == null ||
                            quantityCtrl.text.isEmpty) return;

                        final qty = double.tryParse(quantityCtrl.text) ?? 0;
                        final cost = double.tryParse(costCtrl.text) ?? 0;

                        final transaction = GeneralStockTransaction(
                          itemId: selectedItem!.id!,
                          type: type,
                          quantity: qty,
                          costPerUnit: cost,
                          totalCost: cost != null ? cost * qty : null,
                          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          notes: notesCtrl.text,
                          sync_id: Utils.getUniueId(),
                          sync_status: SyncStatus.SYNCED,
                          farm_id: Utils.isMultiUSer? Utils.currentUser!.farmId : "",
                          modified_by: Utils.isMultiUSer? Utils.currentUser!.email : "",
                          last_modified: Utils.getTimeStamp()
                        );



                        genTransFB = GeneralStockTransactionFB(stock_sync_id: widget.generalStockItem.sync_id!, stockTransaction: transaction);
                        if(cost > 0) {
                          final finTrans = TransactionItem(f_id: -1,
                              date: transaction.date,
                              f_name: "Farm Wide",
                              sale_item: selectedItem!.name,
                              expense_item: selectedItem!.name,
                              type: type == "IN" ? "Expense" : "Income",
                              amount: transaction.totalCost.toString(),
                              unitPrice: transaction.costPerUnit,
                              payment_method: "CASH",
                              payment_status: "CLEARED",
                              sold_purchased_from: "Unknown",
                              short_note: notesCtrl.text.toString(),
                              how_many: transaction.quantity.toString(),
                              extra_cost: "extra_cost",
                              extra_cost_details: "extra_cost_details",
                              flock_update_id: "-1",
                              sync_id: Utils.getUniueId(),
                              sync_status: SyncStatus.SYNCED,
                              farm_id: Utils.isMultiUSer? Utils.currentUser!.farmId : "",
                              modified_by: Utils.isMultiUSer? Utils.currentUser!.email : "",
                              last_modified: Utils.getTimeStamp());
                          int? trId = await DatabaseHelper.insertNewTransaction(
                              finTrans);
                          transaction.trId = trId;
                          genTransFB.transactionItem = finTrans;
                        }


                        await DatabaseHelper.insertStockTransaction(transaction);

                        if(type=="IN"){
                        double currQty =  selectedItem!.currentQuantity;
                        double addedQty = qty;
                        double totalQty = currQty + addedQty;
                        selectedItem!.currentQuantity = totalQty;
                        await DatabaseHelper.updateGeneralStockItem(selectedItem!);
                        }else{
                          double currQty =  selectedItem!.currentQuantity;
                          double addedQty = qty;
                          double totalQty = currQty - addedQty;
                          selectedItem!.currentQuantity = totalQty;
                          await DatabaseHelper.updateGeneralStockItem(selectedItem!);
                        }


                        if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                          await FireBaseUtils.uploadGenStockTransRecord(genTransFB);
                        }

                        Navigator.pop(context);
                        _loadTransactions();
                      },
                      child:  Text(
                        "Save Transaction".tr(),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _transactionCard(GeneralStockTransaction t) {
    final item = allItems.firstWhere((i) => i.id == t.itemId,
        orElse: () => GeneralStockItem(
            id: 0,
            name: "Unknown",
            category: "",
            unit: "",
            currentQuantity: 0,
            minQuantity: 0,
            createdAt: ""));

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title:  Text("Confirm Delete".tr()),
            content:  Text("Are you sure you want to delete this entry?".tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child:  Text("CANCEL".tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child:  Text("Delete".tr(), style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {

        GeneralStockTransactionFB generalStockTransactionFB;
        TransactionItem? transactionItem = await DatabaseHelper.getSingleTransaction(t.id.toString());
        generalStockTransactionFB = GeneralStockTransactionFB(stock_sync_id: widget.generalStockItem.sync_id!, stockTransaction: t);
        if(transactionItem != null)
          generalStockTransactionFB.transactionItem = transactionItem;

        await DatabaseHelper.deleteStockTransaction(t.id!);
        if(t.trId != null) {
          await DatabaseHelper.deleteItem("Transactions", t.trId!);
        }

        GeneralStockItem? generalStockItem = await DatabaseHelper.getGenStockItemById(t.itemId);
        if(t.type=="IN") {
          double currQty =  generalStockItem!.currentQuantity;
          double addedQty = t.quantity;
          double totalQty = currQty - addedQty;
          generalStockItem.currentQuantity = totalQty;
          await DatabaseHelper.updateGeneralStockItem(generalStockItem);
        } else {
          double currQty =  generalStockItem!.currentQuantity;
          double addedQty = t.quantity;
          double totalQty = currQty + addedQty;
          generalStockItem.currentQuantity = totalQty;
          await DatabaseHelper.updateGeneralStockItem(generalStockItem);
        }

        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_stock")){
          await FireBaseUtils.deleteGenStockTransRecord(generalStockTransactionFB);
        }

        _loadTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction deleted")),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor:
            t.type == "IN" ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              t.type == "IN" ? Icons.arrow_downward : Icons.arrow_upward,
              color: t.type == "IN" ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Qty".tr()+": ${t.quantity} ${item.unit}"),
              if (t.totalCost != null)
                Text("Total Cost".tr()+": ${t.totalCost!.toStringAsFixed(2)}"),
              Text("Date".tr()+": ${t.date}"),
              if (t.notes != null && t.notes!.isNotEmpty)
                Text("Notes".tr()+": ${t.notes}"),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total IN and OUT
    final totalIn = inTransactions.fold<double>(
        0, (sum, t) => sum + t.quantity);
    final totalOut = outTransactions.fold<double>(
        0, (sum, t) => sum + t.quantity);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title:  Text("Stock Transactions".tr(), style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs:  [
            Tab(text: "IN".tr()),
            Tab(text: "OUT".tr()),
          ],
        ),
      ),
      body: Column(
        children: [
          Utils.showBannerAd(_bannerAd, _isBannerAdReady),

          // ------------------- TOTAL IN/OUT SUMMARY -------------------
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      totalIn.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                     Text("Total IN".tr(),
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      totalOut.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                     Text("Total OUT".tr(),
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          // ------------------- TAB VIEW -------------------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: inTransactions.length,
                  itemBuilder: (context, index) =>
                      _transactionCard(inTransactions[index]),
                ),
                ListView.builder(
                  itemCount: outTransactions.length,
                  itemBuilder: (context, index) =>
                      _transactionCard(outTransactions[index]),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(
            _tabController.index == 0 ? "IN" : "OUT"),
        child: const Icon(Icons.add),
      ),
    );
  }

}
