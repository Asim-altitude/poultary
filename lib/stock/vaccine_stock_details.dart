import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/vaccine_stock_history.dart';
import 'package:poultary/model/vaccine_stock_summary.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:sqflite/sqflite.dart';

import '../model/medicine_stock_history.dart';
import '../model/medicine_stock_summary.dart';
import '../model/stock_expense.dart';
import '../model/transaction_item.dart';
import '../multiuser/model/vaccinestockfb.dart';
import '../multiuser/utils/FirebaseUtils.dart';
import '../utils/utils.dart';

class VaccineStockDetailScreen extends StatefulWidget{
  final VaccineStockSummary stock;
  final List<VaccineStockHistory> stockHistory;

  VaccineStockDetailScreen({Key? key, required this.stock, required this. stockHistory}) : super(key: key);

  @override
  _VaccineStockDetailScreen  createState() => _VaccineStockDetailScreen();
}

class _VaccineStockDetailScreen extends State<VaccineStockDetailScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vaccine Stock Details".tr())),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStockItem(widget.stock),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text("Stock History".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: widget.stockHistory.length,
                  itemBuilder: (context, index) {
                    final entry = widget.stockHistory[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.medication, color: Colors.blue),
                        title: Text(
                          "${entry.quantity} ${entry.unit} of ${entry.vaccineName}",
                          style: TextStyle(fontSize: 16),
                        ),
                        subtitle: Text("DATE".tr()+": ${Utils.getFormattedDate(entry.date)}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Delete Entry".tr()),
                                content: Text("Are you sure you want to delete this stock entry?".tr()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("CANCEL".tr())),
                                  TextButton(
                                    onPressed: () async {
                                      // _deleteStock(entry.id);
                                      entry.sync_status = SyncStatus.DELETED;
                                      VaccineStockFB vaccineStockfb = VaccineStockFB(stock: entry);
                                      StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(entry.id!);
                                      if(stockExpense != null)
                                      {
                                        TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(stockExpense.transactionId.toString());
                                        vaccineStockfb.transaction = transaction;
                                        vaccineStockfb.transaction!.sync_status = SyncStatus.DELETED;

                                        await DatabaseHelper.deleteByStockItemId(entry.id!);
                                        await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);

                                        vaccineStockfb.transaction = transaction;
                                      }

                                      if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_vaccine")) {
                                        vaccineStockfb.sync_id = entry.sync_id;
                                        vaccineStockfb.sync_status = SyncStatus.DELETED;
                                        vaccineStockfb.last_modified = Utils.getTimeStamp();
                                        vaccineStockfb.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                        vaccineStockfb.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                                        await FireBaseUtils.updateVaccineStock(vaccineStockfb);
                                      }

                                      await deleteMedicineStock(entry.id!);
                                      Utils.showToast("SUCCESSFUL".tr());
                                      setState(() {
                                        widget.stockHistory.remove(entry);
                                      });

                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text("DELETE".tr(), style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(VaccineStockSummary stock) {
    double progress = stock.totalStock > 0 ? stock.usedStock / stock.totalStock : 0.0;
    double usedWidth = progress.clamp(0.0, 1.0);
    double remainingWidth = (1 - progress).clamp(0.0, 1.0);
    bool isLowStock = stock.availableStock <= (stock.totalStock * 0.2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stock.vaccineName.tr() +" (${stock.unit})",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 20),
              ],
            ),

            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Stock".tr()+": ${stock.totalStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    SizedBox(height: 4),
                    Text("Used Stock".tr()+": ${stock.usedStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.red : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Available".tr()+": ${stock.availableStock} ${stock.unit}",
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12),

            if (isLowStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 800),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2)],
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "⚠️"+ "LOW STOCK".tr(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),

            LayoutBuilder(
              builder: (context, constraints) {
                double totalWidth = constraints.maxWidth;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 18,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                      ),
                    ),

                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      width: totalWidth * usedWidth,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                        gradient: LinearGradient(
                          colors: [Colors.orangeAccent, Colors.red],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),

                    Positioned(
                      left: totalWidth * usedWidth,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: totalWidth * remainingWidth,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                          gradient: LinearGradient(
                            colors: isLowStock ? [Colors.red, Colors.orange] : [Colors.lightGreen, Colors.green],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: (totalWidth * usedWidth > 10 ? totalWidth * usedWidth - 10 : 0),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Center(
                          child: Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> deleteMedicineStock(int id) async{

    Database? _database = await DatabaseHelper.instance.database;
    return await _database?.delete(
      'VaccineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );

  }
}

