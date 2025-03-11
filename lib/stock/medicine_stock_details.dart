import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../model/medicine_stock_history.dart';
import '../model/medicine_stock_summary.dart';
import '../utils/utils.dart';

class MedicineStockDetailScreen extends StatelessWidget {
  final MedicineStockSummary stock;
  final List<MedicineStockHistory> stockHistory;

  MedicineStockDetailScreen({required this.stock, required this.stockHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medicine Stock Details".tr())),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStockItem(stock),
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
                  itemCount: stockHistory.length,
                  itemBuilder: (context, index) {
                    final entry = stockHistory[index];
                    return Dismissible(
                      key: Key(entry.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Entry".tr()),
                            content: Text("Are you sure you want to delete this medicine entry?".tr()),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  deleteMedicineStock(entry.id!);
                                  Navigator.of(context).pop(true);
                                },
                                child: Text("DELETE".tr(), style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        deleteMedicineStock(entry.id!);
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(Icons.medication, color: Colors.blue),
                          title: Text(
                            "${entry.quantity} ${entry.unit} of ${entry.medicineName}",
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text("DATE"+": ${Utils.getFormattedDate(entry.date)}"),
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

  Widget _buildStockItem(MedicineStockSummary stock) {
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
                    stock.medicineName.tr() +" (${stock.unit})",
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
                    Text("Total Stock"+": ${stock.totalStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
                      "Available"+": ${stock.availableStock} ${stock.unit}",
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
                      "⚠️"+ "LOW STOCK",
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
      'MedicineStockHistory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

