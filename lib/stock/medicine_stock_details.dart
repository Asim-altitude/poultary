import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../model/medicine_stock_history.dart';
import '../model/medicine_stock_summary.dart';
import '../model/stock_expense.dart';
import '../model/transaction_item.dart';
import '../multiuser/model/medicinestockfb.dart';
import '../multiuser/utils/FirebaseUtils.dart';
import '../multiuser/utils/SyncStatus.dart';
import '../utils/utils.dart';

class MedicineStockDetailScreen extends StatefulWidget{
  final MedicineStockSummary stock;
  final List<MedicineStockHistory> stockHistory;

  MedicineStockDetailScreen({Key? key, required this.stock, required this. stockHistory}) : super(key: key);

  @override
  _MedicineStockDetailScreen  createState() => _MedicineStockDetailScreen();
}

class _MedicineStockDetailScreen extends State<MedicineStockDetailScreen> {
  BannerAd? _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,

      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _heightBanner = 60;
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _heightBanner = 0;
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }
  @override
  void initState() {
    super.initState();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
  }
  @override
  void dispose() {
    try{
      _bannerAd?.dispose();
    }catch(ex){

    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Medicine Stock Details".tr())),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),
      
              _buildStockItem(widget.stock),
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  "Stock History".tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),
      
              // Use Expanded correctly here
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(10),
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
                          "${entry.quantity} ${entry.unit} of ${entry.medicineName}",
                          style: TextStyle(fontSize: 16),
                        ),
                        subtitle: Text("DATE: ${Utils.getFormattedDate(entry.date)}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {


                            if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_health")){
                              Utils.showMissingPermissionDialog(context, "delete_health");
                              return;
                            }



                            final confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Delete Entry".tr()),
                                content: Text("Are you sure you want to delete this stock entry?".tr()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("CANCEL".tr())),
                                  TextButton(
                                    onPressed: () async {
                                      entry.sync_status = SyncStatus.DELETED;
                                      MedicineStockFB medicineStockFB = MedicineStockFB(stock: entry);
      
                                      StockExpense? stockExpense = await DatabaseHelper.getByStockItemId(entry.id!);
                                      if (stockExpense != null) {
                                        TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(stockExpense.transactionId.toString());
                                        medicineStockFB.transaction = transaction;
                                        medicineStockFB.transaction!.sync_status = SyncStatus.DELETED;
      
                                        await DatabaseHelper.deleteByStockItemId(entry.id!);
                                        await DatabaseHelper.deleteItem("Transactions", stockExpense.transactionId);
                                      }
                                      await deleteMedicineStock(entry.id!);
                                      Utils.showToast("SUCCESSFUL".tr());
      
                                      if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_medicine")) {
                                        medicineStockFB.sync_id = entry.sync_id;
                                        medicineStockFB.sync_status = SyncStatus.DELETED;
                                        medicineStockFB.last_modified = Utils.getTimeStamp();
                                        medicineStockFB.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                        medicineStockFB.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';
      
                                        await FireBaseUtils.updateMedicineStock(medicineStockFB);
                                      }
      
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
      
                            if (confirm ?? false) {
                              // Already deleted in dialog
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

